// lib/screens/conductor_screen.dart
//
// Pantalla del conductor - modo minimalista para tracking GPS.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

class ConductorScreen extends StatefulWidget {
  final String conductorToken;
  final String nombreConductor;
  final String rutaAsignada;

  const ConductorScreen({
    super.key,
    required this.conductorToken,
    required this.nombreConductor,
    required this.rutaAsignada,
  });

  @override
  State<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends State<ConductorScreen> {
  final _api = ApiService();
  bool _isTracking = false;
  Position? _currentPosition;
  Timer? _gpsTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _error = 'Servicio de ubicación desactivado');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _error = 'Permisos de ubicación denegados');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _error = 'Permisos de ubicación denegados permanentemente');
      return;
    }

    setState(() => _error = null);
  }

  Future<void> _startTracking() async {
    setState(() => _isTracking = true);

    // Obtener posición inicial
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      setState(() => _error = 'Error obteniendo ubicación: $e');
      setState(() => _isTracking = false);
      return;
    }

    // Iniciar timer para enviar GPS cada 5 segundos
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() => _currentPosition = position);

        // Enviar posición al backend
        await _api.sendConductorPosition(
          widget.conductorToken,
          position.latitude,
          position.longitude,
          position.speed,
        );
      } catch (e) {
        setState(() => _error = 'Error enviando posición: $e');
      }
    });
  }

  void _stopTracking() {
    _gpsTimer?.cancel();
    setState(() => _isTracking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.colorPrimary,
      appBar: AppBar(
        title: Text('Conductor: ${widget.nombreConductor}'),
        backgroundColor: AppConfig.colorPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Estado de tracking
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _isTracking ? Colors.green : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isTracking ? Icons.gps_fixed : Icons.gps_off,
                size: 60,
                color: _isTracking ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Información del conductor
            Text(
              'Ruta: ${widget.rutaAsignada}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Posición actual
            if (_currentPosition != null)
              Text(
                'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                'Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

            // Error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppConfig.colorAlert,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 48),

            // Botón de control
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _error != null
                    ? null
                    : _isTracking
                        ? _stopTracking
                        : _startTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.colorAccent,
                  foregroundColor: AppConfig.colorPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isTracking ? 'Detener Seguimiento' : 'Iniciar Seguimiento',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}