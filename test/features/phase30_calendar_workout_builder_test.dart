import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit/features/activities/providers/activities_provider.dart';
import 'package:orbit/features/auth/providers/user_provider.dart';
import 'package:orbit/features/calendar/domain/workout_compliance_evaluator.dart';
import 'package:orbit/features/calendar/models/planned_workout.dart';
import 'package:orbit/features/calendar/providers/calendar_provider.dart';
import 'package:orbit/features/calendar/screens/calendar_screen.dart';
import 'package:orbit/features/coach_link/providers/athlete_context_provider.dart';
import 'package:orbit/features/dashboard/screens/dashboard_screen.dart';
import 'package:orbit/features/home/models/home_dashboard_data.dart';
import 'package:orbit/features/home/providers/home_dashboard_provider.dart';
import 'package:orbit/features/workout_builder/screens/workout_builder_screen.dart';
import 'package:orbit/features/workout_builder/widgets/today_workout_preview_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de', null);
  });

  group('Phase 30: WorkoutComplianceEvaluator (Soll-/Ist-Ampel)', () {
    test('bewertet Abweichung <= 15 % als GREEN (Perfekt getroffen)', () {
      final res = WorkoutComplianceEvaluator.evaluate(
        plannedDurationSec: 3600, // 60 min
        plannedLoad: 60.0,
        actualDurationSec: 3780, // 63 min (5 % Abweichung)
        actualLoad: 63.0, // 5 % Abweichung
        isCompleted: true,
      );

      expect(res.status, ComplianceStatus.green);
      expect(res.isGreen, isTrue);
      expect(res.statusLabel, 'Perfekt getroffen');
      expect(res.statusColor, const Color(0xFF10B981));
    });

    test(
        'bewertet Abweichung zwischen 15 % und 35 % als YELLOW (Belastung angepasst)',
        () {
      final res = WorkoutComplianceEvaluator.evaluate(
        plannedDurationSec: 3600, // 60 min
        plannedLoad: 60.0,
        actualDurationSec: 4500, // 75 min (25 % Abweichung)
        actualLoad: 75.0, // 25 % Abweichung
        isCompleted: true,
      );

      expect(res.status, ComplianceStatus.yellow);
      expect(res.isYellow, isTrue);
      expect(res.statusLabel, 'Belastung angepasst');
      expect(res.statusColor, const Color(0xFFF59E0B));
    });

    test('bewertet Abweichung > 35 % als RED (Stark abgewichen)', () {
      final res = WorkoutComplianceEvaluator.evaluate(
        plannedDurationSec: 3600, // 60 min
        plannedLoad: 60.0,
        actualDurationSec: 5400, // 90 min (50 % Abweichung)
        actualLoad: 95.0,
        isCompleted: true,
      );

      expect(res.status, ComplianceStatus.red);
      expect(res.isRed, isTrue);
      expect(res.statusLabel, 'Stark abgewichen');
      expect(res.statusColor, const Color(0xFFEF4444));
    });

    test('bewertet Einheit nach Mitternacht als RED (Ausgefallen)', () {
      final res = WorkoutComplianceEvaluator.evaluate(
        plannedDurationSec: 3600,
        plannedLoad: 60.0,
        actualDurationSec: 0,
        actualLoad: 0,
        isCompleted: false,
        isPastMidnight: true,
      );

      expect(res.status, ComplianceStatus.red);
      expect(res.statusLabel, 'Ausgefallen');
      expect(res.statusColor, const Color(0xFFEF4444));
    });
  });

  group('Phase 30: TodayWorkoutPreviewCard (Vorschau auf Heute)', () {
    testWidgets('rendert Titel, Zielwerte und Stufen-Balkendiagramm',
        (tester) async {
      const workout = PlannedWorkout(
        id: 'pw-1',
        athleteId: 'ath-1',
        createdBy: 'ath-1',
        localDate: '2026-10-18',
        sport: 'BIKE',
        title: 'Schwellen-Intervalle (4x4)',
        plannedDurationSec: 3600,
        plannedLoad: 65,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TodayWorkoutPreviewCard(
              workout: workout,
              ftpWatts: 337,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Schwellen-Intervalle (4x4)'), findsOneWidget);
      expect(find.text('1h · 65 TSS'), findsOneWidget);
      // Berechnete konkrete Wattwerte aus FTP (337 W)
      expect(find.textContaining('FTP = 320–354 W'), findsOneWidget);
      expect(find.text('GEPLANT'), findsOneWidget);
    });

    testWidgets('rendert Erfüllungs-Ampel-Badge wenn Einheit abgeschlossen',
        (tester) async {
      const workout = PlannedWorkout(
        id: 'pw-2',
        athleteId: 'ath-1',
        createdBy: 'ath-1',
        localDate: '2026-10-18',
        sport: 'BIKE',
        title: 'GA1 Grundlage',
        plannedDurationSec: 3600,
        plannedLoad: 50,
        status: 'COMPLETED',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TodayWorkoutPreviewCard(
              workout: workout,
              actualDurationSec: 3700,
              actualLoad: 51,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PERFEKT GETROFFEN'), findsOneWidget);
    });
  });

  group('Phase 30: BottomNavigation & CalendarScreen (Kalender statt Plan)',
      () {
    testWidgets('Dashboard Bottom Navigation enthält Tab "Kalender"',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAthleteIdProvider.overrideWithValue('test_athlete'),
            viewedAthleteIdProvider.overrideWith((ref) => 'test_athlete'),
            userDocumentProvider
                .overrideWith((ref) => Stream.value({'role': 'ATHLETE'})),
            homeDashboardProvider('test_athlete')
                .overrideWith((ref) => Future.value(
                      const HomeDashboardData(todayLocalDate: '2026-10-18'),
                    )),
            athleteCurrentWeekWorkoutsProvider('test_athlete')
                .overrideWith((ref) => Stream.value([])),
            athleteCurrentMonthWorkoutsProvider('test_athlete')
                .overrideWith((ref) => Stream.value([])),
            activitiesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kein "Plan" mehr in der Leiste, sondern "Kalender"
      expect(find.text('Kalender'), findsOneWidget);
      expect(find.text('Plan'), findsNothing);
    });

    testWidgets('CalendarScreen rendert Wochensoll-Karte und SegmentedButton',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAthleteIdProvider.overrideWithValue('test_athlete'),
            viewedAthleteIdProvider.overrideWith((ref) => 'test_athlete'),
            athleteCurrentWeekWorkoutsProvider('test_athlete')
                .overrideWith((ref) => Stream.value([])),
            athleteCurrentMonthWorkoutsProvider('test_athlete')
                .overrideWith((ref) => Stream.value([])),
            activitiesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: CalendarScreen(athleteId: 'test_athlete'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Woche'), findsOneWidget);
      expect(find.text('Monat'), findsOneWidget);
      expect(find.text('Liste'), findsOneWidget);
      expect(find.text('Training planen'), findsOneWidget);
    });
  });

  group('Phase 30: WorkoutBuilderScreen (Visuelle Blöcke)', () {
    testWidgets(
        'WorkoutBuilder startet im visuellen Block-Modus mit Schnellbausteinen',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorkoutBuilderScreen(sport: 'BIKE'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visuelle Blöcke'), findsOneWidget);
      expect(find.text('Text-Code'), findsOneWidget);
      expect(find.text('+ Warmup'), findsOneWidget);
      expect(find.text('+ Intervall (Z4)'), findsOneWidget);
      expect(find.text('+ Pause (Z1)'), findsOneWidget);
      expect(find.text('+ 4x Schleife'), findsOneWidget);
      expect(find.text('+ Cooldown'), findsOneWidget);
      expect(find.text('Im Kalender einplanen'), findsOneWidget);
    });
  });
}
