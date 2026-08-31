import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

/// Standalone route pill for the map — renders above bus markers.
/// Uses opaque Canal surface background, route-color accent,
/// JetBrains Mono for code, pointer triangle pointing to bus location.
/// In light mode: route-color border + strong shadow for contrast over tiles.
/// In dark mode: subtle border + shadow on dark surface.
class RouteMapPill extends StatelessWidget {
  final String routeCode;
  final String? destination;
  final bool isDark;
  final bool selected;

  const RouteMapPill({
    super.key,
    required this.routeCode,
    this.destination,
    required this.isDark,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final routeColor = CanalColors.routeColorForCode(routeCode);
    final textColor = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;

    // Light mode: route-color border for visibility on pale tiles.
    // Dark mode: subtle neutral border.
    final borderColor = isDark
        ? (selected ? routeColor : CanalColors.darkBorder)
        : routeColor.withValues(alpha: selected ? 1.0 : 0.5);

    // Stronger shadow in light mode for contrast over map tiles.
    final shadowAlpha = isDark ? 0.3 : 0.18;
    final shadowBlur = isDark ? 6.0 : 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pill body
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: shadowAlpha),
                blurRadius: shadowBlur,
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
                  color: routeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                routeCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Pointer triangle — points down to bus location
        CustomPaint(
          size: const Size(10, 5),
          painter: _TrianglePainter(color: borderColor),
        ),
      ],
    );
  }
}

/// Small downward-pointing triangle for the pill pointer.
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
