import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme get textTheme {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
      ),
    );
  }
}
