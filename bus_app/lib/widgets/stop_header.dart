import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class StopHeader extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Widget? trailing;

  const StopHeader({
    super.key,
    this.icon = Icons.location_on,
    required this.titulo,
    required this.subtitulo,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitulo, style: AppTypography.textTheme.bodyMedium),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
