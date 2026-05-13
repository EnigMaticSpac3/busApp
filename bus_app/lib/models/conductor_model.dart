// lib/models/conductor_model.dart
//
// Modelo de conductor para autenticación y sesión.

class Conductor {
  final String token;
  final String conductorId;
  final String nombre;
  final String rutaAsignada;

  Conductor({
    required this.token,
    required this.conductorId,
    required this.nombre,
    required this.rutaAsignada,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      token: json['token'] ?? '',
      conductorId: json['conductor_id'] ?? '',
      nombre: json['nombre'] ?? '',
      rutaAsignada: json['ruta_asignada'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'conductor_id': conductorId,
      'nombre': nombre,
      'ruta_asignada': rutaAsignada,
    };
  }
}