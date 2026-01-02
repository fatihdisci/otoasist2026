// Basic widget test for Oto Asist app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oto_asist/main.dart';

void main() {
  testWidgets('App should show garage dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: OtoAsistApp()));

    // Verify that app bar title is present
    expect(find.text('Garajım'), findsOneWidget);
  });
}
