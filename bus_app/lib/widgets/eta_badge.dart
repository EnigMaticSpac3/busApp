import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class EtaBadge extends StatelessWidget {
  final String eta;
  final int minutos;

  const EtaBadge({
    super.key,
    required this.eta,
    required this.minutos,
  });

  Color get _bgColor {
    if (minutos <= 1) return AppColors.alert;
    if (minutos <= 5) return AppColors.warning;
    return AppColors.accent;
  }

  Color get _textColor {
    if (minutos <= 1) return AppColors.white;
    if (minutos <= 5) return AppColors.textPrimary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        eta,
        style: AppTypography.textTheme.labelLarge?.copyWith(
          color: _textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
