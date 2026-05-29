import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bus_app/theme/export.dart';
import '../services/api_service.dart';

class ConductorScreen extends StatefulWidget {
  final String conductorToken;
  final String nombreConductor;
  final String rutaAsignada;

  const ConductorScreen({
    super.key,
    required this.conductorToken,
    required this.nombreConductor,
    required this.rutaAsignada,
  });

  @override
  State<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends State<ConductorScreen> {
  final _api = ApiService();
  bool _isTracking = false;
  Position? _currentPosition;
  Timer? _gpsTimer;
  Timer? _deadManTimer;
  Timer? _durationTimer;
  String? _error;

  int _posicionesEnviadas = 0;
  Duration _duracionSesion = Duration.zero;
  DateTime? _inicioSesion;
  bool _deadManActivo = false;

  static const int _deadManIntervalSeconds = 300;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _deadManTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  String get _tiempoFormateado {
    final horas = _duracionSesion.inHours;
    final minutos = _duracionSesion.inMinutes.remainder(60);
    final segundos = _duracionSesion.inSeconds.remainder(60);
    if (horas > 0) {
      return '${horas}h ${minutos}m ${segundos}s';
    } else if (minutos > 0) {
      return '${minutos}m ${segundos}s';
    }
    return '${segundos}s';
  }

  String get _velocidadFormateada {
    if (_currentPosition == null) return '-- km/h';
    final kmh = _currentPosition!.speed * 3.6;
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String get _deadManTexto {
    if (!_isTracking) return 'Iniciar Seguimiento';
    if (_deadManActivo) return 'Vivo';
    return 'Tap para confirmar';
  }

  Color get _deadManColor {
    if (!_isTracking) return AppColors.accent;
    return _deadManActivo ? AppColors.accent : AppColors.alert;
  }

  Future<void> _checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _error = 'Activa el GPS en ajustes');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _error = 'Permisos de ubicación denegados');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _error = 'Permisos denegados permanentemente');
      return;
    }

    setState(() => _error = null);
  }

  Future<void> _startTracking() async {
    setState(() {
      _isTracking = true;
      _posicionesEnviadas = 0;
      _duracionSesion = Duration.zero;
      _inicioSesion = DateTime.now();
      _deadManActivo = true;
    });

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      setState(() => _error = 'Error obteniendo ubicación');
      setState(() => _isTracking = false);
      return;
    }

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_inicioSesion != null) {
        setState(() {
          _duracionSesion = DateTime.now().difference(_inicioSesion!);
        });
      }
    });

    _deadManTimer = Timer.periodic(
      Duration(seconds: _deadManIntervalSeconds),
      (_) {
        if (_isTracking && mounted) {
          setState(() => _deadManActivo = false);
          _showDeadManAlert();
        }
      },
    );

    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
          _posicionesEnviadas++;
        });

        await _api.sendConductorPosition(
          widget.conductorToken,
          position.latitude,
          position.longitude,
          position.speed,
        );
      } catch (e) {
        setState(() => _error = 'Error enviando posición');
      }
    });
  }

  void _showDeadManAlert() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Confirma que estás activo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.alert,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'CONFIRMAR',
          textColor: AppColors.white,
          onPressed: _reiniciarDeadMan,
        ),
      ),
    );
  }

  void _reiniciarDeadMan() {
    setState(() => _deadManActivo = true);
  }

  void _stopTracking() {
    _gpsTimer?.cancel();
    _deadManTimer?.cancel();
    _durationTimer?.cancel();
    setState(() {
      _isTracking = false;
      _deadManActivo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: Text(widget.nombreConductor),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión de conductor',
            onPressed: () {
              _stopTracking();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              _buildEstadoIndicator(),
              const SizedBox(height: AppSpacing.xxl),
              _buildMetricsRow(),
              const SizedBox(height: AppSpacing.xxl),
              _buildPositionInfo(),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildErrorBanner(),
              ],
              const Spacer(),
              _buildDeadManButton(),
              const SizedBox(height: AppSpacing.lg),
              _buildControlButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: _isTracking
            ? AppColors.accent.withValues(alpha: 0.2)
            : AppColors.gray300.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: _isTracking ? AppColors.accent : AppColors.gray300,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isTracking ? Icons.gps_fixed : Icons.gps_off,
            color: AppColors.white,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _isTracking ? 'SESIÓN ACTIVA' : 'SESIÓN INACTIVA',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricCard(
          icon: Icons.speed,
          label: 'Velocidad',
          value: _velocidadFormateada,
        ),
        _buildMetricCard(
          icon: Icons.timer,
          label: 'Duración',
          value: _tiempoFormateado,
        ),
        _buildMetricCard(
          icon: Icons.location_on,
          label: 'Envíos',
          value: '$_posicionesEnviadas',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              color: AppColors.alert, fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionInfo() {
    if (_currentPosition == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Text(
          'Sin ubicación disponible',
          style: TextStyle(color: AppColors.white.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: AppColors.white.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}',
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: AppColors.white.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.alert.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.alert, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.alert, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadManButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isTracking ? _reiniciarDeadMan : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _deadManColor,
          foregroundColor: _isTracking ? AppColors.white : AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _deadManActivo ? Icons.check_circle : Icons.warning,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              _deadManTexto,
          style: TextStyle(
              color: AppColors.alert, fontSize: 14,
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _error != null
            ? null
            : _isTracking
                ? _stopTracking
                : _startTracking,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isTracking ? AppColors.alert : AppColors.accent,
          foregroundColor: _isTracking ? AppColors.white : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          disabledBackgroundColor: AppColors.textSecondary,
        ),
        child: _isTracking
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Detener Seguimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Iniciar Seguimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
