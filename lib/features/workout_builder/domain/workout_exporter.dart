import '../models/workout_builder_models.dart';

/// Platzhalter-Interface für den Export strukturierter Trainingseinheiten
/// (z. B. Garmin FIT Workout, Zwift ZWO, MRC/ERG).
/// Gemäß Phase 09 Spezifikation nur als Schnittstellendefinition angelegt.
abstract class WorkoutExporter {
  /// Exportiert die Struktur in ein Byte-Array (z. B. FIT-Binary).
  Future<List<int>> exportToFit(WorkoutStructure structure);

  /// Exportiert die Struktur in ein Textformat (z. B. ZWO-XML).
  Future<String> exportToZwo(WorkoutStructure structure);
}

/// Dummy-Implementierung als Platzhalter für zukünftige Phasen.
class PlaceholderWorkoutExporter implements WorkoutExporter {
  const PlaceholderWorkoutExporter();

  @override
  Future<List<int>> exportToFit(WorkoutStructure structure) async {
    throw UnimplementedError(
        'FIT-Export wird in einer späteren Phase umgesetzt.');
  }

  @override
  Future<String> exportToZwo(WorkoutStructure structure) async {
    throw UnimplementedError(
        'ZWO-Export wird in einer späteren Phase umgesetzt.');
  }
}
