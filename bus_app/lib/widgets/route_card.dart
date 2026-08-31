import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';
import '../theme/eta_utils.dart';
import 'live_badge.dart';
import 'status_chip.dart';

enum LegMode { metro, bus, walk }

class Stop {
  final String name;
  final int? distanceMeters;
  const Stop(this.name, {this.distanceMeters});
}

class Leg {
  final LegMode mode;
  final String label;
  final String? via;
  final String? departureTime;
  final String? arrivalTime;
  final int? durationMin;
  final int? stopCount;
  const Leg(this.mode, this.label, {this.via, this.departureTime, this.arrivalTime, this.durationMin, this.stopCount});
}

class RouteItem {
  final String routeCode;
  final String destination;
  final String via;
  final int nextEta;
  final int durationMin;
  final String price;
  final String nextStop;
  final String stopsSummary;
  final List<Leg> legs;
  final List<List<Stop>> stopsPerLeg;
  final StatusLevel status;
  final bool isLive;
  final Color? _badgeColor;
  final String? routeLabel;

  const RouteItem({
    required this.routeCode,
    required this.destination,
    this.via = '',
    required this.nextEta,
    required this.durationMin,
    required this.price,
    required this.nextStop,
    required this.stopsSummary,
    required this.legs,
    this.stopsPerLeg = const [],
    required this.status,
    this.isLive = true,
    Color? badgeColor,
    this.routeLabel,
  }) : _badgeColor = badgeColor;

  Color get badgeColor => _badgeColor ?? CanalColors.routeColorForCode(routeCode);

  /// Primer leg de bus (código real de la ruta MiBus), para el prompt de contribución.
  String get busCode {
    for (final leg in legs) {
      if (leg.mode == LegMode.bus) return leg.label;
    }
    return routeCode;
  }
}

Color legTextColor(LegMode mode, bool isDark) {
  return chipTextColor(legColor(mode), isDark);
}

Color legColor(LegMode mode) {
  switch (mode) {
    case LegMode.metro:
      return CanalColors.modeMetro;
    case LegMode.bus:
      return CanalColors.modeBus;
    case LegMode.walk:
      return CanalColors.modeWalk;
  }
}

/// Color del leg cuando se dibuja como trazo sobre el mapa (canvas, no UI).
/// Cumple WCAG no-text 3:1 (§12): walk en light se oscurece y metro en dark
/// usa el token nocturno §14.
Color legMapColor(LegMode mode, bool isDark) {
  switch (mode) {
    case LegMode.metro:
      return isDark ? CanalColors.modeMetroDark : CanalColors.modeMetro;
    case LegMode.bus:
      return isDark ? CanalColors.modeBus : CanalColors.modeBusMapDay;
    case LegMode.walk:
      return isDark ? CanalColors.modeWalk : CanalColors.modeWalkMapDay;
  }
}

IconData legIcon(LegMode mode) {
  switch (mode) {
    case LegMode.metro:
      return Icons.subway_rounded;
    case LegMode.bus:
      return Icons.directions_bus_rounded;
    case LegMode.walk:
      return Icons.directions_walk_rounded;
  }
}

/// Card de ruta (estilo Jakdojade §07): badge de código, destino, vía,
/// ETA hero + badge de fuente explícito, próxima parada + precio + estado textual.
/// El tap es un InkWell (gesture arena distingue tap de scroll): el detalle
/// SOLO se abre por tap intencional (reporte §2E).
class RouteCard extends StatelessWidget {
  final RouteItem route;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.route,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final etaCol = route.isLive
        ? etaTextColor(route.nextEta, isDark)
        : textSecondary;

    return Semantics(
      button: true,
      label:
          'Ruta ${route.routeCode} a ${route.destination}, llega en ${route.nextEta} minutos, ${route.isLive ? 'en vivo' : 'programado'}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divider, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteBadge(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          if (route.via.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              route.via,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildEtaColumn(etaCol),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: route.legs.length,
                    separatorBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '\u203a',
                        style: TextStyle(
                          fontSize: 16,
                          color: textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    itemBuilder: (_, i) => _buildLegChip(route.legs[i]),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      legIcon(route.legs.first.mode),
                      size: 12,
                      color: legColor(route.legs.first.mode),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        route.nextStop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      route.price,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                if (route.status == StatusLevel.delayed) ...[
                  const SizedBox(height: 8),
                  _DisruptionBanner(isDark: isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteBadge() {
    final scheduled = !route.isLive;
    final bg = scheduled
        ? (isDark ? CanalColors.darkSurface2 : CanalColors.lightSurface2)
        : route.badgeColor;
    final fg = scheduled
        ? (isDark
              ? CanalColors.darkTextSecondary
              : CanalColors.lightTextSecondary)
        : CanalColors.routeTextColor(route.routeCode, isDark: isDark);

    return Container(
      width: 54,
      height: 38,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: scheduled
            ? Border.all(color: textMuted.withValues(alpha: 0.4))
            : null,
      ),
      child: Center(
        child: Text(
          route.routeCode,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.02,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildEtaColumn(Color etaCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${route.nextEta}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: etaCol,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'min',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            if (route.isLive)
              LiveBadge(isDark: isDark)
            else
              ProgramadoBadge(isDark: isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildLegChip(Leg leg) {
    final textColor = legTextColor(leg.mode, isDark);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: legColor(leg.mode).withValues(alpha: isDark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(legIcon(leg.mode), size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            leg.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Disruption banner inline (Citymapper pattern) — muestra cuando la ruta
/// está demorada. Amber accent bg + warning icon + texto (§14 delayed tokens).
class _DisruptionBanner extends StatelessWidget {
  final bool isDark;
  const _DisruptionBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? CanalColors.delayedNight.withValues(alpha: 0.15) : CanalColors.delayedDay.withValues(alpha: 0.12);
    final fg = isDark ? CanalColors.delayedNight : CanalColors.delayedDay;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Demora en la línea \u00b7 ETA ajustado',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
