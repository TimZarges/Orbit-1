import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit/features/activities/models/activity.dart';
import 'package:orbit/features/activities/screens/activity_cockpit_screen.dart';

/// Unit- und Widget-Tests für das Activity-Cockpit (Phase 35.3).
///
/// Prüft:
/// - Sportart-Badge, editierbarer Titel und deutsches Datums-/Zeitformat (DD.MM.YYYY • HH:mm Uhr)
/// - Öffnen und Bestätigen des Titel-Änderungsdialogs
/// - Soll/Ist-Erfüllungs-Ampelbanner
/// - 2x3 Kern-Metrik-Grid (Distanz, Dauer, Ø Leistung/Pace, Höhenmeter, HF, ORBIT Load/IF)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Activity createTestActivity({
    String sport = 'BIKE',
    String? plannedWorkoutId,
    String? matchStatus,
  }) {
    return Activity(
      id: 'act-test-123',
      athleteId: 'ath-test-456',
      startTimeUtc: DateTime.utc(2026, 10, 18, 14, 30),
      localDate: '2026-10-18T14:30:00.000',
      sport: sport,
      title: 'Schwellen-Intervalle 4x4m',
      durationSec: 3600,
      distanceM: 32000,
      summary: ActivitySummary(
        avgPowerW: 255,
        maxPowerW: 620,
        avgHr: 148,
        maxHr: 174,
        avgCadence: 88,
        elevationGainM: 340,
      ),
      metrics: ActivityMetrics(
        tss: 78,
        iff: 0.89,
        np: 268,
        ef: 1.74,
      ),
      plannedWorkoutId: plannedWorkoutId,
      matchStatus: matchStatus,
    );
  }

  Widget createWidgetUnderTest(Activity activity) {
    return ProviderScope(
      child: MaterialApp(
        home: ActivityCockpitScreen(activity: activity),
      ),
    );
  }

  group('ActivityCockpitScreen (Phase 35.3 High-End Cockpit)', () {
    testWidgets('Rendert Header mit Sport-Badge, deutschem Datum und editierbarem Titel', (tester) async {
      final activity = createTestActivity();
      await tester.pumpWidget(createWidgetUnderTest(activity));
      await tester.pumpAndSettle();

      // Sportart-Badge
      expect(find.byKey(const Key('activity_sport_badge')), findsOneWidget);
      expect(find.text('RADFAHREN'), findsOneWidget);

      // Datumsanzeige im 24h-Format
      expect(find.byKey(const Key('activity_date_time_text')), findsOneWidget);
      expect(find.textContaining('18.10.2026 • 14:30 Uhr'), findsOneWidget);

      // Editierbarer Titel & Edit-Button
      expect(find.byKey(const Key('activity_title_text')), findsOneWidget);
      expect(find.text('Schwellen-Intervalle 4x4m'), findsWidgets);
      expect(find.byKey(const Key('activity_title_edit_button')), findsOneWidget);
    });

    testWidgets('Titel-Änderungsdialog lässt sich öffnen und aktualisiert den Titel', (tester) async {
      final activity = createTestActivity();
      await tester.pumpWidget(createWidgetUnderTest(activity));
      await tester.pumpAndSettle();

      // Klick auf den Edit-Button
      await tester.tap(find.byKey(const Key('activity_title_edit_button')));
      await tester.pumpAndSettle();

      // Prüfe, ob Dialog geöffnet ist
      expect(find.byKey(const Key('activity_title_input_field')), findsOneWidget);
      expect(find.byKey(const Key('activity_title_save_button')), findsOneWidget);

      // Neuen Titel eingeben
      await tester.enterText(
          find.byKey(const Key('activity_title_input_field')), 'Neuer Titel 5x5m');
      await tester.tap(find.byKey(const Key('activity_title_save_button')));
      await tester.pumpAndSettle();

      // Verifiziere neuen Titel im Header
      expect(find.text('Neuer Titel 5x5m'), findsWidgets);
    });

    testWidgets('2x3 Kern-Metrik-Grid rendert alle 6 Daten-Kacheln vollständig', (tester) async {
      final activity = createTestActivity();
      await tester.pumpWidget(createWidgetUnderTest(activity));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activity_core_metrics_grid')), findsOneWidget);
      expect(find.byKey(const Key('metric_card_distance')), findsOneWidget);
      expect(find.byKey(const Key('metric_card_duration')), findsOneWidget);
      expect(find.byKey(const Key('metric_card_power_pace')), findsOneWidget);
      expect(find.byKey(const Key('metric_card_elevation')), findsOneWidget);
      expect(find.byKey(const Key('metric_card_heart_rate')), findsOneWidget);
      expect(find.byKey(const Key('metric_card_load_if')), findsOneWidget);

      // Werte-Prüfung (gescoped auf die jeweiligen Kacheln)
      expect(find.descendant(of: find.byKey(const Key('metric_card_distance')), matching: find.text('32.0 km')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('metric_card_duration')), matching: find.text('1:00:00')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('metric_card_power_pace')), matching: find.text('255 W')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('metric_card_elevation')), matching: find.text('+340 hm')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('metric_card_heart_rate')), matching: find.text('148 bpm')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('metric_card_load_if')), matching: find.text('78')), findsOneWidget);
    });

    testWidgets('Soll/Ist-Erfüllungs-Banner zeigt Ampel bei geplanter Einheit', (tester) async {
      final plannedActivity = createTestActivity(plannedWorkoutId: 'workout-plan-999');
      await tester.pumpWidget(createWidgetUnderTest(plannedActivity));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activity_compliance_banner')), findsOneWidget);
      expect(find.textContaining('Soll/Ist-Abgleich:'), findsOneWidget);
      expect(find.textContaining('Plan-Treue'), findsOneWidget);
    });

    testWidgets('Soll/Ist-Banner zeigt Freie-Einheit-Status wenn kein Workout verknüpft ist', (tester) async {
      final freeActivity = createTestActivity(plannedWorkoutId: null);
      await tester.pumpWidget(createWidgetUnderTest(freeActivity));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activity_compliance_banner')), findsOneWidget);
      expect(find.textContaining('Freie Trainingseinheit'), findsOneWidget);
    });
  });
}
