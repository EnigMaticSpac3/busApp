import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../theme/canal_colors.dart';
import 'route_map_pill.dart';
import 'sponsored_poi_marker.dart';

/// Wraps a child in a counter-rotation so it stays upright (screen-aligned)
/// even when the map is rotated. [rotation] is the map's rotation in degrees.
class _CounterRotated extends StatelessWidget {
  final double rotation;
  final Widget child;
  const _CounterRotated({required this.rotation, required this.child});

  @override
  Widget build(BuildContext context) {
    if (rotation == 0) return child;
    return Transform.rotate(
      angle: -rotation * math.pi / 180,
      child: child,
    );
  }
}

class TransitMapOverlays {
  TransitMapOverlays._();

  static const userLocation = LatLng(9.051, -79.447); // Metro Cerro Viento area

  /// Calcula el heading (grados desde norte) entre dos puntos.
  static double computeHeading(LatLng from, LatLng to) {
    final dx = to.longitude - from.longitude;
    final dy = to.latitude - from.latitude;
    return math.atan2(dx, dy) * 180 / math.pi;
  }

  static const _nearbyStops = <(String, LatLng)>[
    ('UTP - Facultad de Ciencias y Tec.', LatLng(8.9817, -79.5442)),
    ('Universidad Tecnológica', LatLng(8.9812, -79.5438)),
    ('Albrook - Bahía C', LatLng(8.9760, -79.5445)),
    ('Albrook - Bahía D', LatLng(8.9755, -79.5435)),
    ('Albrook', LatLng(8.9756, -79.5432)),
  ];

