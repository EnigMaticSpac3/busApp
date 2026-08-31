import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';
import '../widgets/timetable_widget.dart';
import '../widgets/live_badge.dart';

/// Pantalla de horarios — muestra las próximas salidas de una ruta.
/// Accedida desde el route list (icono de reloj) y desde el route detail.
/// Datos hardcodeados demo (frecuencia ~8 min, servicio 5:30 AM–10:00 PM).
class TimetableScreen extends StatelessWidget {
  final String routeCode;
  final String destination;

  const TimetableScreen({
    super.key,
    required this.routeCode,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? CanalColors.darkBackground : CanalColors.lightBackground;
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textSecondary = isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final divider = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;

    final departures = _generateDemoDepartures();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeCode,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            Text(
              destination,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frequency header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: divider, width: 1)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Frecuencia: cada 8 min · 5:30 AM – 10:00 PM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Departures list
          Expanded(
            child: ListView.builder(
              itemCount: departures.length,
              itemBuilder: (context, index) {
                final d = departures[index];
                return _TimetableRow(
                  entry: d,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  divider: divider,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Genera salidas demo cada 8 min desde 5:30 AM.
  static List<DepartureEntry> _generateDemoDepartures() {
    final entries = <DepartureEntry>[];
    // Simular 20 salidas desde las 7:00 AM
    final baseHour = 7;
    final baseMinute = 0;
    for (int i = 0; i < 20; i++) {
      final totalMin = baseHour * 60 + baseMinute + (i * 8);
      final hour = totalMin ~/ 60;
      final min = totalMin % 60;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';

      // Simular que las primeras 2-3 ya tienen GPS, el resto programado
      final isLive = i < 3;
      final etaMin = isLive ? (i == 0 ? 2 : i == 1 ? 6 : 10) : null;

      entries.add(DepartureEntry(timeStr, isLive: isLive, etaMin: etaMin));
    }
    return entries;
  }
}

class _TimetableRow extends StatelessWidget {
  final DepartureEntry entry;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;

  const _TimetableRow({
    required this.entry,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    final isNext = entry.isLive && entry.etaMin != null && entry.etaMin! <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isNext ? CanalColors.secondary.withValues(alpha: 0.06) : null,
        border: Border(bottom: BorderSide(color: divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 52,
            child: Text(
              entry.time,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isNext ? CanalColors.secondary : textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: entry.isLive ? CanalColors.secondary : textMuted,
              ),
            ),
          ),
          // ETA countdown
          if (entry.etaMin != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: entry.etaMin! <= 5
                    ? CanalColors.error.withValues(alpha: 0.1)
                    : CanalColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '~${entry.etaMin} min',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: entry.etaMin! <= 5 ? CanalColors.error : CanalColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
