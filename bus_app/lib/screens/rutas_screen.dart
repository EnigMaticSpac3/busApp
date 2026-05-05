// lib/screens/rutas_screen.dart
//
// Pantalla de selección de rutas - lista de rutas disponibles.

import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';
import 'ruta_detalle_screen.dart';

class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  final _api = ApiService();
  List<RutaModel> _rutas = [];
  bool _cargando = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _cargarRutas();
    // Polling automático cada 5 segundos
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _cargarRutas(soloActualizar: true),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
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
        backgroundColor: AppConfig.colorPrimary,
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
              onPressed: _cargarRutas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_rutas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay rutas disponibles',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarRutas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rutas.length,
        itemBuilder: (context, index) => _buildRutaCard(_rutas[index]),
      ),
    );
  }

  Widget _buildRutaCard(RutaModel ruta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RutaDetalleScreen(ruta: ruta),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Código de ruta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConfig.colorAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ruta.codigo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppConfig.colorPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Nombre y buses activos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 14,
                          color: ruta.tieneBusesActivos
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ruta.busesActivos} buses activos',
                          style: TextStyle(
                            fontSize: 13,
                            color: ruta.tieneBusesActivos
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ruta.tieneBusesActivos
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ruta.tieneBusesActivos
                            ? Colors.green
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ruta.tieneBusesActivos ? 'Activa' : 'Sin servicio',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: ruta.tieneBusesActivos
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}