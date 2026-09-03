import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// OfflineProvider — backward-compatible wrapper around ConnectivityService.
/// Screens that use `context.watch<OfflineProvider>()` will automatically
/// reflect real network state without code changes.
class OfflineProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  bool _disposed = false;
  bool? _debugOfflineOverride; // null = follow real connectivity

  OfflineProvider(this._connectivityService) {
    _connectivityService.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// True when device has no network connection.
  /// If a debug override is active, it takes precedence.
  bool get offline => _debugOfflineOverride ?? !_connectivityService.isConnected;

  /// Last time the device was connected (null if never connected yet).
  DateTime? get lastConnectedTime => _connectivityService.lastConnectedTime;

  /// Manually re-check connectivity (e.g. on app resume).
  Future<void> recheck() => _connectivityService.recheck();

  /// Debug: toggle offline state manually (for profile screen dev switch).
  void toggle() {
    _debugOfflineOverride =
        !(_debugOfflineOverride ?? !_connectivityService.isConnected);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
