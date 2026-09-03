import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// ConnectivityService — real network connectivity detection
/// Uses connectivity_plus to monitor network state.
/// Exposes: isConnected, connectivityStream, lastConnectedTime.
/// Does NOT depend on any API endpoint — pure network detection.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  DateTime? _lastConnectedTime;
  List<ConnectivityResult> _currentResults = [];

  /// Current connectivity state — true if any network interface is active.
  bool get isConnected => _isConnected;

  /// Raw stream of connectivity changes from connectivity_plus.
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Last time the device was connected (null if never connected yet).
  DateTime? get lastConnectedTime => _lastConnectedTime;

  /// Current raw connectivity results.
  List<ConnectivityResult> get currentResults => _currentResults;

  /// Initialize the service — call once at app startup.
  /// Performs an initial connectivity check and starts listening.
  Future<void> init() async {
    // Initial check
    final initial = await _connectivity.checkConnectivity();
    _updateState(initial);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateState(results);
    });
  }

  void _updateState(List<ConnectivityResult> results) {
    _currentResults = results;
    final wasConnected = _isConnected;
    _isConnected = results.any((r) => r != ConnectivityResult.none);

    if (_isConnected && !wasConnected) {
      _lastConnectedTime = DateTime.now();
    }

    if (wasConnected != _isConnected) {
      notifyListeners();
    }
  }

  /// Manually re-check connectivity (e.g. on app resume).
  Future<void> recheck() async {
    final results = await _connectivity.checkConnectivity();
    _updateState(results);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
