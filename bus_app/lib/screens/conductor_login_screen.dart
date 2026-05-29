import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bus_app/theme/export.dart';
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
    } else {
      setState(() {});
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
        Navigator.pushReplacementNamed(
          context,
          '/conductor',
          arguments: {
            'conductorToken': conductor.token,
            'nombreConductor': conductor.nombre,
            'rutaAsignada': conductor.rutaAsignada,
          },
        );
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
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              const Spacer(flex: 1),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildPinInput(),
              const SizedBox(height: AppSpacing.xxl),
              _buildErrorMessage(),
              const Spacer(flex: 1),
              _buildLoginButton(),
              const SizedBox(height: AppSpacing.xxl),
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
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 60,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const Text(
          'Conductor',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: _hasError
              ? AppColors.alert
              : Colors.white.withValues(alpha: 0.5),
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
          hintText: '\u2022\u2022\u2022\u2022',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 24,
            fontSize: 32,
          ),
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_error == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.alert.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: AppColors.alert.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.alert,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.alert,
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
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.2),
          foregroundColor: isValid
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, size: 24),
                  const SizedBox(width: AppSpacing.sm),
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
            color: Colors.white.withValues(alpha: 0.9),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Volver',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
