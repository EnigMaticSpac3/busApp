import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class AppSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final String hintText;

  const AppSearchBar({
    super.key,
    this.onTap,
    this.hintText = '¿A dónde vas?',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                hintText,
                style: AppTypography.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
