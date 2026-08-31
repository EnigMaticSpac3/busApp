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
import '../widgets/search_pill.dart';
import '../widgets/bus_marker_widget.dart';
import '../widgets/canal_vector_map.dart';
import '../widgets/contribuir_fab.dart';

import '../widgets/connection_banner.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/route_badge.dart';
import '../widgets/seleccionar_ruta_sheet.dart';
import '../widgets/stop_detail_sheet.dart';
import '../widgets/stop_marker.dart';
import '../widgets/subida_bus_sheet.dart';
import '../widgets/user_location_marker.dart';
import '../theme/export.dart';
import 'profile_screen.dart';
import 'ruta_detalle_screen.dart';

/// HomeScreen con patrón Citymapper: mapa vectorial a pantalla completa
/// como fondo, DraggableScrollableSheet con contenido contextual por tab,
/// BottomNavigationBar fijo, FAB de reubicación con opacidad animada,
/// y brújula visible al rotar el mapa.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Servicios (via Provider) ──
  late final ApiService _api;
  late final CrowdsourcingService _crowdsourcing;
  final _mapController = MapController();
  WebSocketService? _wsService;
  bool _initialized = false;

  // ── Estado del mapa ──
  List<LatLng> _routePoints = [];
  List<BusSesion> _flota = [];
  LatLng? _posicionUsuario;

  Map<String, LatLng> _posicionesAnterioresBuses = {};
  bool _cargandoRuta = true;
  String? _errorRuta;

  List<ParadaModel> _paradas = [];
  double _currentZoom = 15.0;
  Timer? _pollingTimer;
  StreamSubscription<Position>? _locationSubscription;
  bool _emptyBannerDismissed = false;

  // ── Estado de rutas (pestaña Rutas) ──
  List<RutaModel> _rutas = [];
  bool _cargandoRutas = true;
  String? _errorRutas;
  Timer? _rutasPollingTimer;

  // ── Navegación y sheet ──
  int _selectedTab = 0;
  final _sheetController = DraggableScrollableController();
  double _sheetExtent = 0.18;

  // ── Brújula ──
  double _mapRotation = 0;

  // ── Conexión ──
  bool _isOffline = false;

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    // Services are read from Provider in didChangeDependencies
    _sheetController.addListener(_onSheetChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize services from Provider on first build
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

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _rutasPollingTimer?.cancel();
    _locationSubscription?.cancel();
    _crowdsourcing.removeListener(_onCrowdsourcingChange);
    _wsService?.removeListener(_onWsChange);
    _wsService?.dispose();
    _crowdsourcing.dispose();
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    super.dispose();
  }

  // ── Listeners ──

  void _onSheetChanged() {
    if (!mounted) return;
    final height = MediaQuery.of(context).size.height;
    if (height <= 0) return;
    final extent = _sheetController.size / height;
    if ((extent - _sheetExtent).abs() > 0.005) {
      setState(() => _sheetExtent = extent);
    }
  }

  void _onCrowdsourcingChange() {
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

  // ── Ubicación GPS ──

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

  // ── Crowdsourcing ──

  Future<void> _mostrarSheetSiCorresponde() async {
    // First-launch crowdsourcing prompt: skip for now (shown on demand)
  }

  Future<void> _seleccionarRutaYContinuar() async {
    await SeleccionarRutaSheet.mostrar(
      context,
      onRutaSeleccionada: (ruta) async {
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

  Future<void> _toggleContribucion() async {
    if (_crowdsourcing.estaActivo) {
      _crowdsourcing.detener();
    } else {
      await _seleccionarRutaYContinuar();
    }
  }

  // ── Datos ──

  Future<void> _loadEmptyBannerPreference() async {
    // Defaults to not dismissed; banner shows until user dismisses
    if (mounted) setState(() => _emptyBannerDismissed = false);
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

  Future<void> _cargarRutas({bool soloActualizar = false}) async {
    if (!soloActualizar) {
      setState(() {
        _cargandoRutas = true;
        _errorRutas = null;
      });
    }
    final rutas = await _api.fetchRutas();
    if (!mounted) return;
    setState(() {
      _rutas = rutas;
      if (!soloActualizar) _cargandoRutas = false;
      if (_rutas.isEmpty && !soloActualizar) {
        _errorRutas = 'No se pudieron cargar las rutas';
      }
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
      0.06,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onMapEvent(MapEvent event) {
    final rotation = event.camera.rotation;
    final shouldShowCompass = rotation.abs() > 5;
    if (shouldShowCompass != _mapRotation.abs() > 5 || mounted) {
      setState(() => _mapRotation = rotation);
    }
    // Detectar cambio de zoom para paradas
    final newZoom = event.camera.zoom;
    final zoomCambioSignificativo = (newZoom - _currentZoom).abs() >= 1;
    if (zoomCambioSignificativo && mounted) {
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
      etas: response?.buses
              .map((b) => EtaCard(
                    rutaCodigo: b.rutaCodigo,
                    destino: b.rutaId,
                    eta: b.eta,
                    minutos: _parseMinutos(b.eta),
                  ))
              .toList() ??
          [],
    );
  }

  int _parseMinutos(String eta) {
    final match = RegExp(r'(\d+)\s*min').firstMatch(eta);
    if (match != null) return int.parse(match.group(1)!);
    return eta.contains('Menos de 1 min') ? 0 : 999;
  }

  // ── Navegación de tabs ──

  void _onTabChanged(int index) {
    setState(() => _selectedTab = index);
    switch (index) {
      case 0: // Mapa — colapsar al peek
        _sheetController.animateTo(
          0.06,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      case 1: // Rutas — expandir a la mitad
        _sheetController.animateTo(
          0.45,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      case 2: // Perfil — expandir a la mitad
        _sheetController.animateTo(
          0.40,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
    }
  }

  // ──────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final livingTheme = context.watch<LivingTheme>();
    final isDark = livingTheme.isDark;
    final padding = MediaQuery.of(context).padding;
    final navBarHeight = kBottomNavigationBarHeight + padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ═══ Capa base: mapa vectorial a pantalla completa ═══
          Positioned.fill(child: _buildMap(isDark)),

          // ═══ SearchPill flotante sobre el mapa ═══
          Positioned(
            top: padding.top + AppSpacing.md,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: SearchPill(
              label: '¿A dónde vas?',
              isDark: isDark,
              onTap: () {
                // TODO: open search flow
              },
              onFilter: () {
                // TODO: open filters
              },
            ),
          ),

          // ═══ Sheet deslizante (sobre el mapa, debajo de la nav) ═══
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: navBarHeight,
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.18,
              minChildSize: 0.06,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.06, 0.40, 0.75],
              builder: (context, scrollController) =>
                  _buildSheetPanel(scrollController, isDark),
            ),
          ),

          // ═══ Bottom NavigationBar fijo ═══
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(isDark),
          ),

          // ═══ FABs flotantes (derecha, sobre la nav) ═══
          Positioned(
            right: AppSpacing.lg,
            bottom: navBarHeight + AppSpacing.lg,
            child: _buildFABs(isDark),
          ),

          // ═══ Brújula (se muestra al rotar) ═══
          if (_mapRotation.abs() > 5)
            Positioned(
              top: padding.top + AppSpacing.md,
              right: AppSpacing.lg,
              child: _buildCompassButton(isDark),
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
              bottom: navBarHeight + AppSpacing.xxl + 60,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
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
    );
  }

  // ──────────────────────────────────────────────────────────────
  // MAPA
  // ──────────────────────────────────────────────────────────────

  Widget _buildMap(bool isDark) {
    return IgnorePointer(
      // El mapa es interactuable solo cuando el sheet está en peek
      ignoring: _sheetExtent > 0.15,
      child: GestureDetector(
        // Al tocar el mapa, colapsar el sheet
        onTap: () {
          if (_sheetExtent > 0.15) {
            _sheetController.animateTo(
              0.06,
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
  // DRAGGABLE SHEET
  // ──────────────────────────────────────────────────────────────

  Widget _buildSheetPanel(ScrollController scrollController, bool isDark) {
    final bgColor =
        isDark ? CanalColors.darkSurface : CanalColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xlarge)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        children: [
          // ── Handle de arrastre ──
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? CanalColors.darkTextMuted
                    : CanalColors.lightTextMuted,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),

          // ── Contenido por tab ──
          _buildTabContent(isDark),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    switch (_selectedTab) {
      case 0:
        return _buildMapTabContent(isDark);
      case 1:
        return _buildRutasTabContent(isDark);
      case 2:
        return _buildPerfilTabContent(isDark);
      default:
        return _buildMapTabContent(isDark);
    }
  }

  // ── Tab Mapa: contenido mínimo ──

  Widget _buildMapTabContent(bool isDark) {
    final textColor = isDark
        ? CanalColors.darkTextPrimary
        : CanalColors.lightTextPrimary;
    final secondaryColor = isDark
        ? CanalColors.darkTextSecondary
        : CanalColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Transita',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_errorRuta != null)
            Row(
              children: [
                Icon(Icons.wifi_off, size: 14, color: CanalColors.alert),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _errorRuta!,
                    style: const TextStyle(fontSize: 13, color: CanalColors.alert),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _errorRuta = null);
                    _cargarRuta();
                  },
                  child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
                ),
              ],
            )
          else ...[
            Text(
              _flota.isEmpty
                  ? 'No hay buses activos'
                  : '${_flota.length} buses en tiempo real',
              style: TextStyle(fontSize: 13, color: secondaryColor),
            ),
            if (_wsService?.conectado == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: CanalColors.liveGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Conectado',
                    style: const TextStyle(
                        fontSize: 11, color: CanalColors.liveGreen),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Tab Rutas: lista de rutas ──

  Widget _buildRutasTabContent(bool isDark) {
    if (_cargandoRutas) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorRutas != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: EmptyState(
          icon: Icons.error_outline,
          message: _errorRutas!,
          actionLabel: 'Reintentar',
          onAction: _cargarRutas,
        ),
      );
    }

    if (_rutas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: EmptyState(
          icon: Icons.directions_bus,
          message: 'No hay rutas disponibles',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _rutas.length,
      itemBuilder: (context, index) => _buildRutaCard(_rutas[index], isDark),
    );
  }

  Widget _buildRutaCard(RutaModel ruta, bool isDark) {
    final busesActivos =
        _flota.where((b) => b.rutaId == ruta.rutaId && b.esActivo).length;
    final tieneBuses = busesActivos > 0;
    final secondaryColor = isDark
        ? CanalColors.darkTextSecondary
        : CanalColors.lightTextSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              RouteBadge(codigo: ruta.codigo, fontSize: 16),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta.nombre,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 14,
                          color: tieneBuses
                              ? CanalColors.accent
                              : secondaryColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '$busesActivos buses activos',
                          style: TextStyle(
                            fontSize: 13,
                            color: tieneBuses
                                ? CanalColors.accent
                                : secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: secondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Perfil: pantalla completa con ajustes y conductor ──

  Widget _buildPerfilTabContent(bool isDark) {
    return const ProfileScreen();
  }

  // ──────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR
  // ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav(bool isDark) {
    return NavigationBar(
      selectedIndex: _selectedTab,
      onDestinationSelected: _onTabChanged,
      backgroundColor:
          isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: CanalColors.primary.withValues(alpha: 0.12),
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Mapa',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_bus_outlined),
          selectedIcon: Icon(Icons.directions_bus),
          label: 'Rutas',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // FABs
  // ──────────────────────────────────────────────────────────────

  Widget _buildFABs(bool isDark) {
    final activo = _crowdsourcing.estaActivo;
    final ignorado = _crowdsourcing.estado == EstadoContribucion.ignorado;
    final busId = _crowdsourcing.busAsignado;
    final fabOpacity = _sheetExtent < 0.25 ? 1.0 : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── FAB reubicar GPS ──
        AnimatedOpacity(
          opacity: fabOpacity,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: _sheetExtent >= 0.25,
            child: Padding(
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
          ),
        ),

        // ── FAB contribuir ──
        AnimatedOpacity(
          opacity: fabOpacity,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: _sheetExtent >= 0.25,
            child: ContribuirFab(
              activo: activo,
              busId: busId,
              ignorado: ignorado,
              onPressed: _toggleContribucion,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // BRÚJULA
  // ──────────────────────────────────────────────────────────────

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
          width: 40,
          height: 40,
          child: Transform.rotate(
            angle: _mapRotation * (3.14159 / 180),
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
