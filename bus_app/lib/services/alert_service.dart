// lib/services/alert_service.dart
//
// Servicio que gestiona alertas de servicio en tiempo real.
// Obtiene alertas via HTTP y recibe actualizaciones por WebSocket.
// Notifica a listeners cuando cambia la lista de alertas activas.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/service_alert_model.dart';

class AlertService extends ChangeNotifier {
  List<ServiceAlert> _alerts = [];
  WebSocketChannel? _channel;
  bool _conectado = false;
  int _intentosReconexion = 0;
  static const int _maxReconexiones = 3;
  String? _wsUrl;
  Timer? _pollingTimer;

  List<ServiceAlert> get alerts => List.unmodifiable(_alerts);
  bool get conectado => _conectado;

  /// Alertas activas (no expiradas).
  List<ServiceAlert> get activeAlerts =>
      _alerts.where((a) => a.isValid).toList();

  /// Obtiene alertas del backend via HTTP.
  Future<void> fetchAlerts() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.backendUrl}/api/alerts'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final alertsList = data['alerts'] as List? ?? [];
        _alerts = alertsList
            .map((j) => ServiceAlert.fromJson(j as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AlertService.fetchAlerts error: $e');
    }
  }

  /// Conecta al WebSocket para recibir alertas en tiempo real.
  void connectWebSocket(String wsUrl) {
    _wsUrl = wsUrl;
    _intentosReconexion = 0;
    _connect(wsUrl);
  }

  void _connect(String wsUrl) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _conectado = true;
      _intentosReconexion = 0;
      notifyListeners();

      _channel!.stream.listen(
        _onMessage,
        onError: (_) => _reconnect(),
        onDone: _reconnect,
      );
    } catch (e) {
      debugPrint('AlertService WS error: $e');
      _reconnect();
    }
  }

  void _onMessage(dynamic mensaje) {
    try {
      final data = jsonDecode(mensaje as String) as Map<String, dynamic>;
      final eventType = data['event'] as String? ?? data['tipo'] as String?;

      if (eventType == 'alert:new' || eventType == 'alert:update') {
        final alertData = data['data'] as Map<String, dynamic>? ??
            data['datos'] as Map<String, dynamic>?;
        if (alertData != null) {
          final alert = ServiceAlert.fromJson(alertData);
          // Update or add
          final index = _alerts.indexWhere((a) => a.alertId == alert.alertId);
          if (index >= 0) {
            _alerts[index] = alert;
          } else {
            _alerts.add(alert);
          }
          notifyListeners();
        }
      } else if (eventType == 'alert:expired') {
        final alertId = data['data']?['alert_id'] as String? ??
            data['datos']?['alert_id'] as String?;
        if (alertId != null) {
          _alerts.removeWhere((a) => a.alertId == alertId);
          notifyListeners();
        }
      } else if (eventType == 'alerts:full' || eventType == 'flota') {
        // Full list sync
        final alertsList = (data['data'] as List?) ??
            (data['datos'] as List?);
        if (alertsList != null) {
          _alerts = alertsList
              .map((j) => ServiceAlert.fromJson(j as Map<String, dynamic>))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AlertService parse error: $e');
    }
  }

  void _reconnect() {
    _conectado = false;
    _channel = null;
    notifyListeners();

    _intentosReconexion++;
    debugPrint('AlertService: reconnect $_intentosReconexion/$_maxReconexiones');

    if (_intentosReconexion >= _maxReconexiones) {
      debugPrint('AlertService: max retries, falling back to HTTP polling');
      _startPolling();
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        if (_wsUrl != null && _intentosReconexion < _maxReconexiones) {
          _connect(_wsUrl!);
        }
      });
    }
  }

  /// Fallback: periodic HTTP polling when WebSocket is unavailable.
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchAlerts(),
    );
  }

  /// Disconnect WebSocket and stop polling.
  void disconnect() {
    _channel?.sink.close();
    _wsUrl = null;
    _conectado = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
