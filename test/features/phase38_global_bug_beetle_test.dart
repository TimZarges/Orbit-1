import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/beta_feedback/widgets/global_floating_bug_beetle.dart';

void main() {
  testWidgets('GlobalFloatingBugBeetle rendert, ist verschiebbar und bleibt über Sheets sichtbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(
                child: ElevatedButton(
                  key: const Key('open_sheet_button'),
                  onPressed: () {},
                  child: const Text('Sheet öffnen'),
                ),
              ),
              const GlobalFloatingBugBeetle(),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Käfer-Button ist sichtbar
    final bugFinder = find.byKey(const Key('global_floating_bug_beetle'));
    expect(bugFinder, findsOneWidget);

    // Initial-Position erfassen
    final initialTopLeft = tester.getTopLeft(bugFinder);

    // 2. Draggen / Verschieben
    await tester.drag(bugFinder, const Offset(-50, -50));
    await tester.pumpAndSettle();

    final draggedTopLeft = tester.getTopLeft(bugFinder);
    expect(draggedTopLeft.dx, lessThan(initialTopLeft.dx));
    expect(draggedTopLeft.dy, lessThan(initialTopLeft.dy));

    // 3. Modales Bottom Sheet öffnen
    final BuildContext context = tester.element(find.byType(Scaffold));
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(
        height: 300,
        child: Center(child: Text('Test Modal Sheet')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Modal Sheet'), findsOneWidget);
    // Käfer existiert weiterhin im Widget-Baum
    expect(bugFinder, findsOneWidget);
  });
}
