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
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.gray600),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(
              message,
              style: AppTypography.textTheme.bodyLarge?.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
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

    if (onDismiss != null) {
      return Stack(
        children: [
          content,
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

    return content;
  }
}
