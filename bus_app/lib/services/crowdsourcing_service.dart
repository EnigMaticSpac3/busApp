// lib/services/crowdsourcing_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/contribution_model.dart';

enum EstadoContribucion { inactivo, activo, ignorado, error }

class CrowdsourcingService extends ChangeNotifier {
  EstadoContribucion _estado    = EstadoContribucion.inactivo;
  String?            _busAsignado;
  String?            _usuarioId;
  Timer?             _timer;

  EstadoContribucion get estado      => _estado;
  String?            get busAsignado => _busAsignado;
  bool               get estaActivo  =>
      _estado == EstadoContribucion.activo ||
      _estado == EstadoContribucion.ignorado;
  // estaActivo incluye 'ignorado' para que el botón no cambie a azul
  // mientras el backend no detecta bus — el usuario SÍ está contribuyendo,
  // solo que aún no fue asignado a un bus

  // -------------------------------------------------------------------------
  // ID anónimo persistente
  // -------------------------------------------------------------------------

  Future<String> _obtenerUsuarioId() async {
    if (_usuarioId != null) return _usuarioId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('usuario_id');
    if (id == null) {
      final rng = Random.secure();
      id = List.generate(16, (_) => rng.nextInt(16).toRadixString(16)).join();
      await prefs.setString('usuario_id', id);
    }
    _usuarioId = id;
    return id;
  }

  // -------------------------------------------------------------------------
  // Permisos
  // -------------------------------------------------------------------------

  Future<bool> solicitarPermiso() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    return permiso == LocationPermission.whileInUse ||
           permiso == LocationPermission.always;
  }

  // -------------------------------------------------------------------------
  // Iniciar / detener
  // -------------------------------------------------------------------------

  Future<void> iniciar() async {
    if (estaActivo) return;

    final permisoConcedido = await solicitarPermiso();
    if (!permisoConcedido) {
      _estado = EstadoContribucion.error;
      notifyListeners();
      return;
    }

    // Marcamos como ignorado al arrancar (contribuyendo pero sin bus asignado aún)
    _estado = EstadoContribucion.ignorado;
    notifyListeners();

    await _enviarUbicacion();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _enviarUbicacion(),
    );
  }

  void detener() {
    _timer?.cancel();
    _timer       = null;
    _estado      = EstadoContribucion.inactivo;
    _busAsignado = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Envío de ubicación
  // -------------------------------------------------------------------------

  Future<void> _enviarUbicacion() async {
    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final usuarioId = await _obtenerUsuarioId();

      // En modo debug simulamos velocidad de bus para bypasear el map matching
      final velocidad = AppConfig.debugCrowdsourcing
          ? 8.0   // ~29 km/h — velocidad típica de bus urbano
          : (posicion.speed < 0 ? 0.0 : posicion.speed);

      final payload = ContribucionUbicacion(
        usuarioId:   usuarioId,
        lat:         posicion.latitude,
        lon:         posicion.longitude,
        velocidadMs: velocidad,
        precisionM:  posicion.accuracy,
      );

      final response = await http
          .post(
            Uri.parse('${AppConfig.backendUrl}/api/contribuir-ubicacion'
            '${AppConfig.debugCrowdsourcing ? "?debug=true" : ""}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final nuevoEstado = data['estado'] as String;

        if (nuevoEstado == 'aceptado') {
          _estado      = EstadoContribucion.activo;
          _busAsignado = data['bus_id'] as String?;
        } else {
          // 'ignorado' — backend no detectó bus cercano aún
          _estado      = EstadoContribucion.ignorado;
          _busAsignado = null;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CrowdsourcingService error: $e');
      // No desactivamos — seguimos intentando en el próximo tick
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}