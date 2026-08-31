// lib/providers/gamification_provider.dart
//
// Local gamification stats for the conductor profile screen.
// Stores points, trips, streak, and badges in SharedPreferences.
// No backend integration — purely local demo data that accumulates
// each time the driver starts a tracking session.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationProvider extends ChangeNotifier {
  static const _pointsKey = 'gamification_total_points';
  static const _tripsKey = 'gamification_trips_count';
  static const _streakKey = 'gamification_streak_days';
  static const _lastDateKey = 'gamification_last_tracking_date';
  static const _badgesKey = 'gamification_earned_badges';

  int _totalPoints = 0;
  int _tripsCount = 0;
  int _streakDays = 0;
  List<String> _earnedBadges = [];
  bool _initialized = false;

  // ── Getters ──────────────────────────────────────────────────────────

  int get totalPoints => _totalPoints;
  int get tripsCount => _tripsCount;
  int get streakDays => _streakDays;
  List<String> get earnedBadges => List.unmodifiable(_earnedBadges);
  bool get isTopContributor => _totalPoints > 500;

  String get rankLabel {
    if (_totalPoints >= 1000) return 'Maestro GPS';
    if (_totalPoints >= 500) return 'Conductor Experto';
    if (_totalPoints >= 100) return 'Conductor Activo';
    if (_totalPoints >= 10) return 'Contribuidor';
    return 'Nuevo';
  }

  // ── Init ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _totalPoints = prefs.getInt(_pointsKey) ?? 0;
    _tripsCount = prefs.getInt(_tripsKey) ?? 0;
    _streakDays = prefs.getInt(_streakKey) ?? 0;
    _earnedBadges = prefs.getStringList(_badgesKey) ?? [];
    _updateStreak(prefs);
    _initialized = true;
    notifyListeners();
  }

  void _updateStreak(SharedPreferences prefs) {
    final lastMs = prefs.getInt(_lastDateKey);
    if (lastMs == null) return;

    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final diff = today.difference(last).inDays;

    if (diff > 1) {
      _streakDays = 0;
      prefs.setInt(_streakKey, 0);
    }
  }

  // ── Mutations ────────────────────────────────────────────────────────

  Future<void> addPoints(int points, {bool isPeakHours = false}) async {
    final actual = isPeakHours ? points * 2 : points;
    _totalPoints += actual;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, _totalPoints);
    _checkBadges(prefs);
    notifyListeners();
  }

  Future<void> recordTrackingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastMs = prefs.getInt(_lastDateKey);

    if (lastMs != null) {
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final today = DateTime(now.year, now.month, now.day);
      final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(last).inDays;

      if (diff == 1) {
        _streakDays += 1;
      } else if (diff > 1) {
        _streakDays = 1;
      }
      // diff == 0 → same day, no streak change
    } else {
      _streakDays = 1;
    }

    _tripsCount += 1;
    await prefs.setInt(_streakKey, _streakDays);
    await prefs.setInt(_tripsKey, _tripsCount);
    await prefs.setInt(_lastDateKey, now.millisecondsSinceEpoch);
    _checkBadges(prefs);
    notifyListeners();
  }

  void _checkBadges(SharedPreferences prefs) {
    final badges = List<String>.from(_earnedBadges);
    bool changed = false;

    if (_tripsCount >= 1 && !badges.contains('primera_ruta')) {
      badges.add('primera_ruta');
      changed = true;
    }
    if (_tripsCount >= 10 && !badges.contains('conductor_activo')) {
      badges.add('conductor_activo');
      changed = true;
    }
    if (_totalPoints >= 1000 && !badges.contains('maestro_gps')) {
      badges.add('maestro_gps');
      changed = true;
    }
    if (_streakDays >= 7 && !badges.contains('racha_semanal')) {
      badges.add('racha_semanal');
      changed = true;
    }
    if (_streakDays >= 30 && !badges.contains('racha_mensual')) {
      badges.add('racha_mensual');
      changed = true;
    }

    if (changed) {
      _earnedBadges = badges;
      prefs.setStringList(_badgesKey, badges);
    }
  }

  // ── Badge helpers ────────────────────────────────────────────────────

  String badgeLabel(String key) {
    const labels = {
      'primera_ruta': 'Primera Ruta',
      'conductor_activo': 'Conductor Activo',
      'maestro_gps': 'Maestro GPS',
      'racha_semanal': 'Racha Semanal',
      'racha_mensual': 'Racha Mensual',
      'top_contributor': 'Top Contributor',
    };
    return labels[key] ?? key;
  }

  String badgeIcon(String key) {
    const icons = {
      'primera_ruta': '\u{1F68C}',
      'conductor_activo': '\u2B50',
      'maestro_gps': '\u{1F31F}',
      'racha_semanal': '\u{1F525}',
      'racha_mensual': '\u{1F48E}',
      'top_contributor': '\u{1F3C6}',
    };
    return icons[key] ?? '\u{1F3C5}';
  }
}
