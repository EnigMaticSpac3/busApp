import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/bus_sesion_model.dart';
import '../models/parada_model.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';
import '../services/crowdsourcing_service.dart';
import '../services/websocket_service.dart';
import '../widgets/bus_sesion_adapter.dart';
import '../widgets/map_overlays.dart';
import '../widgets/contribuir_fab.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/connection_banner.dart';
import '../widgets/stop_detail_sheet.dart';
import '../widgets/seleccionar_ruta_sheet.dart';
import '../widgets/subida_bus_sheet.dart';
import '../widgets/crowdsourcing_sheet.dart';
import '../theme/canal_colors.dart';
import '../theme/living_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

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
  late final ApiService _api;
  late final CrowdsourcingService _crowdsourcing;
  final _mapController = MapController();
  WebSocketService? _wsService;
  bool _initialized = false;

  List<LatLng> _routePoints = [];
  List<BusSesion> _flota = [];
  LatLng? _posicionUsuario;
  bool _mapaCentradoPorUsuario = true;

  bool _cargandoRuta = true;
  String? _errorRuta;

  List<ParadaModel> _paradas = [];
  List<RutaModel> _rutas = [];
  double _currentZoom = 15.0;
  double _currentRotation = 0;
  String? _selectedStop;

  Timer? _pollingTimer;
  StreamSubscription<Position>? _locationSubscription;
  bool _emptyBannerDismissed = false;

  /// Build a lookup map from rutaId → codigo for bus route labels.
  Map<String, String> get _rutaIdToCodigo {
    final map = <String, String>{};
    for (final ruta in _rutas) {
      map[ruta.rutaId] = ruta.codigo;
    }
    return map;
  }

  /// Convert real fleet data into adapter objects for TransitMapOverlays.
  List<BusSesionAdapter> get _busAdapters =>
      BusSesionAdapter.fromFlota(_flota, _rutaIdToCodigo);

  /// Convert real stop data into (name, LatLng) tuples for TransitMapOverlays.
  List<(String, LatLng)> get _stopTuples =>
      _paradas.map((p) => (p.nombre, LatLng(p.lat, p.lon))).toList();

  @override
  void initState() {
    super.initState();
    if (widget.coordenadasIniciales != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.coordenadasIniciales!, widget.zoomInicial);
        widget.onMapaCentrado?.call();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _api = context.read<ApiService>();
      _crowdsourcing = context.read<CrowdsourcingService>();
      _wsService = context.read<WebSocketService>();
      _wsService!.addListener(_onWsChange);
      _crowdsourcing.addListener(_onCrowdsourcingChange);

      _iniciarWebSocket();
      _cargarRuta();
      _iniciarPolling();
      _iniciarUbicacion();
      _cargarRutas();
      _mostrarSheetSiCorresponde();
      _loadEmptyBannerPreference();
    }
  }

  Future<void> _loadEmptyBannerPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _emptyBannerDismissed =
            prefs.getBool('empty_banner_dismissed') ?? false;
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
    final wsUrl = AppConfig.backendUrl
        .replaceAll('https://', 'wss://')
        .replaceAll('http://', 'ws://');
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

    _locationSubscription =
        Geolocator.getPositionStream(
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

  Future<void> _cargarRutas() async {
    final rutas = await _api.fetchRutas();
    if (!mounted) return;
    setState(() {
      _rutas = rutas;
    });
  }

  void _iniciarPolling() {
    _actualizarFlota();
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConfig.flotaPollingSegundos),
      (_) => _actualizarFlota(),
    );
  }

  void _centrarEnUsuario() {
    if (_posicionUsuario != null) {
      _mapController.move(_posicionUsuario!, 16.0);
      setState(() => _mapaCentradoPorUsuario = true);
    }
  }

  Future<void> _onStopTap(String stopName) async {
    // Find the parada by name
    final parada = _paradas.firstWhere(
      (p) => p.nombre == stopName,
      orElse: () =>
          ParadaModel(paradaId: '', nombre: stopName, lat: 0, lon: 0, orden: 0),
    );
    if (parada.paradaId.isEmpty) return;

    final response = await _api.fetchEtaParada(parada.paradaId);
    if (!mounted) return;

    StopDetailSheet.mostrar(
      context,
      paradaNombre: parada.nombre,
      paradaId: parada.paradaId,
      etas:
          response?.buses
              .map(
                (b) => StopEtaCard(
                  rutaCodigo: b.rutaCodigo,
                  destino: b.rutaId,
                  eta: b.eta,
                  minutos: _parseMinutos(b.eta),
                ),
              )
              .toList() ??
          [],
    );
  }

  void _onBusTap(String routeCode) {
    // Find a bus with this route code and center on it
    final bus = _busAdapters.firstWhere(
      (b) => b.routeCode == routeCode,
      orElse: () =>
          const BusSesionAdapter(id: '', routeCode: '', position: LatLng(0, 0)),
    );
    if (bus.position != const LatLng(0, 0)) {
      _mapController.move(bus.position, 15.5);
    }
  }

  int _parseMinutos(String eta) {
    final match = RegExp(r'(\d+)\s*min').firstMatch(eta);
    if (match != null) return int.parse(match.group(1)!);
    return eta.contains('Menos de 1 min') ? 0 : 999;
  }

  Future<void> _actualizarFlota() async {
    final flota = await _api.fetchFlota();
    if (!mounted) return;
    setState(() {
      _flota = flota;
    });
  }

  @override
  Widget build(BuildContext context) {
    final livingTheme = context.watch<LivingTheme>();
    final isDark = livingTheme.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Mapa vectorial a pantalla completa
          Positioned.fill(child: _buildMapOrState(isDark)),

          // FABs flotantes
          Positioned(
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: _buildFABs(isDark),
          ),

          // Brújula (se muestra al rotar)
          if (_currentRotation.abs() > 5)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              right: AppSpacing.lg,
              child: _buildCompassButton(isDark),
            ),

          // Banner offline
          if (!(_wsService?.conectado ?? true))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConnectionBanner(
                lastUpdated: 'hace un momento',
                isDark: isDark,
                onRetry: () {
                  _iniciarWebSocket();
                },
              ),
            ),

          // Banner de error crowdsourcing
          if (_crowdsourcing.estado == EstadoContribucion.fueraRuta)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ErrorBanner(
                message: 'Dejaste de contribuir (saliste de la ruta)',
              ),
            ),

          // Banner vacío
          if (_flota.isEmpty && !_cargandoRuta && !_emptyBannerDismissed)
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom + AppSpacing.xxl + 60,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                color: isDark
                    ? CanalColors.darkSurface
                    : CanalColors.lightSurface,
                surfaceTintColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: EmptyState(
                    icon: Icons.directions_bus_outlined,
                    message:
                        'No hay buses activos en este momento.\nSé el primero en contribuir.',
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
      ),
    );
  }

  // ── MAPA ──

  Widget _buildMapOrState(bool isDark) {
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

    return FlutterMap(
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
          if ((newZoom - _currentZoom).abs() >= 1) {
            setState(() => _currentZoom = newZoom);
          }
          final rotation = position.rotation;
          if ((rotation - _currentRotation).abs() > 0.5) {
            setState(() => _currentRotation = rotation);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.bus_app',
        ),
        // ── Capa de paradas (Transita V2 styling) ──
        TransitMapOverlays.stopsLayer(
          isDark: isDark,
          currentZoom: _currentZoom,
          selectedStop: _selectedStop,
          rotation: _currentRotation,
          stops: _stopTuples,
          onStopTap: (name) {
            setState(() {
              _selectedStop = _selectedStop == name ? null : name;
            });
            if (_selectedStop != null) {
              _onStopTap(name);
            }
          },
        ),

        // ── Polilínea de ruta ──
        if (_routePoints.isNotEmpty)
          TransitMapOverlays.routePolylineLayer(
            _routePoints,
            color: CanalColors.primary.withValues(alpha: 0.6),
          ),

        // ── Capa de buses (Transita V2 styling con datos reales) ──
        TransitMapOverlays.busLayer(
          isDark: isDark,
          onBusTap: _onBusTap,
          simulatedBuses: _busAdapters,
          rotation: _currentRotation,
        ),

        // ── Route pill layer (labels sobre buses) ──
        if (_flota.isNotEmpty)
          TransitMapOverlays.routePillLayer(
            buses: _busAdapters,
            isDark: isDark,
            rotation: _currentRotation,
            onBusTap: _onBusTap,
          ),

        // ── Capa de ubicación del usuario ──
        if (_posicionUsuario != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _posicionUsuario!,
                width: 18,
                height: 18,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: CanalColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CanalColors.lightSurface,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CanalColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── FABs ──

  Widget _buildFABs(bool isDark) {
    final activo = _crowdsourcing.estaActivo;
    final ignorado = _crowdsourcing.estado == EstadoContribucion.ignorado;
    final busId = _crowdsourcing.busAsignado;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // FAB reubicar GPS
        if (!_mapaCentradoPorUsuario && _posicionUsuario != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _centrarEnUsuario,
              backgroundColor: isDark
                  ? CanalColors.darkSurface
                  : CanalColors.lightSurface,
              foregroundColor: isDark
                  ? CanalColors.darkTextPrimary
                  : CanalColors.lightTextPrimary,
              elevation: 2,
              child: const Icon(Icons.my_location),
            ),
          ),

        // FAB contribuir
        ContribuirFab(
          activo: activo,
          busId: busId,
          ignorado: ignorado,
          onPressed: _toggleContribucion,
        ),
      ],
    );
  }

  // ── BRÚJULA ──

  Widget _buildCompassButton(bool isDark) {
    return Material(
      color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _mapController.rotate(0);
          setState(() => _currentRotation = 0);
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Transform.rotate(
            angle: _currentRotation * (3.14159 / 180),
            child: const Icon(
              Icons.navigation,
              color: CanalColors.primary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
