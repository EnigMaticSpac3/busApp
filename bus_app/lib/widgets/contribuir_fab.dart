import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class ContribuirFab extends StatefulWidget {
  final bool activo;
  final String? busId;
  final bool ignorado;
  final VoidCallback? onPressed;

  const ContribuirFab({
    super.key,
    required this.activo,
    this.busId,
    this.ignorado = false,
    this.onPressed,
  });

  @override
  State<ContribuirFab> createState() => _ContribuirFabState();
}

class _ContribuirFabState extends State<ContribuirFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ContribuirFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activo && !oldWidget.activo) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.activo && oldWidget.activo) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.activo ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton.extended(
            heroTag: 'contribuir',
            onPressed: widget.onPressed,
            tooltip: widget.activo
                ? 'Detener contribución GPS'
                : 'Iniciar contribución GPS',
            backgroundColor: widget.activo ? AppColors.accent : AppColors.white,
            elevation: widget.activo ? 4 : 2,
            icon: Icon(
              widget.activo ? Icons.signal_wifi_4_bar : Icons.location_on,
              color: widget.activo ? AppColors.textPrimary : AppColors.primary,
            ),
            label: Text(
              () {
                if (widget.activo) {
                  if (widget.busId != null) return 'En ${widget.busId}';
                  if (widget.ignorado) return 'Buscando bus...';
                  return 'Contribuyendo';
                }
                return 'Contribuir';
              }(),
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: widget.activo ? AppColors.textPrimary : AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
