import 'package:flutter/material.dart';
import 'package:bus_app/theme/export.dart';

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? textColor;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
