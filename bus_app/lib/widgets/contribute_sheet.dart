import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

Future<bool> showContributeSheet(BuildContext context, {String routeCode = 'K480'}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ContributeSheet(routeCode: routeCode),
  ).then((v) => v ?? false);
}

class _ContributeSheet extends StatefulWidget {
  final String routeCode;

  const _ContributeSheet({required this.routeCode});

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textSecondary = isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final divider = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CanalColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.share_location_rounded, size: 22, color: CanalColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Comparte tu ubicación y ayuda a otros',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CanalColors.liveGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: CanalColors.liveGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Otros pasajeros ya aportan el ETA de ${widget.routeCode}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CanalColors.liveGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Mientras viajas en el bus, tu posición mejora la hora de llegada para quienes te siguen. Solo se comparte mientras el viaje está activo. Los datos se suman al cálculo del ETA: otros pasajeros ven el bus y la hora, nunca tu punto personal.',
                style: TextStyle(fontSize: 13, height: 1.5, color: textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? CanalColors.darkBackground : CanalColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: divider),
                ),
                child: Column(
                  children: [
                    _costRow(Icons.battery_5_bar_rounded, '~5% de batería por 20 min', textSecondary),
                    const SizedBox(height: 8),
                    _costRow(Icons.data_usage_rounded, '<100 KB por viaje', textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CanalColors.secondary,
                    foregroundColor: CanalColors.onSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Aceptar y ayudar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Quizás luego',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _costRow(IconData icon, String label, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 15, color: textSecondary),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
      ],
    );
  }
}
