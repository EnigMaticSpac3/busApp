import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/ruta_model.dart';

/// Offline-first route cache using Hive.
/// Strategy: hardcoded base → API enrichment → cache for offline.
class RouteCacheService {
  static const _boxName = 'route_cache';
  static const _routesKey = 'cached_routes';
  static const _timestampKey = 'last_sync';

  /// TTL: routes are considered fresh for 12 hours
  static const _ttl = Duration(hours: 12);

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Get cached routes. Returns null if cache is empty or expired.
  List<RutaModel>? getCachedRoutes() {
    if (_box == null) return null;
    final data = _box!.get(_routesKey);
    if (data == null) return null;

    final timestamp = _box!.get(_timestampKey);
    if (timestamp != null) {
      final lastSync = DateTime.parse(timestamp);
      if (DateTime.now().difference(lastSync) > _ttl * 2) {
        return null; // Expired (> 2x TTL)
      }
    }

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((j) => RutaModel.fromJson(j)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Check if cache is stale (needs background refresh).
  bool isStale() {
    if (_box == null) return true;
    final timestamp = _box!.get(_timestampKey);
    if (timestamp == null) return true;
    final lastSync = DateTime.parse(timestamp);
    return DateTime.now().difference(lastSync) > _ttl;
  }

  /// Save routes to cache.
  Future<void> cacheRoutes(List<RutaModel> routes) async {
    if (_box == null) return;
    final jsonList = routes.map((r) => r.toJson()).toList();
    await _box!.put(_routesKey, jsonEncode(jsonList));
    await _box!.put(_timestampKey, DateTime.now().toIso8601String());
  }

  /// Clear cache.
  Future<void> clear() async {
    await _box?.clear();
  }
}
