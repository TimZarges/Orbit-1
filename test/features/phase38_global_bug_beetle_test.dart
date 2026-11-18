/// Datei-Header: `test/features/phase38_global_bug_beetle_test.dart`
/// Zweck: Widget-Tests zur Sicherstellung der V1.0.0-Vorgabe, dass kein schwebender
/// Bug-Button den Bildschirminhalt verdeckt, während die Bugmeldung in der Topbar
/// (`AppBar`) sauber erreichbar ist und den Bug-Report-Dialog öffnet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/config/release_config.dart';
import 'package:orbit/features/beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import 'package:orbit/features/beta_feedback/widgets/global_floating_bug_beetle.dart';

void main() {
  tearDown(() {
    ReleaseConfig.resetTestingOverrides();
  });

  testWidgets(
      'V1.0.0 zeigt keinen schwebenden Bug-Overlay-Button, aber funktionierende Topbar-Bugmeldung',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final isV2Enabled = ref.watch(
              releaseConfigProvider.select((cfg) => cfg.isV2Enabled),
            );
            return MaterialApp(
              builder: (ctx, child) {
                return Stack(
                  children: [
                    if (child != null) child,
                    if (isV2Enabled) const GlobalFloatingBugBeetle(),
                  ],
                );
              },
              home: Scaffold(
                appBar: AppBar(
                  title: const Text('ORBIT V1.0.0'),
                  actions: const [
                    BetaBugReportIconButton(),
                  ],
                ),
                body: const Center(child: Text('Hauptinhalt')),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Kein schwebender Overlay-Bug-Button im V1.0.0-Standardbetrieb
    expect(find.byKey(const Key('global_floating_bug_beetle')), findsNothing);

    // 2. Topbar-Bugmeldung ist sichtbar und öffnet das Feedback-Sheet
    final topbarBugFinder =
        find.byKey(const Key('beta_bug_report_icon_button'));
    expect(topbarBugFinder, findsOneWidget);

    await tester.tap(topbarBugFinder);
    await tester.pumpAndSettle();

    expect(find.byType(BetaBugReporterSheet), findsOneWidget);
  });
}
