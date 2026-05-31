import 'package:flutter/material.dart';

/// Paleta visual oficial de San Antonio Bus Tracker (Brandbook v1.0).
///
/// Todos los colores están alineados con la identidad corporativa definida
/// en el brandbook del proyecto. Cada token incluye su referencia HEX para
/// facilitar la comunicación con el equipo de diseño y la verificación
/// visual durante el desarrollo.
///
/// Jerarquía de la paleta:
/// 1. Colores primarios (primary, accent, alert) — usos principales en UI
/// 2. Neutros (surface, textPrimary, textSecondary) — fondos y tipografía
/// 3. Semánticos (success, warning) — estados y feedback
/// 4. Escalas tonales (blue*, lime*, orange*, gray*) — variantes para gradientes y hover
class AppColors {
  // ─────────────────────────────────────────────────────────────
  // 1. PALETA PRINCIPAL (Primary Colors)
  // ─────────────────────────────────────────────────────────────

  /// Azul institucional — #283C90
  /// AppBar, BottomNav activo, FAB inactivo, headers, botones primarios.
  static const primary = Color(0xFF283C90);

  /// Versión clara del primario — #5568B5
  /// Usado para estados hover, fondos de input activos, badges suaves.
  static const primaryLight = Color(0xFF5568B5);

  /// Versión oscura del primario — #172368
  /// Usado en textos sobre fondos claros, shadows, estados pressed.
  static const primaryDark = Color(0xFF172368);

  /// Verde lima corporativo — #C8D527
  /// Polyline de ruta en mapa, FAB activo, accentos destacados,
  /// toggle activo, indicadores de contribución GPS activa.
  static const accent = Color(0xFFC8D527);

  /// Naranja alerta — #E88D67
  /// Marcador de bus activo, indicadores de estado en sesión,
  /// opacidad al 50% para estado "incierto", al 20% para "perdido".
  static const alert = Color(0xFFE88D67);

  // ─────────────────────────────────────────────────────────────
  // 2. NEUTROS (Neutral / Surface Colors)
  // ─────────────────────────────────────────────────────────────

  /// Blanco puro — #FFFFFF
  /// Fondos de tarjetas, modales, bottoms sheets, texto sobre color.
  static const white = Color(0xFFFFFFFF);

  /// Fondo base de pantallas — #F6F7F9
  /// Scaffold background, fondos de listas, contenido general.
  static const surface = Color(0xFFF6F7F9);

  /// Fondo secundario (elevado) — #E8ECF1
  /// Cards, contenedores elevados, secciones agrupadas,
  /// fondo de inputs deshabilitados.
  static const surfaceDark = Color(0xFFE8ECF1);

  /// Texto primario — #1F2937
  /// Títulos, textos de alto contraste, body principal.
  static const textPrimary = Color(0xFF1F2937);

  /// Texto secundario — #6B7280
  /// Subtítulos, metadatos, hints, placeholders.
  static const textSecondary = Color(0xFF6B7280);

  // ─────────────────────────────────────────────────────────────
  // 3. COLORES SEMÁNTICOS (Semantic Colors)
  // ─────────────────────────────────────────────────────────────

  /// Verde de éxito — #C8D527 (hereda del accent)
  /// Indicadores de operación correcta, confirmaciones, checkmarks.
  static const success = Color(0xFFC8D527);

  /// Anaranjado de advertencia — #E88D67 (hereda del alert)
  /// Alertas no críticas, warned state, batería baja, señal débil.
  static const warning = Color(0xFFE88D67);

  // ─────────────────────────────────────────────────────────────
  // 4. ESCALAS TONALES (Tonal Scales)
  // ─────────────────────────────────────────────────────────────

  /// — Escala Azul (Blue) —
  /// Derivada de primary (#283C90) para gradientes y fondos translúcidos.
  static const blue50   = Color(0xFFE8EEFA);
  static const blue300  = Color(0xFF7A9AE0);
  static const blue600  = Color(0xFF2F54AD);
  static const blue900  = Color(0xFF131C70);

  /// — Escala Lima (Lime) —
  /// Derivada de accent (#C8D527) para estados hover de botones accent.
  static const lime50   = Color(0xFFF4F8D0);
  static const lime300  = Color(0xFFD4E46A);
  static const lime600  = Color(0xFF8FA020);
  static const lime900  = Color(0xFF576010);

  /// — Escala Naranja (Orange) —
  /// Derivada de alert (#E88D67) para fondos de badges de alerta.
  static const orange50   = Color(0xFFFDF0E8);
  static const orange300  = Color(0xFFF0AC80);
  static const orange600  = Color(0xFFB85520);
  static const orange900  = Color(0xFF7A2F0E);

  /// — Escala Gris (Gray) —
  /// Neutros puros para borders, separadores, fondos deshabilitados.
  static const gray50   = Color(0xFFF0F0EF);
  static const gray300  = Color(0xFF868684);
  static const gray600  = Color(0xFF484846);
  static const gray900  = Color(0xFF101010);
}
