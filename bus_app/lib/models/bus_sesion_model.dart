// lib/models/bus_sesion_model.dart
//
// Modelo extendido de Bus con información de sesión.
// Incluye estado de conexión y opacidad para UI.

class BusSesion {
  final String sessionId;
  final double lat;
  final double lon;
  final double velMs;
  final String modo;
  final double segundosSinSenal;

  const BusSesion({
    required this.sessionId,
    required this.lat,
    required this.lon,
    required this.velMs,
    required this.modo,
    required this.segundosSinSenal,
  });

  factory BusSesion.fromJson(Map<String, dynamic> json) {
    return BusSesion(
      sessionId: json['session_id'] as String? ?? json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      velMs: (json['vel_ms'] as num).toDouble(),
      modo: json['modo'] as String? ?? 'activo',
      segundosSinSenal: (json['segundos_sin_senal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get esActivo => modo == 'activo';
  bool get esIncierto => modo == 'incierto';
  bool get esPerdido => modo == 'perdido';

  double get opacidad => esActivo ? 1.0 : esIncierto ? 0.5 : 0.2;

  String get etiquetaTiempo {
    if (esActivo) return 'En tiempo real';
    final min = (segundosSinSenal / 60).floor();
    return 'Última señal hace ${min}m';
  }

  double get velKmh => velMs * 3.6;

  @override
  String toString() =>
      'BusSesion($sessionId, lat: $lat, lon: $lon, modo: $modo, vel: ${velKmh.toStringAsFixed(1)} km/h)';
}