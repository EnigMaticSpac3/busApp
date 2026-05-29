import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bus_app/theme/export.dart';
import 'package:bus_app/widgets/route_badge.dart';
import '../models/bus_sesion_model.dart';
import '../models/parada_model.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';

class RutaDetalleScreen extends StatefulWidget {
  final RutaModel ruta;
  final void Function(double lat, double lon)? onCentrarEn;

  const RutaDetalleScreen({super.key, required this.ruta, this.onCentrarEn});

  @override
  State<RutaDetalleScreen> createState() => _RutaDetalleScreenState();
}

class _RutaDetalleScreenState extends State<RutaDetalleScreen> {
  final _api = ApiService();
  final _mapController = MapController();
  List<ParadaModel> _paradas = [];
  List<BusSesion> _flota = [];
  bool _cargando = true;
  String? _error;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _cargarParadas();
    _cargarFlota();
    _iniciarPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarParadas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final paradas = await _api.fetchParadas(widget.ruta.rutaId);
    if (!mounted) return;
    setState(() {
      _paradas = paradas;
      _cargando = false;
      _error = paradas.isEmpty ? 'No se pudieron cargar las paradas' : null;
    });
  }

  Future<void> _cargarFlota() async {
    final flota = await _api.fetchFlota();
    if (!mounted) return;
    setState(() {
      _flota = flota.where((b) => b.rutaId == widget.ruta.rutaId).toList();
    });
  }

  void _iniciarPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _cargarFlota(),
    );
  }

  void _centrarEnParada(double lat, double lon) {
    _mapController.move(LatLng(lat, lon), 17.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RouteBadge(codigo: widget.ruta.codigo),
            const SizedBox(width: AppSpacing.sm),
            Text(widget.ruta.codigo),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando && _paradas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _paradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _cargarParadas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildMapView(),
        ),
        _buildBottomSheet(),
      ],
    );
  }

  Widget _buildMapView() {
    final stopPoints = _paradas
        .map((p) => LatLng(p.lat, p.lon))
        .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _paradas.isNotEmpty
                ? LatLng(_paradas.first.lat, _paradas.first.lon)
                : const LatLng(9.0561, -79.4582),
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.bus_app',
            ),
            if (stopPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: stopPoints,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    strokeWidth: 5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                ..._flota.map((bus) => Marker(
                  point: LatLng(bus.lat, bus.lon),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bus.esActivo ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (bus.esActivo)
                          const BoxShadow(
                            color: Color.fromRGBO(200, 213, 39, 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: bus.esActivo ? AppColors.accent : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                )),
                ..._paradas.map((parada) => Marker(
                  point: LatLng(parada.lat, parada.lon),
                  width: 32,
                  height: 32,
                  child: _StopMarker(orden: parada.orden),
                )),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [AppShadows.shadowLg],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              RouteBadge(codigo: widget.ruta.codigo),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.ruta.nombre, style: AppTypography.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.directions_bus, size: 14,
                            color: widget.ruta.tieneBusesActivos ? AppColors.accent : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.ruta.busesActivos} buses activos',
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                            color: widget.ruta.tieneBusesActivos ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: _paradas.length,
              itemBuilder: (context, index) => _buildParadaItem(_paradas[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParadaItem(ParadaModel parada) {
    return InkWell(
      onTap: () => _centrarEnParada(parada.lat, parada.lon),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${parada.orden}',
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                parada.nombre,
                style: AppTypography.textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StopMarker extends StatelessWidget {
  final int orden;
  const _StopMarker({required this.orden});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [AppShadows.shadowSm],
      ),
      child: Center(
        child: Text(
          '$orden',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
