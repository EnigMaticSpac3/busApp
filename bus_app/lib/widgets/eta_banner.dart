import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      width: double.infinity,
      color: _colorFondo,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (webSocketConectado != null) ...[
            _buildConnectionIndicator(),
            const SizedBox(width: AppSpacing.sm),
          ],
          Icon(_icono, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              _texto,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
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
            ? AppColors.accent.withValues(alpha: 0.2)
            : AppColors.alert.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected ? Icons.wifi : Icons.wifi_off,
            size: 12,
            color: connected ? AppColors.accent : AppColors.alert,
          ),
          const SizedBox(width: 4),
          Text(
            connected ? 'WS' : 'HTTP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: connected ? AppColors.accent : AppColors.alert,
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
    if (cargando || eta == null) return AppColors.surface;
    if (eta!.esFinDeRecorrido) return AppColors.orange50;
    if (_esEtaCorto) return AppColors.orange50;
    return AppColors.lime50;
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
