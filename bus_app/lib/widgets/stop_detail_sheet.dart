import 'package:flutter/material.dart';
import 'package:bus_app/theme/canal_colors.dart';
import 'package:bus_app/widgets/eta_card.dart';

/// Data class for ETA information in the stop detail sheet.
/// Renamed from EtaCard to avoid conflict with the ETACard widget.
class StopEtaCard {
  final String rutaCodigo;
  final String destino;
  final String eta;
  final int minutos;

  const StopEtaCard({
    required this.rutaCodigo,
    required this.destino,
    required this.eta,
    required this.minutos,
  });
}

class StopDetailSheet extends StatelessWidget {
  final String paradaNombre;
  final String paradaId;
  final List<StopEtaCard> etas;
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
    required List<StopEtaCard> etas,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? CanalColors.darkTextMuted : CanalColors.lightBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stop header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CanalColors.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CanalColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: CanalColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paradaNombre,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? CanalColors.darkTextPrimary
                            : CanalColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Parada • $paradaId',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? CanalColors.darkTextSecondary
                            : CanalColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.star_border,
                  color: isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted,
                ),
                onPressed: onFavorito,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ETA cards using Transita V2 ETACard widget
          if (etas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No hay buses en camino',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? CanalColors.darkTextSecondary
                        : CanalColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            ...etas.map((eta) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ETACard(
                    routeCode: eta.rutaCodigo,
                    destination: eta.destino,
                    via: eta.rutaCodigo,
                    eta: eta.minutos,
                    isLive: true,
                    variant: 'compact',
                    isDark: isDark,
                    onTap: () {
                      // TODO: navigate to route detail
                    },
                  ),
                )),
        ],
      ),
    );
  }
}
