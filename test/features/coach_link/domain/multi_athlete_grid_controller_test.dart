import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/coach_link/domain/multi_athlete_grid_controller.dart';
import 'package:orbit/features/calendar/models/planned_workout.dart';

void main() {
  group('MultiAthleteGridController Tests', () {
    late MultiAthleteGridController controller;
    late PlannedWorkout testWorkout;

    setUp(() {
      controller = MultiAthleteGridController();
      testWorkout = PlannedWorkout(
        id: 'w1',
        athleteId: 'ath1',
        coachId: 'coachA',
        createdBy: 'coachA',
        localDate: '2026-10-14',
        sport: 'BIKE',
        title: '2h Grundlagenausdauer',
        plannedDurationSec: 7200,
        plannedLoad: 90.0,
        status: 'PLANNED',
        createdAt: DateTime(2026, 10, 1),
      );
    });

    test('Moving a workout changes targetAthleteId and targetDate with same ID',
        () {
      final moved = controller.handleDrop(
        workout: testWorkout,
        targetAthleteId: 'ath2',
        targetDate: '2026-10-16',
        isCopy: false,
        coachId: 'coachA',
      );

      expect(moved.id, equals('w1'));
      expect(moved.athleteId, equals('ath2'));
      expect(moved.localDate, equals('2026-10-16'));
      expect(moved.title, equals(testWorkout.title));

      expect(controller.canUndo, isTrue);
      expect(controller.undoStack.last.type, equals(GridActionType.move));
    });

    test('Alt-drag copying creates a duplicate with a new ID', () {
      final copied = controller.handleDrop(
        workout: testWorkout,
        targetAthleteId: 'ath3',
        targetDate: '2026-10-18',
        isCopy: true,
        coachId: 'coachA',
      );

      expect(copied.id, isNot(equals('w1')));
      expect(copied.id, startsWith('copy_'));
      expect(copied.athleteId, equals('ath3'));
      expect(copied.localDate, equals('2026-10-18'));
      expect(copied.plannedLoad, equals(90.0));

      expect(controller.canUndo, isTrue);
      expect(controller.undoStack.last.type, equals(GridActionType.copy));
    });

    test('Undo pops the last action from the stack', () {
      controller.handleDrop(
        workout: testWorkout,
        targetAthleteId: 'ath2',
        targetDate: '2026-10-15',
        isCopy: false,
        coachId: 'coachA',
      );

      expect(controller.canUndo, isTrue);
      final undoneAction = controller.popUndo();
      expect(undoneAction, isNotNull);
      expect(undoneAction!.type, equals(GridActionType.move));
      expect(undoneAction.previousState.id, equals('w1'));
      expect(controller.canUndo, isFalse);
    });
  });
}
