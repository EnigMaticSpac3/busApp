// lib/screens/rutas_screen.dart
//
// Pantalla de selección de rutas (placeholder para v3).

import 'package:flutter/material.dart';

class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas'),
        backgroundColor: const Color(0xFF283C90),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 64,
              color: Color(0xFF283C90),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selección de Rutas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283C90),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente: elige tu ruta de origen a destino',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Placeholder: lista de rutas disponibles
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildRutaItem('E598', 'San Antonio - Albrook', 3),
                  const Divider(),
                  _buildRutaItem('E502', 'Albrook - San Antonio', 2),
                  const Divider(),
                  _buildRutaItem('C01', 'Corredor Norte', 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRutaItem(String codigo, String nombre, int buses) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFC8D527),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          codigo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF283C90),
          ),
        ),
      ),
      title: Text(nombre),
      subtitle: Text('$buses buses activos'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: implementar selección de ruta
      },
    );
  }
}