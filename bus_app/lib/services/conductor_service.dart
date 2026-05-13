// lib/services/conductor_service.dart
//
// Servicio para gestionar la sesión del conductor.
// Encargado de GPS y Dead Man's Switch.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../models/sesion_conductor_model.dart';

class ConductorService extends ChangeNotifier {
  SesionConductor? _sesionActiva;
  Timer? _deadManTimer;
  Timer? _gpsTimer;
  bool _servicioActivo = false;
  DateTime? _ultimoReporteGps;

  SesionConductor? get sesionActiva => _sesionActiva;
  bool get servicioActivo => _servicioActivo;
  DateTime? get ultimoReporteGps => _ultimoReporteGps;

  /// Inicia el servicio del conductor (sesión + GPS + Dead Man's Switch).
  Future<bool> iniciarServicio(String conductorToken, String rutaId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/sesion-conductor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductor_token': conductorToken,
          'ruta_id': rutaId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sesionActiva = SesionConductor(
          sessionId: data['session_id'] ?? '',
          conductorToken: conductorToken,
          rutaId: rutaId,
          inicio: DateTime.now(),
          activo: true,
        );
        _servicioActivo = true;
        _ultimoReporteGps = DateTime.now();
        _iniciarGpsYDeadMan();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al iniciar servicio: $e');
      return false;
    }
  }

  void _iniciarGpsYDeadMan() {
    // GPS cada 5 segundos
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) => _reportarGps());
    // Dead Man's Switch: verificar cada 30 segundos
    _deadManTimer = Timer.periodic(const Duration(seconds: 30), (_) => _verificarDeadMan());
  }

  Future<void> _reportarGps() async {
    if (!_servicioActivo || _sesionActiva == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );

      await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/gps-conductor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductor_token': _sesionActiva!.conductorToken,
          'lat': position.latitude,
          'lng': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
        }),
      );

      _ultimoReporteGps = DateTime.now();
      notifyListeners();
    } catch (e) {
      // GPS error silencioso - no interrumpir el servicio
    }
  }

  /// Verifica si hay reporte GPS en los últimos 30 segundos.
  /// Retorna true si hay alerta (sin GPS reciente).
  bool _verificarDeadMan() {
    if (!_servicioActivo || _ultimoReporteGps == null) return false;

    final tiempoSinReporte = DateTime.now().difference(_ultimoReporteGps!);
    if (tiempoSinReporte.inSeconds > 30) {
      debugPrint('ALERTA: Sin reporte GPS por ${tiempoSinReporte.inSeconds} segundos');
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Confirma que el conductor está activo (reset del Dead Man's Switch).
  void confirmarActivo() {
    _ultimoReporteGps = DateTime.now();
    notifyListeners();
  }

  /// Finaliza el servicio del conductor.
  void finalizarServicio() {
    _servicioActivo = false;
    _gpsTimer?.cancel();
    _deadManTimer?.cancel();
    _sesionActiva = null;
    _ultimoReporteGps = null;
    notifyListeners();
  }

  @override
  void dispose() {
    finalizarServicio();
    super.dispose();
  }
}