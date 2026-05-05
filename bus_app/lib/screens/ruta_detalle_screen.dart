// lib/screens/ruta_detalle_screen.dart
//
// Pantalla de detalle de una ruta - lista de paradas en orden.

import 'package:flutter/material.dart';
import '../models/parada_model.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';

class RutaDetalleScreen extends StatefulWidget {
  final RutaModel ruta;

  const RutaDetalleScreen({super.key, required this.ruta});

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
        title: Text(widget.ruta.codigo),
        backgroundColor: const Color(0xFF283C90),
        foregroundColor: Colors.white,
        elevation: 0,
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
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay paradas en esta ruta',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info de la ruta
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF283C90).withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ruta.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.directions_bus,
                    size: 16,
                    color: widget.ruta.tieneBusesActivos
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.ruta.busesActivos} buses activos',
                    style: TextStyle(
                      color: widget.ruta.tieneBusesActivos
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista de paradas
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
          color: const Color(0xFFC8D527).withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${parada.orden}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF283C90),
            ),
          ),
        ),
      ),
      title: Text(parada.nombre),
      subtitle: Text(
        '${parada.lat.toStringAsFixed(4)}, ${parada.lon.toStringAsFixed(4)}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // TODO: navegar al mapa centrado en esta parada
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