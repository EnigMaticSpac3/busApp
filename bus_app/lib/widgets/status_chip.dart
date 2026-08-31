import 'package:flutter/material.dart';
import 'package:bus_app/theme/canal_colors.dart';
import 'package:bus_app/theme/eta_utils.dart';

enum StatusLevel {
  onTime,
  delayed,
  cancelled;

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
        return CanalColors.delayedDay;
      case StatusLevel.cancelled:
        return CanalColors.error;
    }
  }
}

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
    final bg = level.color;
    final text = chipTextColor(bg, isDark);
    final displayEta = level == StatusLevel.cancelled
        ? '· ${level.label}'
        : '· $eta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            route,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            displayEta,
            style: TextStyle(
              color: text,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final bg = level.color;
    final text = chipTextColor(bg, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
