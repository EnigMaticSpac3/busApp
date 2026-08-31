import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

/// Sponsored POI marker — rounded rectangle, accent color, radically different
/// from real transit stops. Max 1 visible at a time. Hidden in GO mode, offline,
/// or when a route polyline is active.
class SponsoredPoiMarker extends StatelessWidget {
  final String partnerName;
  final String category;
  final bool isDark;
  final VoidCallback? onTap;

  const SponsoredPoiMarker({
    super.key,
    required this.partnerName,
    required this.category,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final accent = isDark ? CanalColors.accentDark : CanalColors.accent;
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: 'Publicidad: $partnerName, patrocinado',
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill card — rounded rectangle, accent border
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Patrocinado" label chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PATROCINADO',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Partner name
                    Text(
                      partnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Category
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Pointer triangle
              CustomPaint(
                size: const Size(12, 6),
                painter: _TrianglePainter(
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small downward-pointing triangle for the marker pointer.
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
