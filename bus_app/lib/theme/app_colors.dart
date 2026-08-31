import 'package:flutter/material.dart';
import 'canal_colors.dart';

/// Capa de compatibilidad para AppColors.
/// Mantiene los nombres de la paleta anterior (canal50-900, amber50-900, etc.)
/// pero apunta a los colores equivalentes de CanalColors.
///
/// DEPRECATED: Usar CanalColors directamente en código nuevo.
class AppColors {
  // ─────────────────────────────────────────────────────────────
  // RAMPA CANAL (Azul) — Primary
  // ─────────────────────────────────────────────────────────────
  static const canal50  = Color(0xFFF0F8FD);
  static const canal100 = Color(0xFFDFF0F9);
  static const canal200 = Color(0xFFB0D4EE);
  static const canal300 = Color(0xFF72B3DD);
  static const canal400 = Color(0xFF3A8FC9);
  static const canal500 = Color(0xFF1A6B98);
  static const canal600 = Color(0xFF004F7C);
  static const canal700 = Color(0xFF003D60);
  static const canal800 = Color(0xFF002D48);
  static const canal900 = Color(0xFF001E30);

  // ─────────────────────────────────────────────────────────────
  // RAMPA AMANECER (Naranja) — Accent
  // ─────────────────────────────────────────────────────────────
  static const amber50  = Color(0xFFFFF9F2);
  static const amber100 = Color(0xFFFEF3E5);
  static const amber200 = Color(0xFFFBDCB8);
  static const amber300 = Color(0xFFF8BC7A);
  static const amber400 = Color(0xFFF59D3D);
  static const amber500 = Color(0xFFC47200);
  static const amber600 = Color(0xFF9E5800);
  static const amber700 = Color(0xFF7A4000);
  static const amber800 = Color(0xFF5A2E00);
  static const amber900 = Color(0xFF3D1E00);

  // ─────────────────────────────────────────────────────────────
  // RAMPA SEÑAL (Rojo) — Alert
  // ─────────────────────────────────────────────────────────────
  static const signal50  = Color(0xFFFFF4F2);
  static const signal200 = Color(0xFFFADDD8);
  static const signal400 = Color(0xFFEF7A63);
  static const signal500 = Color(0xFFE84C2B);
  static const signal600 = Color(0xFFC02010);

  // ─────────────────────────────────────────────────────────────
  // RAMPA NEUTRO (Grises)
  // ─────────────────────────────────────────────────────────────
  static const neutral0   = Color(0xFFFFFFFF);
  static const neutral50  = Color(0xFFF8F9FC);
  static const neutral100 = Color(0xFFF2F3F7);
  static const neutral200 = Color(0xFFE4E6EF);
  static const neutral300 = Color(0xFFCED2E0);
  static const neutral400 = Color(0xFFB0B5C8);
  static const neutral500 = Color(0xFF8B91A8);
  static const neutral600 = Color(0xFF606680);
  static const neutral700 = Color(0xFF454A60);
  static const neutral800 = Color(0xFF2D3142);
  static const neutral900 = Color(0xFF1A1C24);

  // ─────────────────────────────────────────────────────────────
  // ROLES SEMÁNTICOS
  // ─────────────────────────────────────────────────────────────

  // Primary
  static const primary = CanalColors.primary;
  static const primaryHover = Color(0xFF003D60);
  static const primarySubtle = Color(0xFFF0F8FD);
  static const primaryBorder = Color(0xFF72B3DD);
  static const onPrimary = Colors.white;

  // Secondary
  static const secondary = Color(0xFF3A8FC9);
  static const secondarySubtle = Color(0xFFDFF0F9);
  static const onSecondary = Color(0xFF002D48);

  // Accent
  static const accent = CanalColors.accent;
  static const accentHover = Color(0xFFC47200);
  static const accentSubtle = Color(0xFFFFF9F2);
  static const onAccent = CanalColors.onAccent;

  // Alert
  static const alert = CanalColors.error;
  static const alertSubtle = Color(0xFFFFF4F2);
  static const onAlert = Colors.white;

  // Text
  static const textPrimary = CanalColors.lightTextPrimary;
  static const textSecondary = CanalColors.lightTextSecondary;
  static const textMuted = CanalColors.lightTextMuted;
  static const textDisabled = Color(0xFFB0B5C8);
  static const textInverse = Colors.white;

  // Surfaces
  static const surfacePage = CanalColors.lightBackground;
  static const surfaceCard = CanalColors.lightSurface;
  static const surfaceRaised = CanalColors.lightSurface2;
  static const surfaceOverlay = CanalColors.surfaceOverlay;

  // Borders
  static const border = CanalColors.lightBorder;
  static const borderStrong = Color(0xFFCED2E0);

  // ─────────────────────────────────────────────────────────────
  // ALIASES RETROCOMPATIBLES (DEPRECATED)
  // ─────────────────────────────────────────────────────────────
  @Deprecated('Usar surfaceCard o neutral0 en su lugar')
  static const white = Colors.white;

  @Deprecated('Usar surfacePage en su lugar')
  static const surface = CanalColors.lightBackground;

  @Deprecated('Usar surfaceRaised en su lugar')
  static const surfaceDark = CanalColors.lightSurface2;

  @Deprecated('Usar secondary (canal400) o primary según el contexto')
  static const primaryLight = Color(0xFF5568B5);

  @Deprecated('Usar canal800 o canal700 según el contexto')
  static const primaryDark = Color(0xFF172368);

  @Deprecated('Usar accent o primary según el contexto')
  static const success = CanalColors.success;

  @Deprecated('Usar accent o amber según el contexto')
  static const warning = CanalColors.warning;

  // Escalas tonales previas — mantenidas para compatibilidad con widgets existentes
  @Deprecated('Usar canal50 en su lugar')
  static const blue50  = Color(0xFFE8EEFA);
  @Deprecated('Usar canal300 en su lugar')
  static const blue300 = Color(0xFF7A9AE0);
  @Deprecated('Usar canal600 (primary) en su lugar')
  static const blue600 = Color(0xFF2F54AD);
  @Deprecated('Usar canal900 en su lugar')
  static const blue900 = Color(0xFF131C70);

  @Deprecated('Usar primarySubtle (canal50) o eval si se necesita verde')
  static const lime50  = Color(0xFFF4F8D0);
  @Deprecated('Usar primaryBorder (canal300) o eval')
  static const lime300 = Color(0xFFD4E46A);
  @Deprecated('Usar primary (canal600) o eval')
  static const lime600 = Color(0xFF8FA020);
  @Deprecated('Usar canal900 o eval')
  static const lime900 = Color(0xFF576010);

  @Deprecated('Usar accentSubtle (amber50) en su lugar')
  static const orange50  = Color(0xFFFDF0E8);
  @Deprecated('Usar amber300 en su lugar')
  static const orange300 = Color(0xFFF0AC80);
  @Deprecated('Usar amber600 en su lugar')
  static const orange600 = Color(0xFFB85520);
  @Deprecated('Usar amber900 en su lugar')
  static const orange900 = Color(0xFF7A2F0E);

  @Deprecated('Usar neutral50 en su lugar')
  static const gray50  = CanalColors.lightSurface2;
  @Deprecated('Usar neutral300 o borderStrong en su lugar')
  static const gray300 = CanalColors.lightBorder;
  @Deprecated('Usar neutral600 o textSecondary en su lugar')
  static const gray600 = CanalColors.lightTextSecondary;
  @Deprecated('Usar neutral900 o textPrimary en su lugar')
  static const gray900 = CanalColors.lightTextPrimary;
}
