// lib/models/parada_model.dart
//
// Modelo de datos para una parada de bus.

class ParadaModel {
  final String paradaId;
  final String nombre;
  final double lat;
  final double lon;
  final int orden;

  const ParadaModel({
    required this.paradaId,
    required this.nombre,
    required this.lat,
    required this.lon,
    required this.orden,
  });

  factory ParadaModel.fromJson(Map<String, dynamic> json) {
    return ParadaModel(
      paradaId: json['parada_id'] as String,
      nombre:   json['nombre'] as String,
      lat:      (json['lat'] as num).toDouble(),
      lon:      (json['lon'] as num).toDouble(),
      orden:    json['orden'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'ParadaModel($orden: $nombre)';
}