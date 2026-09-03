import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/bus_sesion_model.dart';
import '../models/parada_model.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';
import '../services/crowdsourcing_service.dart';
import '../services/websocket_service.dart';
import '../services/alert_service.dart';
import '../widgets/search_pill.dart';
import '../widgets/bus_marker_widget.dart';
import '../widgets/canal_vector_map.dart';
import '../widgets/connection_banner.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/route_badge.dart';
import '../widgets/stop_detail_sheet.dart';
import '../widgets/stop_marker.dart';
import '../widgets/user_location_marker.dart';
import '../widgets/status_chip.dart';
import '../widgets/alert_banner.dart';
import '../widgets/ad_banner.dart';
import '../theme/export.dart';
import '../theme/settings_service.dart';
import 'alert_detail_screen.dart';
import 'profile_screen.dart';
import 'route_list_screen.dart';
import 'ruta_detalle_screen.dart';


/// HomeScreen con patrón Citymapper V2: mapa vectorial a pantalla completa
/// como fondo, DraggableScrollableSheet con contenido contextual state-driven
/// (peek → half → search → detail), FAB de reubicación, brújula visible
/// al rotar el mapa.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Servicios (via Provider) ──
  late final ApiService _api;
  late final CrowdsourcingService _crowdsourcing;
  late final AlertService _alertService;
  final _mapController = MapController();
  WebSocketService? _wsService;
  bool _initialized = false;

  // ── Sheet controller ──
  final _sheetController = DraggableScrollableController();
  double _sheetExtent = 0.26;
  double _previousSheetSize = 0.26;

  // ── Search state ──
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();
  bool _searching = false;
  bool _editingOrigin = false;
  String _origin = 'Mi ubicación';
  String _destination = '';
  bool _hasSearched = false;

  // ── Detail state ──
  bool _detailOpen = false;
  int _selectedRouteIndex = 0;

  // ── Map state ──
  List<LatLng> _routePoints = [];
  List<BusSesion> _flota = [];
  LatLng? _posicionUsuario;
  Map<String, LatLng> _posicionesAnterioresBuses = {};
  bool _cargandoRuta = true;
  List<ParadaModel> _paradas = [];
  double _currentZoom = 15.0;
  Timer? _pollingTimer;
  StreamSubscription<Position>? _locationSubscription;
  bool _emptyBannerDismissed = false;

  // ── Routes ──
  List<RutaModel> _rutas = [];

  // ── Compass ──
  double _mapRotation = 0;

  // ── Connection ──
  bool _isOffline = false;

  // ── Context-aware sheet sizes (Transita V2 pattern) ──
  /// Peek: solo muestra los 3 chips de estado (mínimo mapa visible).
  static const _sheetPeekSize = 0.26;
  /// Half: muestra la parada + lista de rutas (~45% pantalla).
  static const _sheetHalfSize = 0.45;
  /// Detail: itinerario de ruta (~55% pantalla).
  static const _sheetDetailSize = 0.55;
  /// Search: editor de origen/destino + resultados (~75% pantalla).
  static const _sheetSearchSize = 0.75;

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _api = context.read<ApiService>();
      _crowdsourcing = context.read<CrowdsourcingService>();
      _alertService = context.read<AlertService>();
      _wsService = context.read<WebSocketService>();
      _wsService!.addListener(_onWsChange);
      _crowdsourcing.addListener(_onCrowdsourcingChange);
      _alertService.addListener(_onAlertChange);

      _iniciarWebSocket();
      _iniciarAlertas();
      _cargarRuta();
      _iniciarPolling();
      _iniciarUbicacion();
      _cargarRutas();
      _loadEmptyBannerPreference();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _locationSubscription?.cancel();
    _crowdsourcing.removeListener(_onCrowdsourcingChange);
    _alertService.removeListener(_onAlertChange);
    _wsService?.removeListener(_onWsChange);
    _wsService?.dispose();
    _crowdsourcing.dispose();
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Listeners ──

  void _onSheetChanged() {
    if (!mounted || !_sheetController.isAttached) return;
    final size = _sheetController.size;
    final ascending = size > _previousSheetSize;
    _previousSheetSize = size;
    if ((size - _sheetExtent).abs() > 0.005) {
      setState(() => _sheetExtent = size);
    }
    // Close search when user drags below half
    if (_searching && !ascending && size < _sheetHalfSize - 0.05 && mounted) {
      _searchFocusNode.unfocus();
      setState(() {
        _searching = false;
        _editingOrigin = false;
        _searchController.clear();
      });
    }
  }

  void _onCrowdsourcingChange() {
    if (mounted) setState(() {});
  }

  void _onAlertChange() {
    if (mounted) setState(() {});
  }

  void _onWsChange() {
    if (mounted) {
      setState(() {
        _flota = _wsService!.flota;
        _isOffline = !(_wsService?.conectado ?? false);
      });
    }
  }

  // ── WebSocket ──

  void _iniciarWebSocket() {
    final wsUrl = AppConfig.backendUrl
        .replaceAll('https://', 'wss://')
        .replaceAll('http://', 'ws://');
    _wsService!.conectar('$wsUrl/ws/flota');
  }

  // ── Alertas ──

  void _iniciarAlertas() {
    // Fetch initial alerts via HTTP
    _alertService.fetchAlerts();
    // Connect WebSocket for real-time alerts
    final wsUrl = AppConfig.backendUrl
        .replaceAll('https://', 'wss://')
        .replaceAll('http://', 'ws://');
    _alertService.connectWebSocket('$wsUrl/ws/alerts');
  }

  // ── Ubicación GPS ──

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

  // ── Datos ──

  Future<void> _loadEmptyBannerPreference() async {
    if (mounted) setState(() => _emptyBannerDismissed = false);
  }

  Future<void> _cargarRuta() async {
    final response = await _api.fetchRuta();
    if (!mounted) return;
    if (response == null) {
      setState(() => _cargandoRuta = false);
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
    setState(() => _paradas = paradas);
  }

  void _iniciarPolling() {
    _actualizarFlota();
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConfig.flotaPollingSegundos),
      (_) => _actualizarFlota(),
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
    if (!mounted) return;
    setState(() {
      _posicionesAnterioresBuses = posicionesActuales;
      _flota = flota;
    });
  }

  Future<void> _cargarRutas() async {
    final rutas = await _api.fetchRutas();
    if (!mounted) return;
    setState(() {
      _rutas = rutas;
    });
  }

  // ── Mapa ──

  void _centrarEnUsuario() {
    if (_posicionUsuario != null) {
      _mapController.move(_posicionUsuario!, 16.0);
    }
  }

  void _centrarEn(double lat, double lon, {double zoom = 16.0}) {
    _mapController.move(LatLng(lat, lon), zoom);
    _sheetController.animateTo(
      0.20,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onMapEvent(MapEvent event) {
    final rotation = event.camera.rotation;
    if (rotation.abs() > 5 != _mapRotation.abs() > 5 || mounted) {
      setState(() => _mapRotation = rotation);
    }
    final newZoom = event.camera.zoom;
    if ((newZoom - _currentZoom).abs() >= 1 && mounted) {
      setState(() => _currentZoom = newZoom);
    }
  }

  Future<void> _onStopTap(ParadaModel parada) async {
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

  int _parseMinutos(String eta) {
    final match = RegExp(r'(\d+)\s*min').firstMatch(eta);
    if (match != null) return int.parse(match.group(1)!);
    return eta.contains('Menos de 1 min') ? 0 : 999;
  }

  // ── Sheet state management ──

  void _startSearch() {
    setState(() {
      _searching = true;
      _detailOpen = false;
      _editingOrigin = false;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          _sheetSearchSize,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _exitSearch() {
    _searchFocusNode.unfocus();
    setState(() {
      _searching = false;
      _editingOrigin = false;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        _sheetHalfSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _selectOrigin(String label) {
    _searchFocusNode.unfocus();
    setState(() {
      _origin = label;
      _hasSearched = true;
      _searching = false;
      _editingOrigin = false;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        _sheetHalfSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _selectDestination(String label) {
    _searchFocusNode.unfocus();
    setState(() {
      _destination = label;
      _hasSearched = true;
      _searching = false;
      _editingOrigin = false;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        _sheetHalfSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _activateField({required bool origin}) {
    setState(() {
      _editingOrigin = origin;
      _searchController.text = origin ? _origin : _destination;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _openRouteDetail(int index) {
    setState(() {
      _selectedRouteIndex = index;
      _detailOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        _sheetDetailSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _closeDetail() {
    setState(() => _detailOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        _sheetPeekSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ── Derived data ──

  /// Agrupa la flota por rutaId y cruza con _rutas para obtener el código.
  List<_RouteBuses> get _rutasConBuses {
    final map = <String, _RouteBuses>{};
    for (final ruta in _rutas) {
      final busesEnRuta =
          _flota.where((b) => b.rutaId == ruta.rutaId).toList();
      final activos = busesEnRuta.where((b) => b.esActivo).length;
      map[ruta.rutaId] = _RouteBuses(
        ruta: ruta,
        buses: busesEnRuta,
        activos: activos,
      );
    }
    // Also include flota buses that don't match a known route
    final knownIds = _rutas.map((r) => r.rutaId).toSet();
    final unknownBuses = _flota.where((b) => !knownIds.contains(b.rutaId)).toList();
    if (unknownBuses.isNotEmpty) {
      map['unknown'] = _RouteBuses(
        ruta: null,
        buses: unknownBuses,
        activos: unknownBuses.where((b) => b.esActivo).length,
      );
    }
    return map.values.toList()
      ..sort((a, b) => b.activos.compareTo(a.activos));
  }

  /// Top 3 route codes with active buses for peek chips.
  List<StatusChipData> get _peekChips {
    final rutas = _rutasConBuses
        .where((r) => r.ruta != null && r.activos > 0)
        .take(3)
        .toList();
    return rutas.map((r) {
      return StatusChipData(
        route: r.ruta!.codigo,
        busCount: r.activos,
        level: StatusLevel.onTime,
      );
    }).toList();
  }

  /// Active buses per route code (for passing to RouteListScreen).
  Map<String, int> get _activeBusesByRoute {
    final map = <String, int>{};
    for (final bus in _flota) {
      if (bus.rutaId != null && bus.rutaId!.isNotEmpty) {
        map[bus.rutaId!] = (map[bus.rutaId!] ?? 0) + 1;
      }
    }
    // Convert rutaId → codigo using _rutas
    final codeMap = <String, int>{};
    for (final ruta in _rutas) {
      if (map.containsKey(ruta.rutaId)) {
        codeMap[ruta.codigo] = map[ruta.rutaId]!;
      }
    }
    return codeMap;
  }

  // ──────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBottom = MediaQuery.of(context).size.height * _sheetExtent;

    return PopScope(
      canPop: !_searching && !_detailOpen && _sheetExtent < _sheetPeekSize + 0.01,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_searching) {
          _exitSearch();
        } else if (_detailOpen) {
          _closeDetail();
        } else if (_sheetExtent > 0.21) {
          if (_sheetController.isAttached) {
            _sheetController.animateTo(
              _sheetPeekSize,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ═══ Capa base: mapa vectorial a pantalla completa ═══
            Positioned.fill(child: _buildMap(isDark)),

            // ═══ Sheet deslizante con contenido contextual state-driven ═══
            if (!_isOffline || true) // Always show sheet
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomSheet(isDark),
              ),

            // ═══ FAB reubicar GPS ═══
            if (_sheetExtent < 0.55)
              Positioned(
                right: AppSpacing.lg,
                bottom: sheetBottom + AppSpacing.xs + MediaQuery.of(context).viewPadding.bottom,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _sheetExtent > 0.50 ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: _sheetExtent > 0.50,
                    child: _buildCenterFab(isDark),
                  ),
                ),
              ),

            // ═══ Brújula (se muestra al rotar) ═══
            if (_sheetExtent < 0.55 && _mapRotation.abs() > 5)
              Positioned(
                right: AppSpacing.lg,
                bottom: sheetBottom + AppSpacing.sm + 56 + 12 + MediaQuery.of(context).viewPadding.bottom,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _sheetExtent > 0.50 ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: _sheetExtent > 0.50,
                    child: _buildCompassButton(isDark),
                  ),
                ),
              ),

            // ═══ Banner offline ═══
            if (_isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ConnectionBanner(
                  lastUpdated: 'hace un momento',
                  isDark: isDark,
                  onRetry: () {
                    _iniciarWebSocket();
                    setState(() => _isOffline = false);
                  },
                ),
              ),

            // ═══ Banner de error crowdsourcing ═══
            if (_crowdsourcing.estado == EstadoContribucion.fueraRuta)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: const ErrorBanner(
                  message: 'Dejaste de contribuir (saliste de la ruta)',
                ),
              ),

            // ═══ Banner vacío ═══
            if (_flota.isEmpty &&
                !_cargandoRuta &&
                !_emptyBannerDismissed &&
                _sheetExtent < 0.25)
              Positioned(
                bottom: sheetBottom + AppSpacing.xxl,
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
                      onDismiss: () {
                        setState(() => _emptyBannerDismissed = true);
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // MAPA
  // ──────────────────────────────────────────────────────────────

  Widget _buildMap(bool isDark) {
    return IgnorePointer(
      ignoring: _sheetExtent > 0.45,
      child: GestureDetector(
        onTap: () {
          if (_sheetExtent > 0.15) {
            _sheetController.animateTo(
              0.20,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        },
        child: CanalVectorMap(
          isDark: isDark,
          mapController: _mapController,
          initialCenter: const LatLng(9.0561, -79.4582),
          initialZoom: 15.0,
          onMapEvent: _onMapEvent,
          children: [
            // Polilínea de ruta
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: CanalColors.primary.withValues(alpha: 0.6),
                    strokeWidth: 5,
                  ),
                ],
              ),

            // Marcadores de buses y paradas
            MarkerLayer(
              markers: [
                ...buildBusMarkers(_flota, _posicionesAnterioresBuses),
                if (_currentZoom >= 15)
                  ..._paradas.map(
                    (parada) => Marker(
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
                    ),
                  ),

                // Marcador de ubicación del usuario
                if (_posicionUsuario != null)
                  Marker(
                    point: _posicionUsuario!,
                    child: const UserLocationMarker(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // DRAGGABLE SHEET — state-driven (Transita V2 pattern)
  // ──────────────────────────────────────────────────────────────

  Widget _buildBottomSheet(bool isDark) {
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final textPrimary = isDark
        ? CanalColors.darkTextPrimary
        : CanalColors.lightTextPrimary;
    final textSecondary = isDark
        ? CanalColors.darkTextSecondary
        : CanalColors.lightTextSecondary;
    final textMuted = isDark
        ? CanalColors.darkTextMuted
        : CanalColors.lightTextMuted;
    final divider = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _sheetPeekSize,
      minChildSize: 0.20,
      maxChildSize: 0.88,
      expand: false,
      snap: true,
      snapSizes: const [_sheetPeekSize, _sheetHalfSize, _sheetDetailSize, 0.88],
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Handle de arrastre ──
              _buildGrabber(isDark),

              // ── Search trigger + profile/routes icons (when not searching/detail) ──
              if (!_searching && !_detailOpen) _buildSheetSearchTrigger(isDark),

              // ── Contenido contextual state-driven ──
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    if (_searching)
                      _buildSearchContent(
                        isDark, textPrimary, textSecondary, textMuted, divider,
                      )
                    else if (_detailOpen)
                      _buildDetailContent(
                        isDark, surface, textPrimary, textSecondary, textMuted, divider,
                      )
                    else if (_sheetExtent < _sheetPeekSize + 0.04)
                      _buildPeekContent(isDark, textPrimary, textSecondary)
                    else
                      _buildHalfContent(
                        isDark, surface, textPrimary, textSecondary, textMuted, divider,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrabber(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? CanalColors.darkTextMuted : CanalColors.lightBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // ── Sheet search trigger (SearchPill + routes icon + profile icon) ──

  Widget _buildSheetSearchTrigger(bool isDark) {
    final alignment = context.watch<SettingsService>().searchAlignment;
    final searchFlex = switch (alignment) {
      SearchAlignment.left => 5,
      SearchAlignment.center => 4,
      SearchAlignment.right => 3,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Row(
        children: [
          // ── Left side icons ──
          if (alignment == SearchAlignment.center) ...[
            _buildRoutesIcon(isDark),
            const SizedBox(width: 8),
          ],
          if (alignment == SearchAlignment.right) ...[
            _buildRoutesIcon(isDark),
            const SizedBox(width: 4),
            _buildProfileIcon(isDark),
            const SizedBox(width: 8),
          ],
          // ── Search pill ──
          Expanded(
            flex: searchFlex,
            child: SearchPill(
              key: const Key('searchPill'),
              isDark: isDark,
              label: _hasSearched
                  ? '$_origin → $_destination'
                  : '¿A dónde vas?',
              onTap: _startSearch,
              onFilter: _startSearch,
            ),
          ),
          // ── Right side icons ──
          if (alignment == SearchAlignment.center) ...[
            const SizedBox(width: 8),
            _buildProfileIcon(isDark),
          ],
          if (alignment == SearchAlignment.left) ...[
            const SizedBox(width: 8),
            _buildRoutesIcon(isDark),
            const SizedBox(width: 4),
            _buildProfileIcon(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileIcon(bool isDark) {
    final iconColor = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    return Semantics(
      key: const Key('profileIcon'),
      button: true,
      label: 'Perfil',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_outline_rounded,
            size: 22,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRoutesIcon(bool isDark) {
    final iconColor = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    return Semantics(
      key: const Key('routesIcon'),
      button: true,
      label: 'Ver otras rutas',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RouteListScreen(
                activeBuses: _activeBusesByRoute,
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          child: Icon(
            Icons.alt_route_rounded,
            size: 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  // ── FAB reubicar ──

  Widget _buildCenterFab(bool isDark) {
    return Semantics(
      key: const Key('centerFab'),
      button: true,
      label: 'Centrar en mi ubicación',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _centrarEnUsuario,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.my_location_rounded,
              size: 24,
              color: isDark
                  ? CanalColors.darkTextPrimary
                  : CanalColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Compass button ──

  Widget _buildCompassButton(bool isDark) {
    return Material(
      color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _mapController.rotate(0);
          setState(() => _mapRotation = 0);
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Transform.rotate(
            angle: _mapRotation * (3.14159 / 180),
            child: Icon(
              Icons.explore,
              size: 22,
              color: CanalColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SHEET CONTENT: PEEK (StatusChips with real flota data)
  // ──────────────────────────────────────────────────────────────

  Widget _buildPeekContent(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_bus_rounded,
                size: 14,
                color: textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Próximos buses',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          if (_isOffline)
            ConnectionBanner(
              lastUpdated: 'hace un momento',
              isDark: isDark,
              onRetry: () {
                _iniciarWebSocket();
                setState(() => _isOffline = false);
              },
            ),
          // ── Alert banners ──
          ..._alertService.activeAlerts.take(3).map(
            (alert) => AlertBanner(
              alert: alert,
              isDark: isDark,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlertDetailScreen(alert: alert),
                  ),
                );
              },
              onDismiss: () {
                // Dismiss handled by Dismissible in AlertBanner
              },
            ),
          ),
          const SizedBox(height: 8),
          if (!_isOffline)
            _buildStatusChips(isDark),
          if (!_isOffline) ...[
            const SizedBox(height: 8),
            AdBanner(isDark: isDark, placementId: 'home_peek'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChips(bool isDark) {
    final chips = _peekChips;
    if (chips.isEmpty) {
      return Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: CanalColors.darkTextMuted),
          const SizedBox(width: 6),
          Text(
            _flota.isEmpty ? 'Sin buses en vivo' : 'Cargando rutas...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: CanalColors.darkTextMuted,
            ),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            StatusChip(
              route: chips[i].route,
              eta: '${chips[i].busCount} bus${chips[i].busCount > 1 ? 'es' : ''}',
              level: chips[i].level,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SHEET CONTENT: HALF (Stop header + route cards list)
  // ──────────────────────────────────────────────────────────────

  Widget _buildHalfContent(
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color divider,
  ) {
    final rutasConBuses = _rutasConBuses;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isOffline) ...[
            const SizedBox(height: 10),
            ConnectionBanner(
              lastUpdated: 'hace un momento',
              isDark: isDark,
              onRetry: () {
                _iniciarWebSocket();
                setState(() => _isOffline = false);
              },
            ),
          ],
          const SizedBox(height: 6),
          // Parada actual: nombre + distancia/ubicación
          _buildStopHeader(isDark, textPrimary, textSecondary),
          const SizedBox(height: 18),
          Text(
            'Salen pronto',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (rutasConBuses.isEmpty)
            EmptyState(
              icon: Icons.directions_bus_outlined,
              message: _isOffline
                  ? 'No hay rutas disponibles.\nRevisa tu red para ver buses en tiempo real.'
                  : 'No hay buses disponibles ahora.',
              actionLabel: _isOffline ? 'Reintentar' : 'Explorar el mapa',
              onAction: _isOffline
                  ? () {
                      _iniciarWebSocket();
                      setState(() => _isOffline = false);
                    }
                  : _centrarEnUsuario,
            )
          else
            ...rutasConBuses.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRouteCard(e.value, isDark, surface, textPrimary, textSecondary, textMuted, divider),
              ),
            ),
          // View all routes link
          if (rutasConBuses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RouteListScreen(
                        activeBuses: _activeBusesByRoute,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Ver todas las rutas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CanalColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStopHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: CanalColors.primary.withValues(
              alpha: isDark ? 0.18 : 0.1,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CanalColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.location_on_rounded,
              size: 18,
              color: CanalColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _paradas.isNotEmpty ? _paradas.first.nombre : 'Mi ubicación',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _posicionUsuario != null
                    ? '${_flota.length} buses en tiempo real'
                    : 'Obteniendo ubicación...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_rutas.length} rutas',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(
    _RouteBuses rb,
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color divider,
  ) {
    if (rb.ruta == null) return const SizedBox.shrink();
    final ruta = rb.ruta!;
    final tieneBuses = rb.activos > 0;
    final busLabel = rb.activos > 0
        ? '${rb.activos} bus${rb.activos > 1 ? 'es' : ''} activo${rb.activos > 1 ? 's' : ''}'
        : 'Sin buses';

    return Semantics(
      button: true,
      label: 'Ruta ${ruta.codigo} a ${ruta.nombre}, $busLabel',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final index = _rutas.indexOf(ruta);
            if (index >= 0) _openRouteDetail(index);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider, width: 1),
            ),
            child: Row(
              children: [
                RouteBadge(codigo: ruta.codigo, fontSize: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruta.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_bus,
                            size: 14,
                            color: tieneBuses
                                ? CanalColors.accent
                                : textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            busLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: tieneBuses
                                  ? CanalColors.accent
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SHEET CONTENT: SEARCH (inline, not modal)
  // ──────────────────────────────────────────────────────────────

  Widget _buildSearchContent(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color divider,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final stops = _paradas
        .where((p) => p.nombre.toLowerCase().contains(query))
        .toList();
    final rutas = _rutas
        .where(
          (r) =>
              '${r.codigo} ${r.nombre}'.toLowerCase().contains(query),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: 'Cancelar búsqueda',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _exitSearch,
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        color: CanalColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Origin/Destination fields
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider),
            ),
            child: Column(
              children: [
                _buildSearchFieldRow(
                  isOrigin: true,
                  isActive: _editingOrigin,
                  value: _origin,
                  placeholder: '¿Desde dónde?',
                  dotColor: textSecondary,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                Divider(height: 1, thickness: 1, color: divider),
                _buildSearchFieldRow(
                  isOrigin: false,
                  isActive: !_editingOrigin,
                  value: _destination,
                  placeholder: '¿A dónde vas?',
                  dotColor: CanalColors.primary,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Quick chips or filtered results
          if (query.isEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSearchQuickChip(
                  Icons.my_location_rounded,
                  'Mi ubicación',
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'RUTAS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 4),
            ..._rutas.map(
              (r) => _buildSearchRouteRow(r, textPrimary, textMuted),
            ),
          ] else ...[
            if (stops.isNotEmpty) ...[
              Text(
                'PARADAS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 4),
              ...stops.map(
                (s) => _buildSearchStopRow(s, textPrimary, textMuted),
              ),
            ],
            if (rutas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'RUTAS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 4),
              ...rutas.map(
                (r) => _buildSearchRouteRow(r, textPrimary, textMuted),
              ),
            ],
            if (stops.isEmpty && rutas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    'Sin resultados para "$query"',
                    style: TextStyle(fontSize: 14, color: textMuted),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchFieldRow({
    required bool isOrigin,
    required bool isActive,
    required String value,
    required String placeholder,
    required Color dotColor,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Material(
      color: isActive
          ? CanalColors.primary.withValues(alpha: isDark ? 0.08 : 0.05)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive ? null : () => _activateField(origin: isOrigin),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isActive
                    ? TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 15, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: placeholder,
                          hintStyle: TextStyle(color: textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
              ),
              if (!isActive)
                Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchQuickChip(IconData icon, String label, bool isDark) {
    return Material(
      color: isDark
          ? CanalColors.darkBackground
          : CanalColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: () {
          _selectOrigin(label);
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: CanalColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CanalColors.darkTextPrimary
                      : CanalColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchStopRow(
    ParadaModel parada,
    Color textPrimary,
    Color textMuted,
  ) {
    return Semantics(
      button: true,
      label: parada.nombre,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_editingOrigin) {
            _selectOrigin(parada.nombre);
          } else {
            _selectDestination(parada.nombre);
          }
          _centrarEn(parada.lat, parada.lon);
        },
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parada.nombre,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRouteRow(
    RutaModel ruta,
    Color textPrimary,
    Color textMuted,
  ) {
    return Semantics(
      button: true,
      label: 'Ruta ${ruta.codigo} ${ruta.nombre}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_editingOrigin) {
            _selectOrigin(ruta.nombre);
          } else {
            _selectDestination(ruta.nombre);
          }
        },
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: CanalColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ruta.codigo,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ruta.nombre,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SHEET CONTENT: DETAIL (route detail with stops)
  // ──────────────────────────────────────────────────────────────

  Widget _buildDetailContent(
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color divider,
  ) {
    if (_selectedRouteIndex >= _rutas.length) return const SizedBox.shrink();
    final ruta = _rutas[_selectedRouteIndex];
    final busesEnRuta = _flota.where((b) => b.rutaId == ruta.rutaId).toList();
    final activos = busesEnRuta.where((b) => b.esActivo).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDetail,
              child: SizedBox(
                height: 48,
                width: 48,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: textMuted,
                ),
              ),
            ),
          ),
          // Route header
          Row(
            children: [
              RouteBadge(codigo: ruta.codigo, fontSize: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta.nombre,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activos buses activos',
                      style: TextStyle(
                        fontSize: 12,
                        color: activos > 0 ? CanalColors.accent : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Navigate to full detail
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RutaDetalleScreen(
                      ruta: ruta,
                      onCentrarEn: (lat, lon) => _centrarEn(lat, lon),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text(
                'Ver en mapa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CanalColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          // Contribuir button (only in detail mode, like GO mode in Transita V2)
          if (!_isOffline) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Trigger crowdsourcing for this route
                  _crowdsourcing.setRutaPoints(_routePoints);
                  _crowdsourcing.iniciar();
                },
                icon: Icon(
                  Icons.location_on,
                  size: 18,
                  color: _crowdsourcing.estaActivo
                      ? CanalColors.accent
                      : CanalColors.primary,
                ),
                label: Text(
                  _crowdsourcing.estaActivo
                      ? 'Contribuyendo GPS'
                      : 'Contribuir GPS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _crowdsourcing.estaActivo
                        ? CanalColors.accent
                        : CanalColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _crowdsourcing.estaActivo
                        ? CanalColors.accent
                        : CanalColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
          // Ad banner — bottom of trip detail
          const SizedBox(height: 12),
          AdBanner(isDark: isDark, placementId: 'trip_detail'),
        ],
      ),
    );
  }
}

// ── Helper data class ──

class _RouteBuses {
  final RutaModel? ruta;
  final List<BusSesion> buses;
  final int activos;

  const _RouteBuses({
    required this.ruta,
    required this.buses,
    required this.activos,
  });
}

class StatusChipData {
  final String route;
  final int busCount;
  final StatusLevel level;

  const StatusChipData({
    required this.route,
    required this.busCount,
    required this.level,
  });
}
