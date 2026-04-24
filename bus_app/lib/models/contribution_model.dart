// lib/models/contribucion_model.dart

class ContribucionUbicacion {
  final String usuarioId;
  final double lat;
  final double lon;
  final double velocidadMs;
  final double? precisionM;

  const ContribucionUbicacion({
    required this.usuarioId,
    required this.lat,
    required this.lon,
    required this.velocidadMs,
    this.precisionM,
  });

  Map<String, dynamic> toJson() => {
        'usuario_id':  usuarioId,
        'lat':         lat,
        'lon':         lon,
        'velocidad_ms': velocidadMs,
        if (precisionM != null) 'precision_m': precisionM,
      };
}