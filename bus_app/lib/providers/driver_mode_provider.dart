// lib/providers/driver_mode_provider.dart
//
// Thin adapter that exposes ConductorService state for the profile screen UI.
// The real GPS tracking and Dead Man's Switch live in ConductorService.
// This provider just makes it easy for the profile screen to observe
// isTracking / currentRouteCode via Consumer<DriverModeProvider>.

import 'package:flutter/foundation.dart';
import '../services/conductor_service.dart';

class DriverModeProvider extends ChangeNotifier {
  final ConductorService _conductorService;

  DriverModeProvider(this._conductorService) {
    _conductorService.addListener(_onServiceChange);
  }

  /// Whether the conductor is currently sharing GPS.
  bool get isTracking => _conductorService.servicioActivo;

  /// The route the conductor is currently serving (nullable).
  String? get currentRouteCode => _conductorService.sesionActiva?.rutaId;

  /// Elapsed time since the session started.
  DateTime? get trackingStartTime => _conductorService.sesionActiva?.inicio;

  void _onServiceChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    _conductorService.removeListener(_onServiceChange);
    super.dispose();
  }
}
