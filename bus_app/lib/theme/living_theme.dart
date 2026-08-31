import 'package:flutter/material.dart';
import 'app_theme.dart';

enum CanalMoment {
  dawn,    // 05:30 - 08:00
  day,     // 08:00 - 17:30
  sunset,  // 17:30 - 19:00
  night,   // 19:00 - 05:30
}

class LivingTheme extends ChangeNotifier {
  CanalMoment _moment = CanalMoment.day;
  bool _useManualOverride = false;
  CanalMoment _manualMoment = CanalMoment.day;

  CanalMoment get currentMoment => _useManualOverride ? _manualMoment : _moment;
  bool get isManualOverride => _useManualOverride;

  ThemeData get theme {
    switch (currentMoment) {
      case CanalMoment.dawn:
      case CanalMoment.day:
        return AppTheme.canalDay;
      case CanalMoment.sunset:
      case CanalMoment.night:
        return AppTheme.canalSunset;
    }
  }

  bool get isDark => currentMoment == CanalMoment.sunset || currentMoment == CanalMoment.night;

  void updateFromTime(TimeOfDay time) {
    if (_useManualOverride) return;

    final hour = time.hour + time.minute / 60.0;
    final newMoment = _momentForHour(hour);

    if (newMoment != _moment) {
      _moment = newMoment;
      notifyListeners();
    }
  }

  void setManualMoment(CanalMoment moment) {
    _useManualOverride = true;
    _manualMoment = moment;
    notifyListeners();
  }

  void toggleDarkMode() {
    _useManualOverride = true;
    _manualMoment = isDark ? CanalMoment.day : CanalMoment.night;
    notifyListeners();
  }

  void clearManualOverride() {
    _useManualOverride = false;
    notifyListeners();
  }

  String get momentLabel {
    switch (currentMoment) {
      case CanalMoment.dawn: return 'Amanecer';
      case CanalMoment.day: return 'Canal Day';
      case CanalMoment.sunset: return 'Atardecer';
      case CanalMoment.night: return 'Canal Night';
    }
  }

  IconData get momentIcon {
    switch (currentMoment) {
      case CanalMoment.dawn: return Icons.wb_twilight;
      case CanalMoment.day: return Icons.light_mode;
      case CanalMoment.sunset: return Icons.wb_sunny;
      case CanalMoment.night: return Icons.dark_mode;
    }
  }

  static CanalMoment _momentForHour(double hour) {
    if (hour >= 5.5 && hour < 8.0) return CanalMoment.dawn;
    if (hour >= 8.0 && hour < 17.5) return CanalMoment.day;
    if (hour >= 17.5 && hour < 19.0) return CanalMoment.sunset;
    return CanalMoment.night;
  }
}
