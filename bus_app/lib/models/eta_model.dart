// lib/models/eta_model.dart
//
// Representa la respuesta del endpoint /api/parada-cercana

class EtaParada {
  final String parada;
  final String eta;
  final double distanciaMetros;

  const EtaParada({
    required this.parada,
    required this.eta,
    required this.distanciaMetros,
  });

  factory EtaParada.fromJson(Map<String, dynamic> json) {
    return EtaParada(
      parada:           json['parada']    as String,
      eta:              json['eta']       as String,
      distanciaMetros: (json['distancia'] as num).toDouble(),
    );
  }

  bool get esFinDeRecorrido => parada == 'Fin de recorrido';
}