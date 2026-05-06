// lib/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/bus_sesion_model.dart';
import '../models/eta_model.dart';
import '../services/api_service.dart';
import '../services/crowdsourcing_service.dart';
import '../services/websocket_service.dart';
import '../widgets/bus_marker.dart';
import '../widgets/bus_marker_animated.dart';
import '../widgets/crowdsourcing_sheet.dart';
import '../widgets/eta_banner.dart';
import '../widgets/seleccionar_ruta_sheet.dart';
import '../widgets/subida_bus_sheet.dart';

class MapScreen extends StatefulWidget {
  final LatLng? coordenadasIniciales;
  final double zoomInicial;
  final VoidCallback? onMapaCentrado;

  const MapScreen({
    super.key,
    this.coordenadasIniciales,
    this.zoomInicial = 16.0,
    this.onMapaCentrado,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api              = ApiService();
  final _crowdsourcing    = CrowdsourcingService();
  final _mapController    = MapController();
  late final WebSocketService _wsService;

  // Estado del mapa
  List<LatLng> _routePoints = [];
  List<BusSesion> _flota = [];
  EtaParada?   _eta;
  String?      _currentSessionId;
  LatLng?      _posicionUsuario;
  bool         _mapaCentradoPorUsuario = true;

  // Estado de carga
  bool    _cargandoRuta = true;
  bool    _cargandoEta  = true;
  String? _errorRuta;

  Timer? _pollingTimer;
  StreamSubscription<Position>? _locationSubscription;

  // -------------------------------------------------------------------------
  // Ciclo de vida
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _crowdsourcing.addListener(_onCrowdsourcingChange);
    _cargarRuta();
    _iniciarPolling();
    _iniciarUbicacion();
    _mostrarSheetSiCorresponde();

    // Si hay coordenadas iniciales (desde RutaDetalle), centrar el mapa
    if (widget.coordenadasIniciales != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.coordenadasIniciales!, widget.zoomInicial);
        widget.onMapaCentrado?.call();
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _locationSubscription?.cancel();
    _crowdsourcing.removeListener(_onCrowdsourcingChange);
    _wsService.dispose();
    _crowdsourcing.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Ubicación del usuario
  // -------------------------------------------------------------------------

  Future<void> _iniciarUbicacion() async {
    // Verificar permisos
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.deniedForever) return;

    // Escuchar cambios de ubicación
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metros
      ),
    ).listen((Position posicion) {
      if (mounted) {
        setState(() {
          _posicionUsuario = LatLng(posicion.latitude, posicion.longitude);
        });
      }
    });
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
        // Primero seleccionar la ruta
        await _seleccionarRutaYContinuar();
      },
      onAhora: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('crowdsourcing_decidido', true);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  /// Flow: seleccionar ruta → confirmar subida al bus → iniciar contribución
  Future<void> _seleccionarRutaYContinuar() async {
    await SeleccionarRutaSheet.mostrar(
      context,
      onRutaSeleccionada: (ruta) async {
        // Guardar ruta_id seleccionada
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ruta_id', ruta.rutaId);

        if (!mounted) return;
        // Mostrar confirmación de subida
        await SubidaBusSheet.mostrar(
          context,
          busId: null,
          onConfirmado: (sessionId) {
            setState(() => _currentSessionId = sessionId);
            _crowdsourcing.setRutaPoints(_routePoints);
            _crowdsourcing.iniciar();
          },
        );
      },
    );
  }

  void _onCrowdsourcingChange() => setState(() {});

  Future<void> _toggleContribucion() async {
    if (_crowdsourcing.estaActivo) {
      _crowdsourcing.detener();
    } else {
      await _seleccionarRutaYContinuar();
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
    // Pasamos los puntos de la ruta al servicio de crowdsourcing para geofencing
    _crowdsourcing.setRutaPoints(puntos);
  }

  void _iniciarPolling() {
    _actualizarFlotaYEta();
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConfig.flotaPollingSegundos),
      (_) => _actualizarFlotaYEta(),
    );
  }

  void _centrarEnUsuario() {
    if (_posicionUsuario != null) {
      _mapController.move(_posicionUsuario!, _mapController.camera.zoom);
      setState(() => _mapaCentradoPorUsuario = true);
    }
  }

  Future<void> _actualizarFlotaYEta() async {
    // Usar session_id del estado, o desde SharedPreferences como fallback
    final prefs = await SharedPreferences.getInstance();
    final sessionId = _currentSessionId ?? prefs.getString('session_id');
    final busId = sessionId ?? 'Bus'; // No hardcodear "Bus-01"

    final resultados = await Future.wait([
      _api.fetchFlota(),
      _api.fetchEta(busId),
    ]);
    if (!mounted) return;
    setState(() {
      _flota = resultados[0] as List<BusSesion>;
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
        backgroundColor: AppConfig.colorPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner de salida de ruta
          if (_crowdsourcing.estado == EstadoContribucion.fueraRuta)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              width: double.infinity,
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dejaste de contribuir (saliste de la ruta)',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          EtaBanner(eta: _eta, cargando: _cargandoEta, busId: _currentSessionId),
          Expanded(child: _buildMapOrState()),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  /// Botones flotantes: contribuir (principal) y centrar mapa (secundario)
  Widget _buildFab() {
    final activo   = _crowdsourcing.estaActivo;
    final ignorado = _crowdsourcing.estado == EstadoContribucion.ignorado;
    final busId    = _crowdsourcing.busAsignado;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Botón centrar en mi ubicación (aparece si el usuario movió el mapa)
        if (!_mapaCentradoPorUsuario && _posicionUsuario != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.small(
              heroTag: 'centrar',
              onPressed: _centrarEnUsuario,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: AppConfig.colorPrimary),
            ),
          ),
        // Botón contribuir
        FloatingActionButton.extended(
          heroTag: 'contribuir',
          onPressed: _toggleContribucion,
          backgroundColor: activo ? AppConfig.colorAccent : AppConfig.colorPrimary,
          icon: Icon(
            activo ? Icons.location_on : Icons.location_off,
            color: activo ? AppConfig.colorPrimary : Colors.white,
          ),
          label: Text(
            activo
                ? (busId != null ? 'En $busId 🟢' : (ignorado ? 'Buscando bus...' : 'Contribuyendo 🟢'))
                : 'Contribuir',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
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

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(9.0561, -79.4582),
            initialZoom: 15.0,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() => _mapaCentradoPorUsuario = false);
              }
            },
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
                  color: AppConfig.colorPrimary.withValues(alpha: 0.6),
                  strokeWidth: 5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                ...buildAnimatedBusMarkers(_flota, _posicionesAnterioresBuses),
                if (_posicionUsuario != null)
                  Marker(
                    point: _posicionUsuario!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      width: 16,
                      height: 16,
                    ),
                  ),
              ],
            ),
          ],
        ),
        // Mensaje cuando no hay buses activos
        if (_flota.isEmpty && !_cargandoRuta)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "No hay buses activos en este momento.\nSé el primero en contribuir.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}