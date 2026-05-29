import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class RouteBadge extends StatelessWidget {
  final String codigo;
  final double fontSize;

  const RouteBadge({
    super.key,
    required this.codigo,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        codigo,
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
