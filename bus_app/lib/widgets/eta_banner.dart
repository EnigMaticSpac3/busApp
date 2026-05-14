// lib/widgets/eta_banner.dart
//
// Banner que muestra el ETA del próximo bus.
// Incluye indicador de conexión WebSocket.

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/eta_model.dart';

class EtaBanner extends StatelessWidget {
  final EtaParada? eta;
  final bool cargando;
  final String? busId;
  final bool? webSocketConectado;

  const EtaBanner({
    super.key,
    this.eta,
    this.cargando = false,
    this.busId,
    this.webSocketConectado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      width: double.infinity,
      color: _colorFondo,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (webSocketConectado != null) ...[
            _buildConnectionIndicator(),
            const SizedBox(width: 8),
          ],
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

  Widget _buildConnectionIndicator() {
    final connected = webSocketConectado ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: connected
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected ? Icons.wifi : Icons.wifi_off,
            size: 12,
            color: connected ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            connected ? 'WS' : 'HTTP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: connected ? Colors.green : Colors.orange,
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
    if (_esEtaCorto) return AppConfig.surfaceWarning;
    return AppConfig.surfaceSuccess;
  }

  bool get _esEtaCorto {
    if (eta == null) return false;
    final etaStr = eta!.eta.toLowerCase();
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