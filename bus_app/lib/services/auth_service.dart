// lib/services/auth_service.dart
//
// Servicio de autenticación para conductores.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conductor_model.dart';
import '../config/app_config.dart';

class AuthService {
  /// Autentica al conductor con PIN de 4 dígitos.
  Future<Conductor?> loginPin(String pin) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/auth/conductor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );

      if (response.statusCode == 200) {
        return Conductor.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Inicia sesión de conductor con token y ruta.
  Future<bool> iniciarSesionConductor(String token, String rutaId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/sesion-conductor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'conductor_token': token,
          'ruta_id': rutaId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}