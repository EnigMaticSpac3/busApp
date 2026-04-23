// lib/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/bus_model.dart';
import '../models/eta_model.dart';
import '../services/api_service.dart';
import '../widgets/bus_marker.dart';
import '../widgets/eta_banner.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiService();

  // Estado del mapa
  List<LatLng> _routePoints = [];
  List<Bus>    _flota       = [];
  EtaParada?   _eta;

  // Estado de carga
  bool _cargandoRuta = true;
  bool _cargandoEta  = true;
  String? _errorRuta;

  Timer? _pollingTimer;

  // -------------------------------------------------------------------------
  // Ciclo de vida
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _cargarRuta();
    _iniciarPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Lógica
  // -------------------------------------------------------------------------

  Future<void> _cargarRuta() async {
    final puntos = await _api.fetchRuta();
    if (!mounted) return;

    setState(() {
      _cargandoRuta = puntos.isEmpty ? true : false;
      _errorRuta    = puntos.isEmpty ? 'No se pudo cargar la ruta' : null;
      _routePoints  = puntos;
    });
  }

  void _iniciarPolling() {
    // Llamada inmediata al arrancar, sin esperar el primer tick
    _actualizarFlotaYEta();

    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConfig.flotaPollingSegundos),
      (_) => _actualizarFlotaYEta(),
    );
  }

  /// Obtiene la flota y el ETA de Bus-01 en paralelo para no bloquear uno al otro.
  Future<void> _actualizarFlotaYEta() async {
    final resultados = await Future.wait([
      _api.fetchFlota(),
      _api.fetchEta('Bus-01'),
    ]);

    if (!mounted) return;

    setState(() {
      _flota      = resultados[0] as List<Bus>;
      _eta        = resultados[1] as EtaParada?;
      _cargandoEta = false;
    });
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('San Antonio Bus Tracker'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          EtaBanner(eta: _eta, cargando: _cargandoEta),
          Expanded(child: _buildMapOrState()),
        ],
      ),
    );
  }

  Widget _buildMapOrState() {
    // Error al cargar la ruta
    if (_errorRuta != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorRuta!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarRuta,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Cargando la ruta por primera vez
    if (_cargandoRuta) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(9.0561, -79.4582),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.bus_app',
        ),
        // Traza de la ruta
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              color: Colors.blue.withOpacity(0.6),
              strokeWidth: 4,
            ),
          ],
        ),
        // Marcadores de la flota
        MarkerLayer(
          markers: buildBusMarkers(_flota),
        ),
      ],
    );
  }
}