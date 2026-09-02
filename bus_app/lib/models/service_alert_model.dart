// lib/models/service_alert_model.dart
//
// Modelo para alertas de servicio (GTFS-RT compatible).
// Mapea la tabla service_alerts del backend.

class ServiceAlert {
  final String alertId;
  final String type; // DETOUR, CLOSURE, SUSPENSION, SPECIAL_EVENT, DELAY
  final String severity; // low, medium, high, critical
  final String title;
  final String? description;
  final List<String> affectedRoutes; // route codes (E598, etc.)
  final List<String> affectedStops; // stop_ids
  final DateTime validFrom;
  final DateTime? validUntil;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceAlert({
    required this.alertId,
    required this.type,
    required this.severity,
    required this.title,
    this.description,
    this.affectedRoutes = const [],
    this.affectedStops = const [],
    required this.validFrom,
    this.validUntil,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceAlert.fromJson(Map<String, dynamic> json) {
    return ServiceAlert(
      alertId: json['alert_id'] as String? ?? '',
      type: json['type'] as String? ?? 'UNKNOWN',
      severity: json['severity'] as String? ?? 'low',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      affectedRoutes: (json['affected_routes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      affectedStops: (json['affected_stops'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      validFrom: DateTime.tryParse(json['valid_from'] as String? ?? '') ??
          DateTime.now(),
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'] as String)
          : null,
      source: json['source'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': alertId,
      'type': type,
      'severity': severity,
      'title': title,
      'description': description,
      'affected_routes': affectedRoutes,
      'affected_stops': affectedStops,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Whether the alert is currently valid (not expired).
  bool get isValid {
    final now = DateTime.now();
    if (now.isBefore(validFrom)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  /// Severity as an enum-like for display.
  AlertSeverity get severityLevel =>
      AlertSeverity.fromString(severity);

  /// Alert type as an enum-like for display.
  AlertType get alertType => AlertType.fromString(type);

  /// Human-readable validity period.
  String get validityText {
    final from = _formatDate(validFrom);
    if (validUntil == null) return 'Desde $from';
    final to = _formatDate(validUntil!);
    return '$from — $to';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical;

  factory AlertSeverity.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      case 'low':
      default:
        return AlertSeverity.low;
    }
  }

  String get label {
    switch (this) {
      case AlertSeverity.low:
        return 'Baja';
      case AlertSeverity.medium:
        return 'Media';
      case AlertSeverity.high:
        return 'Alta';
      case AlertSeverity.critical:
        return 'Crítica';
    }
  }

  String get icon {
    switch (this) {
      case AlertSeverity.low:
        return 'ℹ️';
      case AlertSeverity.medium:
        return '⚠️';
      case AlertSeverity.high:
        return '🔶';
      case AlertSeverity.critical:
        return '🔴';
    }
  }
}

enum AlertType {
  detour,
  closure,
  suspension,
  specialEvent,
  delay,
  unknown;

  factory AlertType.fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DETOUR':
        return AlertType.detour;
      case 'CLOSURE':
        return AlertType.closure;
      case 'SUSPENSION':
        return AlertType.suspension;
      case 'SPECIAL_EVENT':
        return AlertType.specialEvent;
      case 'DELAY':
        return AlertType.delay;
      default:
        return AlertType.unknown;
    }
  }

  String get label {
    switch (this) {
      case AlertType.detour:
        return 'Desvío';
      case AlertType.closure:
        return 'Cierre';
      case AlertType.suspension:
        return 'Suspensión';
      case AlertType.specialEvent:
        return 'Evento Especial';
      case AlertType.delay:
        return 'Retraso';
      case AlertType.unknown:
        return 'Aviso';
    }
  }
}
