import 'package:flutter/material.dart';
import 'package:bus_app/widgets/app_bottom_sheet.dart';
import 'package:bus_app/widgets/app_primary_button.dart';
import 'package:bus_app/theme/export.dart';

class CrowdsourcingSheet extends StatelessWidget {
  final VoidCallback onContribuir;
  final VoidCallback onAhoraNoPor;

  const CrowdsourcingSheet({
    super.key,
    required this.onContribuir,
    required this.onAhoraNoPor,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required VoidCallback onContribuir,
    required VoidCallback onAhora,
  }) {
    return AppBottomSheet.mostrar(
      context,
      child: CrowdsourcingSheet(
        onContribuir: onContribuir,
        onAhoraNoPor: onAhora,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          '¿Vas en el bus ahora?',
          style: AppTypography.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Compartiendo tu ubicación mientras viajas, '
          'otros pasajeros pueden ver dónde está el bus en tiempo real.',
          style: AppTypography.textTheme.bodyMedium?.copyWith(height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lime50,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.lime300.withValues(alpha: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 18, color: AppColors.lime600),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'No se recopilan datos personales.\n'
                  'Tu participación es voluntaria, anónima '
                  'y puedes desactivarla cuando quieras.',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.lime900,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        AppPrimaryButton(
          label: 'Sí, quiero contribuir',
          icon: Icons.location_on,
          onPressed: onContribuir,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onAhoraNoPor,
            child: Text(
              'Ahora no',
              style: TextStyle(
                color: AppColors.alert,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
