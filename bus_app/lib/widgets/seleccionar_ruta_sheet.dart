// lib/widgets/seleccionar_ruta_sheet.dart
//
// Bottom sheet para seleccionar la ruta antes de contribuir.

import 'package:flutter/material.dart';
import '../config/app_config.dart';
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
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SeleccionarRutaSheet(
        onRutaSeleccionada: onRutaSeleccionada,
      ),
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

    // Si solo hay una ruta, seleccionarla automáticamente
    if (_rutas.length == 1) {
      widget.onRutaSeleccionada(_rutas.first);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título
          const Text(
            'Selecciona tu ruta',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Elige la ruta del bus en la que vas a viajar',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Lista de rutas
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else if (_rutas.isEmpty)
            const Text('No hay rutas disponibles')
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
      ),
    );
  }

  Widget _buildRutaItem(RutaModel ruta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppConfig.colorAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            ruta.codigo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppConfig.colorPrimary,
            ),
          ),
        ),
        title: Text(ruta.nombre),
        subtitle: Row(
          children: [
            Icon(
              Icons.directions_bus,
              size: 14,
              color: ruta.tieneBusesActivos ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              '${ruta.busesActivos} buses activos',
              style: TextStyle(
                fontSize: 12,
                color: ruta.tieneBusesActivos ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          widget.onRutaSeleccionada(ruta);
        },
      ),
    );
  }
}