// lib/widgets/subida_bus_sheet.dart
//
// Bottom sheet de confirmación cuando el usuario indica que está en el bus.
// Reemplaza el flow genérico anterior.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubidaBusSheet(
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
    // Generar usuario_id anónimo
    final prefs = await SharedPreferences.getInstance();
    var usuarioId = prefs.getString('usuario_id');
    if (usuarioId == null) {
      usuarioId = List.generate(16, (_) => Random.secure().nextInt(16).toRadixString(16)).join();
      await prefs.setString('usuario_id', usuarioId);
    }

    const rutaId = 'SA_INTERNAL';

    debugPrint('=== INICIAR SESIÓN ===');
    debugPrint('usuario_id: $usuarioId');
    debugPrint('ruta_id: $rutaId');

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

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sessionId = data['session_id'] as String?;
        debugPrint('session_id recibido: $sessionId');
        return sessionId;
      }
      return null;
    } catch (e) {
      debugPrint('Error creando sesión bus: $e');
      return null;
    }
  }

  Future<void> _confirmarSubida() async {
    setState(() => _cargando = true);

    final sessionId = await _crearSesionBus();
    if (sessionId == null) {
      debugPrint('ERROR: No se pudo obtener session_id');
      setState(() => _cargando = false);
      return;
    }

    // Guardar session_id y ruta_id en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', sessionId);
    await prefs.setString('ruta_id', 'SA_R1');
    await prefs.setBool('contribuyendo', true);

    debugPrint('session_id guardado: $sessionId');

    if (mounted) {
      Navigator.pop(context, true);
      widget.onConfirmado(sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icono
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFC8D527).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus,
              size: 40,
              color: Color(0xFFC8D527),
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Text(
            widget.busId != null
                ? '¿Subiste al bus ${widget.busId}?'
                : '¿Subiste al bus?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Descripción
          Text(
            'Confirma para comenzar a compartir tu ubicación como pasajero.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Botón confirmar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cargando ? null : _confirmarSubida,
              icon: _cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_cargando ? 'Conectando...' : 'Sí, ya subí'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8D527),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Botón todavía no
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Todavía no',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}