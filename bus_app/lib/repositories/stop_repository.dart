// lib/repositories/stop_repository.dart
//
// Offline-first repository for stops.
//
// Flow:
//   1. Emit local data immediately (Stream)
//   2. Check SyncMetadata — is this route's data stale?
//   3. If stale/missing → fetch from API → upsert into DB
//   4. Stream auto-re-emits fresh data (Drift reactivity)

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/stop_dao.dart';
import '../database/daos/sync_metadata_dao.dart';
import '../models/parada_model.dart';
import '../services/api_service.dart';

/// Duration after which cached stops are considered stale.
const _staleAfter = Duration(hours: 1);

/// Metadata key prefix — final key is `stops_<routeId>`.
const _metaPrefix = 'stops_';

class StopRepository {
  StopRepository({
    required AppDatabase db,
    required ApiService api,
  })  : _api = api,
        _stopDao = StopDao(db),
        _syncDao = SyncMetadataDao(db);

  final ApiService _api;
  final StopDao _stopDao;
  final SyncMetadataDao _syncDao;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns a stream of stops for [routeId].
  ///
  /// Emits local data immediately. If the local cache is stale (or empty),
  /// fetches fresh data from the API in the background and re-emits.
  Stream<List<ParadaModel>> watchStopsByRoute(String routeId) async* {
    // 1. Emit local data immediately.
    final local = await _stopDao.getByRouteId(routeId);
    yield local.map(_stopToModel).toList();

    // 2. Check freshness and sync in background if needed.
    _syncIfNeeded(routeId);
  }

  /// One-shot read: returns stops for [routeId] from local DB.
  Future<List<ParadaModel>> getStopsByRoute(String routeId) async {
    final local = await _stopDao.getByRouteId(routeId);
    if (local.isNotEmpty) {
      // Kick off background refresh but don't block caller.
      _syncIfNeeded(routeId);
      return local.map(_stopToModel).toList();
    }

    // No local data — must fetch from API.
    return await _fetchAndCache(routeId);
  }

  /// Returns a single stop, or null.
  Future<ParadaModel?> getById(String stopId) async {
    final row = await _stopDao.getById(stopId);
    return row == null ? null : _stopToModel(row);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Background sync: only hits the API if local data is stale or missing.
  Future<void> _syncIfNeeded(String routeId) async {
    final metaKey = '$_metaPrefix$routeId';
    final stale = await _syncDao.isStale(metaKey);
    if (!stale) return; // Data is fresh enough.

    await _fetchAndCache(routeId);
  }

  /// Fetch stops from API, upsert into DB, update sync metadata.
  /// Returns the freshly fetched models.
  Future<List<ParadaModel>> _fetchAndCache(String routeId) async {
    try {
      final apiStops = await _api.fetchParadas(routeId);
      if (apiStops.isEmpty) return [];

      // Map to companions (with routeId) and bulk-upsert.
      final companions =
          apiStops.map((m) => _modelToCompanion(m, routeId)).toList();
      await _stopDao.replaceAll(companions);

      // Update sync metadata.
      final now = DateTime.now().millisecondsSinceEpoch;
      await _syncDao.upsert(
        datasetName: '$_metaPrefix$routeId',
        downloadedAt: now,
        expiresAt: now + _staleAfter.inMilliseconds,
        version: 1,
        recordCount: companions.length,
      );

      return apiStops;
    } catch (e) {
      debugPrint('StopRepository._fetchAndCache error: $e');
      // Return whatever we have locally on failure.
      final fallback = await _stopDao.getByRouteId(routeId);
      return fallback.map(_stopToModel).toList();
    }
  }

  // ── Mapping ─────────────────────────────────────────────────────────────────

  /// Drift Stop row → app ParadaModel.
  static ParadaModel _stopToModel(Stop row) => ParadaModel(
        paradaId: row.stopId,
        nombre: row.name ?? '',
        lat: row.lat,
        lon: row.lon,
        orden: row.sequence,
      );

  /// App ParadaModel → Drift StopsCompanion (for insert/replace).
  static StopsCompanion _modelToCompanion(ParadaModel m, String routeId) =>
      StopsCompanion(
        stopId: Value(m.paradaId),
        routeId: Value(routeId),
        name: Value(m.nombre),
        lat: Value(m.lat),
        lon: Value(m.lon),
        sequence: Value(m.orden),
        lastSynced: Value(DateTime.now().millisecondsSinceEpoch),
        version: const Value(1),
      );
}
