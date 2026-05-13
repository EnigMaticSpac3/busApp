// lib/models/sesion_conductor_model.dart
//
// Modelo de sesión activa del conductor.

class SesionConductor {
  final String sessionId;
  final String conductorToken;
  final String rutaId;
  final DateTime inicio;
  final bool activo;

  SesionConductor({
    required this.sessionId,
    required this.conductorToken,
    required this.rutaId,
    required this.inicio,
    required this.activo,
  });

  factory SesionConductor.fromJson(Map<String, dynamic> json) {
    return SesionConductor(
      sessionId: json['session_id'] ?? '',
      conductorToken: json['conductor_token'] ?? '',
      rutaId: json['ruta_id'] ?? '',
      inicio: DateTime.fromMillisecondsSinceEpoch(
        (json['inicio'] * 1000).toInt(),
      ),
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'conductor_token': conductorToken,
      'ruta_id': rutaId,
      'inicio': inicio.millisecondsSinceEpoch / 1000,
      'activo': activo,
    };
  }
}