// lib/services/api_service.dart
//
// Toda la comunicación con el backend vive aquí.
// La UI nunca hace http.get directamente — siempre pasa por este servicio.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/bus_model.dart';
import '../models/eta_model.dart';

class ApiService {
  final String _base = AppConfig.backendUrl;

  // Timeout para no bloquear la UI si el backend no responde
  static const _timeout = Duration(seconds: 5);

  // -------------------------------------------------------------------------
  // Ruta
  // -------------------------------------------------------------------------

  /// Descarga los puntos del shape de la ruta.
  /// Se llama una sola vez al iniciar la app.
  Future<List<LatLng>> fetchRuta() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/api/ruta'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['puntos'] as List)
            .map((p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lon'] as num).toDouble(),
                ))
            .toList();
      }
      debugPrint('fetchRuta: status ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('fetchRuta error: $e');
      return [];
    }
  }

  // -------------------------------------------------------------------------
  // Flota
  // -------------------------------------------------------------------------

  /// Obtiene la posición actual de todos los buses.
  /// Se llama periódicamente (polling).
  Future<List<Bus>> fetchFlota() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/api/flota'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data
            .map((json) => Bus.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      debugPrint('fetchFlota: status ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('fetchFlota error: $e');
      return [];
    }
  }

  // -------------------------------------------------------------------------
  // ETA
  // -------------------------------------------------------------------------

  /// Obtiene la próxima parada y ETA para un bus específico.
  Future<EtaParada?> fetchEta(String idBus) async {
    try {
      final response = await http
          .get(Uri.parse('$_base/api/parada-cercana/$idBus'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data.containsKey('error')) {
          debugPrint('fetchEta: ${data['error']}');
          return null;
        }
        return EtaParada.fromJson(data);
      }
      debugPrint('fetchEta: status ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('fetchEta error: $e');
      return null;
    }
  }
}