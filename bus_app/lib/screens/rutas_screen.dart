import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';
import 'package:bus_app/widgets/route_badge.dart';
import 'package:bus_app/widgets/empty_state.dart';
import '../models/bus_sesion_model.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';
import 'ruta_detalle_screen.dart';

class RutasScreen extends StatefulWidget {
  final void Function(double lat, double lon, {double zoom})? onCentrarEn;

  const RutasScreen({super.key, this.onCentrarEn});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  final _api = ApiService();
  List<RutaModel> _rutas = [];
  List<BusSesion> _flota = [];
  bool _cargando = true;
  String? _error;
  Timer? _pollingTimer;
  Timer? _flotaTimer;

  @override
  void initState() {
    super.initState();
    _cargarRutas();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _cargarRutas(soloActualizar: true),
    );
    _flotaTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _cargarFlota(),
    );
    _cargarFlota();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _flotaTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarFlota() async {
    final flota = await _api.fetchFlota();
    if (!mounted) return;
    setState(() {
      _flota = flota;
    });
  }

  int _contarBusesActivos(String rutaId) {
    return _flota.where((bus) => bus.rutaId == rutaId && bus.esActivo).length;
  }

  Future<void> _cargarRutas({bool soloActualizar = false}) async {
    if (!soloActualizar) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    final rutas = await _api.fetchRutas();

    if (!mounted) return;

    setState(() {
      _rutas = rutas;
      if (!soloActualizar) _cargando = false;
      if (_rutas.isEmpty && !soloActualizar) _error = 'No se pudieron cargar las rutas';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _cargarRutas,
      );
    }

    if (_rutas.isEmpty) {
      return const EmptyState(
        icon: Icons.directions_bus,
        message: 'No hay rutas disponibles',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cargarRutas(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _rutas.length,
        itemBuilder: (context, index) => _buildRutaCard(_rutas[index]),
      ),
    );
  }

  Widget _buildRutaCard(RutaModel ruta) {
    final busesActivos = _contarBusesActivos(ruta.rutaId);
    final tieneBuses = busesActivos > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: AppColors.gray300.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RutaDetalleScreen(
                ruta: ruta,
                onCentrarEn: widget.onCentrarEn != null
                    ? (lat, lon) => widget.onCentrarEn!(lat, lon)
                    : null,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              RouteBadge(codigo: ruta.codigo, fontSize: 16),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta.nombre,
                      style: AppTypography.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 14,
                          color: tieneBuses ? AppColors.accent : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '$busesActivos buses activos',
                          style: TextStyle(
                            fontSize: 13,
                            color: tieneBuses ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: tieneBuses ? AppColors.lime50 : AppColors.gray50,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tieneBuses ? AppColors.accent : AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      tieneBuses ? 'Activa' : 'Sin servicio',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: tieneBuses ? AppColors.accent : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
