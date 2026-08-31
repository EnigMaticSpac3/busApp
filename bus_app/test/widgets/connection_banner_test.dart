import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/widgets/connection_banner.dart';

void main() {
  group('ConnectionBanner', () {
    testWidgets('muestra mensaje de sin conexión', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionBanner(
              lastUpdated: 'hace 4 min',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('Mostrando datos de hace 4 min'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('muestra botón de reintentar cuando onRetry no es null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionBanner(
              lastUpdated: 'hace 4 min',
              isDark: false,
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('no muestra botón de reintentar cuando onRetry es null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionBanner(
              lastUpdated: 'hace 4 min',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('onRetry se ejecuta al tocar el botón', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionBanner(
              lastUpdated: 'hace 4 min',
              isDark: false,
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reintentar'));
      expect(retried, isTrue);
    });

    testWidgets('funciona en modo dark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionBanner(
              lastUpdated: 'hace 1 min',
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('Mostrando datos de hace 1 min'), findsOneWidget);
    });
  });
}
