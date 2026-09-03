import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/schedule_dao.dart';
import '../widgets/timetable_widget.dart' show DepartureEntry;

/// Repository for schedule data — local-first, no API yet.
///
/// All reads come from the local Drift database. Use [seedDemoSchedules]
/// to populate realistic demo data for testing.
class ScheduleRepository {
  late final ScheduleDao _dao;

  ScheduleRepository(AppDatabase db) : _dao = ScheduleDao(db);

  // ── Read ────────────────────────────────────────────────────────────────────

  /// All schedules for [routeId], ordered by start time.
  Future<List<Schedule>> getSchedulesByRoute(String routeId) {
    return _dao.getByRouteId(routeId);
  }

  /// Schedules for [routeId] and [dayType] (weekday / saturday / sunday_holiday).
  Future<List<Schedule>> getSchedulesByRouteAndDay(
    String routeId,
    String dayType,
  ) {
    return _dao
        .getByRouteId(routeId)
        .then((list) => list.where((s) => s.dayType == dayType).toList());
  }

  /// Reactive stream of schedules for [routeId] + [dayType].
  Stream<List<Schedule>> watchSchedulesByRouteAndDay(
    String routeId,
    String dayType,
  ) {
    return _dao.watchByRouteAndDay(routeId, dayType);
  }

  // ── Mapping ─────────────────────────────────────────────────────────────────

  /// Convert a [Schedule] row to a [DepartureEntry] for the timetable UI.
  ///
  /// [isLive] and [etaMin] are passed in because they depend on GPS state,
  /// which the repository does not own.
  static DepartureEntry scheduleToDeparture(
    Schedule s, {
    bool isLive = false,
    int? etaMin,
  }) {
    return DepartureEntry(s.startTime, isLive: isLive, etaMin: etaMin);
  }

  /// Bulk-convert a list of schedules to departures.
  static List<DepartureEntry> schedulesToDepartures(
    List<Schedule> schedules, {
    bool Function(String startTime)? liveFilter,
    int Function(String startTime)? etaResolver,
  }) {
    return schedules.map((s) {
      final isLive = liveFilter?.call(s.startTime) ?? false;
      final eta = etaResolver?.call(s.startTime);
      return scheduleToDeparture(s, isLive: isLive, etaMin: eta);
    }).toList();
  }

  // ── Seed ────────────────────────────────────────────────────────────────────

  /// Insert realistic demo schedules for [routeId].
  ///
  /// Generates weekday, saturday, and sunday_holiday entries with frequencies
  /// that match the current hardcoded demo data (~8 min intervals).
  Future<void> seedDemoSchedules(String routeId) async {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;

    final entries = <SchedulesCompanion>[
      // ── Weekday ─────────────────────────────────────────────
      _seedEntry(
        scheduleId: '${routeId}_weekday_am',
        routeId: routeId,
        dayType: 'weekday',
        startTime: '05:30',
        endTime: '12:00',
        frequencySeconds: 480, // 8 min
        timestamp: timestamp,
      ),
      _seedEntry(
        scheduleId: '${routeId}_weekday_pm',
        routeId: routeId,
        dayType: 'weekday',
        startTime: '12:00',
        endTime: '22:00',
        frequencySeconds: 480,
        timestamp: timestamp,
      ),

      // ── Saturday ────────────────────────────────────────────
      _seedEntry(
        scheduleId: '${routeId}_saturday',
        routeId: routeId,
        dayType: 'saturday',
        startTime: '06:00',
        endTime: '22:00',
        frequencySeconds: 600, // 10 min
        timestamp: timestamp,
      ),

      // ── Sunday / Holiday ────────────────────────────────────
      _seedEntry(
        scheduleId: '${routeId}_sunday_holiday',
        routeId: routeId,
        dayType: 'sunday_holiday',
        startTime: '07:00',
        endTime: '21:00',
        frequencySeconds: 720, // 12 min
        timestamp: timestamp,
      ),
    ];

    await _dao.replaceAll(entries);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  SchedulesCompanion _seedEntry({
    required String scheduleId,
    required String routeId,
    required String dayType,
    required String startTime,
    required String endTime,
    required int frequencySeconds,
    required int timestamp,
  }) {
    return SchedulesCompanion(
      scheduleId: Value(scheduleId),
      routeId: Value(routeId),
      dayType: Value(dayType),
      startTime: Value(startTime),
      endTime: Value(endTime),
      frequencySeconds: Value(frequencySeconds),
      lastSynced: Value(timestamp),
      version: const Value(0),
    );
  }
}
