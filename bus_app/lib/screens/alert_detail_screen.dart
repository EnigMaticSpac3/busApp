// lib/screens/alert_detail_screen.dart
//
// Pantalla de detalle completo para una alerta de servicio.
// Muestra: AppBar con tipo, badge de severidad, descripción completa,
// rutas afectadas (con RouteBadge), paradas afectadas, período de validez,
// y fuente/attribution.

import 'package:flutter/material.dart';
import '../models/service_alert_model.dart';
import '../theme/canal_colors.dart';
import '../widgets/route_badge.dart';

/// Full-screen detail view for a service alert.
class AlertDetailScreen extends StatelessWidget {
  final ServiceAlert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severity = alert.severityLevel;

    return Scaffold(
      backgroundColor:
          isDark ? CanalColors.darkBackground : CanalColors.lightBackground,
      appBar: AppBar(
        title: Text(
          alert.alertType.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor:
            isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
        foregroundColor:
            isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Severity badge + type ──
            _buildSeverityHeader(isDark, severity),
            const SizedBox(height: 16),

            // ── Title ──
            Text(
              alert.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? CanalColors.darkTextPrimary
                    : CanalColors.lightTextPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // ── Description ──
            if (alert.description != null && alert.description!.isNotEmpty)
              _buildDescriptionSection(isDark),

            // ── Affected routes ──
            if (alert.affectedRoutes.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(isDark, 'Rutas afectadas', Icons.alt_route_rounded),
              const SizedBox(height: 8),
              _buildAffectedRoutes(isDark),
            ],

            // ── Affected stops ──
            if (alert.affectedStops.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(isDark, 'Paradas afectadas', Icons.location_on_rounded),
              const SizedBox(height: 8),
              _buildAffectedStops(isDark),
            ],

            // ── Validity period ──
            const SizedBox(height: 20),
            _buildSectionHeader(isDark, 'Período de validez', Icons.schedule_rounded),
            const SizedBox(height: 8),
            _buildValidityPeriod(isDark),

            // ── Source ──
            if (alert.source != null && alert.source!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(isDark, 'Fuente', Icons.source_rounded),
              const SizedBox(height: 8),
              _buildSource(isDark),
            ],

            // ── Alert metadata ──
            const SizedBox(height: 24),
            _buildMetadata(isDark),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityHeader(bool isDark, AlertSeverity severity) {
    return Row(
      children: [
        // Severity badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _severityColor(severity).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _severityColor(severity).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _severityColor(severity),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                severity.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _severityColor(severity),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? CanalColors.darkSurface2 : CanalColors.lightSurface2,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            alert.alertType.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
        ),
      ),
      child: Text(
        alert.description!,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          height: 1.6,
          color: isDark
              ? CanalColors.darkTextPrimary
              : CanalColors.lightTextPrimary,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title, IconData icon) {
    final color =
        isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAffectedRoutes(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: alert.affectedRoutes.map((code) {
        return RouteBadge(codigo: code, fontSize: 13);
      }).toList(),
    );
  }

  Widget _buildAffectedStops(bool isDark) {
    final textColor =
        isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alert.affectedStops.map((stopId) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: CanalColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stopId, // TODO: resolve stop name from ID
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildValidityPeriod(bool isDark) {
    final textColor =
        isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final mutedColor =
        isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final isActive = alert.isValid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? CanalColors.success : CanalColors.offline,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Activa' : 'Expirada',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? CanalColors.success : CanalColors.offline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Desde',
            _formatDateTime(alert.validFrom),
            textColor,
            mutedColor,
          ),
          if (alert.validUntil != null) ...[
            const SizedBox(height: 4),
            _buildDetailRow(
              'Hasta',
              _formatDateTime(alert.validUntil!),
              textColor,
              mutedColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSource(bool isDark) {
    final textColor =
        isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
        ),
      ),
      child: Text(
        alert.source!,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMetadata(bool isDark) {
    final mutedColor =
        isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          'Creada',
          _formatDateTime(alert.createdAt),
          mutedColor,
          mutedColor,
        ),
        const SizedBox(height: 4),
        _buildDetailRow(
          'ID',
          alert.alertId.length > 12
              ? '${alert.alertId.substring(0, 12)}...'
              : alert.alertId,
          mutedColor,
          mutedColor,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return CanalColors.primary;
      case AlertSeverity.medium:
        return CanalColors.accent;
      case AlertSeverity.high:
        return CanalColors.error;
      case AlertSeverity.critical:
        return CanalColors.error;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
