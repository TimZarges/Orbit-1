import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit/features/health/models/daily_metrics.dart';
import 'package:orbit/features/health/widgets/three_rings_hero_card.dart';
import 'package:orbit/features/health/widgets/daily_journal_card.dart';
import 'package:orbit/features/health/widgets/correlation_insights_card.dart';
import 'package:orbit/features/health/widgets/vital_trend_chart_card.dart';
import 'package:orbit/features/health/widgets/sleep_breakdown_card.dart';
import 'package:orbit/features/health/widgets/health_report_card.dart';
import 'package:orbit/features/health/screens/health_cockpit_screen.dart';
import 'package:orbit/features/coach_link/models/coach_dashboard_athlete.dart';
import 'package:orbit/features/coach_link/widgets/coach_athletes_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 21: ThreeRingsHeroCard & Graceful Degradation', () {
    testWidgets('Rendert die 3 Ringe, ORBIT Gesamt-Score Badge und Empfehlung',
        (tester) async {
      final metrics = DailyMetrics(
        localDate: '2026-10-16',
        restingHrBpm: 50,
        hrvMs: 68,
        sleepSeconds: 27000,
        recoveryData: const RecoveryData(
          score: 82,
          classification: 'GREEN',
          recommendationDe:
              'Exzellente Erholung. Bereit für Schwellenintervalle.',
          recommendationEn: 'Excellent recovery.',
          weightsUsed: {
            'hrv': 0.45,
            'rhr': 0.25,
            'sleep': 0.2,
            'respiration': 0.1
          },
        ),
        strainData: const StrainData(
          score: 64,
          trainingTss: 50.0,
          alltagLoad: 14.0,
          totalRawLoad: 64.0,
          targetMin: 55,
          targetMax: 78,
        ),
        sleepScoreData: const SleepScoreData(
          score: 85,
          needHours: 8.0,
          actualHours: 7.75,
          accumulatedDebtHours: 0.25, // 15 min
          durationScore: 85,
          efficiencyScore: 88,
          stagesScore: 82,
        ),
        orbitScoreData: const OrbitScoreData(
          score: 80,
          consistencyScore: 85,
          tsbScore: 80,
          recoveryAvg7d: 78,
          sleepAvg7d: 82,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThreeRingsHeroCard(
              dailyMetrics: metrics,
              actualLoad: 60.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ORBIT Score Badge
      expect(find.text('80'), findsOneWidget);
      expect(find.textContaining('ORBIT'), findsWidgets);

      // Empfehlung
      expect(find.textContaining('Exzellente Erholung'), findsOneWidget);

      // 3 Ring Werte in Legende
      expect(find.text('82 %'), findsOneWidget); // Erholung
      expect(find.text('64'), findsOneWidget); // Belastung
      expect(find.text('85 %'), findsOneWidget); // Schlaf
      expect(find.text('Ziel: 55–78'), findsOneWidget); // Zielkorridor
    });

    testWidgets('Zeigt bei Graceful Degradation einen dezenten Sensor-Hinweis',
        (tester) async {
      final metrics = DailyMetrics(
        localDate: '2026-10-16',
        restingHrBpm: 52,
        sleepSeconds: 25000,
        recoveryData: const RecoveryData(
          score: 68,
          classification: 'YELLOW',
          recommendationDe: 'Moderate Erholung.',
          recommendationEn: 'Moderate recovery.',
          weightsUsed: {
            'rhr': 0.5,
            'sleep': 0.5
          }, // hrv fehlt -> isGracefulDegradation is true!
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThreeRingsHeroCard(
              dailyMetrics: metrics,
              actualLoad: 40.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('keine nächtliche HRV'), findsOneWidget);
    });
  });

  group('Phase 21: DailyJournalCard (15-Sekunden-Kurz-Journal)', () {
    testWidgets('Rendert Lifestyle-Tags und toggelt Auswahl', (tester) async {
      JournalData? savedJournal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyJournalCard(
              athleteId: '', // kein Firestore-Call
              dateStr: '2026-10-16',
              onSaved: (j) => savedJournal = j,
            ),
          ),
        ),
      );

      // Prüfe Vorhandensein der Tags
      expect(find.text('Spätes Koffein'), findsOneWidget);
      expect(find.text('Alkohol'), findsOneWidget);
      expect(find.text('Hydration gut'), findsOneWidget);
      expect(find.text('Muskelkater'), findsOneWidget);

      // Tippe auf Alkohol & Hydration
      await tester.tap(find.text('Alkohol'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hydration gut'));
      await tester.pumpAndSettle();

      // Speichern
      await tester.tap(find.text('Eintrag speichern'));
      await tester.pumpAndSettle();

      expect(savedJournal, isNotNull);
      expect(savedJournal!.alcohol, isTrue);
      expect(savedJournal!.goodHydration, isTrue);
      expect(savedJournal!.lateCaffeine, isFalse);
    });
  });

  group('Phase 21: CorrelationInsightsCard', () {
    testWidgets('Zeigt Sperr-Fortschritt bei N < 14 Einträgen', (tester) async {
      final history = List.generate(
        8,
        (i) => DailyMetrics(
          localDate: '2026-10-0$i',
          journal: const JournalData(lateCaffeine: true),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CorrelationInsightsCard(history: history),
          ),
        ),
      );

      expect(find.text('8 / 14 Tage'), findsOneWidget);
      expect(
          find.textContaining('Noch 6 Morgen-Check-ins nötig'), findsOneWidget);
    });

    testWidgets('Zeigt Korrelationen bei N >= 14 Einträgen', (tester) async {
      // 10 Tage mit Alkohol (reduzierte HRV 50ms) + 10 Tage ohne (hohe HRV 70ms)
      final history = <DailyMetrics>[];
      for (int i = 0; i < 10; i++) {
        history.add(DailyMetrics(
          localDate: '2026-09-${10 + i}',
          hrvMs: 50,
          journal: const JournalData(alcohol: true),
        ));
      }
      for (int i = 0; i < 10; i++) {
        history.add(DailyMetrics(
          localDate: '2026-09-${20 + i}',
          hrvMs: 70,
          journal: const JournalData(alcohol: false, goodHydration: true),
        ));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CorrelationInsightsCard(history: history),
          ),
        ),
      );

      expect(find.text('20 / 14 Tage'), findsOneWidget);
      expect(find.text('Alkohol am Vorabend'), findsOneWidget);
      expect(find.textContaining('-29 % HRV'), findsOneWidget);
    });
  });

  group('Phase 21: VitalTrendChartCard & SleepBreakdownCard', () {
    testWidgets(
        'VitalTrendChartCard kennzeichnet Werte außerhalb des Normbands neutral',
        (tester) async {
      final points = [
        VitalDataPoint(date: DateTime(2026, 10, 1), value: 65),
        VitalDataPoint(date: DateTime(2026, 10, 2), value: 66),
        VitalDataPoint(
            date: DateTime(2026, 10, 3), value: 48), // Ausreißer nach unten
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VitalTrendChartCard(
              title: 'Herzfrequenz-Variabilität (HRV)',
              unit: 'ms',
              points: points,
              baselineMean: 65.0,
              baselineStd: 5.0, // Band: 60 - 70
            ),
          ),
        ),
      );

      expect(find.text('Herzfrequenz-Variabilität (HRV)'), findsOneWidget);
      expect(find.text('48 ms'), findsOneWidget);
      // Neutrales Wording gemäß Regelwerk
      expect(
          find.text('Außerhalb deines 30-Tage-Normbereichs'), findsOneWidget);
    });

    testWidgets('SleepBreakdownCard visualisiert Phasen und Schlafschuld',
        (tester) async {
      final metrics = DailyMetrics(
        localDate: '2026-10-16',
        deepSleepSeconds: 6000,
        remSleepSeconds: 6500,
        awakeSleepSeconds: 1500,
        sleepScoreData: const SleepScoreData(
          score: 82,
          needHours: 8.0,
          actualHours: 7.5,
          accumulatedDebtHours: 0.4166, // ~25 min
          durationScore: 82,
          efficiencyScore: 85,
          stagesScore: 80,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SleepBreakdownCard(todayMetrics: metrics),
          ),
        ),
      );

      expect(find.text('Schlaf & Phasenanalyse'), findsOneWidget);
      expect(find.text('82 %'), findsOneWidget);
      expect(find.text('7.5 Std.'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);
      expect(find.text('Tiefschlaf'), findsOneWidget);
      expect(find.text('REM'), findsOneWidget);
    });

    testWidgets('HealthReportCard visualisiert Durchschnitte und Ampelzähler',
        (tester) async {
      const metricsList = [
        DailyMetrics(
          localDate: '2026-10-14',
          restingHrBpm: 50,
          hrvMs: 65,
          recovery: RecoveryData(
            score: 80,
            classification: 'GREEN',
            recommendationDe: 'Top',
            recommendationEn: 'Top',
          ),
          strain: StrainData(
            score: 60,
            trainingTss: 50.0,
            alltagLoad: 10.0,
            totalRawLoad: 60.0,
            targetMin: 50,
            targetMax: 70,
          ),
          sleep: SleepScoreData(
            score: 85,
            needHours: 8.0,
            actualHours: 8.0,
            accumulatedDebtHours: 0.0,
            durationScore: 85,
            efficiencyScore: 90,
            stagesScore: 80,
          ),
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HealthReportCard(metrics: metricsList),
          ),
        ),
      );

      expect(find.text('Wochenbericht (Letzte 7 Tage)'), findsOneWidget);
      expect(find.text('80 %'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('85 %'), findsOneWidget);
      expect(find.text('1 Grün'), findsOneWidget);
    });
  });

  group('Phase 21: CoachAthletesTable (Art. 9 DSGVO Gate)', () {
    testWidgets('Sperrt Gesundheitsdaten bei fehlender Berechtigung',
        (tester) async {
      final athleteWithoutConsent = CoachDashboardAthlete(
        athleteId: 'ath_1',
        coachId: 'coach_1',
        name: 'Max Mustermann',
        sport: 'BIKE',
        formStatus: CoachAthleteFormStatus.optimal,
        ctl: 75,
        atl: 70,
        tsb: 5,
        compliance7d: 95,
        actualLoad7d: 450,
        plannedLoad7d: 470,
        hasHealthPermission: false, // Art. 9 DSGVO Gate greift!
        recoveryScore: 85, // Darf NICHT angezeigt werden
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CoachAthletesTable(
                athletes: [athleteWithoutConsent],
                onAthleteOpen: (_, __) {},
                onCreateProposal: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Erholung'), findsOneWidget);
      // Gesperrtes Schloss-Badge
      expect(find.text('Gesperrt'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      // Sensibler Gesundheitswert darf NICHT im Widgetbaum sichtbar sein
      expect(find.text('85 %'), findsNothing);
    });

    testWidgets(
        'Zeigt Erholungsscore nur bei aktiver Freigabe (hasHealthPermission: true)',
        (tester) async {
      final athleteWithConsent = CoachDashboardAthlete(
        athleteId: 'ath_2',
        coachId: 'coach_1',
        name: 'Anna Ausdauer',
        sport: 'TRIATHLON',
        formStatus: CoachAthleteFormStatus.optimal,
        ctl: 80,
        atl: 72,
        tsb: 8,
        compliance7d: 100,
        actualLoad7d: 520,
        plannedLoad7d: 520,
        hasHealthPermission: true, // Freigegeben
        coachLinkStatus: 'ACTIVE',
        recoveryScore: 78,
        recoveryTrafficLight: 'GREEN',
        hrvTrend: 'UP',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CoachAthletesTable(
                athletes: [athleteWithConsent],
                onAthleteOpen: (_, __) {},
                onCreateProposal: (_) {},
              ),
            ),
          ),
        ),
      );

      // Score und Trendpfeil müssen sichtbar sein
      expect(find.text('78 %'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('Gesperrt (Art. 9)'), findsNothing);
    });
  });

  group('Phase 21: HealthCockpitScreen & Medizinischer Disclaimer', () {
    testWidgets('Rendert HealthCockpitScreen mit Disclaimer und Trendcharts',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HealthCockpitScreen(
              athleteName: 'Lukas Renner',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gesundheit: Lukas Renner'), findsOneWidget);
      expect(find.text('Morgen-Check-in (15 Sek.)'), findsOneWidget);
      expect(find.text('Lifestyle- & HRV-Korrelationen'), findsOneWidget);
      expect(find.text('Herzfrequenz-Variabilität (HRV)'), findsOneWidget);
      expect(find.text('Ruhepuls (RHR)'), findsOneWidget);
      expect(find.text('Body Battery & Alltagsstress'), findsOneWidget);

      // Pflicht-Disclaimer gemäß Spezifikation
      expect(
        find.textContaining('ORBIT ist kein Medizinprodukt'),
        findsOneWidget,
      );
    });
  });
}
