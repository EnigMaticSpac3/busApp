// lib/widgets/alert_banner.dart
//
// Banner que muestra alertas de servicio activas en la parte superior
// del home screen. Diseño alineado con la paleta Canal de Transita V2.
// Swipe para descartar, tap para abrir AlertDetailScreen.
// Severidad codificada por color: low=azul, medium=naranja, high=rojo, critical=rojo oscuro.

import 'package:flutter/material.dart';
import '../models/service_alert_model.dart';
import '../theme/canal_colors.dart';

/// Severity color mapping for Canal palette (light + dark modes).
class _SeverityColors {
  static const Map<AlertSeverity, Color> backgrounds = {
    AlertSeverity.low: Color(0xFFE8F2FF), // Canal primaryTint
    AlertSeverity.medium: Color(0xFFFEF3E5), // Amber 100
    AlertSeverity.high: Color(0xFFFEF0EF), // Error tint
    AlertSeverity.critical: Color(0xFFE8453C), // Canal error
  };

  static const Map<AlertSeverity, Color> foregrounds = {
    AlertSeverity.low: Color(0xFF0055A4), // Canal primary
    AlertSeverity.medium: Color(0xFFB45309), // onTintAccent
    AlertSeverity.high: Color(0xFFA93228), // onTintError
    AlertSeverity.critical: Color(0xFFFFFFFF),
  };

  static const Map<AlertSeverity, Color> iconColors = {
    AlertSeverity.low: Color(0xFF0055A4),
    AlertSeverity.medium: Color(0xFFF59E0B), // accent
    AlertSeverity.high: Color(0xFFE8453C), // error
    AlertSeverity.critical: Color(0xFFFFFFFF),
  };

  // Dark mode
  static const Map<AlertSeverity, Color> darkBackgrounds = {
    AlertSeverity.low: Color(0xFF1C2A3D),
    AlertSeverity.medium: Color(0xFF2D2215),
    AlertSeverity.high: Color(0xFF2D1A17),
    AlertSeverity.critical: Color(0xFFE8453C),
  };

  static const Map<AlertSeverity, Color> darkForegrounds = {
    AlertSeverity.low: Color(0xFF74B6EF),
    AlertSeverity.medium: Color(0xFFFCD34D),
    AlertSeverity.high: Color(0xFFF87171),
    AlertSeverity.critical: Color(0xFFFFFFFF),
  };
}

/// Alert type → display icon.
IconData _iconForType(AlertType type) {
  switch (type) {
    case AlertType.detour:
      return Icons.alt_route_rounded;
    case AlertType.closure:
      return Icons.block_rounded;
    case AlertType.suspension:
      return Icons.cancel_rounded;
    case AlertType.specialEvent:
      return Icons.celebration_rounded;
    case AlertType.delay:
      return Icons.schedule_rounded;
    case AlertType.unknown:
      return Icons.info_outline_rounded;
  }
}

/// Banner widget that displays an active service alert.
///
/// Shows severity color coding, alert icon, title, and truncated description.
/// Swipe to dismiss, tap to navigate to [AlertDetailScreen].
class AlertBanner extends StatelessWidget {
  final ServiceAlert alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool isDark;

  const AlertBanner({
    super.key,
    required this.alert,
    this.onTap,
    this.onDismiss,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final severity = alert.severityLevel;
    final bg = isDark
        ? _SeverityColors.darkBackgrounds[severity]!
        : _SeverityColors.backgrounds[severity]!;
    final fg = isDark
        ? _SeverityColors.darkForegrounds[severity]!
        : _SeverityColors.foregrounds[severity]!;
    final iconColor = _SeverityColors.iconColors[severity]!;
    final borderColor = isDark
        ? fg.withValues(alpha: 0.2)
        : fg.withValues(alpha: 0.15);

    return Semantics(
      button: true,
      label: 'Alerta: ${alert.title}',
      child: Dismissible(
        key: Key('alert_${alert.alertId}'),
        direction: onDismiss != null
            ? DismissDirection.endToStart
            : DismissDirection.none,
        onDismissed: (_) => onDismiss?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: CanalColors.error,
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Severity icon ──
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconForType(alert.alertType),
                    size: 18,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 10),
                // ── Text content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row: severity badge + title
                      Row(
                        children: [
                          // Severity badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: fg.withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              severity.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: fg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Type label
                          Text(
                            alert.alertType.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: fg.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Title
                      Text(
                        alert.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          height: 1.3,
                        ),
                      ),
                      // Description (truncated)
                      if (alert.description != null &&
                          alert.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          alert.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: fg.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Chevron ──
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: fg.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
