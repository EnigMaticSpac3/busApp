import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';
import '../models/eta_model.dart';
import 'stop_detail_sheet.dart';

class CollapsedEtaCard extends StatelessWidget {
  final EtaParada? eta;
  final bool cargando;
  final String? busId;
  final bool? webSocketConectado;

  const CollapsedEtaCard({
    super.key,
    this.eta,
    this.cargando = false,
    this.busId,
    this.webSocketConectado,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando || eta == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => StopDetailSheet.mostrar(
        context,
        paradaNombre: eta!.parada,
        paradaId: busId ?? 'Bus',
        etas: [],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
          boxShadow: [AppShadows.shadowLg],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _bgColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: _bgColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eta!.parada,
                    style: AppTypography.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.near_me, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${eta!.distanciaMetros.toInt()} m',
                        style: AppTypography.textTheme.labelMedium,
                      ),
                      if (webSocketConectado != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _buildConnectionDot(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (_minutos <= 1)
              Text(
                'Ahora',
                style: AppTypography.textTheme.displayLarge?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _bgColor,
                ),
              )
            else
              Text.rich(
                TextSpan(
                  text: '$_minutos',
                  style: AppTypography.textTheme.displayLarge?.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: _bgColor,
                  ),
                  children: [
                    TextSpan(
                      text: "'",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _bgColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDot() {
    final connected = webSocketConectado ?? false;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: connected ? AppColors.accent : AppColors.alert,
        shape: BoxShape.circle,
      ),
    );
  }

  int get _minutos {
    if (eta == null) return 999;
    final etaStr = eta!.eta.toLowerCase();
    final match = RegExp(r'(\d+)\s*min').firstMatch(etaStr);
    if (match != null) return int.tryParse(match.group(1)!) ?? 999;
    return etaStr.contains('llegando') || etaStr.contains('ahora') ? 0 : 999;
  }

  Color get _bgColor {
    if (_minutos <= 1) return AppColors.alert;
    if (_minutos <= 5) return AppColors.orange600;
    return AppColors.accent;
  }

}
