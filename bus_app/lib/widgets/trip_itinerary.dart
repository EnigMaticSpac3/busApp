import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';
import 'route_card.dart';

class TripItinerary extends StatefulWidget {
  final RouteItem route;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final ValueChanged<int>? onLegTap;

  const TripItinerary({
    super.key,
    required this.route,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    this.onLegTap,
  });

  @override
  State<TripItinerary> createState() => _TripItineraryState();
}

class _TripItineraryState extends State<TripItinerary> {
  int? _expandedLegIndex;

  void _toggleLeg(int index) {
    setState(() {
      _expandedLegIndex = _expandedLegIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final legs = widget.route.legs;
    if (legs.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        ..._buildTimeline(legs),
      ],
    );
  }

  Widget _buildHeader() {
    final route = widget.route;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (route.routeLabel != null) ...[
          Text(
            route.routeLabel!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Text(
              '${route.durationMin} min',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: widget.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            Text(
              route.price,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildLegChips(),
      ],
    );
  }

  Widget _buildLegChips() {
    final legs = widget.route.legs;
    final chips = <Widget>[];

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      if (leg.mode == LegMode.walk) {
        final duration = leg.durationMin ?? 3;
        chips.add(_WalkChip(
          duration: duration,
          isDark: widget.isDark,
          textMuted: widget.textMuted,
          onTap: widget.onLegTap != null ? () => widget.onLegTap!(i) : null,
        ));
      } else {
        chips.add(_LegChip(
          code: leg.label,
          mode: leg.mode,
          isDark: widget.isDark,
          onTap: widget.onLegTap != null ? () => widget.onLegTap!(i) : null,
        ));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips,
      ),
    );
  }

  List<Widget> _buildTimeline(List<Leg> legs) {
    final widgets = <Widget>[];
    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      final isLast = i == legs.length - 1;
      final isExpanded = _expandedLegIndex == i;

      if (leg.mode == LegMode.walk) {
        widgets.add(_WalkLeg(
          leg: leg,
          isLast: isLast,
          textPrimary: widget.textPrimary,
          textSecondary: widget.textSecondary,
          textMuted: widget.textMuted,
          divider: widget.divider,
          isDark: widget.isDark,
        ));
      } else {
        final stops = i < widget.route.stopsPerLeg.length
            ? List<Stop>.from(widget.route.stopsPerLeg[i])
            : <Stop>[];
        widgets.add(_RideLeg(
          leg: leg,
          stops: stops,
          isLast: isLast,
          textPrimary: widget.textPrimary,
          textSecondary: widget.textSecondary,
          textMuted: widget.textMuted,
          isDark: widget.isDark,
          isExpanded: isExpanded,
          onToggle: () => _toggleLeg(i),
        ));
      }

      if (!isLast) {
        final next = legs[i + 1];
        final isRideToRide = leg.mode != LegMode.walk && next.mode != LegMode.walk;
        final connColor = isRideToRide
            ? legColor(leg.mode).withValues(alpha: 0.5)
            : widget.divider;
        final waitMin = isRideToRide &&
                next.departureTime != null &&
                leg.arrivalTime != null
            ? _parseMinutesBetween(leg.arrivalTime!, next.departureTime!)
            : 0;
        widgets.add(_Connector(
          color: connColor,
          isRideToRide: isRideToRide,
          waitMin: waitMin,
          textMuted: widget.textMuted,
        ));
      }
    }

    final lastLeg = legs.last;
    widgets.add(_Destination(
      arrivalStr: lastLeg.arrivalTime ?? '',
      destination: widget.route.destination,
      textPrimary: widget.textPrimary,
      textSecondary: widget.textSecondary,
    ));

    return widgets;
  }

  int _parseMinutesBetween(String from, String to) {
    try {
      final f = _parseTime(from);
      final t = _parseTime(to);
      return t.difference(f).inMinutes;
    } catch (_) {
      return 0;
    }
  }

  DateTime _parseTime(String time) {
    final parts = time.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
    var h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    if (time.toLowerCase().contains('pm') && h < 12) h += 12;
    if (time.toLowerCase().contains('am') && h == 12) h = 0;
    return DateTime(2026, 1, 1, h, m);
  }
}

class _LegChip extends StatelessWidget {
  final String code;
  final LegMode mode;
  final bool isDark;
  final VoidCallback? onTap;

  const _LegChip({
    required this.code,
    required this.mode,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = mode == LegMode.metro
        ? CanalColors.modeMetro
        : CanalColors.routeColorForCode(code);
    final fg = mode == LegMode.metro
        ? Colors.white
        : CanalColors.routeTextColor(code, isDark: isDark);

    final chip = Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );

    if (onTap == null) return chip;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Center(child: chip),
        ),
      ),
    );
  }
}

class _WalkChip extends StatelessWidget {
  final int duration;
  final bool isDark;
  final Color textMuted;
  final VoidCallback? onTap;

