import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

/// Sponsored card — appears as a separate card AFTER the trip itinerary,
/// not mixed into the timeline. Gate-approved: accent border, 32px gap
/// from itinerary, explicit "Patrocinado" chip, direct copy.
/// Jakdojade-style "Cele Sponsorowane" — suggested destination near the route.
class SponsoredCard extends StatelessWidget {
  final String partnerName;
  final String category;
  final String tagline;
  final bool isDark;
  final VoidCallback? onTap;

  const SponsoredCard({
    super.key,
    required this.partnerName,
    required this.category,
    required this.tagline,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final accent = isDark ? CanalColors.accentDark : CanalColors.accent;
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textSecondary = isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 32),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: "Patrocinado" chip + category
            Row(
              children: [
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
                const SizedBox(width: 8),
                Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Partner name
            Text(
              partnerName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Tagline — "Sugerencia: [Partner] está cerca de tu destino"
            Text(
              tagline,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // CTA button — "Ver en mapa"
            Row(
              children: [
                Icon(Icons.map_outlined, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Ver en mapa',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
