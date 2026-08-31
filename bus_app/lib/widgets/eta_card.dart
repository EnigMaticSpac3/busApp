import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';
import '../theme/eta_utils.dart';
import 'live_badge.dart';

class ETACard extends StatelessWidget {
  final String routeCode;
  final String destination;
  final String via;
  final int eta;
  final bool isLive;
  final String alertLevel;
  final String occupancy;
  final String variant;
  final bool isDark;
  final VoidCallback? onTap;

  const ETACard({
    super.key,
    required this.routeCode,
    required this.destination,
    required this.via,
    required this.eta,
    this.isLive = false,
    this.alertLevel = 'ok',
    this.occupancy = 'medium',
    this.variant = 'hero',
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == 'compact') return _buildCompact();
    return _buildHero();
  }

  Widget _buildHero() {
    final borderColor = _alertBorderColor();
    final etaColor = _etaColor();
    final progress = (eta / 30.0).clamp(0.05, 0.95);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Route badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CanalColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: CanalColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    routeCode,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isLive)
                  LiveBadge(isDark: isDark)
                else
                  ProgramadoBadge(isDark: isDark),
                const Spacer(),
                // Arrival time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$eta min',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: etaColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'llegada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? CanalColors.darkTextMuted
                            : CanalColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Route info
            Text(
              destination,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? CanalColors.darkTextPrimary
                    : CanalColors.lightTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'vía $via',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? CanalColors.darkTextSecondary
                    : CanalColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1.0 - progress,
                backgroundColor: isDark
                    ? CanalColors.darkBorder
                    : CanalColors.lightBorder,
                valueColor: AlwaysStoppedAnimation(_occupancyColor()),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            // Footer
            Row(
              children: [
                // Occupancy
                Icon(Icons.people_rounded,
                    size: 13,
                    color: isDark
                        ? CanalColors.darkTextMuted
                        : CanalColors.lightTextMuted),
                const SizedBox(width: 4),
                ...List.generate(3, (i) {
                  final filled = i < _occupancyLevel();
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? _occupancyColor()
                          : (isDark
                              ? CanalColors.darkBorder
                              : CanalColors.lightBorder),
                    ),
                  );
                }),
                const Spacer(),
                // View route
                Text(
                  'Ver ruta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CanalColors.primary,
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 14, color: CanalColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Route badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: CanalColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                routeCode,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CanalColors.darkTextPrimary
                          : CanalColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'vía $via',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? CanalColors.darkTextSecondary
                          : CanalColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$eta min',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _etaColor(),
                  ),
                ),
                const SizedBox(height: 2),
                if (isLive)
                  LiveBadge(isDark: isDark)
                else
                  ProgramadoBadge(isDark: isDark),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 16,
                color: isDark
                    ? CanalColors.darkTextMuted
                    : CanalColors.lightTextMuted),
          ],
        ),
      ),
    );
  }

  Color _alertBorderColor() {
    switch (alertLevel) {
      case 'alert':
        return CanalColors.error.withValues(alpha: 0.4);
      case 'warn':
        return CanalColors.accent.withValues(alpha: 0.4);
      default:
        return isDark ? CanalColors.darkBorder : CanalColors.lightBorder;
    }
  }

  Color _etaColor() => etaColor(eta);

  Color _occupancyColor() {
    switch (occupancy) {
      case 'high':
        return CanalColors.error;
      case 'medium':
        return CanalColors.accent;
      default:
        return CanalColors.success;
    }
  }

  int _occupancyLevel() {
    switch (occupancy) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }
}
