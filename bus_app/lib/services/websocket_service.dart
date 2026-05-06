// lib/services/websocket_service.dart
//
// WebSocket para recibir flota en tiempo real.
// Fallback automático a HTTP si WebSocket falla tras 3 intentos.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/bus_sesion_model.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  final List<BusSesion> _flota = [];
  bool _conectado = false;
  int _intentosReconexion = 0;
  static const int _maxReconexiones = 3;

  String? _wsUrl;

  List<BusSesion> get flota => List.unmodifiable(_flota);
  bool get conectado => _conectado;

  /// Inicia la conexión WebSocket
  void conectar(String wsUrl) {
    _wsUrl = wsUrl;
    _intentosReconexion = 0;
    _iniciarWebSocket(wsUrl);
  }

  void _iniciarWebSocket(String wsUrl) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _conectado = true;
      _intentosReconexion = 0;
      notifyListeners();

      _channel!.stream.listen(
        _onMensaje,
        onError: (_) => _reconectar(),
        onDone: _reconectar,
      );
    } catch (e) {
      debugPrint('WebSocket: error conectando: $e');
      _reconectar();
    }
  }

  void _onMensaje(dynamic mensaje) {
    try {
      final data = jsonDecode(mensaje as String) as Map<String, dynamic>;
      if (data['tipo'] == 'flota') {
        _flota.clear();
        _flota.addAll(
          (data['datos'] as List)
              .map((j) => BusSesion.fromJson(j as Map<String, dynamic>))
              .toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('WebSocket: error parseando mensaje: $e');
    }
  }

  void _reconectar() {
    _conectado = false;
    _channel = null;
    notifyListeners();

    _intentosReconexion++;
    debugPrint('WebSocket: intento $_intentosReconexion/$_maxReconexiones');

    if (_intentosReconexion >= _maxReconexiones) {
      debugPrint('WebSocket: máximo intentos alcanzados, se usará polling HTTP');
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        if (_wsUrl != null && _intentosReconexion < _maxReconexiones) {
          _iniciarWebSocket(_wsUrl!);
        }
      });
    }
  }

  void desconectar() {
    _channel?.sink.close();
    _wsUrl = null;
    _conectado = false;
  }

  @override
  void dispose() {
    desconectar();
    super.dispose();
  }
}