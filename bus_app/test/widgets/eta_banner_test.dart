// test/widgets/eta_banner_test.dart
//
// Tests para el widget EtaBanner.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/widgets/eta_banner.dart';
import 'package:bus_app/models/eta_model.dart';

void main() {
  group('EtaBanner', () {
    testWidgets('muestra "Conectando..." cuando cargando', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EtaBanner(cargando: true),
          ),
        ),
      );

      expect(find.text('Conectando con el servidor...'), findsOneWidget);
    });

    testWidgets('muestra "Sin datos de ETA" cuando eta es null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EtaBanner(eta: null, cargando: false),
          ),
        ),
      );

      expect(find.text('Sin datos de ETA'), findsOneWidget);
    });

    testWidgets('muestra info de parada cuando hay datos', (tester) async {
      final eta = EtaParada(
        parada: 'Parada Central',
        eta: '5 min',
        distanciaMetros: 500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EtaBanner(eta: eta, cargando: false, busId: 'Bus-01'),
          ),
        ),
      );

      expect(find.textContaining('Parada Central'), findsOneWidget);
    });

    testWidgets('muestra indicador WS cuando webSocketConectado es true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EtaBanner(
              eta: null,
              cargando: false,
              webSocketConectado: true,
            ),
          ),
        ),
      );

      expect(find.text('WS'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('muestra indicador HTTP cuando webSocketConectado es false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EtaBanner(
              eta: null,
              cargando: false,
              webSocketConectado: false,
            ),
          ),
        ),
      );

      expect(find.text('HTTP'), findsOneWidget);
    });

    testWidgets('no muestra indicador cuando webSocketConectado es null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EtaBanner(
              eta: null,
              cargando: false,
              webSocketConectado: null,
            ),
          ),
        ),
      );

      expect(find.text('WS'), findsNothing);
      expect(find.text('HTTP'), findsNothing);
    });
  });
}