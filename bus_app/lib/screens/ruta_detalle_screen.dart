import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';
import 'package:bus_app/widgets/route_badge.dart';
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
  List<ParadaModel> _paradas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarParadas();
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
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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

    if (_paradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No hay paradas en esta ruta',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ruta.nombre,
                style: AppTypography.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.directions_bus,
                    size: 16,
                    color: widget.ruta.tieneBusesActivos ? AppColors.accent : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${widget.ruta.busesActivos} buses activos',
                    style: TextStyle(
                      color: widget.ruta.tieneBusesActivos ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: _paradas.length,
            itemBuilder: (context, index) => _buildParadaItem(_paradas[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildParadaItem(ParadaModel parada) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${parada.orden}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      title: Text(parada.nombre),
      subtitle: Text(
        '${parada.lat.toStringAsFixed(4)}, ${parada.lon.toStringAsFixed(4)}',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ir a: ${parada.nombre}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
