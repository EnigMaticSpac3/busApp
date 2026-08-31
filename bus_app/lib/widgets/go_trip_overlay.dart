import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/canal_colors.dart';

/// Modo de transporte de una parada del timeline GO.
enum GoMode { metro, bus, walk }

/// Parada del timeline de progreso del GO trip mode.
class GoStop {
  final String name;
  final GoMode mode;
  final String? line;
  final String? eta;
  final String? action;
  final LatLng? coordinates;
  const GoStop(this.name, {required this.mode, this.line, this.eta, this.action, this.coordinates});
}

/// Overlay premium de GO trip mode — map-first glassmorphism layout.
/// El mapa es el héroe (Brandbook §10). La UI flota con blur/glass:
/// - Top: single unified panel (close + status + progress dots + stats)
/// - Floating instruction card (instruction + contribute in one glass card)
class GoTripOverlay extends StatefulWidget {
  const GoTripOverlay({
    super.key,
    required this.isDark,
    required this.routeCode,
    required this.instruction,
    required this.instructionSub,
    required this.stops,
    this.currentStopIndex = 3,
    this.routeName = 'K480',
    this.isLive = true,
    this.offline = false,
    this.showContribute = true,
    this.disruptionText,
    required this.onExit,
    this.onContribute,
  });

  final bool isDark;
  final String routeCode;
  final String routeName;
  final String instruction;
  final String instructionSub;
  final List<GoStop> stops;
  final int currentStopIndex;
  final bool isLive;
  final bool offline;
  final bool showContribute;
  final String? disruptionText;
  final VoidCallback onExit;
  final void Function(String routeCode)? onContribute;

  @override
  State<GoTripOverlay> createState() => _GoTripOverlayState();
}

class _GoTripOverlayState extends State<GoTripOverlay> {
  bool get _isDark => widget.isDark;

  // Glass scrim — light surface in light mode, dark in dark mode
  Color get _scrim => _isDark
      ? CanalColors.darkSurface.withValues(alpha: 0.75)
      : CanalColors.lightSurface.withValues(alpha: 0.85);

  // Theme-aware text/icon colors
  Color get _textPrimary => _isDark ? Colors.white : CanalColors.lightTextPrimary;
  Color get _textSecondary => _isDark
      ? Colors.white.withValues(alpha: 0.7)
      : CanalColors.lightTextSecondary;
  Color get _textMuted => _isDark
      ? Colors.white.withValues(alpha: 0.8)
      : CanalColors.lightTextSecondary.withValues(alpha: 0.8);
  Color get _iconColor => _isDark ? Colors.white : CanalColors.lightTextPrimary;
  Color get _dividerColor => _isDark
      ? Colors.white.withValues(alpha: 0.15)
      : CanalColors.lightBorder.withValues(alpha: 0.5);
  Color get _dotInactive => _isDark
      ? Colors.white.withValues(alpha: 0.25)
      : CanalColors.lightBorder.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top: single unified panel (close + status + dots + stats)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _buildTopPanel(),
          ),
        ),
        // Floating instruction card (instruction + contribute in one glass card)
        Positioned(
          bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          left: 16,
          right: 16,
          child: _buildInstructionCard(),
        ),
        // Floating disruption banner
        if (widget.disruptionText != null)
          Positioned(
            bottom: (widget.showContribute ? 120 : 68) + MediaQuery.of(context).viewPadding.bottom,
            left: 16,
            right: 16,
            child: _buildDisruptionBanner(),
          ),
      ],
    );
  }

  // ─── Unified top panel ────────────────────────────────────────────────────

  Widget _buildTopPanel() {
    final stopsLeft = widget.stops.length - widget.currentStopIndex - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: _scrim,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                _buildClose(),
                _buildStatus(),
                const SizedBox(width: 6),
                Expanded(child: _buildDots()),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$stopsLeft parada${stopsLeft == 1 ? '' : 's'}\u00B7${widget.stops.last.eta ?? ''}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClose() {
    return Semantics(
      button: true,
      label: 'Salir del viaje',
      child: InkWell(
        onTap: widget.onExit,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Align(
            alignment: Alignment.center,
            child: Icon(Icons.close_rounded, size: 18, color: _iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    final Color dotColor;
    if (widget.offline) {
      dotColor = CanalColors.offline;
    } else if (!widget.isLive) {
      dotColor = CanalColors.offline;
    } else {
      dotColor = CanalColors.liveGreen;
    }
    return Semantics(
      label: widget.offline ? 'Sin conexión' : widget.isLive ? 'En vivo' : 'Programado',
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      children: [
        for (var i = 0; i < widget.stops.length; i++) ...[
          _StopDot(
            isPassed: i < widget.currentStopIndex,
            isCurrent: i == widget.currentStopIndex,
            isDark: _isDark,
          ),
          if (i < widget.stops.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: i < widget.currentStopIndex
                    ? CanalColors.primary
                    : _dotInactive,
              ),
            ),
        ],
      ],
    );
  }

  // ─── Instruction card (instruction + contribute, glass) ────────────────────

  Widget _buildInstructionCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: _scrim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Instruction row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.instruction,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.instructionSub,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Route badge — inverted for light mode
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isDark
                            ? CanalColors.primary.withValues(alpha: 0.5)
                            : CanalColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bus_rounded,
                            size: 12,
                            color: _isDark ? Colors.white : CanalColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.routeName,
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _isDark ? Colors.white : CanalColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Contribute row (inside the card)
              if (widget.showContribute) ...[
                Container(height: 0.5, color: _dividerColor),
                Semantics(
                  button: true,
                  label: '¿Vas en el ${widget.routeCode}? Aporta el ETA en vivo',
                  child: InkWell(
                    onTap: () => widget.onContribute?.call(widget.routeCode),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded, size: 14, color: CanalColors.onTintSuccess),
                          const SizedBox(width: 6),
                          Text(
                            'Aporta ETA',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CanalColors.onTintSuccess,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Disruption banner (glass) ────────────────────────────────────────────

  Widget _buildDisruptionBanner() {
    final warningColor = _isDark ? CanalColors.delayedNight : CanalColors.delayedDay;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _scrim,
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: warningColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.disruptionText!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Progress bar dot ─────────────────────────────────────────────────────

class _StopDot extends StatelessWidget {
  final bool isPassed;
  final bool isCurrent;
  final bool isDark;
  const _StopDot({required this.isPassed, required this.isCurrent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = isCurrent ? 10.0 : 8.0;
    final unfilledBorder = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : CanalColors.lightBorder;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPassed || isCurrent ? CanalColors.primary : Colors.transparent,
        border: Border.all(
          color: isPassed || isCurrent ? CanalColors.primary : unfilledBorder,
          width: isCurrent ? 2 : 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: CanalColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
