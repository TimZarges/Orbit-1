import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/activities/models/activity_stream.dart';
import 'package:orbit/features/activities/widgets/telemetry_map_widget.dart';
import 'package:orbit/features/analysis/models/personal_record.dart';
import 'package:orbit/features/analysis/widgets/personal_records_card.dart';
import 'package:orbit/features/diagnostics/models/guided_test_info.dart';

void main() {
  group('Phase 31.2 - GPS-Aktivitätskarte (Volt-Spur & Hell/Dunkel)', () {
    final sampleGpsPoints = [
      ActivityStreamPoint(
        timeSec: 0,
        lat: 50.1109,
        lng: 8.6821,
        power: 200,
        hr: 140,
        speedMps: 7.5,
      ),
      ActivityStreamPoint(
        timeSec: 60,
        lat: 50.1120,
        lng: 8.6840,
        power: 250,
        hr: 155,
        speedMps: 8.2,
      ),
      ActivityStreamPoint(
        timeSec: 120,
        lat: 50.1135,
        lng: 8.6865,
        power: 310,
        hr: 172,
        speedMps: 9.0,
      ),
    ];

    testWidgets('Standard-Modus ist Volt-Spur und rendert Outlined Polyline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelemetryMapWidget(
              points: sampleGpsPoints,
              initialTilesEnabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('telemetry_map_container')), findsOneWidget);
      expect(find.byKey(const Key('telemetry_map_mode_voltStandard')),
          findsOneWidget);
      expect(find.text('Volt-Spur'), findsOneWidget);
    });

    testWidgets('Hell/Dunkel Umschalter schaltet MapStyle bei aktiven Kacheln',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelemetryMapWidget(
              points: sampleGpsPoints,
              initialTilesEnabled: true,
              initialMapStyle: TelemetryMapStyle.dark,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Style Toggle Button sichtbar
      final styleToggle = find.byKey(const Key('telemetry_map_style_toggle'));
      expect(styleToggle, findsOneWidget);
      expect(find.text('Hell'), findsOneWidget);

      // Klick wechselt auf Hell
      await tester.tap(styleToggle);
      await tester.pumpAndSettle();

      expect(find.text('Dunkel'), findsOneWidget);
    });
  });

  group('Phase 31.3 - Diagnostik: Ramp Test & 5-Minuten-All-Out Test', () {
    test('Standard-Protokoll Stufentest (Ramp Test) für Radfahren vorhanden',
        () {
      final rampTest = GuidedTestInfo.standardTests.firstWhere(
        (t) => t.id == 'bike_ramp_test',
      );

      expect(rampTest.sport, equals('BIKE'));
      expect(rampTest.titleDe, contains('Stufentest'));
      expect(rampTest.protocolDe, contains('100 Watt'));
      expect(rampTest.protocolDe, contains('+25 Watt alle 30 Sekunden'));
      expect(rampTest.protocolDe, contains('MAP'));
      expect(rampTest.protocolDe, contains('FTP'));
      expect(rampTest.durationMinutes, equals(25));
    });

    test('Standard-Protokoll 5-Minuten-All-Out für Laufen vorhanden', () {
      final runTest = GuidedTestInfo.standardTests.firstWhere(
        (t) => t.id == 'run_5min_all_out',
      );

      expect(runTest.sport, equals('RUN'));
      expect(runTest.titleDe, contains('5-Minuten-All-Out'));
      expect(runTest.protocolDe, contains('5 min'));
      expect(runTest.protocolDe, contains('vVO2max'));
      expect(runTest.protocolDe, contains('Schwellenpace'));
      expect(runTest.durationMinutes, equals(30));
    });

    test('Filterung nach Sportart liefert neue Tests zuverlässig', () {
      final bikeTests =
          GuidedTestInfo.standardTests.where((t) => t.sport == 'BIKE').toList();
      final runTests =
          GuidedTestInfo.standardTests.where((t) => t.sport == 'RUN').toList();

      expect(bikeTests.any((t) => t.id == 'bike_ramp_test'), isTrue);
      expect(runTests.any((t) => t.id == 'run_5min_all_out'), isTrue);
    });
  });

  group('Phase 31.4 - PR-Datenbank & Leistungskurven', () {
    test(
        'PersonalRecordsSummary generiert vollständige Stützpunkte für alle Zeiträume',
        () {
      final summary = PersonalRecordsSummary.demo(ftp: 280, weightKg: 70);

      for (final tf in PRTimeframe.values) {
        final bike = summary.getBike(tf);
        final run = summary.getRun(tf);
        final swim = summary.getSwim(tf);

        // Rad: 11 Stützpunkte (5s bis 180m)
        expect(bike.length, equals(11));
        expect(bike.first.durationLabel, equals('5s'));
        expect(bike.last.durationLabel, equals('180m'));
        expect(bike.first.watts, greaterThan(bike.last.watts));
        expect(bike.first.wattsPerKg, greaterThan(0));

        // Lauf: 7 Standard-Distanzen (400m bis Marathon)
        expect(run.length, equals(7));
        expect(run.first.distanceLabel, equals('400m'));
        expect(run.last.distanceLabel, equals('Marathon'));
        expect(run.first.timeSec, lessThan(run.last.timeSec));
        expect(run.first.formattedPace, contains('/km'));

        // Schwimmen: 5 Distanzen (100m bis 1500m)
        expect(swim.length, equals(5));
        expect(swim.first.distanceLabel, equals('100m'));
        expect(swim.last.distanceLabel, equals('1500m'));
        expect(swim.first.formattedPace, contains('/100m'));
      }
    });

    testWidgets(
        'PersonalRecordsCard rendert Sport-Umschalter und Grid-Elemente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalRecordsCard(
                summary: PersonalRecordsSummary.demo(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card und Header
      expect(find.byKey(const Key('personal_records_card')), findsOneWidget);
      expect(find.text('PR-Datenbank'), findsOneWidget);

      // Rad Grid ist standardmäßig aktiv
      expect(find.byKey(const Key('pr_bike_grid')), findsOneWidget);
      expect(find.text('5s'), findsOneWidget);
      expect(find.text('20m'), findsOneWidget);
      expect(find.text('60m'), findsOneWidget);

      // Wechsel auf Lauf-PRs
      await tester.tap(find.byKey(const Key('pr_sport_run')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pr_run_grid')), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('Halbmarathon'), findsOneWidget);

      // Wechsel auf Schwimm-PRs
      await tester.tap(find.byKey(const Key('pr_sport_swim')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pr_swim_grid')), findsOneWidget);
      expect(find.text('100m'), findsOneWidget);
      expect(find.text('400m'), findsOneWidget);
      expect(find.text('1500m'), findsOneWidget);

      // Zeitfilter-Umschaltung
      await tester.tap(find.byKey(const Key('pr_timeframe_year2026')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pr_swim_grid')), findsOneWidget);
    });
  });
}
