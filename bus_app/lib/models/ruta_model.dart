// lib/models/ruta_model.dart
//
// Modelo de datos para una ruta de bus.

class RutaModel {
  final String rutaId;
  final String codigo;
  final String nombre;
  final String color;
  final int busesActivos;

  const RutaModel({
    required this.rutaId,
    required this.codigo,
    required this.nombre,
    required this.color,
    required this.busesActivos,
  });

  factory RutaModel.fromJson(Map<String, dynamic> json) {
    return RutaModel(
      rutaId:       json['ruta_id'] as String,
      codigo:       json['codigo'] as String,
      nombre:       json['nombre'] as String,
      color:        json['color'] as String? ?? '007BFF',
      busesActivos: json['buses_activos'] as int? ?? 0,
    );
  }

  bool get tieneBusesActivos => busesActivos > 0;

  @override
  String toString() => 'RutaModel($codigo: $nombre, $busesActivos buses)';
}