import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';
import '../theme/eta_utils.dart';

enum StatusLevel { onTime, delayed, cancelled }

/// Extendido: los estados textuales SIEMPRE acompañan al color (regla no color-only).
extension StatusLevelX on StatusLevel {
  String get label {
    switch (this) {
      case StatusLevel.onTime:
        return 'A tiempo';
      case StatusLevel.delayed:
        return 'Demorado';
      case StatusLevel.cancelled:
        return 'Cancelado';
    }
  }

  Color get color {
    switch (this) {
      case StatusLevel.onTime:
        return CanalColors.modeWalk;
      case StatusLevel.delayed:
        return CanalColors.accent;
      case StatusLevel.cancelled:
        return CanalColors.error;
    }
  }

  /// Color de texto del estado con contraste AA en el modo activo.
  Color textColor(bool isDark) => chipTextColor(color, isDark);
}

/// Chip de estado completo con dot + color (sin depender solo del color).
class StatusChip extends StatelessWidget {
  final String route;
  final String eta;
  final StatusLevel level;
  final bool isDark;

  const StatusChip({
    super.key,
    required this.route,
    required this.eta,
    required this.level,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final status = level.color;
    final bg = status.withValues(alpha: 0.15);
    final etaMin = int.tryParse(eta.split(' ').first);
    final etaCol = etaMin == null
        ? level.textColor(isDark)
        : etaTextColor(etaMin, isDark);
    final routeCol = level.textColor(isDark);

    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: status),
          ),
          const SizedBox(width: 6),
          Text(
            route,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: routeCol,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            level == StatusLevel.cancelled
                ? '\u00b7 Cancelado'
                : '\u00b7 $eta',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: level == StatusLevel.cancelled ? routeCol : etaCol,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de estado pequeño (usado en las cards de ruta).
class StatusChipSmall extends StatelessWidget {
  final StatusLevel level;
  final bool isDark;

  const StatusChipSmall({
    super.key,
    required this.level,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final status = level.color;
    final bg = status.withValues(alpha: 0.12);
    final textCol = level.textColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(500),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: status),
          ),
          const SizedBox(width: 4),
          Text(
            level.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}
