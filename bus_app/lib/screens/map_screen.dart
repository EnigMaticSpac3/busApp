import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/bus_sesion_model.dart';
import '../models/parada_model.dart';
import '../services/api_service.dart';
import '../services/crowdsourcing_service.dart';
import '../services/websocket_service.dart';
import '../widgets/bus_marker_widget.dart';
import '../widgets/crowdsourcing_sheet.dart';
import '../widgets/stop_marker.dart';
import '../widgets/stop_detail_sheet.dart';
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
  LatLng?      _posicionUsuario;
  bool         _mapaCentradoPorUsuario = true;
  Map<String, LatLng> _posicionesAnterioresBuses = {};

  bool    _cargandoRuta = true;
  String? _errorRuta;

  List<ParadaModel> _paradas = [];
  double _currentZoom = 15.0;

  Timer? _pollingTimer;
  StreamSubscription<Position>? _locationSubscription;
  bool _emptyBannerDismissed = false;

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
    _loadEmptyBannerPreference();

    if (widget.coordenadasIniciales != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.coordenadasIniciales!, widget.zoomInicial);
        widget.onMapaCentrado?.call();
      });
    }
  }

  Future<void> _loadEmptyBannerPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _emptyBannerDismissed = prefs.getBool('empty_banner_dismissed') ?? false;
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
    final response = await _api.fetchRuta();
    if (!mounted) return;
    if (response == null) {
      setState(() {
        _cargandoRuta = false;
        _errorRuta = 'No se pudo cargar la ruta';
      });
      return;
    }
    setState(() {
      _cargandoRuta = false;
      _routePoints = response.puntos;
    });
    _crowdsourcing.setRutaPoints(response.puntos);
    await _cargarParadas(response.rutaId);
  }

  Future<void> _cargarParadas(String rutaId) async {
    final paradas = await _api.fetchParadas(rutaId);
    if (!mounted) return;
    setState(() {
      _paradas = paradas;
    });
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
      _mapController.move(_posicionUsuario!, 16.0);
      setState(() => _mapaCentradoPorUsuario = true);
    }
  }

  Future<void> _onStopTap(ParadaModel parada) async {
    final response = await _api.fetchEtaParada(parada.paradaId);
    if (!mounted) return;

    StopDetailSheet.mostrar(
      context,
      paradaNombre: parada.nombre,
      paradaId: parada.paradaId,
      etas: response?.buses.map((b) => EtaCard(
        rutaCodigo: b.rutaCodigo,
        destino: b.rutaId,
        eta: b.eta,
        minutos: _parseMinutos(b.eta),
      )).toList() ?? [],
    );
  }

  int _parseMinutos(String eta) {
    final match = RegExp(r'(\d+)\s*min').firstMatch(eta);
    if (match != null) return int.parse(match.group(1)!);
    return eta.contains('Menos de 1 min') ? 0 : 999;
  }

  Future<void> _actualizarFlotaYEta() async {
    final posicionesActuales = <String, LatLng>{};
    for (final bus in _flota) {
      if (bus.lat != 0 && bus.lon != 0) {
        posicionesActuales[bus.sessionId] = LatLng(bus.lat, bus.lon);
      }
    }

    final flota = await _api.fetchFlota();
    if (!mounted) return;
    setState(() {
      _posicionesAnterioresBuses = posicionesActuales;
      _flota = flota;
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
            minZoom: 12.0,
            maxZoom: 18.0,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() => _mapaCentradoPorUsuario = false);
              }
              final newZoom = position.zoom;
              final zoomCambioSignificativo = (newZoom - _currentZoom).abs() >= 1;
              final cruceUmbral = (_currentZoom < 15 && newZoom >= 15) ||
                                  (_currentZoom >= 15 && newZoom < 15);
              if (zoomCambioSignificativo || cruceUmbral) {
                setState(() => _currentZoom = newZoom);
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
                if (_currentZoom >= 15)
                  ..._paradas.map((parada) => Marker(
                    point: LatLng(parada.lat, parada.lon),
                    width: _currentZoom >= 16 ? 24 : 18,
                    height: _currentZoom >= 16 ? 24 : 18,
                    child: GestureDetector(
                      onTap: () => _onStopTap(parada),
                      child: StopMarker(
                        orden: parada.orden,
                        size: _currentZoom >= 16 ? 24 : 18,
                        showNumber: _currentZoom >= 16,
                      ),
                    ),
                  )),
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
        if (_flota.isEmpty && !_cargandoRuta && !_emptyBannerDismissed)
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
                  onDismiss: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('empty_banner_dismissed', true);
                    if (mounted) {
                      setState(() => _emptyBannerDismissed = true);
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
