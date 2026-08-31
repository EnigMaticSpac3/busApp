import 'dart:math';
import 'package:flutter/material.dart';

/// Disney-style light trail animation for "Transita" text.
///
/// A glowing amber dot traces each letter, revealing white text behind it.
/// The effect uses a trim-path reveal (clip rect) + glowing dot.
class TransitaLightTrailPainter extends CustomPainter {
  TransitaLightTrailPainter({
    required this.glowProgress,
    required this.textPainter,
    required this.isDark,
  });

  /// 0.0 = no reveal, 1.0 = full text visible.
  final double glowProgress;

  /// Pre-measured TextPainter for "Transita".
  final TextPainter textPainter;

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (glowProgress <= 0) return;

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    // Center the text on screen
    final textOffset = Offset(
      (size.width - textWidth) / 2,
      (size.height - textHeight) / 2,
    );

    // --- 1. Clip-rect reveal: reveal text left-to-right ---
    final revealWidth = textWidth * glowProgress.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        textOffset.dx - 20,
        textOffset.dy - 20,
        revealWidth + 40,
        textHeight + 40,
      ),
    );
    textPainter.paint(canvas, textOffset);
    canvas.restore();

    // --- 2. Faint outline before reveal (guide) ---
    if (glowProgress < 0.95) {
      final outlinePaint = Paint()
        ..color = (isDark ? Colors.white : Colors.white)
            .withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      textPainter.paint(canvas, textOffset);
      outlinePaint.color = Colors.transparent;
    }

    // --- 3. Glowing dot at the leading edge ---
    if (glowProgress > 0 && glowProgress < 1.0) {
      final dotX = textOffset.dx + textWidth * glowProgress;
      final dotY = textOffset.dy + textHeight * 0.48;

      // Glow pulse
      final pulse = 1.0 + 0.15 * sin(glowProgress * pi * 6);

      // Outer glow
      final glowPaint = Paint()
        ..color = const Color(0xFFF5B400).withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * pulse);
      canvas.drawCircle(Offset(dotX, dotY), 6 * pulse, glowPaint);

      // Mid glow
      final midGlowPaint = Paint()
        ..color = const Color(0xFFF5B400).withValues(alpha: 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), 3, midGlowPaint);

      // Core dot
      final corePaint = Paint()..color = const Color(0xFFF5B400);
      canvas.drawCircle(Offset(dotX, dotY), 2, corePaint);

      // Trail (fading line behind the dot)
      final trailPaint = Paint()
        ..color = const Color(0xFFF5B400).withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final trailStart = dotX - 30 * pulse;
      if (trailStart > textOffset.dx) {
        canvas.drawLine(
          Offset(trailStart, dotY),
          Offset(dotX - 3, dotY),
          trailPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TransitaLightTrailPainter oldDelegate) =>
      oldDelegate.glowProgress != glowProgress;
}
