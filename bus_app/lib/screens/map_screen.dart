// lib/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/bus_model.dart';
import '../models/eta_model.dart';
import '../services/api_service.dart';
import '../services/crowdsourcing_service.dart';
import '../widgets/bus_marker.dart';
import '../widgets/crowdsourcing_sheet.dart';
import '../widgets/eta_banner.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api              = ApiService();
  final _crowdsourcing    = CrowdsourcingService();

  // Estado del mapa
  List<LatLng> _routePoints = [];
  List<Bus>    _flota       = [];
  EtaParada?   _eta;

  // Estado de carga
  bool    _cargandoRuta = true;
  bool    _cargandoEta  = true;
  String? _errorRuta;

  Timer? _pollingTimer;

  // -------------------------------------------------------------------------
  // Ciclo de vida
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _crowdsourcing.addListener(_onCrowdsourcingChange);
    _cargarRuta();
    _iniciarPolling();
    _mostrarSheetSiCorresponde();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _crowdsourcing.removeListener(_onCrowdsourcingChange);
    _crowdsourcing.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Crowdsourcing
  // -------------------------------------------------------------------------

  /// Muestra el bottom sheet solo si el usuario nunca ha tomado una decisión.
  Future<void> _mostrarSheetSiCorresponde() async {
    final prefs = await SharedPreferences.getInstance();
    final yaDecidio = prefs.getBool('crowdsourcing_decidido') ?? false;
    if (yaDecidio || !mounted) return;

    // Pequeña espera para que el mapa cargue primero
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    await CrowdsourcingSheet.mostrar(
      context,
      onContribuir: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('crowdsourcing_decidido', true);
        if (mounted) Navigator.pop(context);
        await _crowdsourcing.iniciar();
      },
      onAhora: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('crowdsourcing_decidido', true);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _onCrowdsourcingChange() => setState(() {});

  Future<void> _toggleContribucion() async {
    if (_crowdsourcing.estaActivo) {
      _crowdsourcing.detener();
    } else {
      await _crowdsourcing.iniciar();
    }
  }

  // -------------------------------------------------------------------------
  // Mapa y polling
  // -------------------------------------------------------------------------

  Future<void> _cargarRuta() async {
    final puntos = await _api.fetchRuta();
    if (!mounted) return;
    setState(() {
      _cargandoRuta = puntos.isEmpty;
      _errorRuta    = puntos.isEmpty ? 'No se pudo cargar la ruta' : null;
      _routePoints  = puntos;
    });
  }

  void _iniciarPolling() {
    _actualizarFlotaYEta();
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConfig.flotaPollingSegundos),
      (_) => _actualizarFlotaYEta(),
    );
  }

  Future<void> _actualizarFlotaYEta() async {
    final resultados = await Future.wait([
      _api.fetchFlota(),
      _api.fetchEta('Bus-01'),
    ]);
    if (!mounted) return;
    setState(() {
      _flota       = resultados[0] as List<Bus>;
      _eta         = resultados[1] as EtaParada?;
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
      floatingActionButton: _buildFab(),
    );
  }

  /// Botón flotante para activar/desactivar la contribución GPS.
  Widget _buildFab() {
    final activo   = _crowdsourcing.estaActivo;
    final ignorado = _crowdsourcing.estado == EstadoContribucion.ignorado;
    final busId    = _crowdsourcing.busAsignado;

    return FloatingActionButton.extended(
      onPressed: _toggleContribucion,
      backgroundColor: activo ? Colors.green : Colors.blueAccent,
      icon: Icon(activo ? Icons.location_on : Icons.location_off),
      label: Text(
        activo
            ? (busId != null ? 'En $busId 🟢' : (ignorado ? 'Buscando bus...' : 'Contribuyendo 🟢'))
            : 'Contribuir',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMapOrState() {
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
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              color: Colors.blue.withOpacity(0.6),
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: buildBusMarkers(_flota),
        ),
      ],
    );
  }
}