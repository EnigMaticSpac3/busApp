// lib/screens/conductor_login_screen.dart
//
// Pantalla de login para conductores con PIN de 4 dígitos.
// UI/UX mejorada: teclado numérico, validación en tiempo real, errores claros.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    super.dispose();
  }

  void _onPinChanged() {
    if (_pinController.text.length == 4 && _hasError) {
      setState(() {
        _error = null;
        _hasError = false;
      });
    }
  }

  Future<void> _login() async {
    final pin = _pinController.text;

    if (pin.length != 4) {
      setState(() {
        _error = 'Ingresa los 4 dígitos del PIN';
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasError = false;
    });

    final conductor = await _authService.loginPin(pin);

    if (conductor != null) {
      final ok = await _authService.iniciarSesionConductor(
        conductor.token,
        conductor.rutaAsignada,
      );

      if (ok && mounted) {
        Navigator.pushReplacementNamed(context, '/conductor');
      } else {
        setState(() {
          _error = 'Error al iniciar sesión';
          _hasError = true;
        });
      }
    } else {
      setState(() {
        _error = 'PIN incorrecto';
        _hasError = true;
      });
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.colorPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildPinInput(),
              const SizedBox(height: 24),
              _buildErrorMessage(),
              const Spacer(flex: 1),
              _buildLoginButton(),
              const SizedBox(height: 24),
              _buildBackButton(),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppConfig.colorAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppConfig.colorAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 60,
            color: AppConfig.colorPrimary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Conductor',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu PIN de 4 dígitos',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPinInput() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hasError
                  ? AppConfig.colorAlert
                  : Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(
              fontSize: 32,
              letterSpacing: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: '••••',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                letterSpacing: 24,
                fontSize: 32,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final filled = _pinController.text.length > index;
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? AppConfig.colorAccent
                    : Colors.white.withValues(alpha: 0.3),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_error == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConfig.colorAlert.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConfig.colorAlert.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppConfig.colorAlert,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppConfig.colorAlert,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final pinLength = _pinController.text.length;
    final isValid = pinLength == 4;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !isValid) ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid
              ? AppConfig.colorAccent
              : Colors.white.withValues(alpha: 0.2),
          foregroundColor: isValid
              ? AppConfig.colorPrimary
              : Colors.white.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            'Volver',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}