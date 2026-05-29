import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class FloatingMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const FloatingMapButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: UniqueKey().toString(),
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.white,
      child: Icon(icon, color: iconColor ?? AppColors.primary),
    );
  }
}
