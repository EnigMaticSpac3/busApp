// lib/providers/driver_credentials_provider.dart
//
// Adapter that bridges busApp's AuthService with the profile screen UI.
// Verifies conductor PIN via the real backend, persists the session
// state in SharedPreferences so the driver doesn't have to re-enter
// the PIN every time the app restarts.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conductor_model.dart';
import '../services/auth_service.dart';

class DriverCredentialsProvider extends ChangeNotifier {
  static const _verifiedKey = 'driver_is_verified';
  static const _nameKey = 'driver_name';
  static const _tokenKey = 'driver_token';
  static const _idKey = 'driver_id';
  static const _routeKey = 'driver_ruta';

  final AuthService _authService;

  bool _isVerified = false;
  String _driverName = '';
  String _conductorToken = '';
  String _conductorId = '';
  String _rutaAsignada = '';
  bool _initialized = false;

  // ── Getters ──────────────────────────────────────────────────────────

  bool get isVerified => _isVerified;
  String get driverName => _driverName;

  /// Returns a full [Conductor] object if verified, null otherwise.
  Conductor? get conductor => _isVerified
      ? Conductor(
          token: _conductorToken,
          conductorId: _conductorId,
          nombre: _driverName,
          rutaAsignada: _rutaAsignada,
        )
      : null;

  // ── Init ─────────────────────────────────────────────────────────────

  DriverCredentialsProvider(this._authService);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _isVerified = prefs.getBool(_verifiedKey) ?? false;
    _driverName = prefs.getString(_nameKey) ?? '';
    _conductorToken = prefs.getString(_tokenKey) ?? '';
    _conductorId = prefs.getString(_idKey) ?? '';
    _rutaAsignada = prefs.getString(_routeKey) ?? '';
    _initialized = true;
    notifyListeners();
  }

  // ── Verify ───────────────────────────────────────────────────────────

  /// Validates a 4-digit PIN against the backend.
  /// Returns `true` on success; the conductor data is persisted.
  Future<bool> verifyCode(String code) async {
    final pin = code.trim();
    if (pin.length != 4) return false;

    final conductor = await _authService.loginPin(pin);
    if (conductor == null) return false;

    _isVerified = true;
    _driverName = conductor.nombre;
    _conductorToken = conductor.token;
    _conductorId = conductor.conductorId;
    _rutaAsignada = conductor.rutaAsignada;

    await _save();
    notifyListeners();
    return true;
  }

  // ── Deactivate ───────────────────────────────────────────────────────

  void deactivate() {
    _isVerified = false;
    _driverName = '';
    _conductorToken = '';
    _conductorId = '';
    _rutaAsignada = '';
    _save();
    notifyListeners();
  }

  // ── Persistence ──────────────────────────────────────────────────────

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_verifiedKey, _isVerified);
    await prefs.setString(_nameKey, _driverName);
    await prefs.setString(_tokenKey, _conductorToken);
    await prefs.setString(_idKey, _conductorId);
    await prefs.setString(_routeKey, _rutaAsignada);
  }
}
