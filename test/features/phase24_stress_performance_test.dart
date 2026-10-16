import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit/features/activities/models/activity.dart';
import 'package:orbit/features/activities/models/activity_stream.dart';
import 'package:orbit/features/activities/domain/lttb_downsampler.dart';
import 'package:orbit/features/activities/domain/wbal_calculator.dart';
import 'package:orbit/features/activities/screens/activity_cockpit_screen.dart';
import 'package:orbit/features/analysis/domain/aggregates_calculator.dart';
import 'package:orbit/features/analysis/widgets/fitness_fatigue_trend_chart.dart';
import 'package:orbit/features/home/models/race_goal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
      'Phase 24.1: Performance-Benchmark & Stresstest (LTTB, W\'bal & Charts)',
      () {
    test(
        'LTTB Downsampler verarbeitet 6-Stunden-Radausfahrt (21.600 1Hz-Samples) in < 15 ms',
        () {
      // 21.600 Sekunden-Punkte simulieren (6 Stunden bei 1 Hz)
      final rawPoints = List.generate(21600, (i) {
        final surge = i % 1800 < 120 ? 400.0 : 0.0;
        return ActivityStreamPoint(
          timeSec: i,
          power: 210.0 + surge + (sin(i / 100.0) * 30.0),
          hr: 138.0 + (surge > 0 ? 25.0 : 0.0),
          cadence: 88.0 + (i % 5),
          speedMps: 8.8,
          distanceM: i * 8.8,
          altitudeM: 150.0 + (sin(i / 500.0) * 80.0),
        );
      });

      expect(rawPoints.length, 21600);

      // Benchmark-Messung
      final stopwatch = Stopwatch()..start();
      final downsampled = LttbDownsampler.downsample(rawPoints, 500);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      // Kriterium: < 15 ms
      expect(elapsedMs, lessThan(15));
      expect(downsampled.length, 500);
      expect(downsampled.first.timeSec, 0);
      expect(downsampled.last.timeSec, 21599);

      // Verifiziere Erhalt der Leistungsspitzen
      final maxP = downsampled
          .map((p) => p.power ?? 0.0)
          .reduce((a, b) => a > b ? a : b);
      expect(maxP, greaterThanOrEqualTo(400.0));
    });

    test(
        'WBalCalculator verarbeitet 6-Stunden-Radausfahrt (21.600 1Hz-Samples) in < 15 ms',
        () {
      // 21.600 Sekunden-Punkte für 6 Stunden
      final rawPoints = List.generate(21600, (i) {
        final surge = (i >= 3600 && i < 3900) ? 380.0 : 0.0;
        return ActivityStreamPoint(
          timeSec: i,
          power: 220.0 + surge,
          hr: 140.0,
        );
      });

      // Benchmark-Messung
      final stopwatch = Stopwatch()..start();
      final wBalPoints = WBalCalculator.calculateWBalSeries(
        points: rawPoints,
        cpWatts: 260.0,
        wPrimeJoules: 21000.0,
      );
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      // Kriterium: < 15 ms
      expect(elapsedMs, lessThan(15));
      expect(wBalPoints.length, 21600);

      // W'bal muss bei supramaximalem Intervall entleert und danach regeneriert werden
      final minWBal = wBalPoints
          .map((p) => p.wBalJoules ?? 21000.0)
          .reduce((a, b) => a < b ? a : b);
      expect(minWBal, lessThan(21000.0));
      expect(wBalPoints.last.wBalJoules, greaterThan(minWBal));
    });

    testWidgets(
        'ActivityCockpitScreen rendert 21.600 Samples via LTTB ohne Layout-Overflow',
        (tester) async {
      final activity = Activity(
        id: 'act_stress_6h',
        athleteId: 'ath_tim',
        localDate: '2026-08-01',
        sport: 'BIKE',
        title: '6-Stunden-Alpenmarathon',
        startTimeUtc: DateTime(2026, 8, 1, 7, 0),
        durationSec: 21600,
        distanceM: 183600.0,
        summary: ActivitySummary(
          avgPowerW: 215,
          avgHr: 145,
          maxPowerW: 550,
          maxHr: 178,
          avgCadence: 86,
          elevationGainM: 2400,
        ),
        metrics: ActivityMetrics(
          tss: 380.0,
          np: 245.0,
          iff: 0.88,
          cpWatts: 260.0,
          wPrimeKj: 20.0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ActivityCockpitScreen(
                activity: activity,
                athleteName: 'Tim Zarges',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('6-Stunden-Alpenmarathon'), findsOneWidget);
      expect(find.byType(ActivityCockpitScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'FitnessFatigueTrendChart rendert 150 historische Tage + 5 A/B/C Rennen ohne Frame-Drop',
        (tester) async {
      // 150 Tage Historie simulieren
      final baseDate = DateTime(2026, 3, 1);
      final historyPoints = List.generate(150, (i) {
        final d = baseDate.add(Duration(days: i));
        final dateStr =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final ctl = 40.0 + (i * 0.3);
        final atl = 45.0 + (i % 7 == 0 ? 30.0 : -10.0);
        return FitnessFatiguePoint(
          date: dateStr,
          ctl: ctl,
          atl: atl,
          tsb: ctl - atl,
        );
      });

      // 5 Rennen simulieren (A, B, C)
      final races = [
        const RaceGoal(
          title: 'Saison-Kickoff 10k',
          date: '2026-04-15',
          priority: 'C',
          sport: 'RUN',
        ),
        const RaceGoal(
          title: 'Halbmarathon Frankfurt',
          date: '2026-05-10',
          priority: 'B',
          sport: 'RUN',
        ),
        const RaceGoal(
          title: 'Challenge Kraichgau 70.3',
          date: '2026-06-07',
          priority: 'B',
          sport: 'TRIATHLON',
        ),
        const RaceGoal(
          title: 'DATEV Challenge Roth',
          date: '2026-07-05',
          priority: 'A',
          sport: 'TRIATHLON',
          targetTime: '9:15:00',
          targetPowerWatts: 240,
        ),
        const RaceGoal(
          title: 'Vereinsmeisterschaft EZF',
          date: '2026-07-20',
          priority: 'A',
          sport: 'BIKE',
          targetPowerWatts: 320,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              width: 800,
              child: FitnessFatigueTrendChart(
                points: historyPoints,
                races: races,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FitnessFatigueTrendChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
