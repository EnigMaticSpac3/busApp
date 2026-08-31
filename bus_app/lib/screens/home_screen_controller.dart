// HomeScreenController — extrae lógica de HomeScreen para reducir god widget.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/bus_sesion_model.dart';
import '../models/parada_model.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';
import '../services/crowdsourcing_service.dart';
import '../services/websocket_service.dart';

class HomeScreenController extends ChangeNotifier {
  final ApiService _api;
  final CrowdsourcingService _crowdsourcing;
  final WebSocketService _wsService;

  HomeScreenController({
    required ApiService api,
    required CrowdsourcingService crowdsourcing,
    required WebSocketService wsService,
  })  : _api = api,
        _crowdsourcing = crowdsourcing,
        _wsService = wsService;

  // ── Getters ──
  List<LatLng> get routePoints => _routePoints;
  List<BusSesion> get flota => _flota;
  LatLng? get posicionUsuario => _posicionUsuario;
  Map<String, LatLng> get posicionesAnterioresBuses => _posicionesAnterioresBuses;
  bool get cargandoRuta => _cargandoRuta;
  String? get errorRuta => _errorRuta;
  List<ParadaModel> get paradas => _paradas;
  List<RutaModel> get rutas => _rutas;
  bool get cargandoRutas => _cargandoRutas;
  String? get errorRutas => _errorRutas;
  bool get isOffline => _isOffline;
  bool get emptyBannerDismissed => _emptyBannerDismissed;
  CrowdsourcingService get crowdsourcing => _crowdsourcing;
  WebSocketService get wsService => _wsService;
  ApiService get api => _api;

  // ── Estado ──
  List<LatLng> _routePoints = [];
  List<BusSesion> _flota = [];
  LatLng? _posicionUsuario;
  Map<String, LatLng> _posicionesAnterioresBuses = {};
  bool _cargandoRuta = true;
  String? _errorRuta;
  List<ParadaModel> _paradas = [];
  List<RutaModel> _rutas = [];
  bool _cargandoRutas = true;
  String? _errorRutas;
  bool _isOffline = false;
  bool _emptyBannerDismissed = false;

  Timer? _pollingTimer;
  Timer? _rutasPollingTimer;
  StreamSubscription<Position>? _locationSubscription;

  // ── Lifecycle ──

  void init() {
    _crowdsourcing.addListener(_onServiceChanged);
    _wsService.addListener(_onServiceChanged);

    _iniciarWebSocket();
    cargarRuta();
    _iniciarPolling();
    iniciarUbicacion();
    _cargarRutas();
    _emptyBannerDismissed = false;
  }

  void disposeController() {
    _pollingTimer?.cancel();
    _rutasPollingTimer?.cancel();
    _locationSubscription?.cancel();
    _crowdsourcing.removeListener(_onServiceChanged);
    _wsService.removeListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    // Sync state from services
    _flota = _wsService.flota;
    _isOffline = !_wsService.conectado;
    notifyListeners();
  }

  // ── WebSocket ──

  void _iniciarWebSocket() {
    final wsUrl = AppConfig.backendUrl
        .replaceAll('https://', 'wss://')
        .replaceAll('http://', 'ws://');
    _wsService.conectar('$wsUrl/ws/flota');
  }

  // ── Ubicación GPS ──

  Future<void> iniciarUbicacion() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.deniedForever) return;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position posicion) {
      _posicionUsuario = LatLng(posicion.latitude, posicion.longitude);
      notifyListeners();
    });
  }

  // ── Datos ──

  Future<void> cargarRuta() async {
    final response = await _api.fetchRuta();
    if (response == null) {
      _cargandoRuta = false;
      _errorRuta = 'No se pudo cargar la ruta';
      notifyListeners();
      return;
    }
    _cargandoRuta = false;
    _routePoints = response.puntos;
    _crowdsourcing.setRutaPoints(response.puntos);
    notifyListeners();
    await _cargarParadas(response.rutaId);
  }

  Future<void> _cargarParadas(String rutaId) async {
    final paradas = await _api.fetchParadas(rutaId);
    _paradas = paradas;
    notifyListeners();
  }

  void _iniciarPolling() {
    _actualizarFlota();
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConfig.flotaPollingSegundos),
      (_) => _actualizarFlota(),
    );
    _cargarRutas();
    _rutasPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _cargarRutas(soloActualizar: true),
    );
  }

  Future<void> _actualizarFlota() async {
    final posicionesActuales = <String, LatLng>{};
    for (final bus in _flota) {
      if (bus.lat != 0 && bus.lon != 0) {
        posicionesActuales[bus.sessionId] = LatLng(bus.lat, bus.lon);
      }
    }
    final flota = await _api.fetchFlota();
    _posicionesAnterioresBuses = posicionesActuales;
    _flota = flota;
    notifyListeners();
  }

  Future<void> _cargarRutas({bool soloActualizar = false}) async {
    if (!soloActualizar) {
      _cargandoRutas = true;
      _errorRutas = null;
    }
    final rutas = await _api.fetchRutas();
    _rutas = rutas;
    if (!soloActualizar) _cargandoRutas = false;
    if (_rutas.isEmpty && !soloActualizar) {
      _errorRutas = 'No se pudieron cargar las rutas';
    }
    notifyListeners();
  }

  // ── Crowdsourcing ──

  Future<void> toggleContribucion() async {
    if (_crowdsourcing.estaActivo) {
      _crowdsourcing.detener();
    }
    notifyListeners();
  }

  // ── ETA ──

  int parseMinutos(String eta) {
    final match = RegExp(r'(\d+)\s*min').firstMatch(eta);
    if (match != null) return int.parse(match.group(1)!);
    return eta.contains('Menos de 1 min') ? 0 : 999;
  }

  // ── Map state ──

  void centrarEnUsuario(MapController mapController) {
    if (_posicionUsuario != null) {
      mapController.move(_posicionUsuario!, 16.0);
    }
  }
}
