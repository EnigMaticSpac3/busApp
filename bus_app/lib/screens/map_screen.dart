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
import '../widgets/bus_marker_widget.dart';
import '../widgets/crowdsourcing_sheet.dart';
import '../widgets/collapsed_eta_card.dart';
import '../widgets/seleccionar_ruta_sheet.dart';
import '../widgets/subida_bus_sheet.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/contribuir_fab.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/floating_map_button.dart';
import '../widgets/user_location_marker.dart';
import '../theme/export.dart';

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
  WebSocketService?        _wsService;

  List<LatLng> _routePoints = [];
  List<BusSesion> _flota = [];
  EtaParada?   _eta;
  String?      _currentSessionId;
  LatLng?      _posicionUsuario;
  bool         _mapaCentradoPorUsuario = true;
  Map<String, LatLng> _posicionesAnterioresBuses = {};

  bool    _cargandoRuta = true;
  bool    _cargandoEta  = true;
  String? _errorRuta;

  Timer? _pollingTimer;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _crowdsourcing.addListener(_onCrowdsourcingChange);
    _wsService = WebSocketService();
    _wsService!.addListener(_onWsChange);
    _iniciarWebSocket();
    _cargarRuta();
    _iniciarPolling();
    _iniciarUbicacion();
    _mostrarSheetSiCorresponde();

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
    _wsService?.removeListener(_onWsChange);
    _wsService?.dispose();
    _crowdsourcing.dispose();
    super.dispose();
  }

  void _iniciarWebSocket() {
    final wsUrl = AppConfig.backendUrl.replaceAll('https://', 'wss://').replaceAll('http://', 'ws://');
    _wsService!.conectar('$wsUrl/ws/flota');
  }

  void _onWsChange() {
    if (mounted) {
      setState(() {
        _flota = _wsService!.flota;
      });
    }
  }

  Future<void> _iniciarUbicacion() async {
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
      if (mounted) {
        setState(() {
          _posicionUsuario = LatLng(posicion.latitude, posicion.longitude);
        });
      }
    });
  }

  Future<void> _mostrarSheetSiCorresponde() async {
    final prefs = await SharedPreferences.getInstance();
    final yaDecidio = prefs.getBool('crowdsourcing_decidido') ?? false;
    if (yaDecidio || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    await CrowdsourcingSheet.mostrar(
      context,
      onContribuir: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('crowdsourcing_decidido', true);
        if (mounted) Navigator.pop(context);
        await _seleccionarRutaYContinuar();
      },
      onAhora: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('crowdsourcing_decidido', true);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  Future<void> _seleccionarRutaYContinuar() async {
    await SeleccionarRutaSheet.mostrar(
      context,
      onRutaSeleccionada: (ruta) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ruta_id', ruta.rutaId);

        if (!mounted) return;
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

  Future<void> _cargarRuta() async {
    final puntos = await _api.fetchRuta();
    if (!mounted) return;
    setState(() {
      _cargandoRuta = puntos.isEmpty;
      _errorRuta    = puntos.isEmpty ? 'No se pudo cargar la ruta' : null;
      _routePoints  = puntos;
    });
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
    final posicionesActuales = <String, LatLng>{};
    for (final bus in _flota) {
      if (bus.lat != 0 && bus.lon != 0) {
        posicionesActuales[bus.sessionId] = LatLng(bus.lat, bus.lon);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionId = _currentSessionId ?? prefs.getString('session_id');
    final busId = sessionId ?? 'Bus';

    final resultados = await Future.wait([
      _api.fetchFlota(),
      _api.fetchEta(busId),
    ]);
    if (!mounted) return;
    setState(() {
      _posicionesAnterioresBuses = posicionesActuales;
      _flota = resultados[0] as List<BusSesion>;
      _eta         = resultados[1] as EtaParada?;
      _cargandoEta = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildMapOrState()),
          if (_crowdsourcing.estado == EstadoContribucion.fueraRuta)
            Positioned(
              top: 0, left: 0, right: 0,
              child: ErrorBanner(message: 'Dejaste de contribuir (saliste de la ruta)'),
            ),
          Positioned(
            left: 0, right: 0,
            bottom: 100,
            child: CollapsedEtaCard(
              eta: _eta,
              cargando: _cargandoEta,
              busId: _currentSessionId,
              webSocketConectado: _wsService?.conectado,
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    final activo   = _crowdsourcing.estaActivo;
    final ignorado = _crowdsourcing.estado == EstadoContribucion.ignorado;
    final busId    = _crowdsourcing.busAsignado;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!_mapaCentradoPorUsuario && _posicionUsuario != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: FloatingMapButton(
              icon: Icons.my_location,
              onPressed: _centrarEnUsuario,
            ),
          ),
        ContribuirFab(
          activo: activo,
          busId: busId,
          ignorado: ignorado,
          onPressed: _toggleContribucion,
        ),
      ],
    );
  }

  Widget _buildMapOrState() {
    if (_errorRuta != null) {
      return EmptyState(
        icon: Icons.wifi_off,
        message: _errorRuta!,
        actionLabel: 'Reintentar',
        onAction: _cargarRuta,
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
                  color: AppColors.primary.withValues(alpha: 0.6),
                  strokeWidth: 5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                ...buildBusMarkers(_flota, _posicionesAnterioresBuses),
                if (_posicionUsuario != null)
                  Marker(
                    point: _posicionUsuario!,
                    child: const UserLocationMarker(),
                  ),
              ],
            ),
          ],
        ),
        // SearchBar overlay — respeta área de notch/isla
        Positioned(
          top: AppSpacing.md + MediaQuery.of(context).padding.top,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: AppSearchBar(),
        ),
        if (_flota.isEmpty && !_cargandoRuta)
          Positioned(
            bottom: 80,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              color: AppColors.white,
              surfaceTintColor: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: EmptyState(
                  icon: Icons.directions_bus_outlined,
                  message: 'No hay buses activos en este momento.\nSé el primero en contribuir.',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
