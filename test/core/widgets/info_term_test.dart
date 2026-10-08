import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/widgets/info_term.dart';

void main() {
  testWidgets('InfoTerm opens bottom sheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoTerm(
            title: 'Test Title',
            description: 'Test Description',
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('Test Title'), findsNothing);

    // Tap the icon
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // Verify bottom sheet is shown
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
    expect(find.text('Verstanden'), findsOneWidget);
  });
}
