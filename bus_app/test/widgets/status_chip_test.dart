import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/widgets/status_chip.dart';

void main() {
  group('StatusChip', () {
    testWidgets('muestra nombre de ruta y ETA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusChip(
              route: 'K480',
              eta: '3 min',
              level: StatusLevel.onTime,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('K480'), findsOneWidget);
      expect(find.text('· 3 min'), findsOneWidget);
    });

    testWidgets('muestra estado cancelled correctamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusChip(
              route: 'A120',
              eta: '0 min',
              level: StatusLevel.cancelled,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('A120'), findsOneWidget);
      expect(find.text('· Cancelado'), findsOneWidget);
    });

    test('StatusLevel.label funciona correctamente', () {
      expect(StatusLevel.onTime.label, 'A tiempo');
      expect(StatusLevel.delayed.label, 'Demorado');
      expect(StatusLevel.cancelled.label, 'Cancelado');
    });
  });

  group('StatusChipSmall', () {
    testWidgets('muestra label del nivel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusChipSmall(
              level: StatusLevel.onTime,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('A tiempo'), findsOneWidget);
    });

    testWidgets('muestra label delayed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusChipSmall(
              level: StatusLevel.delayed,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Demorado'), findsOneWidget);
    });
  });
}
