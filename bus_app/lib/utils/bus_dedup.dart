// lib/utils/bus_dedup.dart
//
// Deduplicación de buses por ruta_id.
// Si dos sesiones comparten la misma ruta_id, se conserva únicamente
// la más reciente (por timestamp/segundosSinSenal como proxy de frescura).
// Implementa QA-06 del SPRINT.md.

import '../models/bus_sesion_model.dart';

/// Deduplicates bus positions by route_id.
///
/// When a conductor session and a crowdsourcing session both report
/// the same route, two markers appear for the same bus. This function
/// keeps only the most "active" entry per route:
/// 1. Prefer the one with `modo == 'activo'`.
/// 2. If both are active, prefer the one with lower `segundosSinSenal`.
/// 3. If still tied, keep the last one (most recent insertion).
List<BusSesion> deduplicateBuses(List<BusSesion> buses) {
  final Map<String, BusSesion> best = {};

  for (final bus in buses) {
    final key = bus.rutaId ?? 'unknown_${bus.sessionId}';
    final existing = best[key];

    if (existing == null) {
      best[key] = bus;
    } else {
      best[key] = _pickBest(existing, bus);
    }
  }

  return best.values.toList();
}

/// Returns the "best" of two buses on the same route.
///
/// Priority:
/// 1. `activo` > `incierto` > `perdido`
/// 2. Lower `segundosSinSenal` is better (fresher signal)
BusSesion _pickBest(BusSesion a, BusSesion b) {
  final scoreA = _busScore(a);
  final scoreB = _busScore(b);
  return scoreA >= scoreB ? a : b;
}

/// Higher score = more desirable to keep.
int _busScore(BusSesion bus) {
  int modeScore;
  switch (bus.modo) {
    case 'activo':
      modeScore = 100;
      break;
    case 'incierto':
      modeScore = 50;
      break;
    default:
      modeScore = 0;
  }
  // Subtract seconds-without-signal so fresher data wins.
  // Use integer division to avoid precision issues.
  return modeScore - (bus.segundosSinSenal ~/ 1);
}
