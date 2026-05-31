import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(label),
      ),
    );
  }
}
