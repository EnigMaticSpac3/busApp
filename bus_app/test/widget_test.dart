// Basic Flutter widget test for San Antonio Bus Tracker
//
// Smoke test to verify the app renders without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bus_app/main.dart';

void main() {
  testWidgets('App renders home screen with navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BusApp());
    await tester.pumpAndSettle();

    // Verify that the navigation bar shows both tabs
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);

    // Verify that the map tab is selected by default
    expect(find.byIcon(Icons.map), findsOneWidget);
  });

  testWidgets('Navigation bar switches between tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const BusApp());
    await tester.pumpAndSettle();

    // Tap on Rutas tab
    await tester.tap(find.text('Rutas'));
    await tester.pumpAndSettle();

    // Verify that the Rutas icon is now selected
    expect(find.byIcon(Icons.directions_bus), findsOneWidget);
  });
}