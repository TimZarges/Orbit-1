import '../../calendar/models/planned_workout.dart';

/// Art der Aktion für Undo-Fähigkeit
enum GridActionType {
  move,
  copy,
  delete,
}

/// Dokumentierte Gitter-Aktion zur Rückgängigmachung (Undo).
class GridAction {
  final GridActionType type;
  final PlannedWorkout previousState;
  final PlannedWorkout? newState;

  const GridAction({
    required this.type,
    required this.previousState,
    this.newState,
  });
}

/// Reine Domänen- und Steuerlogik für das Mehrathleten-Wochenraster und Drag & Drop.
class MultiAthleteGridController {
  final List<GridAction> _undoStack = [];

  List<GridAction> get undoStack => List.unmodifiable(_undoStack);
  bool get canUndo => _undoStack.isNotEmpty;

  /// Berechnet das Ergebnis einer Drag-&-Drop-Verschiebung oder Kopie (bei gehaltener Alt/Option-Taste).
  PlannedWorkout handleDrop({
    required PlannedWorkout workout,
    required String targetAthleteId,
    required String targetDate,
    required bool isCopy,
    required String coachId,
  }) {
    final now = DateTime.now();

    if (isCopy) {
      // Neue Kopie erstellen
      final copied = PlannedWorkout(
        id: 'copy_${now.millisecondsSinceEpoch}_${workout.id}',
        athleteId: targetAthleteId,
        coachId: coachId,
        createdBy: coachId,
        localDate: targetDate,
        sport: workout.sport,
        title: workout.title,
        description: workout.description,
        structure: workout.structure,
        plannedDurationSec: workout.plannedDurationSec,
        plannedDistanceM: workout.plannedDistanceM,
        plannedLoad: workout.plannedLoad,
        status: PlannedWorkoutStatus.planned,
        createdAt: now,
        updatedAt: now,
      );

      _undoStack.add(GridAction(
        type: GridActionType.copy,
        previousState: workout,
        newState: copied,
      ));

      return copied;
    } else {
      // Bestehendes Workout verschieben
      final moved = PlannedWorkout(
        id: workout.id,
        athleteId: targetAthleteId,
        coachId: workout.coachId ?? coachId,
        createdBy: workout.createdBy,
        localDate: targetDate,
        sport: workout.sport,
        title: workout.title,
        description: workout.description,
        structure: workout.structure,
        plannedDurationSec: workout.plannedDurationSec,
        plannedDistanceM: workout.plannedDistanceM,
        plannedLoad: workout.plannedLoad,
        status: workout.status,
        createdAt: workout.createdAt,
        updatedAt: now,
      );

      _undoStack.add(GridAction(
        type: GridActionType.move,
        previousState: workout,
        newState: moved,
      ));

      return moved;
    }
  }

  /// Nimmt die letzte Gitter-Aktion zurück.
  GridAction? popUndo() {
    if (_undoStack.isEmpty) return null;
    return _undoStack.removeLast();
  }
}
