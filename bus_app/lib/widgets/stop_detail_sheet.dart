import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';
import 'package:bus_app/widgets/route_badge.dart';
import 'package:bus_app/widgets/stop_header.dart';

class EtaCard {
  final String rutaCodigo;
  final String destino;
  final String eta;
  final int minutos;

  const EtaCard({
    required this.rutaCodigo,
    required this.destino,
    required this.eta,
    required this.minutos,
  });
}

class StopDetailSheet extends StatelessWidget {
  final String paradaNombre;
  final String paradaId;
  final List<EtaCard> etas;
  final VoidCallback? onFavorito;

  const StopDetailSheet({
    super.key,
    required this.paradaNombre,
    required this.paradaId,
    required this.etas,
    this.onFavorito,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required String paradaNombre,
    required String paradaId,
    required List<EtaCard> etas,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      builder: (_) => StopDetailSheet(
        paradaNombre: paradaNombre,
        paradaId: paradaId,
        etas: etas,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StopHeader(
            titulo: paradaNombre,
            subtitulo: 'Parada • $paradaId',
            trailing: IconButton(
              icon: Icon(Icons.star_border, color: AppColors.textSecondary),
              onPressed: onFavorito,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (etas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: Text(
                  'No hay buses en camino',
                  style: AppTypography.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...etas.map(_buildEtaCard),
        ],
      ),
    );
  }

  Widget _buildEtaCard(EtaCard eta) {
    final bgColor = _etaBgColor(eta.minutos);
    final etaColor = _etaTextColor(eta.minutos);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              boxShadow: [AppShadows.shadowSm],
            ),
            child: Row(
              children: [
                RouteBadge(codigo: eta.rutaCodigo),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eta.destino,
                        style: AppTypography.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.directions_bus, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'En tiempo real',
                            style: AppTypography.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (eta.minutos <= 1)
                  Text(
                    'Llegando',
                    style: AppTypography.textTheme.displayLarge?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: etaColor,
                    ),
                  )
                else
                  Text.rich(
                    TextSpan(
                      text: '${eta.minutos}',
                      style: AppTypography.textTheme.displayLarge?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: etaColor,
                      ),
                      children: [
                        TextSpan(
                          text: "'",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: etaColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Divider(
          height: AppSpacing.sm,
          thickness: 0.5,
          color: AppColors.gray50,
          indent: 16,
        ),
      ],
    );
  }

  Color _etaBgColor(int minutos) {
    if (minutos <= 1) return AppColors.orange50;
    if (minutos <= 5) return AppColors.orange50;
    return AppColors.lime50;
  }

  Color _etaTextColor(int minutos) {
    if (minutos <= 1) return AppColors.alert;
    if (minutos <= 5) return AppColors.orange600;
    return AppColors.accent;
  }

}
