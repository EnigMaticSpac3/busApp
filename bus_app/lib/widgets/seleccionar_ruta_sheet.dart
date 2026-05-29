import 'package:flutter/material.dart';
import 'package:bus_app/widgets/app_bottom_sheet.dart';
import 'package:bus_app/widgets/route_badge.dart';
import 'package:bus_app/theme/export.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';

class SeleccionarRutaSheet extends StatefulWidget {
  final void Function(RutaModel ruta) onRutaSeleccionada;

  const SeleccionarRutaSheet({
    super.key,
    required this.onRutaSeleccionada,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required void Function(RutaModel ruta) onRutaSeleccionada,
  }) {
    return AppBottomSheet.mostrar(
      context,
      child: SeleccionarRutaSheet(onRutaSeleccionada: onRutaSeleccionada),
    );
  }

  @override
  State<SeleccionarRutaSheet> createState() => _SeleccionarRutaSheetState();
}

class _SeleccionarRutaSheetState extends State<SeleccionarRutaSheet> {
  final _api = ApiService();
  List<RutaModel> _rutas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRutas();
  }

  Future<void> _cargarRutas() async {
    final rutas = await _api.fetchRutas();
    if (!mounted) return;
    setState(() {
      _rutas = rutas;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Selecciona tu ruta',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Elige la ruta del bus en la que vas a viajar',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_cargando)
          const Center(child: CircularProgressIndicator())
        else if (_rutas.isEmpty)
          Text('No hay rutas disponibles',
              style: TextStyle(color: AppColors.textSecondary))
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _rutas.length,
              itemBuilder: (context, index) => _buildRutaItem(_rutas[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildRutaItem(RutaModel ruta) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: RouteBadge(codigo: ruta.codigo),
        title: Text(ruta.nombre),
        subtitle: Row(
          children: [
            Icon(
              Icons.directions_bus,
              size: 14,
              color: ruta.tieneBusesActivos ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${ruta.busesActivos} buses activos',
              style: TextStyle(
                fontSize: 12,
                color: ruta.tieneBusesActivos ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () {
          Navigator.pop(context);
          widget.onRutaSeleccionada(ruta);
        },
      ),
    );
  }
}
