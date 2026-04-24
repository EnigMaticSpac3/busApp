// lib/widgets/crowdsourcing_sheet.dart

import 'package:flutter/material.dart';

class CrowdsourcingSheet extends StatelessWidget {
  final VoidCallback onContribuir;
  final VoidCallback onAhoraNoPor;

  const CrowdsourcingSheet({
    super.key,
    required this.onContribuir,
    required this.onAhoraNoPor,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required VoidCallback onContribuir,
    required VoidCallback onAhora,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      // isScrollControlled permite que el sheet use hasta el 85% de la pantalla
      // y que el contenido interno pueda hacer scroll si no cabe
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CrowdsourcingSheet(
        onContribuir: onContribuir,
        onAhoraNoPor: onAhora,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // maxHeight: 85% de la pantalla para no tapar todo el mapa
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    // bottomPadding: respeta el área segura del sistema (nav bar, home indicator)
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
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

            // Ícono
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus,
                size: 40,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),

            // Título
            const Text(
              '¿Vas en el bus ahora?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              'Compartiendo tu ubicación mientras viajas, otros pasajeros '
              'pueden ver dónde está el bus en tiempo real.\n\n'
              'Es voluntario, anónimo y puedes desactivarlo cuando quieras '
              'desde el botón en el mapa.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Nota de privacidad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No se recopilan datos personales. '
                      'Tu ID es completamente anónimo.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onContribuir,
                icon: const Icon(Icons.location_on),
                label: const Text('Sí, quiero contribuir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Botón secundario — siempre visible gracias al scroll
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onAhoraNoPor,
                child: Text(
                  'Ahora no',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}