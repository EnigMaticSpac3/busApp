// lib/screens/conductor_screen.dart
//
// Pantalla del conductor - modo minimalista para tracking GPS.
// UI/UX mejorada: velocidad, duración, contador, Dead Man's Switch.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
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

  static const int _deadManIntervalSeconds = 25;

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
    if (_deadManActivo) return '✅ Vivo';
    return '⚠️ Tap para confirmar';
  }

  Color get _deadManColor {
    if (!_isTracking) return AppConfig.colorAccent;
    return _deadManActivo ? Colors.green : AppConfig.colorAlert;
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
          '⚠️ Confirma que estás activo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConfig.colorAlert,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'CONFIRMAR',
          textColor: Colors.white,
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
      backgroundColor: AppConfig.colorPrimary,
      appBar: AppBar(
        title: Text(widget.nombreConductor),
        backgroundColor: AppConfig.colorPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildEstadoIndicator(),
              const SizedBox(height: 24),
              _buildMetricsRow(),
              const SizedBox(height: 24),
              _buildPositionInfo(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(),
              ],
              const Spacer(),
              _buildDeadManButton(),
              const SizedBox(height: 16),
              _buildControlButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _isTracking
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isTracking ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isTracking ? Icons.gps_fixed : Icons.gps_off,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _isTracking ? 'SESIÓN ACTIVA' : 'SESIÓN INACTIVA',
            style: const TextStyle(
              color: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppConfig.colorAccent, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Sin ubicación disponible',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppConfig.colorAlert.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppConfig.colorAlert, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppConfig.colorAlert, fontSize: 14),
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
          foregroundColor: _isTracking ? Colors.white : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _deadManActivo ? Icons.check_circle : Icons.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _deadManTexto,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
          backgroundColor: _isTracking ? Colors.red : AppConfig.colorAccent,
          foregroundColor: _isTracking ? Colors.white : AppConfig.colorPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey,
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