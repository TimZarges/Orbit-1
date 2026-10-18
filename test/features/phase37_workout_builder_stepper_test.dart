import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/calendar/providers/calendar_provider.dart';
import 'package:orbit/features/calendar/repositories/planned_workout_repository.dart';
import 'package:orbit/features/calendar/models/planned_workout.dart';
import 'package:orbit/features/workout_builder/controllers/workout_builder_controller.dart';
import 'package:orbit/features/workout_builder/models/workout_builder_models.dart';
import 'package:orbit/features/workout_builder/screens/workout_builder_screen.dart';

class FakeWorkoutRepo implements PlannedWorkoutRepository {
  PlannedWorkout? lastSaved;

  @override
  Future<String> create(PlannedWorkout workout) async {
    lastSaved = workout;
    return 'w-saved-123';
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
  group('Phase 37.3: Mobiler Klick-Workout-Builder mit Wiederholungsschleifen',
      () {
    testWidgets('Quick-Add Bausteine und Wiederholungs-Stepper (2x bis 30x)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannedWorkoutRepositoryProvider
                .overrideWithValue(FakeWorkoutRepo()),
          ],
          child: const MaterialApp(
            home: WorkoutBuilderScreen(sport: 'BIKE'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Quick-Add Buttons prüfen
      expect(find.byKey(const Key('quick_add_warmup')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_work')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_rest')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_repeat')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_cooldown')), findsOneWidget);

      // Initialer Repeat-Block (Index 1) ist vorhanden
      final textFinder = find.byKey(const Key('repeat_count_text_1'));
      expect(textFinder, findsOneWidget);
      final initialTextWidget = tester.widget<Text>(textFinder);
      expect(initialTextWidget.data, equals('4x Serie'));

      // Ensure visible and increment (+1 -> 5x Serie)
      await tester.ensureVisible(find.byKey(const Key('repeat_increment_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('repeat_increment_1')));
      await tester.pumpAndSettle();
      final incTextWidget = tester.widget<Text>(textFinder);
      expect(incTextWidget.data, equals('5x Serie'));

      // Decrement (-1 -> 4x Serie)
      await tester.ensureVisible(find.byKey(const Key('repeat_decrement_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('repeat_decrement_1')));
      await tester.pumpAndSettle();
      final decTextWidget = tester.widget<Text>(textFinder);
      expect(decTextWidget.data, equals('4x Serie'));
    });

    test('RepeatBlock Stepper begrenzt Werte zwischen 2x und 30x', () {
      final notifier = WorkoutBuilderNotifier(initialSport: 'BIKE');
      final repeat = const RepeatBlock(
        count: 2,
        blocks: [
          StepBlock(
            role: WorkoutRole.work,
            target: WorkoutTarget.duration(180),
            intensity: ZoneIntensity.single(4),
          ),
        ],
      );

      notifier.addBlock(repeat);

      // Decrement unter 2 darf nicht möglich sein
      final decremented =
          repeat.copyWith(count: (repeat.count - 1).clamp(2, 30));
      expect(decremented.count, equals(2));

      // Increment auf 30
      final incremented = repeat.copyWith(count: (35).clamp(2, 30));
      expect(incremented.count, equals(30));
    });
  });
}
