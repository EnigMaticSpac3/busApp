// lib/widgets/eta_banner.dart

import 'package:flutter/material.dart';
import '../models/eta_model.dart';

class EtaBanner extends StatelessWidget {
  final EtaParada? eta;
  final bool cargando;

  const EtaBanner({super.key, this.eta, this.cargando = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      width: double.infinity,
      color: _colorFondo,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icono, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _texto,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String get _texto {
    if (cargando) return 'Conectando con el servidor...';
    if (eta == null) return 'Sin datos de ETA';
    if (eta!.esFinDeRecorrido) return 'Bus-01 — Fin de recorrido';
    return 'Bus-01 → ${eta!.parada}  ·  ${eta!.eta}  ·  ${eta!.distanciaMetros.toInt()} m';
  }

  Color get _colorFondo {
    if (cargando || eta == null) return Colors.grey.shade300;
    if (eta!.esFinDeRecorrido) return Colors.orange.shade200;
    return Colors.amber.shade300;
  }

  IconData get _icono {
    if (cargando) return Icons.sync;
    if (eta == null) return Icons.wifi_off;
    if (eta!.esFinDeRecorrido) return Icons.flag;
    return Icons.directions_bus;
  }
}