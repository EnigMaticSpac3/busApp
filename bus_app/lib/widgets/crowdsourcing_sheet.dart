import 'package:flutter/material.dart';
import 'package:bus_app/widgets/app_bottom_sheet.dart';
import 'package:bus_app/widgets/app_primary_button.dart';
import 'package:bus_app/widgets/app_secondary_button.dart';
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          '¿Vas en el bus ahora?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Compartiendo tu ubicación mientras viajas, otros pasajeros '
          'pueden ver dónde está el bus en tiempo real.\n\n'
          'Es voluntario, anónimo y puedes desactivarlo cuando quieras '
          'desde el botón en el mapa.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.lime50,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(color: AppColors.lime300),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppColors.lime600),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'No se recopilan datos personales. Tu ID es completamente anónimo.',
                  style: TextStyle(fontSize: 12, color: AppColors.lime900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppPrimaryButton(
          label: 'Sí, quiero contribuir',
          icon: Icons.location_on,
          onPressed: onContribuir,
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          label: 'Ahora no',
          textColor: AppColors.textSecondary,
          onPressed: onAhoraNoPor,
        ),
      ],
    );
  }
}
