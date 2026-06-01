import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';
import 'app_primary_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isBanner = onDismiss != null;

    // ── Icono ──────────────────────────────────────────────────
    final iconWidget = isBanner
        ? Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: AppColors.accent),
          )
        : Icon(icon, size: 48, color: AppColors.gray600);

    // ── Texto ──────────────────────────────────────────────────
    final textWidget = Text(
      message,
      style: AppTypography.textTheme.bodyLarge?.copyWith(
        color: isBanner ? AppColors.textPrimary : AppColors.gray600,
      ),
      textAlign: TextAlign.center,
    );

    // ── Contenido principal ────────────────────────────────────
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: textWidget,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(
                label: actionLabel!,
                icon: Icons.refresh,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );

    // ── Modo banner (con dismiss) ──────────────────────────────
    if (onDismiss != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: content,
          ),
          Positioned(
            top: -AppSpacing.sm,
            right: -AppSpacing.sm,
            child: IconButton(
              icon: Icon(Icons.close, color: AppColors.gray300),
              onPressed: onDismiss,
              tooltip: 'Descartar',
            ),
          ),
        ],
      );
    }

    // ── Modo estático (sin dismiss, ej. error de ruta) ────────
    return content;
  }
}
