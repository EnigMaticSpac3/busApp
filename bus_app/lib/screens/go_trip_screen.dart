import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/canal_vector_map.dart';
import '../widgets/contribute_sheet.dart';
import '../widgets/go_trip_overlay.dart';
import '../widgets/map_overlays.dart';

/// Pantalla GO full-map Canal: el mapa vectorial Canal es el héroe y el
/// [GoTripOverlay] vive encima (Brandbook §10). Reemplaza la pantalla legada
/// `RouteDetailCitymapperScreen` (mapa OSM raster de 150px que ocultaba el
/// viaje) en el flujo de resultados del trip planner.
class GoTripScreen extends StatefulWidget {
  const GoTripScreen({
    super.key,
    required this.routePath,
    required this.routeCode,
    required this.routeName,
    required this.instruction,
    required this.instructionSub,
    required this.stops,
    required this.polylineColor,
    this.isLive = true,
    this.offline = false,
    this.showContribute = true,
    this.disruptionText,
  });

  final List<LatLng> routePath;
  final String routeCode;
  final String routeName;
  final String instruction;
  final String instructionSub;
  final List<GoStop> stops;
  final Color polylineColor;
  final bool isLive;
  final bool offline;
  final bool showContribute;
  final String? disruptionText;

  @override
  State<GoTripScreen> createState() => _GoTripScreenState();
}

class _GoTripScreenState extends State<GoTripScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bounds = LatLngBounds.fromPoints(widget.routePath);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 90, bottom: 340, left: 40, right: 40),
          maxZoom: 13.5,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          CanalVectorMap(
            isDark: isDark,
            mapController: _mapController,
            initialCenter: _boundsCenter,
            initialZoom: 12.5,
            minZoom: 12,
            maxZoom: 18,
            children: [
              TransitMapOverlays.stopsLayer(showLabels: true, isDark: isDark),
              TransitMapOverlays.routePolylineLayer(
                widget.routePath,
                color: widget.polylineColor,
              ),
              TransitMapOverlays.userLayer(
                isGoMode: true,
                heading: widget.stops.length > 1
                    ? TransitMapOverlays.computeHeading(
                        widget.stops[widget.stops.length - 2].coordinates ?? TransitMapOverlays.userLocation,
                        widget.stops.last.coordinates ?? TransitMapOverlays.userLocation,
                      )
                    : null,
              ),
              TransitMapOverlays.goStopLabelsLayer(
                stops: widget.stops
                    .where((s) => s.coordinates != null)
                    .take(3)
                    .map((s) => (s.name, s.coordinates!, s.eta))
                    .toList(),
                isDark: isDark,
              ),
            ],
          ),
          GoTripOverlay(
            isDark: isDark,
            routeCode: widget.routeCode,
            routeName: widget.routeName,
            isLive: widget.isLive,
            offline: widget.offline,
            instruction: widget.instruction,
            instructionSub: widget.instructionSub,
            stops: widget.stops,
            currentStopIndex: 3,
            showContribute: widget.showContribute,
            disruptionText: widget.disruptionText,
            onExit: () => Navigator.of(context).pop(),
            onContribute: (code) =>
                showContributeSheet(context, routeCode: code),
          ),
        ],
      ),
    );
  }

  static final _boundsCenter = LatLng(8.984, -79.526);
}
