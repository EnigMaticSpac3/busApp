// lib/models/eta_parada_response.dart
//
// Modelo para la respuesta del endpoint GET /api/eta-parada/{parada_id}
// Devuelve los buses que se acercan a una parada específica con sus ETAs.

class EtaParadaResponse {
  final String parada;
  final String paradaId;
  final List<BusEta> buses;

  const EtaParadaResponse({
    required this.parada,
    required this.paradaId,
    required this.buses,
  });

  factory EtaParadaResponse.fromJson(Map<String, dynamic> json) {
    return EtaParadaResponse(
      parada: json['parada'] as String,
      paradaId: json['parada_id'] as String,
      buses: (json['buses'] as List)
          .map((b) => BusEta.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BusEta {
  final String rutaId;
  final String rutaCodigo;
  final String busId;
  final String eta;
  final double distancia;

  const BusEta({
    required this.rutaId,
    required this.rutaCodigo,
    required this.busId,
    required this.eta,
    required this.distancia,
  });

  factory BusEta.fromJson(Map<String, dynamic> json) {
    return BusEta(
      rutaId: json['ruta_id'] as String,
      rutaCodigo: json['ruta_codigo'] as String? ?? json['ruta_id'] as String,
      busId: json['bus_id'] as String,
      eta: json['eta'] as String,
      distancia: (json['distancia'] as num).toDouble(),
    );
  }
}
