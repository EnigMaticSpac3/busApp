import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografía de Transita.
///
/// DEPRECATED: Usar AppTheme.canalDay.textTheme o AppTheme.canalSunset.textTheme directamente.
/// Mantenido para compatibilidad con widgets existentes.
class AppTypography {
  static TextTheme get textTheme {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        color: AppColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        color: AppColors.textMuted,
        letterSpacing: 0.08 * 11,
      ),
    );
  }

  /// Estilo monoespaciado para datos y ETA (JetBrains Mono).
  static TextStyle get etaStyle => const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.canal600,
    height: 1,
  );
}
