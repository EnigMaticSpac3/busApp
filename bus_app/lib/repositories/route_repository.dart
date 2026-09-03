// lib/repositories/route_repository.dart
//
// Offline-first repository for routes.
//
// Flow:
//   1. Emit local data immediately (Stream)
//   2. Check SyncMetadata — is routes data stale?
//   3. If stale/missing → fetch from API → replaceAll into DB
//   4. Stream auto-re-emits fresh data (Drift reactivity)

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/route_dao.dart';
import '../database/daos/sync_metadata_dao.dart';
import '../models/ruta_model.dart';
import '../services/api_service.dart';

/// Duration after which cached routes are considered stale.
const _staleAfter = Duration(hours: 12);

/// Metadata key for the routes dataset.
const _metaKey = 'routes';

class RouteRepository {
  RouteRepository({
    required AppDatabase db,
    required ApiService api,
  })  : _db = db,
        _api = api,
        _routeDao = RouteDao(db),
        _syncDao = SyncMetadataDao(db);

  final AppDatabase _db;
  final ApiService _api;
  final RouteDao _routeDao;
  final SyncMetadataDao _syncDao;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns a stream of all routes.
  ///
  /// Emits local data immediately. If the local cache is stale (or empty),
  /// fetches fresh data from the API in the background and re-emits.
  Stream<List<RutaModel>> watchRoutes() async* {
    // 1. Emit local data immediately.
    final local = await _routeDao.getAll();
    yield local.map(_routeToModel).toList();

    // 2. Check freshness and sync in background if needed.
    _syncIfNeeded();
  }

  /// One-shot read: returns all routes from local DB.
  /// Triggers background refresh if stale.
  Future<List<RutaModel>> getRoutes() async {
    final local = await _routeDao.getAll();
    if (local.isNotEmpty) {
      // Kick off background refresh but don't block caller.
      _syncIfNeeded();
      return local.map(_routeToModel).toList();
    }

    // No local data — must fetch from API.
    return await _fetchAndCache();
  }

  /// Returns a single route by [routeId], or null.
  Future<RutaModel?> getById(String routeId) async {
    final row = await _routeDao.getById(routeId);
    return row == null ? null : _routeToModel(row);
  }

  /// Search routes by code or name.
  Future<List<RutaModel>> search(String query) async {
    final results = await _routeDao.search(query);
    return results.map(_routeToModel).toList();
  }

  /// Search routes reactively (stream).
  Stream<List<RutaModel>> watchSearch(String query) async* {
    // Emit local search results immediately.
    final local = await _routeDao.search(query);
    yield local.map(_routeToModel).toList();

    // Trigger background sync in case results are stale.
    _syncIfNeeded();
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Background sync: only hits the API if local data is stale or missing.
  Future<void> _syncIfNeeded() async {
    final stale = await _syncDao.isStale(_metaKey);
    if (!stale) return; // Data is fresh enough.

    await _fetchAndCache();
  }

  /// Fetch routes from API, replaceAll into DB, update sync metadata.
  /// Returns the freshly fetched models.
  Future<List<RutaModel>> _fetchAndCache() async {
    try {
      final apiRoutes = await _api.fetchRutas();
      if (apiRoutes.isEmpty) return [];

      // Map to companions and bulk-replace.
      final companions = apiRoutes.map(_modelToCompanion).toList();
      await _routeDao.replaceAll(companions);

      // Update sync metadata.
      final now = DateTime.now().millisecondsSinceEpoch;
      await _syncDao.upsert(
        datasetName: _metaKey,
        downloadedAt: now,
        expiresAt: now + _staleAfter.inMilliseconds,
        version: 1,
        recordCount: companions.length,
      );

      return apiRoutes;
    } catch (e) {
      debugPrint('RouteRepository._fetchAndCache error: $e');
      // Return whatever we have locally on failure.
      final fallback = await _routeDao.getAll();
      return fallback.map(_routeToModel).toList();
    }
  }

  // ── Mapping ─────────────────────────────────────────────────────────────────

  /// Drift Route row → app RutaModel.
  static RutaModel _routeToModel(Route row) => RutaModel(
        rutaId: row.routeId,
        codigo: row.code ?? '',
        nombre: row.name ?? '',
        color: row.color ?? '007BFF',
        busesActivos: 0, // Not stored in DB; populated by flota endpoint.
      );

  /// App RutaModel → Drift RoutesCompanion (for insert/replace).
  static RoutesCompanion _modelToCompanion(RutaModel m) => RoutesCompanion(
        routeId: Value(m.rutaId),
        code: Value(m.codigo),
        name: Value(m.nombre),
        color: Value(m.color),
        lastSynced: Value(DateTime.now().millisecondsSinceEpoch),
        version: const Value(1),
      );
}
