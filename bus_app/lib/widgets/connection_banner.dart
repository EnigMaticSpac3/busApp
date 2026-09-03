import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/offline_provider.dart';
import '../theme/canal_colors.dart';

class ConnectionBanner extends StatelessWidget {
  /// Fallback text when `lastConnectedTime` is null (e.g. app just launched).
  final String lastUpdated;

  /// Callback when the user taps the "Reintentar" button.
  final VoidCallback? onRetry;

  /// Whether the parent context is in dark mode (kept for API compat).
  final bool isDark;

  /// When true, shows the "online but stale" variant.
  /// Pass `true` once a sync engine exists and data is older than a threshold.
  final bool isStale;

  const ConnectionBanner({
    super.key,
    required this.lastUpdated,
    this.onRetry,
    this.isDark = false,
    this.isStale = false,
  });

  @override
  Widget build(BuildContext context) {
    final offlineProvider = context.watch<OfflineProvider>();
    final isOffline = offlineProvider.offline;
    final lastConnected = offlineProvider.lastConnectedTime;

    // ── Online & fresh → hide ──
    if (!isOffline && !isStale) {
      return const SizedBox.shrink();
    }

    // ── Online but stale → informational banner ──
    if (!isOffline && isStale) {
      return _buildBanner(
        context: context,
        icon: Icons.sync,
        title: 'Conectado',
        subtitle: 'Datos desactualizados',
        bg: CanalColors.accentTint,
        textColor: CanalColors.onTintAccent,
        iconColor: CanalColors.accent,
        showRetry: false,
      );
    }

    // ── Offline → warning banner ──
    final subtitle = _formatOfflineSubtitle(lastConnected);

    return _buildBanner(
      context: context,
      icon: Icons.cloud_off_rounded,
      title: 'Sin conexión',
      subtitle: subtitle,
      bg: CanalColors.offlineDark,
      textColor: CanalColors.darkTextPrimary,
      iconColor: CanalColors.darkTextPrimary,
      showRetry: true,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────

  String _formatOfflineSubtitle(DateTime? lastConnected) {
    if (lastConnected == null) return 'Mostrando datos de $lastUpdated';
    final diff = DateTime.now().difference(lastConnected);
    if (diff.inSeconds < 60) return 'Última actualización: hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Última actualización: hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Última actualización: hace ${diff.inHours}h';
    return 'Última actualización: hace ${diff.inDays}d';
  }

  Widget _buildBanner({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bg,
    required Color textColor,
    required Color iconColor,
    required bool showRetry,
  }) {
    return Semantics(
      label: '$title. $subtitle',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            if (showRetry && onRetry != null)
              Material(
                color: CanalColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onRetry,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CanalColors.offlineDark,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
