import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit/features/activities/models/activity.dart';
import 'package:orbit/features/activities/models/activity_stream.dart';
import 'package:orbit/features/activities/domain/lttb_downsampler.dart';
import 'package:orbit/features/activities/domain/wbal_calculator.dart';
import 'package:orbit/features/activities/widgets/aerobic_efficiency_badge.dart';
import 'package:orbit/features/activities/widgets/interval_table_widget.dart';
import 'package:orbit/features/activities/widgets/zone_detail_widget.dart';
import 'package:orbit/features/activities/widgets/telemetry_chart_widget.dart';
import 'package:orbit/features/activities/widgets/telemetry_channel_chips.dart';
import 'package:orbit/features/activities/screens/activity_cockpit_screen.dart';
import 'package:orbit/features/analysis/domain/aggregates_calculator.dart';
import 'package:orbit/features/analysis/models/zone_distribution.dart';
import 'package:orbit/features/analysis/widgets/fitness_fatigue_trend_chart.dart';
import 'package:orbit/features/analysis/widgets/performance_profile_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
      'Phase 20 - Performance-Pflicht für lange Zeitreihen (LTTB & Entkopplung)',
      () {
    test(
        'LTTB Downsampling reduziert 15.000 Samples (4+ Stunden) auf max. 500 Stützpunkte',
        () {
      // 15.000 Sekunden-Punkte simulieren (4h 10min)
      final rawPoints = List.generate(15000, (i) {
        return ActivityStreamPoint(
          timeSec: i,
          power: 200.0 + (i % 60 == 0 ? 350.0 : 0.0), // Periodische Antritte
          hr: 140.0 + (i % 60 == 0 ? 30.0 : 0.0),
          speedMps: 8.5,
          distanceM: i * 8.5,
        );
      });

      expect(rawPoints.length, 15000);

      final downsampled = LttbDownsampler.downsample(rawPoints, 400);

      expect(downsampled.length, 400);
      expect(downsampled.first.timeSec, 0);
      expect(downsampled.last.timeSec, 14999);
      // Spitzen müssen erhalten bleiben
      final maxP = downsampled
          .map((p) => p.power ?? 0.0)
          .reduce((a, b) => a > b ? a : b);
      expect(maxP, 550.0);
    });

    test(
        'WBalCalculator berechnet Skiba W\'bal Entleerung und exponentielle Erholung',
        () {
      // 3 min @ 350 W (supramaximal bei CP = 250 W, W' = 20.000 J)
      // gefolgt von 3 min @ 150 W (submaximal, Erholung)
      final points = <ActivityStreamPoint>[];
      for (int i = 0; i < 180; i++) {
        points.add(ActivityStreamPoint(timeSec: i, power: 350.0));
      }
      for (int i = 180; i < 360; i++) {
        points.add(ActivityStreamPoint(timeSec: i, power: 150.0));
      }

      final wBalPoints = WBalCalculator.calculateWBalSeries(
        points: points,
        cpWatts: 250.0,
        wPrimeJoules: 20000.0,
      );

      expect(wBalPoints.length, 360);
      // Bei t = 180s: 20.000 - (350 - 250) * 180 = 20.000 - 18.000 = 2.000 J (10% Füllstand)
      expect(wBalPoints[179].wBalJoules, closeTo(2000.0, 50.0));
      expect(wBalPoints[179].wBalPercent, closeTo(10.0, 0.5));

      // Bei t = 360s: Wiederaufladung auf ca. 36.5% (tau ≈ 517s nach Skiba et al.)
      expect(wBalPoints.last.wBalPercent, closeTo(36.5, 1.0));
      expect(wBalPoints.last.wBalPercent, greaterThan(35.0));
    });

    testWidgets(
        'TelemetryChartWidget rendert W\'bal-Kurve und entkoppelt Scrubbing Cursor',
        (tester) async {
      final points = List.generate(50, (i) {
        return ActivityStreamPoint(
          timeSec: i * 60,
          power: 250.0 + (i % 2 == 0 ? 50.0 : -50.0),
          hr: 150.0,
          speedMps: 8.0,
          distanceM: i * 480.0,
          wBalPercent: 100.0 - (i * 1.5),
          wBalJoules: 20000.0 - (i * 300.0),
        );
      });

      final scrubNotifier = ValueNotifier<ActivityStreamPoint?>(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelemetryChartWidget(
              points: points,
              activeChannels: const {
                TelemetryChannel.power,
                TelemetryChannel.wBal,
                TelemetryChannel.heartRate,
              },
              externalScrubNotifier: scrubNotifier,
            ),
          ),
        ),
      );

      expect(find.byType(TelemetryChartWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Simuliere Drag / Scrubbing mit gehaltenem Finger
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(TelemetryChartWidget)));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // ScrubNotifier muss während des Scrubbings aktiv sein
      expect(scrubNotifier.value, isNotNull);

      // Beim Loslassen wird der Cursor zurückgesetzt
      await gesture.up();
      await tester.pump();
      expect(scrubNotifier.value, isNull);
    });
  });

  group(
      'Phase 20 - Aktivitäts-Cockpit Widgets (Aerobe Effizienz, Intervalle, Zonen)',
      () {
    testWidgets(
        'AerobicEfficiencyBadge zeigt NP/NGP, IF, VI, EF und Decoupling Ampelfarbe',
        (tester) async {
      final activity = Activity(
        id: 'act_bike_pro',
        athleteId: 'ath_1',
        startTimeUtc: DateTime.now(),
        localDate: '2026-10-16',
        sport: 'BIKE',
        title: 'Lange Grundlageneinheit mit Intervallen',
        durationSec: 7200,
        distanceM: 60000,
        metrics: ActivityMetrics(
          np: 275.0,
          iff: 0.92,
          vi: 1.05,
          ef: 1.83,
          aerobicDecouplingPercent: 3.4,
          decouplingClassification: 'COUPLED',
          brickPaceDropSecPerKm: null,
          cpWatts: 280.0,
          wPrimeKj: 20.0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AerobicEfficiencyBadge(activity: activity),
          ),
        ),
      );

      expect(find.text('Aerobe Effizienz & Belastung'), findsOneWidget);
      expect(find.text('275 W'), findsOneWidget); // NP
      expect(find.text('0.92'), findsOneWidget); // IF
      expect(find.text('1.05'), findsOneWidget); // VI
      expect(find.text('1.83'), findsOneWidget); // EF
      expect(find.textContaining('Gekoppelt (< 5%)'), findsOneWidget);
    });

    testWidgets(
        'AerobicEfficiencyBadge zeigt Brick-Analyse-Badge bei Koppellauf',
        (tester) async {
      final brickActivity = Activity(
        id: 'act_tri_brick',
        athleteId: 'ath_1',
        startTimeUtc: DateTime.now(),
        localDate: '2026-10-16',
        sport: 'TRIATHLON',
        title: 'Koppellauf nach 90 km Rad',
        durationSec: 2400,
        distanceM: 8000,
        metrics: ActivityMetrics(
          np: 230.0,
          iff: 0.95,
          vi: 1.02,
          ef: 1.65,
          aerobicDecouplingPercent: 6.2,
          decouplingClassification: 'MODERATE',
          brickPaceDropSecPerKm: 14.0, // +14s/km Abfall
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AerobicEfficiencyBadge(activity: brickActivity),
          ),
        ),
      );

      expect(find.textContaining('Moderat (5–8%)'), findsOneWidget);
      expect(find.text('Brick-Analyse (Koppellauf):'), findsOneWidget);
      expect(find.textContaining('+14 s/km'), findsOneWidget);
    });

    testWidgets(
        'IntervalTableWidget schaltet zwischen manuellen Runden und Auto-Intervallen um',
        (tester) async {
      final manualLaps = [
        ActivityLapData(
          lapIndex: 1,
          durationSec: 600,
          distanceM: 5000,
          avgWatts: 250,
          npWatts: 255,
          avgHr: 145,
          efficiencyFactor: 1.76,
        ),
      ];

      final autoIntervals = [
        ActivityLapData(
          lapIndex: 1,
          durationSec: 240,
          distanceM: 2000,
          avgWatts: 310,
          npWatts: 315,
          avgHr: 168,
          efficiencyFactor: 1.85,
          isAutoInterval: true,
        ),
        ActivityLapData(
          lapIndex: 2,
          durationSec: 240,
          distanceM: 2050,
          avgWatts: 312,
          npWatts: 318,
          avgHr: 172,
          efficiencyFactor: 1.81,
          isAutoInterval: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IntervalTableWidget(
                laps: manualLaps,
                autoIntervals: autoIntervals,
                sport: 'BIKE',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Intervalle & Runden'), findsOneWidget);
      expect(find.text('Manuell (1)'), findsOneWidget);
      expect(find.text('Auto (2)'), findsOneWidget);

      // Zuerst ist Manuell aktiv
      expect(find.text('250 W'), findsOneWidget);

      // Klick auf Auto
      await tester.tap(find.text('Auto (2)'));
      await tester.pump();

      // Jetzt werden die Auto-Intervalle angezeigt
      expect(find.text('310 W'), findsOneWidget);
      expect(find.text('312 W'), findsOneWidget);
    });

    testWidgets('ZoneDetailWidget schaltet zwischen Watt Z1-Z7 und HF Z1-Z5 um',
        (tester) async {
      final powerSummary = ZoneDistributionSummary.fromSeconds(const [
        360.0,
        1440.0,
        900.0,
        540.0,
        216.0,
        108.0,
        36.0,
      ]);
      final hrSummary = ZoneDistributionSummary.fromSeconds(const [
        480.0,
        1800.0,
        900.0,
        420.0,
        120.0,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ZoneDetailWidget(
                title: 'Zeit in Zonen',
                summary: hrSummary,
                powerSummary: powerSummary,
                hrSummary: hrSummary,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Zeit in Zonen'), findsOneWidget);
      expect(find.text('Watt (Z1–Z7)'), findsOneWidget);
      expect(find.text('HF (Z1–Z5)'), findsOneWidget);

      // Klick auf HF
      await tester.tap(find.text('HF (Z1–Z5)'));
      await tester.pump();

      expect(find.text('Grundlage'), findsOneWidget);
    });
  });

  group('Phase 20 - Saison- & Leistungs-Cockpit (Banister PMC & MMP)', () {
    testWidgets(
        'FitnessFatigueTrendChart rendert CTL/ATL/TSB und warnt bei Ramp-Rate > 7',
        (tester) async {
      // 10 Tage Historie mit steilem Anstieg (+10 CTL in 7 Tagen)
      final points = <FitnessFatiguePoint>[];
      for (int i = 0; i < 10; i++) {
        points.add(
          FitnessFatiguePoint(
            date: '2026-10-0$i',
            ctl: 50.0 +
                (i * 1.5), // Anstieg von 50 auf 63.5 (> 10 TSS in 7 Tagen)
            atl: 80.0 + (i * 2.0),
            tsb: (50.0 + i * 1.5) - (80.0 + i * 2.0),
            dailyLoad: 120,
            isProjection: false,
          ),
        );
      }

      // 14 Tage Projektion anhängen
      for (int i = 1; i <= 14; i++) {
        points.add(
          FitnessFatiguePoint(
            date: '2026-10-${10 + i}',
            ctl: 63.5 - (i * 0.3),
            atl: 98.0 - (i * 1.5),
            tsb: -34.5 + (i * 1.2),
            dailyLoad: 0,
            isProjection: true,
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FitnessFatigueTrendChart(points: points),
            ),
          ),
        ),
      );

      expect(find.text('Performance Management (PMC)'), findsOneWidget);
      expect(find.textContaining('Fitness (CTL)'), findsOneWidget);
      expect(find.textContaining('Ermüdung (ATL)'), findsOneWidget);
      expect(find.textContaining('Form (TSB)'), findsOneWidget);

      // Überlastungswarnung muss sichtbar sein
      expect(find.textContaining('Überlastungswarnung'), findsOneWidget);
      expect(find.textContaining('14-Tage-Projektion'), findsOneWidget);
    });

    testWidgets(
        'PerformanceProfileCard zeigt logarithmische MMP-Kurve, CP und W\'',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PerformanceProfileCard(
                recentMmp: {1: 900, 60: 420, 300: 310, 1200: 275},
                seasonMmp: {1: 980, 60: 440, 300: 330, 1200: 285},
                cpWatts: 280,
                wPrimeKj: 20.4,
                pMaxWatts: 980,
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Leistungsprofil & Critical Power (MMP)'),
        findsOneWidget,
      );
      expect(find.text('280 W'), findsOneWidget); // Critical Power
      expect(find.text('20.4 kJ'), findsOneWidget); // W'
      expect(find.text('980 W'), findsOneWidget); // Pmax
      expect(find.text('Letzte 42 Tage'), findsOneWidget);
      expect(find.text('Saison-Bestwerte'), findsOneWidget);
    });

    testWidgets(
        'ActivityCockpitScreen rendert alle Analyse-Bereiche fehlerfrei',
        (tester) async {
      final activity = Activity(
        id: 'act_cockpit_full',
        athleteId: 'ath_1',
        startTimeUtc: DateTime.now(),
        localDate: '2026-10-16',
        sport: 'BIKE',
        title: 'Feldberg Intervalltraining',
        durationSec: 3600,
        distanceM: 32000,
        summary: ActivitySummary(
          avgPowerW: 245,
          maxPowerW: 750,
          avgHr: 148,
          maxHr: 182,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivityCockpitScreen(activity: activity),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ActivityCockpitScreen), findsOneWidget);
      expect(find.byType(AerobicEfficiencyBadge), findsOneWidget);
      expect(find.byType(TelemetryChartWidget), findsOneWidget);
      expect(find.byType(IntervalTableWidget), findsOneWidget);
      expect(find.byType(ZoneDetailWidget), findsOneWidget);
    });
  });
}
