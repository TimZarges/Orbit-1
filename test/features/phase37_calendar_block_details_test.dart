import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/activities/providers/activities_provider.dart';
import 'package:orbit/features/auth/providers/user_provider.dart';
import 'package:orbit/features/calendar/domain/workout_block_extractor.dart';
import 'package:orbit/features/calendar/models/planned_workout.dart';
import 'package:orbit/features/calendar/providers/calendar_provider.dart';
import 'package:orbit/features/calendar/repositories/planned_workout_repository.dart';
import 'package:orbit/features/calendar/widgets/workout_card.dart';
import 'package:orbit/features/calendar/widgets/workout_detail_sheet.dart';
import 'package:orbit/features/workout_builder/domain/workout_calculator.dart';

class FakePlannedWorkoutRepository implements PlannedWorkoutRepository {
  @override
  Future<String> create(PlannedWorkout workout) async => workout.id;

  @override
  Future<void> update(PlannedWorkout workout) async {}

  @override
  Future<void> delete(String workoutId) async {}

  @override
  Future<void> markSkipped(String workoutId) async {}

  @override
  Future<void> markPlanned(String workoutId) async {}

  @override
  Future<void> linkActivity({
    required String workoutId,
    required String activityId,
    String matchStatus = 'AUTO',
  }) async {}

  @override
  Future<void> unlinkActivity({
    required String workoutId,
    required String activityId,
  }) async {}

  @override
  Future<void> reschedule({
    required String workoutId,
    required String newLocalDate,
  }) async {}

  @override
  Stream<List<PlannedWorkout>> watchWorkoutsForAthlete({
    required String athleteId,
    required String startDate,
    required String endDate,
  }) =>
      Stream.value([]);
}

void main() {
  group('Phase 37.1 & 37.2 — WorkoutBlockExtractor & Calendar Blocks', () {
    test('WorkoutBlockExtractor extracts 10 blocks for 4x4min repeat', () {
      final workout = PlannedWorkout(
        id: 'w-4x4',
        athleteId: 'ath-1',
        title: '4x4min VO2max Intervalle',
        sport: 'BIKE',
        localDate: '2026-10-20',
        plannedDurationSec: 3600,
        createdBy: 'ath-1',
      );

      const thresholds = AthleteThresholds(
        ftp: 300,
        runThresholdPaceSecPerKm: 270,
      );

      final steps = WorkoutBlockExtractor.extractSteps(
        workout,
        thresholds: thresholds,
        maxHr: 190,
      );

      // Warmup (1) + 4x [Intervall + Erholung] (8) + Cooldown (1) = 10 Schritte
      expect(steps.length, equals(10));
      expect(steps[0].label, equals('Aufwärmen'));
      expect(steps[1].label, equals('Intervall 1/4'));
      expect(steps[2].label, equals('Erholung 1/4'));
      expect(steps[9].label, contains('Ausrollen'));

      // Ziel-Watt bei FTP 300 W in Z5 (106–120 %) = 318–360 W
      expect(steps[1].targetWattsLabel, contains('W'));
      expect(steps[1].zone, equals(5));
    });

    test('WorkoutBlockExtractor extracts pace targets for running repeat', () {
      final workout = PlannedWorkout(
        id: 'w-run-repeat',
        athleteId: 'ath-1',
        title: '5x1000m Schwellenläufe',
        sport: 'RUN',
        localDate: '2026-10-21',
        plannedDurationSec: 3000,
        createdBy: 'ath-1',
      );

      const thresholds = AthleteThresholds(
        runThresholdPaceSecPerKm: 270, // 4:30/km
      );

      final steps = WorkoutBlockExtractor.extractSteps(
        workout,
        thresholds: thresholds,
      );

      // 1 Warmup + 5x2 + 1 Cooldown = 12 Schritte
      expect(steps.length, equals(12));
      expect(steps[1].targetPaceLabel, contains('min/km'));
    });

    testWidgets('WorkoutCard renders title and mini block profile',
        (tester) async {
      final workout = PlannedWorkout(
        id: 'w-card',
        athleteId: 'ath-1',
        title: '4x4min VO2max Intervalle',
        sport: 'BIKE',
        localDate: '2026-10-20',
        plannedDurationSec: 3600,
        plannedLoad: 75,
        createdBy: 'ath-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutCard(workout: workout),
          ),
        ),
      );

      expect(find.text('4x4min VO2max Intervalle'), findsOneWidget);
      expect(find.text('BIKE'), findsOneWidget);
      expect(find.text('75 Load'), findsOneWidget);
    });

    testWidgets('WorkoutDetailSheet renders steps and action buttons with keys',
        (tester) async {
      final workout = PlannedWorkout(
        id: 'w-sheet',
        athleteId: 'ath-1',
        title: '4x4min VO2max Intervalle',
        sport: 'BIKE',
        localDate: '2026-10-20',
        plannedDurationSec: 3600,
        plannedLoad: 75,
        createdBy: 'ath-1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannedWorkoutRepositoryProvider
                .overrideWithValue(FakePlannedWorkoutRepository()),
            activitiesProvider.overrideWith((ref) => Stream.value([])),
            userDocumentProvider.overrideWith((ref) => Stream.value({
                  'ftp': 300,
                  'maxHeartRate': 190,
                  'role': 'ATHLETE',
                })),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: WorkoutDetailSheet(workout: workout),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Schritt #1 und #2 müssen vorhanden sein
      expect(find.byKey(const Key('workout_step_1')), findsOneWidget);
      expect(find.byKey(const Key('workout_step_2')), findsOneWidget);

      // Aktionen mit Keys müssen existieren
      expect(find.byKey(const Key('workout_action_postpone_tomorrow')),
          findsOneWidget);
      expect(find.byKey(const Key('workout_action_pick_date')), findsOneWidget);
      expect(
          find.byKey(const Key('workout_action_mark_skipped')), findsOneWidget);
    });
  });
}
