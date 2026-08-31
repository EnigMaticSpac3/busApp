import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

class ConnectionBanner extends StatelessWidget {
  final String lastUpdated;
  final VoidCallback? onRetry;
  final bool isDark;

  const ConnectionBanner({
    super.key,
    required this.lastUpdated,
    this.onRetry,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    const banner = CanalColors.offlineDark;

    return Semantics(
      label: 'Sin conexión. Mostrando datos de $lastUpdated',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: banner,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: CanalColors.darkTextPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sin conexión',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CanalColors.darkTextPrimary,
                  ),
                ),
                Text(
                  'Mostrando datos de $lastUpdated',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CanalColors.darkTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
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
