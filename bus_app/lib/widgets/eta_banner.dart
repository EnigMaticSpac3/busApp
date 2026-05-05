// lib/widgets/eta_banner.dart

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/eta_model.dart';

class EtaBanner extends StatelessWidget {
  final EtaParada? eta;
  final bool cargando;
  final String? busId;

  const EtaBanner({super.key, this.eta, this.cargando = false, this.busId});

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
    final id = busId ?? 'Bus';
    if (cargando) return 'Conectando con el servidor...';
    if (eta == null) return 'Sin datos de ETA';
    if (eta!.esFinDeRecorrido) return '$id — Fin de recorrido';
    return '$id → ${eta!.parada}  ·  ${eta!.eta}  ·  ${eta!.distanciaMetros.toInt()} m';
  }

  Color get _colorFondo {
    if (cargando || eta == null) return AppConfig.surfaceSecondary;
    if (eta!.esFinDeRecorrido) return AppConfig.surfaceWarning;
    // ETA < 5 min → alerta (naranja), ETA normal → acento (lime)
    if (_esEtaCorto) return AppConfig.surfaceWarning;
    return AppConfig.surfaceSuccess;
  }

  bool get _esEtaCorto {
    if (eta == null) return false;
    final etaStr = eta!.eta.toLowerCase();
    // Detecta "1 min", "2 min", "3 min", "4 min", "5 min" o "llegando"
    final match = RegExp(r'(\d+)\s*min').firstMatch(etaStr);
    if (match != null) {
      final minutos = int.tryParse(match.group(1)!) ?? 999;
      return minutos <= 5;
    }
    return etaStr.contains('llegando') || etaStr.contains('ahora');
  }

  IconData get _icono {
    if (cargando) return Icons.sync;
    if (eta == null) return Icons.wifi_off;
    if (eta!.esFinDeRecorrido) return Icons.flag;
    return Icons.directions_bus;
  }
}