  const _WalkChip({
    required this.duration,
    required this.isDark,
    required this.textMuted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: textMuted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk_rounded, size: 12, color: textMuted),
            const SizedBox(width: 4),
            Text(
              '$duration min',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return chip;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Center(child: chip),
        ),
      ),
    );
  }
}

class _WalkLeg extends StatelessWidget {
  final Leg leg;
  final bool isLast;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final bool isDark;

  const _WalkLeg({
    required this.leg,
    required this.isLast,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor =
        isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final duration = leg.durationMin ?? 3;
    final dist = leg.label.isNotEmpty ? leg.label : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 12,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              if (!isLast) Container(width: 2, height: 20, color: divider),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.directions_walk_rounded, size: 14, color: dotColor),
                const SizedBox(width: 6),
                Text(
                  'A pie',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$duration min',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                if (dist != null && dist.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '($dist m)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RideLeg extends StatefulWidget {
  final Leg leg;
  final List<Stop> stops;
  final bool isLast;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const _RideLeg({
    required this.leg,
    required this.stops,
    required this.isLast,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  State<_RideLeg> createState() => _RideLegState();
}

class _RideLegState extends State<_RideLeg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<CurvedAnimation> _stopAnimations = [];
  bool _showStops = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _buildStopAnimations();
    if (widget.isExpanded) {
      _showStops = true;
      _controller.forward();
    }
  }

  void _buildStopAnimations() {
    for (final a in _stopAnimations) {
      a.dispose();
    }
    final count = widget.stops.length;
    _stopAnimations = List.generate(count, (i) {
      final start = (i * 0.12).clamp(0.0, 0.7);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(
          start,
          (start + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(_RideLeg old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      if (widget.isExpanded) {
        setState(() => _showStops = true);
        _controller.forward();
      } else {
        _controller.reverse().then((_) {
          if (mounted) setState(() => _showStops = false);
        });
      }
    }
    if (widget.stops.length != old.stops.length) _buildStopAnimations();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final a in _stopAnimations) {
      a.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeCol = widget.leg.mode == LegMode.metro
        ? CanalColors.modeMetro
        : CanalColors.routeColorForCode(widget.leg.label);
    final duration = widget.leg.durationMin ?? 10;
    final stopCount = widget.leg.stopCount ?? widget.stops.length;

    return GestureDetector(
      onTap: widget.onToggle,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 12,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: routeCol, shape: BoxShape.circle),
                  ),
                  if (!widget.isLast)
                    Expanded(
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: routeCol,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _RouteBadge(
                            code: widget.leg.label,
                            mode: widget.leg.mode,
                            isDark: widget.isDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.leg.mode == LegMode.metro
                                    ? 'Metro ${widget.leg.label}'
                                    : 'Bus ${widget.leg.label}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: widget.textPrimary,
                                ),
                              ),
                              if (widget.leg.via != null &&
                                  widget.leg.via!.isNotEmpty)
                                Text(
                                  widget.leg.via!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11, color: widget.textMuted),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          widget.isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: widget.textMuted,
                        ),
                      ],
                    ),
                    if (!_showStops)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$stopCount paradas · $duration min',
                          style:
                              TextStyle(fontSize: 12, color: widget.textMuted),
                        ),
                      ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.hardEdge,
                      child: _showStops
                          ? _buildStopsList(routeCol)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsList(Color routeCol) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.stops.length; i++)
            FadeTransition(
              opacity: _stopAnimations[i],
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(_stopAnimations[i]),
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: routeCol.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.stops[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: widget.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.stops.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 6, bottom: 4),
              child: Text(
                '→ ${routeCol == CanalColors.modeMetro ? 'Estación' : 'Parada'}',
                style: TextStyle(fontSize: 12, color: widget.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteBadge extends StatelessWidget {
  final String code;
  final LegMode mode;
  final bool isDark;

  const _RouteBadge(
      {required this.code, required this.mode, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = mode == LegMode.metro
        ? CanalColors.modeMetro
        : CanalColors.routeColorForCode(code);
    final fg = mode == LegMode.metro
        ? Colors.white
        : CanalColors.routeTextColor(code, isDark: isDark);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final Color color;
  final bool isRideToRide;
  final int waitMin;
  final Color textMuted;

  const _Connector({
    required this.color,
    required this.isRideToRide,
    required this.waitMin,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        children: [
          Container(
              width: 2, height: isRideToRide ? 24 : 16, color: color),
          if (isRideToRide && waitMin > 0) ...[
            const SizedBox(width: 8),
            Icon(Icons.swap_horiz_rounded,
                size: 12, color: CanalColors.accent),
            const SizedBox(width: 4),
            Text(
              'Transbordo · $waitMin min',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  final String arrivalStr;
  final String destination;
  final Color textPrimary;
  final Color textSecondary;

  const _Destination({
    required this.arrivalStr,
    required this.destination,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: CanalColors.accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                arrivalStr.isNotEmpty
                    ? 'Llegada · $arrivalStr'
                    : destination,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              if (arrivalStr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
