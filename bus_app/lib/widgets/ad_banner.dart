import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

/// Standard ad banner — 320×50 static banner, Canal palette styled.
/// Placed at the edge of content (route list bottom, sheet peek, trip detail).
/// Hidden in GO mode and offline. "Publicidad" label in Inter 11px.
/// Ready for real SDK integration (AdMob banner unit ID).
class AdBanner extends StatelessWidget {
  final bool isDark;
  final String? placementId;

  const AdBanner({
    super.key,
    required this.isDark,
    this.placementId,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? CanalColors.darkSurface2 : CanalColors.lightSurface2;
    final border = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;

    return Semantics(
      label: 'Anuncio publicitario',
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(
            'Publicidad',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
