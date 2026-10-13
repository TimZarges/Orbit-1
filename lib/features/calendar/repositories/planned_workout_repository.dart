import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/planned_workout.dart';

/// Repository für den Zugriff auf geplante Trainingseinheiten (`plannedWorkouts`).
class PlannedWorkoutRepository {
  final FirebaseFirestore _firestore;

  PlannedWorkoutRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('plannedWorkouts');

  /// Erstellt eine neue geplante Trainingseinheit.
  Future<String> create(PlannedWorkout workout) async {
    final docRef = workout.id.isNotEmpty ? _collection.doc(workout.id) : _collection.doc();
    final toSave = workout.id.isNotEmpty ? workout : workout.copyWith(id: docRef.id);
    await docRef.set(toSave.toMap());
    return docRef.id;
  }

  /// Aktualisiert eine bestehende geplante Einheit.
  Future<void> update(PlannedWorkout workout) async {
    await _collection.doc(workout.id).update(workout.toMap());
  }

  /// Löscht eine geplante Einheit.
  Future<void> delete(String workoutId) async {
    await _collection.doc(workoutId).delete();
  }

  /// Markiert eine Einheit als übersprungen (SKIPPED).
  Future<void> markSkipped(String workoutId) async {
    await _collection.doc(workoutId).update({
      'status': 'SKIPPED',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Setzt eine Einheit wieder auf offen (PLANNED).
  Future<void> markPlanned(String workoutId) async {
    await _collection.doc(workoutId).update({
      'status': 'PLANNED',
      'activityId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verknüpft eine absolvierte Aktivität mit einem geplanten Workout (Soll-Ist Match).
  Future<void> linkActivity({
    required String workoutId,
    required String activityId,
    String matchStatus = 'AUTO',
  }) async {
    final batch = _firestore.batch();

    // 1. Planned Workout aktualisieren
    final workoutRef = _collection.doc(workoutId);
    batch.update(workoutRef, {
      'status': 'COMPLETED',
      'activityId': activityId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Activity aktualisieren
    final activityRef = _firestore.collection('activities').doc(activityId);
    batch.update(activityRef, {
      'plannedWorkoutId': workoutId,
      'matchStatus': matchStatus,
    });

    await batch.commit();
  }

  /// Löst die Verknüpfung zwischen Aktivität und Planned Workout wieder auf.
  Future<void> unlinkActivity({
    required String workoutId,
    required String activityId,
  }) async {
    final batch = _firestore.batch();

    // 1. Planned Workout zurücksetzen auf PLANNED
    final workoutRef = _collection.doc(workoutId);
    batch.update(workoutRef, {
      'status': 'PLANNED',
      'activityId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Activity auf UNMATCHED setzen
    final activityRef = _firestore.collection('activities').doc(activityId);
    batch.update(activityRef, {
      'plannedWorkoutId': FieldValue.delete(),
      'matchStatus': 'UNMATCHED',
    });

    await batch.commit();
  }

  /// Verschiebt eine geplante Einheit auf ein neues Datum (`localDate`).
  Future<void> reschedule({
    required String workoutId,
    required String newLocalDate,
  }) async {
    await _collection.doc(workoutId).update({
      'localDate': newLocalDate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streamt alle geplanten Einheiten eines Athleten in einem Datumsintervall (`startDate` bis `endDate`).
  Stream<List<PlannedWorkout>> watchWorkoutsForAthlete({
    required String athleteId,
    required String startDate,
    required String endDate,
  }) {
    return _collection
        .where('athleteId', isEqualTo: athleteId)
        .where('localDate', isGreaterThanOrEqualTo: startDate)
        .where('localDate', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PlannedWorkout.fromFirestore(doc)).toList()
        ..sort((a, b) => a.localDate.compareTo(b.localDate));
    });
  }
}
