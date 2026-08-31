import 'dart:math' show pow;
import 'package:flutter/material.dart';

class CanalColors {
  CanalColors._();

  // ── Brand ──
  static const primary = Color(0xFF0055A4);
  static const secondary = Color(0xFF0D9488);
  static const accent = Color(0xFFF5B400);
  static const error = Color(0xFFE8453C);

  // ── Canal Day (Light) — warm sand palette, aligned with map tiles ──
  static const lightBackground = Color(0xFFF8F7F3); // Arena clara — matches map background
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF0EFE9); // Warm gray for nested cards/inputs
  static const lightTextPrimary = Color(0xFF1F2930); // Warm near-black
  static const lightTextSecondary = Color(0xFF6B7068); // Warm gray
  static const lightTextMuted = Color(0xFF9C9890); // Warm muted
  static const lightBorder = Color(0xFFE5E2D8); // Warm cream border
  static const lightCardShadow = Color(0x0A080000); // Warm-tinted shadow

  // ── Canal Sunset (Dark) ──
  static const darkBackground = Color(0xFF0C0E14);
  static const darkSurface = Color(0xFF151A23);
  static const darkSurface2 = Color(0xFF1C2333);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF64748B);
  static const darkBorder = Color(0xFF1E293B);
  static const darkCardShadow = Color(0x1A000000);

  // ── Variantes hover / on-tint (§11) ──
  static const primaryHover = Color(0xFF004080);
  static const primaryHoverDark = Color(0xFF0066C4);
  static const accentHover = Color(0xFFD49B00);
  static const accentHoverDark = Color(0xFFFBBF24);
  static const accentDark = Color(0xFFF59E0B); // Ámbar atardecer (Canal Sunset)
  // Texto sobre ámbar — NUNCA blanco sobre ámbar (§03 fail 2.6:1)
  static const onAccent = Color(0xFF3D2D00);
  static const onAccentDark = Color(0xFF1C0F00);
  // Dark foregrounds keep compact labels readable on saturated semantic fills.
  // White does not reach AA for normal-size text on coral, teal, or walk green.
  static const onError = Color(0xFF3B0A08);
  static const onSecondary = Color(0xFF06372F);
  static const onWalk = Color(0xFF06372F);
  static const onBus = Color(0xFF451A03); // dark brown for text on amber (5.6:1)
  // Tints (light) — §11
  static const primaryTint = Color(0xFFE8F2FF);
  static const accentTint = Color(0xFFFEF8E6);
  static const errorTint = Color(0xFFFEF0EF);
  static const secondaryTint = Color(0xFFE6FAF8);

  // ── Transport modes ──
  static const modeBus = Color(0xFFF5B400); // ámbar solar (icon/border en marker neutral)
  static const modeWalk = Color(0xFF00B894);
  static const modeMetro = Color(0xFF2B5BFF);
  static const modeBike = Color(0xFFF59E0B);
  // Trazos sobre el mapa (§12 WCAG no-text 3:1).
  static const modeBusMapDay = Color(0xFFD97706); // bus en mapa light (4.3:1)
  static const modeWalkMapDay = Color(0xFF0B8A6E); // walk en mapa light (4.02:1)
  static const modeMetroDark = Color(0xFF4D7FFF); // §14 noche (5.32:1)
  // Texto sobre bus ámbar
  static const onBusDark = Color(0xFFFFFBEB); // near-white for dark mode on amber
  static const modeBusTint = Color(0xFFFEF3C7); // light amber tint for pill bg
  // Marcador de bus neutral — cuerpo blanco/oscuro, icono/borde mode-colored
  static const markerBody = Color(0xFFFFFFFF); // light mode marker body
  static const markerBodyDark = Color(0xFF1C2333); // dark mode marker body (darkSurface2)
  // ── Surface ──
  static const surfaceOverlay = Color.fromRGBO(0, 31, 48, 0.72);

  // ── Semantic ──
  static const success = Color(0xFF00B894); // Walk green — paleta Canal
  static const warning = Color(0xFFF59E0B);
  static const alert = Color(0xFFE8453C);
  static const liveGreen = Color(0xFF00B894); // Walk green — paleta Canal

  // ── Delayed (Brandbook §14) ──
  static const delayedDay = Color(0xFFD97706); // light
  static const delayedNight = Color(0xFFFBBF24); // night

  // ── On-tint text (variantes oscurecidas para AA 4.5:1 sobre tints en light) ──
  static const onTintSuccess = Color(0xFF047857);
  static const onTintAccent = Color(0xFFB45309);
  static const onTintError = Color(0xFFA93228);
  static const onTintSecondary = Color(0xFF0F766E);
  // Aclarados del mismo hue para texto sobre tints/fills en dark (§03/§11)
  static const onTintLightError = Color(0xFFF87171);
  static const onTintLightPrimary = Color(0xFF74B6EF);
  static const onTintLightSecondary = Color(0xFF2DD4BF);

  // ── Offline (gris neutro informativo §04/§05 — NO es error) ──
  static const offline = Color(0xFF9CA3AF); // day
  static const offlineDark = Color(0xFF64748B); // night

  // ── MiBus route colors (AA 4.5:1 sobre surface blanco y oscuro) ──
  // Identificación de ruta EN BADGES SOLAMENTE — nunca usar para estado/funcional.
  static const routeS = Color(0xFF2A5CAA); // Corredor Sur — azul oscuro
  static const routeT = Color(0xFF9B52A1); // Corredor Norte — púrpura
  static const routeV = Color(0xFFFCB94B); // Vía España — amarillo / dorado
  static const routeM = Color(0xFF88C75A); // Tumba Muerto / Alfaro — verde manzana
  static const routeK = Color(0xFF1F96D0); // Transístmica — azul medio (separado de modeMetro #2B5BFF)
  static const routeI = Color(0xFFD94452); // Vía Israel — rojo carmín (separado de error #E8453C)
  static const routeF = Color(0xFF178F82); // Forestal — verde azulado profundo (separado de secondary #0D9488)
  static const routeA = Color(0xFFFF6D32); // Alimentadoras / Panamá Norte — naranja
  static const routeC = Color(0xFF87838A); // Centro / Complementarias — gris
  static const routeE = Color(0xFFA18B6B); // Sector Este — café / beige
  static const routeN = Color(0xFF7D9976); // Sector Norte / San Miguelito — verde oliva

  static const routeFallback = Color(0xFF6B7280); // Gris neutro para códigos desconocidos

  /// Lookup de color de ruta por prefijo del código MiBus.
  static Color routeColorForCode(String code) {
    if (code.isEmpty) return routeFallback;
    switch (code.toUpperCase().characters.first) {
      case 'S':
        return routeS;
      case 'T':
        return routeT;
      case 'V':
        return routeV;
      case 'M':
        return routeM;
      case 'K':
        return routeK;
      case 'I':
        return routeI;
      case 'F':
        return routeF;
      case 'A':
        return routeA;
      case 'C':
        return routeC;
      case 'E':
        return routeE;
      case 'N':
        return routeN;
      default:
        return routeFallback;
    }
  }

  /// Relative luminance de un color sRGB (0..1). WCAG 2.1 §G.
  static double _luminance(Color c) {
    final r = _srgbToLinear(c.r);
    final g = _srgbToLinear(c.g);
    final b = _srgbToLinear(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _srgbToLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();

  /// Texto legible sobre el fondo de ruta por luminancia del badge.
  /// Badges claros → texto oscuro; badges oscuros → blanco.
  /// Dark mode usa threshold mayor (0.45 vs 0.3) porque badges brillantes
  /// (V/M/A) sobre superficie oscura necesitan texto oscuro para no caer
  /// en blanco-sobre-brillante (1.65–2.81:1).
  static Color routeTextColor(String code, {bool isDark = false}) {
    final bg = routeColorForCode(code);
    final threshold = isDark ? 0.45 : 0.3;
    if (_luminance(bg) > threshold) {
      return isDark ? darkTextPrimary : lightTextPrimary;
    }
    return Colors.white;
  }
}
