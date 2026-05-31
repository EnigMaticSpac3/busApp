import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bus_app/widgets/app_bottom_sheet.dart';
import 'package:bus_app/widgets/app_primary_button.dart';
import 'package:bus_app/widgets/app_secondary_button.dart';
import 'package:bus_app/theme/export.dart';
import '../config/app_config.dart';

class SubidaBusSheet extends StatefulWidget {
  final String? busId;
  final void Function(String sessionId) onConfirmado;

  const SubidaBusSheet({
    super.key,
    this.busId,
    required this.onConfirmado,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    String? busId,
    required void Function(String sessionId) onConfirmado,
  }) {
    return AppBottomSheet.mostrar<bool>(
      context,
      child: SubidaBusSheet(
        busId: busId,
        onConfirmado: onConfirmado,
      ),
    );
  }

  @override
  State<SubidaBusSheet> createState() => _SubidaBusSheetState();
}

class _SubidaBusSheetState extends State<SubidaBusSheet> {
  bool _cargando = false;

  Future<String?> _crearSesionBus() async {
    final prefs = await SharedPreferences.getInstance();
    var usuarioId = prefs.getString('usuario_id');
    if (usuarioId == null) {
      usuarioId = List.generate(16, (_) => Random.secure().nextInt(16).toRadixString(16)).join();
      await prefs.setString('usuario_id', usuarioId);
    }

    const rutaId = 'SA_INTERNAL';
    await prefs.setString('ruta_id', rutaId);

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.backendUrl}/api/iniciar-sesion-bus'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'usuario_id': usuarioId,
              'ruta_id': rutaId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['session_id'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _confirmarSubida() async {
    setState(() => _cargando = true);

    final sessionId = await _crearSesionBus();
    if (sessionId == null) {
      setState(() => _cargando = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', sessionId);
    await prefs.setBool('contribuyendo', true);

    if (mounted) {
      Navigator.pop(context, true);
      widget.onConfirmado(sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 40,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          widget.busId != null
              ? '¿Subiste al bus ${widget.busId}?'
              : '¿Subiste al bus?',
          style: AppTypography.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Confirma para comenzar a compartir tu ubicación como pasajero.',
          style: AppTypography.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppPrimaryButton(
          label: 'Sí, ya subí',
          icon: Icons.check,
          onPressed: _cargando ? null : _confirmarSubida,
          isLoading: _cargando,
          backgroundColor: AppColors.accent,
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          label: 'Todavía no',
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}
