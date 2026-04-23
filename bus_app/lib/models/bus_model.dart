// lib/models/bus_model.dart
//
// Clase tipada para los datos de un bus.
// Evita acceder a maps dinámicos con bus['lat'] por toda la app
// y centraliza la deserialización del JSON del backend.

class Bus {
  final String id;
  final double lat;
  final double lon;
  final double velMs;

  const Bus({
    required this.id,
    required this.lat,
    required this.lon,
    required this.velMs,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id:    json['id']     as String,
      lat:   (json['lat']   as num).toDouble(),
      lon:   (json['lon']   as num).toDouble(),
      velMs: (json['vel_ms'] as num).toDouble(),
    );
  }

  // Velocidad en km/h para mostrar en UI
  double get velKmh => velMs * 3.6;

  @override
  String toString() => 'Bus($id, lat: $lat, lon: $lon, vel: ${velKmh.toStringAsFixed(1)} km/h)';
}