  static Widget stopsLayer({
    bool showLabels = false,
    bool isDark = false,
    double currentZoom = 13,
    String? selectedStop,
    double rotation = 0,
    void Function(String name)? onStopTap,
  }) {
    // Zoom-dependent rendering (§10: claridad sobre completitud)
    // zoom < 12: paradas ocultas
    // zoom 12-13: puntos sin label
    // zoom ≥ 13: pills con nombre
    if (currentZoom < 12) return const SizedBox.shrink();
    final showStopLabels = currentZoom >= 13 || showLabels;

    return MarkerLayer(
      markers: _nearbyStops.map((stop) {
        final (name, point) = stop;
        final isSelected = selectedStop == name;
        return Marker(
          key: ValueKey('stopMarker_$name'),
          point: point,
          width: showStopLabels ? (isSelected ? 100 : 80) : 12,
          height: showStopLabels ? (isSelected ? 28 : 22) : 12,
          alignment: Alignment.center,
          child: _CounterRotated(
            rotation: rotation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onStopTap != null ? () => onStopTap(name) : null,
              child: showStopLabels
                  ? _stopLabel(
                      name,
                      isDark: isDark,
                      isSelected: isSelected,
                      highlightRoute: isSelected,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CanalColors.primary
                            : (isDark ? CanalColors.darkSurface : CanalColors.lightSurface),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CanalColors.primary,
                          width: isSelected ? 0 : 1.5,
                        ),
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Labels de paradas sobre el mapa durante GO mode — muestra las próximas 2-3
  /// paradas con nombre y ETA directamente sobre el mapa.
  static Widget goStopLabelsLayer({
    required List<(String name, LatLng coordinates, String? eta)> stops,
    required bool isDark,
  }) {
    if (stops.isEmpty) return const SizedBox.shrink();
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;

    return MarkerLayer(
      markers: stops.map((stop) {
        final (name, point, eta) = stop;
        final label = eta != null ? '$name · $eta' : name;
        return Marker(
          key: ValueKey('goStopLabel_$name'),
          point: point,
          width: 140,
          height: 36,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: CanalColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  static Widget userLayer({double accuracyMeters = 140, bool isGoMode = false, double? heading}) {
    return IgnorePointer(
      child: MarkerLayer(
        markers: [
          Marker(
            point: userLocation,
            width: isGoMode ? 48 : 18,
            height: isGoMode ? 48 : 18,
            alignment: Alignment.center,
            child: isGoMode
                ? _NavigationArrow(heading: heading)
                : Container(
                    decoration: BoxDecoration(
                      color: CanalColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: CanalColors.lightSurface, width: 3),
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
    );
  }

  static const _nearbyBuses = <_Bus>[
    _Bus('M481', LatLng(8.9860, -79.5440), 180, isLive: true, arrivalSoon: true),
    _Bus('C820', LatLng(8.9845, -79.5438), 200, isLive: true),
    _Bus('K480', LatLng(8.9875, -79.5420), 90, isLive: false),
  ];

  /// Capa de buses sobre el mapa (brandbook §10: marcador direccional 36×24dp,
  /// rotación por rumbo; reporte §2D: "buses como íconos direccionales").
  ///
  /// - **En vivo**: body `modeBus` + halo pulsante (1.4s, igual al LiveBadge)
  ///   y pill de ruta con texto AA (`chipTextColor`). Un solo
  ///   [AnimationController] para todos los halos (batería, reporte §5).
  /// - **Programado**: body `surface-2`/muted + borde `scheduled` + ícono
  ///   reloj, sin halo — nunca presentar horario como real-time.
  /// - **Selección**: con [highlightRoute], el bus de esa ruta se resalta con
  ///   anillo primary y los demás bajan a opacidad 0.4 (§10).
  /// - Touch target 48×48 (§12), `Semantics` es-419 (§09/§13).
  static Widget busLayer({
    bool isDark = false,
    String? highlightRoute,
    bool paused = false,
    void Function(String routeCode)? onBusTap,
    List<dynamic>? simulatedBuses,
    double rotation = 0,
  }) {
    return _BusMarkersLayer(
      isDark: isDark,
      highlightRoute: highlightRoute,
      paused: paused,
      onBusTap: onBusTap,
      simulatedBuses: simulatedBuses,
      rotation: rotation,
    );
  }
  /// Polyline de ruta — se dibuja SOLO cuando el usuario selecciona una ruta
  /// (reporte §2C: evitar polución visual). 5px stroke, round cap (§07 m-route).
  static Widget routePolylineLayer(List<LatLng> points, {required Color color}) {
    if (points.length < 2) return const SizedBox.shrink();
    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          color: color,
          strokeWidth: 5,
          borderColor: color.withValues(alpha: 0.35),
          borderStrokeWidth: 7,
          strokeCap: StrokeCap.round,
        ),
      ],
    );
  }

  /// Route pill layer — renders standalone route pills above bus markers.
  /// Each pill shows the route code (JetBrains Mono 12px bold) and optional
  /// destination (Inter 10px). Uses opaque Canal surface for contrast over
  /// any map terrain. Positioned above the bus marker, not inside it.
  static Widget routePillLayer({
    required List<dynamic> buses,
    required bool isDark,
    String? highlightRoute,
    double rotation = 0,
    void Function(String routeCode)? onBusTap,
  }) {
    if (buses.isEmpty) return const SizedBox.shrink();
    // Deduplicate by routeCode — show one pill per route
    final seen = <String>{};
    final uniqueBuses = <dynamic>[];
    for (final bus in buses) {
      if (!seen.contains(bus.routeCode)) {
        seen.add(bus.routeCode);
        uniqueBuses.add(bus);
      }
    }
    return MarkerLayer(
      markers: uniqueBuses.map((bus) {
        final highlighted = highlightRoute != null && bus.routeCode == highlightRoute;
        final dimmed = highlightRoute != null && !highlighted;
        return Marker(
          key: ValueKey('routePill_${bus.routeCode}'),
          point: bus.position,
          width: highlighted ? 100 : 72,
          height: highlighted ? 48 : 36,
          alignment: Alignment.bottomCenter,
          child: _CounterRotated(
            rotation: rotation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBusTap != null ? () => onBusTap(bus.routeCode) : null,
              child: Opacity(
                opacity: dimmed ? 0.4 : 1.0,
                child: RouteMapPill(
                  routeCode: bus.routeCode,
                  isDark: isDark,
                  selected: highlighted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Sponsored POI layer — shows max 1 sponsored marker on the map.
  /// Marker is a rounded rectangle with accent border (radically different
  /// from real transit stops). Hidden when a route polyline is active,
  /// in GO mode, or offline.
  static Widget sponsoredPoiLayer({
    required bool isDark,
    String? partnerName,
    String? category,
    LatLng? position,
    double rotation = 0,
    VoidCallback? onTap,
  }) {
    if (partnerName == null || position == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          key: const ValueKey('sponsoredPoi'),
          point: position,
          width: 140,
          height: 80,
          alignment: Alignment.topCenter,
          child: _CounterRotated(
            rotation: rotation,
            child: SponsoredPoiMarker(
              partnerName: partnerName,
              category: category ?? '',
              isDark: isDark,
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }

  /// Stop dots along the route — jakdojade style. Shows small filled circles
  /// at each stop coordinate. Tap a dot to expand it and show the stop name.
  /// The current stop (first) gets a larger dot with primary fill.
  /// Only shown in route detail view, not GO mode.
  static Widget stopDotsLayer({
    required List<LatLng> stopCoords,
    required bool isDark,
    int currentStopIndex = 0,
    List<String>? stopNames,
    String? selectedStop,
    double rotation = 0,
    void Function(int index, String name)? onStopTap,
  }) {
    if (stopCoords.isEmpty) return const SizedBox.shrink();
    return MarkerLayer(
      markers: stopCoords.asMap().entries.map((entry) {
        final i = entry.key;
        final point = entry.value;
        final isCurrent = i == currentStopIndex;
        final isSelected = selectedStop != null &&
            stopNames != null &&
            i < stopNames.length &&
            stopNames[i] == selectedStop;
        // When selected, show expanded pill; otherwise show dot.
        final width = isSelected ? 140.0 : 44.0;
        final height = isSelected ? 32.0 : 44.0;
        return Marker(
          key: ValueKey('stopDot_$i'),
          point: point,
          width: width,
          height: height,
          alignment: Alignment.center,
          child: _CounterRotated(
            rotation: rotation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: (stopNames != null && i < stopNames.length && onStopTap != null)
                  ? () => onStopTap(i, stopNames[i])
                  : null,
              child: isSelected
                  ? _stopLabel(
                      stopNames[i],
                      isDark: isDark,
                      isSelected: true,
                      highlightRoute: true,
                    )
                  : _stopDot(
                      isCurrent: isCurrent,
                      isDark: isDark,
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Individual stop dot widget — 10px default, 14px for current stop.
  /// Touch target is 44dp (brandbook §10) even though the visible dot is small.
  static Widget _stopDot({required bool isCurrent, required bool isDark}) {
    final size = isCurrent ? 14.0 : 10.0;
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isCurrent ? CanalColors.primary : surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCurrent ? surface : CanalColors.primary,
            width: isCurrent ? 2.5 : 1.5,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: CanalColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  static Widget _stopLabel(
    String name, {
    bool isDark = false,
    bool isSelected = false,
    bool highlightRoute = false,
  }) {
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final border = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: highlightRoute ? CanalColors.primary : border,
          width: highlightRoute ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlightRoute ? CanalColors.primary : textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: highlightRoute ? CanalColors.primary : textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bus {
  final String route;
  final LatLng point;
  final double heading;
  final bool isLive;
  final bool arrivalSoon;
  const _Bus(this.route, this.point, this.heading, {this.isLive = true, this.arrivalSoon = false});
}

/// Capa de markers de buses con UN solo [AnimationController] para los halos
/// pulsantes de todos los buses en vivo (batería, reporte §5). Pausa el pulso
/// cuando `paused` es true (detalle abierto) o con `MediaQuery.disableAnimations`.
class _BusMarkersLayer extends StatefulWidget {
  const _BusMarkersLayer({
    required this.isDark,
    this.highlightRoute,
    this.paused = false,
    this.onBusTap,
    this.simulatedBuses,
    this.rotation = 0,
  });

  final bool isDark;
  final String? highlightRoute;
  final bool paused;
  final void Function(String routeCode)? onBusTap;
  final List<dynamic>? simulatedBuses;
  final double rotation;

  @override
  State<_BusMarkersLayer> createState() => _BusMarkersLayerState();
}

class _BusMarkersLayerState extends State<_BusMarkersLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(_BusMarkersLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused && _pulse.isAnimating) {
      _pulse.stop();
    } else if (!widget.paused && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use simulated buses if provided, otherwise fall back to demo data.
    final simBuses = widget.simulatedBuses;
    if (simBuses != null && simBuses.isNotEmpty) {
      return MarkerLayer(
        markers: simBuses.map((bus) {
          final highlighted =
              widget.highlightRoute != null && bus.routeCode == widget.highlightRoute;
          final dimmed = widget.highlightRoute != null && !highlighted;
          return Marker(
            key: ValueKey('busMarker_${bus.id}'),
            point: bus.position,
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: _CounterRotated(
              rotation: widget.rotation,
              child: Semantics(
                button: true,
                excludeSemantics: true,
                label: 'Bus ${bus.routeCode}, en vivo',
                child: Opacity(
                opacity: dimmed ? 0.4 : 1.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onBusTap?.call(bus.routeCode),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse halo for live buses
                      if (!highlighted)
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) {
                            final alpha = MediaQuery.of(context).disableAnimations
                                ? 0.18
                                : 0.06 + _pulse.value * 0.12;
                            final haloColor = bus.routeCode.startsWith('M')
                                ? CanalColors.modeMetro
                                : CanalColors.accent;
                            return Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: haloColor.withValues(alpha: alpha),
                              ),
                            );
                          },
                        ),
                      if (highlighted)
                        _BusMarkerCircle(
                          isDark: widget.isDark,
                          isMetro: bus.routeCode.startsWith('M'),
                          selected: true,
                        )
                      else
                        _BusMarkerCircle(
                          isDark: widget.isDark,
                          isMetro: bus.routeCode.startsWith('M'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          );
        }).toList(),
      );
    }

    // Fallback: static demo buses (legacy).
    final visibleBuses = TransitMapOverlays._nearbyBuses
        .where((bus) => bus.isLive)
        .toList();
    return MarkerLayer(
      markers: visibleBuses.map((bus) {
        final highlighted =
            widget.highlightRoute != null && bus.route == widget.highlightRoute;
        final dimmed = widget.highlightRoute != null && !highlighted;
        return Marker(
          key: ValueKey('busMarker_${bus.route}'),
          point: bus.point,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Bus ${bus.route}, ${bus.isLive ? 'en vivo' : 'programado'}',
            child: Opacity(
              opacity: dimmed ? 0.4 : 1.0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onBusTap?.call(bus.route),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (bus.isLive && bus.arrivalSoon)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CanalColors.liveGreen.withValues(alpha: 0.18),
                        ),
                      )
                    else if (bus.isLive && !highlighted)
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final alpha = MediaQuery.of(context).disableAnimations
                              ? 0.18
                              : 0.06 + _pulse.value * 0.12;
                          final haloColor = bus.route.startsWith('M')
                              ? CanalColors.modeMetro
                              : CanalColors.accent;
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: haloColor.withValues(alpha: alpha),
                            ),
                          );
                        },
                      )
                    else if (bus.isLive)
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final alpha = MediaQuery.of(context).disableAnimations
                              ? 0.18
                              : 0.06 + _pulse.value * 0.12;
                          final haloColor = bus.route.startsWith('M')
                              ? CanalColors.modeMetro
                              : CanalColors.accent;
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: haloColor.withValues(alpha: alpha),
                            ),
                          );
                        },
                      ),
                    if (highlighted)
                      _BusMarkerCircle(
                        isDark: widget.isDark,
                        isMetro: bus.route.startsWith('M'),
                        selected: true,
                      )
                    else
                      _BusMarkerCircle(
                        isDark: widget.isDark,
                        isMetro: bus.route.startsWith('M'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Bus marker circle — bus: white body + primary blue border; metro: filled blue.
/// Bus body: white (light) / darkSurface2 (dark), border always primary blue.
/// Metro body: modeMetro blue, icon white. Pulse halo stays mode-colored.
/// Icon orientation is fixed (always faces right) — no rotation.
/// When [selected] is true, border widens to 3px.
class _BusMarkerCircle extends StatelessWidget {
  const _BusMarkerCircle({
    required this.isDark,
    required this.isMetro,
    this.selected = false,
  });

  final bool isDark;
  final bool isMetro;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = isMetro ? Icons.train_rounded : Icons.directions_bus_rounded;
    final borderWidth = selected ? 3.0 : 2.0;

    // Metro: filled blue body, white icon. Bus: white/dark body, blue border.
    final bodyColor = isMetro
        ? CanalColors.modeMetro
        : (isDark ? CanalColors.markerBodyDark : CanalColors.markerBody);
    final borderColor = CanalColors.primary;
    final iconColor = isMetro ? Colors.white : CanalColors.primary;
    final shadowColor = isMetro ? CanalColors.modeMetro : CanalColors.primary;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow behind the circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            ),
          ),
          // Main circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bodyColor,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationArrow extends StatelessWidget {
  final double? heading;
  const _NavigationArrow({this.heading});

  @override
  Widget build(BuildContext context) {
    final angle = (heading ?? 0) * math.pi / 180;
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CanalColors.primary,
          boxShadow: [
            BoxShadow(
              color: CanalColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _ArrowPainter(),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - 14)
      ..lineTo(center.dx + 10, center.dy + 10)
      ..lineTo(center.dx + 3, center.dy + 5)
      ..lineTo(center.dx - 3, center.dy + 5)
      ..lineTo(center.dx - 10, center.dy + 10)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
