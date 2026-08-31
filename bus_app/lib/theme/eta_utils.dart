import 'package:flutter/material.dart';
import 'canal_colors.dart';

/// ETA por urgencia (Brandbook v2: <5 min → error, 5-10 min → accent, >10 min → secondary).
Color etaColor(int eta) {
  if (eta < 5) return CanalColors.error;
  if (eta <= 10) return CanalColors.accent;
  return CanalColors.secondary;
}

/// Color de TEXTO del ETA garantizando contraste AA según el modo.
/// Light: variantes on-tint oscurecidas (§03/§11). Dark: el hue directo
/// (large-text >=3:1 del §03: error 4.4:1 / accent 8.1:1 / secondary 4.7:1).
Color etaTextColor(int eta, bool isDark) {
  final base = etaColor(eta);
  return chipTextColor(base, isDark);
}

/// Variante de `etaTextColor` para colores de estado (chips, badges).
///
/// Light: oscuro sobre tintes (on-tint), porque el hue directo no llega a AA
/// como texto pequeño. Dark: el hue aclarado (on-tint-light) o el hue directo
/// cuando pasa AA sobre los fondos oscuros teñidos (§03/§11).
Color chipTextColor(Color base, bool isDark) {
  if (isDark) {
    if (base == CanalColors.error) return CanalColors.onTintLightError;
    if (base == CanalColors.accent) return CanalColors.accentHoverDark;
    if (base == CanalColors.primary) return CanalColors.onTintLightPrimary;
    if (base == CanalColors.secondary) return CanalColors.onTintLightSecondary;
    if (base == CanalColors.modeBus) return CanalColors.onBusDark;
    if (base == CanalColors.modeWalk ||
        base == CanalColors.success ||
        base == CanalColors.liveGreen) {
      return CanalColors.liveGreen;
    }
    return base;
  }
  if (base == CanalColors.modeMetro) return CanalColors.lightTextPrimary;
  if (base == CanalColors.modeBus) return CanalColors.onBus;
  if (base == CanalColors.modeWalk ||
      base == CanalColors.success ||
      base == CanalColors.liveGreen) {
    return CanalColors.onTintSuccess;
  }
  if (base == CanalColors.accent) return CanalColors.onTintAccent;
  if (base == CanalColors.error) return CanalColors.onTintError;
  if (base == CanalColors.secondary) return CanalColors.onTintSecondary;
  return base;
}

/// Etiqueta del ETA (copy §08): 0-1 → "Llegando", >1 → "N min".
String etaLabel(int eta) {
  if (eta <= 1) return 'Llegando';
  return '$eta min';
}

/// Estado de conexión (pill/banner).
/// Offline = gris neutro informativo (§04/§05), En vivo = verde (live, no éxito).
Color connectionStatusColor(bool offline, bool isDark) => offline
    ? (isDark ? CanalColors.offlineDark : CanalColors.offline)
    : (isDark ? CanalColors.liveGreen : CanalColors.modeWalk);

/// Texto AA para el estado de conexión sobre tintes del mismo color.
Color connectionStatusText(Color status, bool offline, bool isDark) {
  if (offline) {
    return isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
  }
  return chipTextColor(status, isDark);
}
