import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

/// Ícono de ondas animado (tipo WiFi rotado 90°) para estado live.
/// Patrón validado por Transit App / jakdojade / Citymapper.
/// viewBox 24×24, path: M2 12c2-3 4-3 6 0s4 3 6 0 4-3 6 0
/// Animación: opacity 0.4→1.0, 1400ms, ease-in-out, reverse (brandbook §04).
class LiveBadge extends StatefulWidget {
  final bool isDark;
  final double size;

  const LiveBadge({super.key, this.isDark = false, this.size = 12});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = MediaQuery.of(context).disableAnimations
            ? 0.9
            : 0.4 + (_controller.value * 0.6);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _WavesPainter(
              color: CanalColors.secondary.withValues(alpha: alpha),
            ),
          ),
        );
      },
    );
  }
}

/// Ícono de ondas estático (sin animación) para estado programado.
/// Color muted — nunca presentar horario como real-time (anti-pattern #1).
class ProgramadoBadge extends StatelessWidget {
  final bool isDark;
  final double size;

  const ProgramadoBadge({super.key, this.isDark = false, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WavesPainter(color: color),
      ),
    );
  }
}

/// Painter para las 3 ondas curvas (WiFi-rotado-90°).
/// viewBox 24×24, stroke-width 2.5, round linecap (brandbook §04).
class _WavesPainter extends CustomPainter {
  final Color color;
  const _WavesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Scale from 24×24 viewBox to actual size.
    final sx = size.width / 24;
    final sy = size.height / 24;

    // M2 12c2-3 4-3 6 0s4 3 6 0 4-3 6 0
    path.moveTo(2 * sx, 12 * sy);
    path.cubicTo(4 * sx, 9 * sy, 6 * sx, 9 * sy, 8 * sx, 12 * sy);
    path.cubicTo(10 * sx, 15 * sy, 12 * sx, 15 * sy, 14 * sx, 12 * sy);
    path.cubicTo(16 * sx, 9 * sy, 18 * sx, 9 * sy, 20 * sx, 12 * sy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => old.color != color;
}
