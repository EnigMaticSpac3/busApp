import 'package:flutter/material.dart';

/// Paleta visual oficial de Transita (Brandbook Canal v1.0).
///
/// Identidad "Canal" — inspirada en el Canal de Panamá:
/// - Azul profundo (#004F7C) como primario (canal600)
/// - Naranja amanecer (#F59D3D) como acento (amber400)
/// - Rojo señal (#E84C2B) como alerta (signal500)
///
/// Jerarquía de la paleta:
/// 1. Roles semánticos (primary, accent, alert) — uso directo en UI
/// 2. Rampas tonales (Canal, Amber, Signal, Neutral) — variantes para hover, fondos, borders
class AppColors {
  // ─────────────────────────────────────────────────────────────
  // 1. RAMPA CANAL (Azul) — Primary
  // ─────────────────────────────────────────────────────────────
  static const canal50  = Color(0xFFF0F8FD);
  static const canal100 = Color(0xFFDFF0F9);
  static const canal200 = Color(0xFFB0D4EE);
  static const canal300 = Color(0xFF72B3DD);
  static const canal400 = Color(0xFF3A8FC9);  // Secondary — Esclusa
  static const canal500 = Color(0xFF1A6B98);
  static const canal600 = Color(0xFF004F7C);  // PRIMARY — Canal Deep
  static const canal700 = Color(0xFF003D60);
  static const canal800 = Color(0xFF002D48);
  static const canal900 = Color(0xFF001E30);

  // ─────────────────────────────────────────────────────────────
  // 2. RAMPA AMANECER (Naranja) — Accent
  // ─────────────────────────────────────────────────────────────
  static const amber50  = Color(0xFFFFF9F2);
  static const amber100 = Color(0xFFFEF3E5);
  static const amber200 = Color(0xFFFBDCB8);
  static const amber300 = Color(0xFFF8BC7A);
  static const amber400 = Color(0xFFF59D3D);  // ACCENT — Amanecer
  static const amber500 = Color(0xFFC47200);
  static const amber600 = Color(0xFF9E5800);
  static const amber700 = Color(0xFF7A4000);
  static const amber800 = Color(0xFF5A2E00);
  static const amber900 = Color(0xFF3D1E00);

  // ─────────────────────────────────────────────────────────────
  // 3. RAMPA SEÑAL (Rojo) — Alert
  // ─────────────────────────────────────────────────────────────
  static const signal50  = Color(0xFFFFF4F2);
  static const signal200 = Color(0xFFFADDD8);
  static const signal400 = Color(0xFFEF7A63);
  static const signal500 = Color(0xFFE84C2B);  // ALERT — Señal Roja
  static const signal600 = Color(0xFFC02010);

  // ─────────────────────────────────────────────────────────────
  // 4. RAMPA NEUTRO (Grises)
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
  // 5. ROLES SEMÁNTICOS
  // ─────────────────────────────────────────────────────────────

  // Primary
  static const primary = Color(0xFF004F7C);         // canal600
  static const primaryHover = Color(0xFF003D60);    // canal700
  static const primarySubtle = Color(0xFFF0F8FD);   // canal50
  static const primaryBorder = Color(0xFF72B3DD);   // canal300
  static const onPrimary = Color(0xFFFFFFFF);

  // Secondary
  static const secondary = Color(0xFF3A8FC9);        // canal400
  static const secondarySubtle = Color(0xFFDFF0F9);  // canal100
  static const onSecondary = Color(0xFF002D48);      // canal800

  // Accent
  static const accent = Color(0xFFF59D3D);           // amber400
  static const accentHover = Color(0xFFC47200);       // amber500
  static const accentSubtle = Color(0xFFFFF9F2);      // amber50
  static const onAccent = Color(0xFF3D1E00);          // amber900 — NUNCA blanco sobre accent

  // Alert
  static const alert = Color(0xFFE84C2B);             // signal500
  static const alertSubtle = Color(0xFFFFF4F2);       // signal50
  static const onAlert = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF1A1C24);       // neutral900
  static const textSecondary = Color(0xFF606680);     // neutral600
  static const textMuted = Color(0xFF8B91A8);         // neutral500
  static const textDisabled = Color(0xFFB0B5C8);      // neutral400
  static const textInverse = Color(0xFFFFFFFF);

  // Surfaces
  static const surfacePage = Color(0xFFF8F9FC);       // neutral50
  static const surfaceCard = Color(0xFFFFFFFF);        // neutral0
  static const surfaceRaised = Color(0xFFF2F3F7);      // neutral100
  static const surfaceOverlay = Color.fromRGBO(0, 31, 48, 0.72);  // canal900 con opacidad

  // Borders
  static const border = Color(0xFFE4E6EF);             // neutral200
  static const borderStrong = Color(0xFFCED2E0);       // neutral300

  // ─────────────────────────────────────────────────────────────
  // 6. ALIASES RETROCOMPATIBLES (DEPRECATED)
  //    Mantenidos para no romper widgets/screens existentes.
  //    Apuntan a los colores equivalentes de la nueva paleta Canal.
  //    Eliminar gradualmente al migrar cada screen.
  // ─────────────────────────────────────────────────────────────
  @Deprecated('Usar surfaceCard o neutral0 en su lugar')
  static const white = Color(0xFFFFFFFF);

  @Deprecated('Usar surfacePage en su lugar')
  static const surface = Color(0xFFF6F7F9);

  @Deprecated('Usar surfaceRaised en su lugar')
  static const surfaceDark = Color(0xFFE8ECF1);

  @Deprecated('Usar secondary (canal400) o primary según el contexto')
  static const primaryLight = Color(0xFF5568B5);

  @Deprecated('Usar canal800 o canal700 según el contexto')
  static const primaryDark = Color(0xFF172368);

  @Deprecated('Usar accent o primary según el contexto')
  static const success = Color(0xFFC8D527);

  @Deprecated('Usar accent o amber según el contexto')
  static const warning = Color(0xFFE88D67);

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
  static const gray50  = Color(0xFFF0F0EF);
  @Deprecated('Usar neutral300 o borderStrong en su lugar')
  static const gray300 = Color(0xFF868684);
  @Deprecated('Usar neutral600 o textSecondary en su lugar')
  static const gray600 = Color(0xFF484846);
  @Deprecated('Usar neutral900 o textPrimary en su lugar')
  static const gray900 = Color(0xFF101010);
}
