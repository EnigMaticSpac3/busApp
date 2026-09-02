import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../theme/canal_colors.dart';
import '../widgets/canal_vector_map.dart';
import '../widgets/map_overlays.dart';
import '../widgets/trip_itinerary.dart';
import '../widgets/go_trip_overlay.dart';
import '../widgets/contribute_sheet.dart';
import '../widgets/route_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/timetable_widget.dart';
import '../widgets/sponsored_card.dart';
import '../widgets/ad_banner.dart';

/// Pantalla de detalle V2 — reemplaza `RouteDetailCitymapperScreen` (legacy).
/// Usa `CanalVectorMap` (no OSM raster), la paleta Canal, y reutiliza
/// `TripItinerary` + `GoTripOverlay`. Se abre desde `RouteListScreen` y
/// `ProfileScreen` (favoritos).
class RouteDetailV2Screen extends StatefulWidget {
  final RouteItem route;

  const RouteDetailV2Screen({super.key, required this.route});

  @override
  State<RouteDetailV2Screen> createState() => _RouteDetailV2ScreenState();
}

class _RouteDetailV2ScreenState extends State<RouteDetailV2Screen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  AnimationController? _routeAnimationController;
  bool _goMode = false;
  double _currentZoom = 12.5;

  // Sample polyline para la ruta (en producción viene del route planner)
  static const _samplePath = [
    LatLng(8.975, -79.545),
    LatLng(8.977, -79.540),
    LatLng(8.979, -79.535),
    LatLng(8.982, -79.528),
    LatLng(8.986, -79.520),
    LatLng(8.990, -79.512),
    LatLng(8.994, -79.506),
  ];

  // Sample stops para el GO mode
  List<GoStop> get _goStops {
    return [
      GoStop('Estación Albrook', mode: GoMode.metro, line: 'L1', coordinates: const LatLng(8.9756, -79.5432)),
      GoStop('Cinco de Mayo', mode: GoMode.metro, line: 'L1', coordinates: const LatLng(8.9760, -79.5440)),
      GoStop('Plaza 5 de Mayo', mode: GoMode.metro, line: 'L1', coordinates: const LatLng(8.9770, -79.5445)),
      GoStop('Caminar 4 min', mode: GoMode.walk, action: 'Transbordo → Bus ${widget.route.routeCode}', coordinates: const LatLng(8.9775, -79.5450)),
      GoStop('El Dorado', mode: GoMode.bus, line: widget.route.routeCode, eta: '3', coordinates: const LatLng(8.9790, -79.5455)),
      GoStop('Los Andes', mode: GoMode.bus, line: widget.route.routeCode, eta: '9', coordinates: const LatLng(8.9810, -79.5460)),
      GoStop('Bethania Terminal', mode: GoMode.bus, line: widget.route.routeCode, eta: '22', coordinates: const LatLng(8.9830, -79.5465)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _routeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Encuadrar la ruta post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fitCameraToRoute(_samplePath);
        // Start polyline animation after camera settles
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _routeAnimationController?.forward(from: 0);
        });
      }
    });
  }

  @override
  void dispose() {
    _routeAnimationController?.dispose();
    super.dispose();
  }

  List<LatLng> get _animatedRoutePath {
    final route = _samplePath;
    final progress = Curves.easeInOutCubic.transform(_routeAnimationController?.value ?? 1);
    if (progress >= 1 || route.length < 2) return route;
    final segmentCount = route.length - 1;
    final scaled = progress * segmentCount;
    final completedSegments = scaled.floor() < segmentCount
        ? scaled.floor()
        : segmentCount - 1;
    final segmentProgress = scaled - completedSegments;
    final points = route.take(completedSegments + 1).toList();
    final start = route[completedSegments];
    final end = route[completedSegments + 1];
    points.add(
      LatLng(
        start.latitude + (end.latitude - start.latitude) * segmentProgress,
        start.longitude + (end.longitude - start.longitude) * segmentProgress,
      ),
    );
    return points;
  }

  void _fitCameraToRoute(List<LatLng> path) {
    if (path.length < 2) return;
    final bounds = LatLngBounds.fromPoints(path);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 60, bottom: 300, left: 40, right: 40),
        maxZoom: 13.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textSecondary = isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final divider = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;

    return PopScope(
      canPop: !_goMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_goMode) setState(() => _goMode = false);
      },
      child: Scaffold(
        backgroundColor: isDark ? CanalColors.darkBackground : CanalColors.lightBackground,
        body: Stack(
          children: [
            // Mapa CanalVectorMap a pantalla completa
            CanalVectorMap(
              isDark: isDark,
              mapController: _mapController,
              onMapEvent: (event) {
                if (event is MapEventMove) {
                  final zoom = _mapController.camera.zoom;
                  if ((zoom - _currentZoom).abs() > 0.1) {
                    setState(() => _currentZoom = zoom);
                  }
                }
              },
              children: [
                TransitMapOverlays.stopsLayer(
                  isDark: isDark,
                  currentZoom: _currentZoom,
                ),
                if (widget.route.legs.isNotEmpty)
                  AnimatedBuilder(
                    animation: _routeAnimationController!,
                    builder: (_, _) => TransitMapOverlays.routePolylineLayer(
                      _animatedRoutePath,
                      color: legMapColor(widget.route.legs.first.mode, isDark),
                    ),
                  ),
                if (!_goMode)
                  TransitMapOverlays.busLayer(
                    isDark: isDark,
                    highlightRoute: widget.route.routeCode,
                    paused: true,
                  ),
                TransitMapOverlays.userLayer(
                  isGoMode: _goMode,
                  heading: _goMode && _goStops.length > 1
                      ? TransitMapOverlays.computeHeading(
                          _goStops[_goStops.length - 2].coordinates ?? TransitMapOverlays.userLocation,
                          _goStops.last.coordinates ?? TransitMapOverlays.userLocation,
                        )
                      : null,
                ),
                if (_goMode)
                  TransitMapOverlays.goStopLabelsLayer(
                    stops: _goStops
                        .where((s) => s.coordinates != null)
                        .take(3)
                        .map((s) => (s.name, s.coordinates!, s.eta))
                        .toList(),
                    isDark: isDark,
                  ),
              ],
            ),

            // Top bar con botón Salir
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildTopBar(),
              ),
            ),

            // Bottom sheet con TripItinerary
            if (!_goMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildDetailSheet(
                  isDark,
                  surface,
                  textPrimary,
                  textSecondary,
                  textMuted,
                  divider,
                ),
              ),

            // GO overlay sobre el mapa
            if (_goMode)
              GoTripOverlay(
                isDark: isDark,
                routeCode: widget.route.routeCode,
                routeName: widget.route.busCode,
                isLive: widget.route.isLive,
                offline: false,
                instruction: 'BAJA EN 2 PARADAS',
                instructionSub:
                    '${widget.route.nextStop} · ${widget.route.isLive ? '' : '~'}${widget.route.nextEta} min',
                stops: _goStops,
                currentStopIndex: 3,
                showContribute: true,
                disruptionText: widget.route.status == StatusLevel.delayed
                    ? 'Línea ${widget.route.busCode}: demora +5 min'
                    : null,
                onExit: () => setState(() => _goMode = false),
                onContribute: (routeCode) =>
                    showContributeSheet(context, routeCode: routeCode),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
      child: Row(
        children: [
          // Back chevron with subtle scrim circle for contrast against map
          Semantics(
            button: true,
            label: 'Volver',
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : CanalColors.darkBackground.withValues(alpha: 0.55),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDetailSheet(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color divider,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? CanalColors.darkTextMuted : CanalColors.lightBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Contenido scrolleable
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8 + MediaQuery.of(context).viewPadding.bottom),
              shrinkWrap: true,
              children: [
                // TripItinerary
                TripItinerary(
                  route: widget.route,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  divider: divider,
                ),
                // Timetable — próximas salidas
                const SizedBox(height: 16),
                TimetableWidget(
                  routeCode: widget.route.routeCode,
                  destination: widget.route.destination,
                  departures: _demoDepartures(),
                  isDark: isDark,
                ),
                // Sponsored card — Phase 2
                SponsoredCard(
                  partnerName: 'McDonald\'s',
                  category: 'Comida rápida',
                  tagline: 'Cerca de tu destino: McDonald\'s San Miguelito',
                  isDark: isDark,
                  onTap: () {},
                ),
                // Ad banner — bottom of trip detail
                const SizedBox(height: 12),
                AdBanner(isDark: isDark, placementId: 'trip_detail'),
              ],
            ),
          ),
          // Departure → arrival + GO button (merged row)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + MediaQuery.of(context).viewPadding.bottom),
            child: Row(
              children: [
                if (widget.route.legs.isNotEmpty &&
                    (widget.route.legs.first.departureTime != null ||
                     widget.route.legs.last.arrivalTime != null))
                  Flexible(
                    child: Text(
                      '${widget.route.legs.first.departureTime ?? ''} → ${widget.route.legs.last.arrivalTime ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _goMode = true),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16, color: CanalColors.onSecondary),
                    label: Text(
                      'Viajar · ${widget.route.routeCode}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CanalColors.onSecondary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CanalColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                      shadowColor: CanalColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color surface(bool isDark) => isDark ? CanalColors.darkSurface : CanalColors.lightSurface;

  /// Demo departures — cada 8 min desde las 7:00 AM.
  static List<DepartureEntry> _demoDepartures() {
    final entries = <DepartureEntry>[];
    for (int i = 0; i < 8; i++) {
      final totalMin = 7 * 60 + (i * 8);
      final hour = totalMin ~/ 60;
      final min = totalMin % 60;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      final isLive = i < 2;
      final etaMin = isLive ? (i == 0 ? 3 : 8) : null;
      entries.add(DepartureEntry(timeStr, isLive: isLive, etaMin: etaMin));
    }
    return entries;
  }
}
