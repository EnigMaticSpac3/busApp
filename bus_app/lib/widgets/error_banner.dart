import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final IconData? icon;

  const ErrorBanner({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.orange50,
        border: Border.all(color: AppColors.orange300.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.warning_amber,
            color: AppColors.alert,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.alert,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
