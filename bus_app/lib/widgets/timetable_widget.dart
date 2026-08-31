import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';
import 'live_badge.dart';

/// Modelo de una salida programada.
class DepartureEntry {
  final String time; // "7:05"
  final bool isLive; // GPS activo o programado
  final int? etaMin; // minutos hasta la llegada

  const DepartureEntry(this.time, {this.isLive = false, this.etaMin});
}

/// Widget de timetable — lista scrollable de salidas programadas.
/// Muestra hora + waves icon (live/programado) + ETA countdown.
/// Reutilizable en route detail sheet y timetable screen.
class TimetableWidget extends StatelessWidget {
  final String routeCode;
  final String destination;
  final List<DepartureEntry> departures;
  final bool isDark;

  const TimetableWidget({
    super.key,
    required this.routeCode,
    required this.destination,
    required this.departures,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textSecondary = isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final divider = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Próximas salidas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                routeCode,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        ...departures.map((d) => _DepartureRow(
          entry: d,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          divider: divider,
        )),
      ],
    );
  }
}

class _DepartureRow extends StatelessWidget {
  final DepartureEntry entry;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;

  const _DepartureRow({
    required this.entry,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 48,
            child: Text(
              entry.time,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Waves icon
          entry.isLive
              ? LiveBadge(size: 12)
              : ProgramadoBadge(size: 12),
          const SizedBox(width: 8),
          // Status text
          Expanded(
            child: Text(
              entry.isLive ? 'En vivo' : 'Programado',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: entry.isLive ? CanalColors.secondary : textMuted,
              ),
            ),
          ),
          // ETA countdown
          if (entry.etaMin != null)
            Text(
              '${entry.etaMin} min',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: entry.etaMin! <= 5 ? CanalColors.error : textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
