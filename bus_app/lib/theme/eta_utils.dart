import 'package:flutter/material.dart';
import 'canal_colors.dart';

Color etaColor(int eta) {
  if (eta < 5) return CanalColors.error;
  if (eta <= 10) return CanalColors.accent;
  return CanalColors.secondary;
}

Color etaTextColor(int eta, bool isDark) {
  final base = etaColor(eta);
  return chipTextColor(base, isDark);
}

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

String etaLabel(int eta) {
  if (eta <= 1) return 'Llegando';
  return '$eta min';
}

Color connectionStatusColor(bool offline, bool isDark) => offline
    ? (isDark ? CanalColors.offlineDark : CanalColors.offline)
    : (isDark ? CanalColors.liveGreen : CanalColors.modeWalk);

Color connectionStatusText(Color status, bool offline, bool isDark) {
  if (offline) {
    return isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
  }
  return chipTextColor(status, isDark);
}
