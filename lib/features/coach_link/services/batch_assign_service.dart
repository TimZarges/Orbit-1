import 'package:cloud_firestore/cloud_firestore.dart';
import '../../workout_builder/models/workout_template.dart';

/// Ergebnis der Massenzuweisung von Trainingseinheiten.
class BatchAssignResult {
  final int successCount;
  final int failureCount;
  final List<String> errorMessages;

  const BatchAssignResult({
    required this.successCount,
    required this.failureCount,
    this.errorMessages = const [],
  });
}

/// Service zur Massenzuweisung von Workouts an mehrere Athleten (`Batch-Writes`).
class BatchAssignService {
  final FirebaseFirestore _firestore;

  BatchAssignService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Weist eine Workout-Vorlage an mehrere Athleten zu.
  /// Nutzt atomare Firestore `WriteBatch` (maximal 500 Operationen pro Batch).
  Future<BatchAssignResult> assignTemplateToAthletes({
    required String coachId,
    required List<String> athleteIds,
    required WorkoutTemplate template,
    required String targetLocalDate,
  }) async {
    if (athleteIds.isEmpty) {
      return const BatchAssignResult(successCount: 0, failureCount: 0);
    }

    final errors = <String>[];
    int success = 0;
    int failure = 0;

    // Batches in Chunks von maximal 450 aufteilen
    const chunkSize = 450;
    for (var i = 0; i < athleteIds.length; i += chunkSize) {
      final chunk = athleteIds.sublist(
          i,
          i + chunkSize > athleteIds.length
              ? athleteIds.length
              : i + chunkSize);
      final batch = _firestore.batch();

      for (final athleteId in chunk) {
        try {
          final workoutDocRef = _firestore.collection('plannedWorkouts').doc();
          final now = DateTime.now();

          final plannedWorkout = {
            'athleteId': athleteId,
            'coachId': coachId,
            'createdBy': coachId,
            'localDate': targetLocalDate,
            'sport': template.sport,
            'title': template.title,
            'structure': template.structure.toJson(),
            'plannedDurationSec': 3600,
            'plannedLoad': 50.0,
            'status': 'PLANNED',
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          };

          batch.set(workoutDocRef, plannedWorkout);
          success++;
        } catch (e) {
          failure++;
          errors.add('Fehler bei Athlet $athleteId: $e');
        }
      }

      await batch.commit();
    }

    return BatchAssignResult(
      successCount: success,
      failureCount: failure,
      errorMessages: errors,
    );
  }
}
