import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/widgets/search_pill.dart';

void main() {
  group('SearchPill', () {
    testWidgets('muestra placeholder por defecto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchPill(
              label: '¿A dónde vas?',
              isDark: false,
              onTap: () {},
              onFilter: () {},
            ),
          ),
        ),
      );

      expect(find.text('¿A dónde vas?'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('muestra label personalizado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchPill(
              label: 'Albrook → Bethania',
              isDark: false,
              onTap: () {},
              onFilter: () {},
            ),
          ),
        ),
      );

      expect(find.text('Albrook → Bethania'), findsOneWidget);
    });

    testWidgets('onTap se ejecuta al tocar', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchPill(
              label: '¿A dónde vas?',
              isDark: false,
              onTap: () => tapped = true,
              onFilter: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SearchPill));
      expect(tapped, isTrue);
    });

    testWidgets('onFilter se ejecuta al tocar el botón de filtros', (tester) async {
      bool filtered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchPill(
              label: '¿A dónde vas?',
              isDark: false,
              onTap: () {},
              onFilter: () => filtered = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.tune_rounded));
      expect(filtered, isTrue);
    });

    testWidgets('funciona en modo dark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchPill(
              label: '¿A dónde vas?',
              isDark: true,
              onTap: () {},
              onFilter: () {},
            ),
          ),
        ),
      );

      expect(find.text('¿A dónde vas?'), findsOneWidget);
    });
  });
}
