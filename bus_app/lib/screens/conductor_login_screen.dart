// lib/screens/conductor_login_screen.dart
//
// Pantalla de login para conductores con PIN de 4 dígitos.
// Estilo minimalista jakdojade.

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

class ConductorLoginScreen extends StatefulWidget {
  const ConductorLoginScreen({super.key});

  @override
  State<ConductorLoginScreen> createState() => _ConductorLoginScreenState();
}

class _ConductorLoginScreenState extends State<ConductorLoginScreen> {
  final _authService = AuthService();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.colorPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de bus
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppConfig.colorAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus,
                  size: 60,
                  color: AppConfig.colorPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Título
              const Text(
                'Conductor',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu PIN de 4 dígitos',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),

              // Campo de PIN
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 16,
                  ),
                  counterText: '',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppConfig.colorAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppConfig.colorAlert,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 32),

              // Botón iniciar sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.colorAccent,
                    foregroundColor: AppConfig.colorPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppConfig.colorPrimary,
                          ),
                        )
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_pinController.text.length != 4) {
      setState(() => _error = 'Ingrese 4 dígitos');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final conductor = await _authService.loginPin(_pinController.text);

    if (conductor != null) {
      final ok = await _authService.iniciarSesionConductor(
        conductor.token,
        conductor.rutaAsignada,
      );

      if (ok && mounted) {
        // Navegar a pantalla de conductor (pendiente crear)
        Navigator.pushReplacementNamed(context, '/conductor');
      } else {
        setState(() => _error = 'Error al iniciar sesión');
      }
    } else {
      setState(() => _error = 'PIN incorrecto');
    }

    setState(() => _isLoading = false);
  }
}