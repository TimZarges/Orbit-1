import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/auth/providers/auth_provider.dart';
import 'package:orbit/features/calendar/models/planned_workout.dart';
import 'package:orbit/features/calendar/providers/calendar_provider.dart';
import 'package:orbit/features/calendar/repositories/planned_workout_repository.dart';
import 'package:orbit/features/calendar/widgets/create_workout_dialog.dart';
import 'package:orbit/features/races/models/race.dart';
import 'package:orbit/features/races/providers/races_provider.dart';
import 'package:orbit/features/races/repositories/race_repository.dart';

class FakeRaceRepo implements RaceRepository {
  Race? savedRace;

  @override
  Future<void> saveRace(Race race) async {
    savedRace = race;
  }

  @override
  Future<List<Race>> getRaces(String userId) async =>
      savedRace != null ? [savedRace!] : [];

  @override
  Future<Race?> getNextRace(String userId, {bool onlyA = true}) async =>
      savedRace;

  @override
  Future<void> deleteRace(String userId, String raceId) async {}

  @override
  Stream<List<Race>> watchRaces(String userId) =>
      Stream.value(savedRace != null ? [savedRace!] : []);
}

class FakePlannedWorkoutRepo implements PlannedWorkoutRepository {
  PlannedWorkout? savedWorkout;

  @override
  Future<String> create(PlannedWorkout workout) async {
    savedWorkout = workout;
    return 'w-123';
  }

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
  group('Phase 37.4: Triathlon-Koppeltraining & A/B/C Wettkampf-Planung', () {
    testWidgets(
        'CreateWorkoutDialog bietet Umschaltung zwischen Training und Wettkampf',
        (tester) async {
      final fakeRaceRepo = FakeRaceRepo();
      final fakeWorkoutRepo = FakePlannedWorkoutRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            raceRepositoryProvider.overrideWithValue(fakeRaceRepo),
            plannedWorkoutRepositoryProvider.overrideWithValue(fakeWorkoutRepo),
            authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateWorkoutDialog(athleteId: 'ath-test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Standardmäßig im Trainings-Modus
      expect(find.byKey(const Key('planner_mode_training')), findsOneWidget);
      expect(find.byKey(const Key('planner_mode_race')), findsOneWidget);

      // Triathlon-Chip ist sichtbar
      expect(find.text('Triathlon / Koppel'), findsOneWidget);

      // Wechsle in Wettkampf-Modus
      await tester.tap(find.byKey(const Key('planner_mode_race')));
      await tester.pumpAndSettle();

      // Wettkampf-Felder müssen sichtbar sein
      expect(find.byKey(const Key('race_title_field')), findsOneWidget);
      expect(find.byKey(const Key('race_distance_field')), findsOneWidget);
      expect(find.byKey(const Key('race_priority_A')), findsOneWidget);
      expect(find.byKey(const Key('race_priority_B')), findsOneWidget);
      expect(find.byKey(const Key('race_priority_C')), findsOneWidget);
      expect(find.byKey(const Key('race_save_button')), findsOneWidget);

      // Speichere Wettkampf
      await tester.ensureVisible(find.byKey(const Key('race_save_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('race_save_button')));
      await tester.pumpAndSettle();

      // Verifiziere Speicherung in beiden Repositories
      expect(fakeRaceRepo.savedRace, isNotNull);
      expect(fakeRaceRepo.savedRace!.title, equals('Saison-Wettkampf'));
      expect(fakeRaceRepo.savedRace!.priority, equals(RacePriority.a));

      expect(fakeWorkoutRepo.savedWorkout, isNotNull);
      expect(fakeWorkoutRepo.savedWorkout!.title,
          contains('A-WETTKAMPF: Saison-Wettkampf'));
    });
  });
}
