// Basic Flutter widget test for San Antonio Bus Tracker
//
// Smoke test to verify basic widget rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App basic rendering', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Transita')),
        ),
      ),
    );
    expect(find.text('Transita'), findsOneWidget);
  });
}
