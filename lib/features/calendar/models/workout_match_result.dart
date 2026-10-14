import 'planned_workout.dart';

/// Art des Zuordnungs-Ergebnisses zwischen einer realen Aktivität und geplanten Workouts.
enum WorkoutMatchStatus {
  /// Genau ein passender Plan mit hoher Konfidenz (automatisch zuordenbar).
  autoMatch,

  /// Mehrere mögliche Kandidaten oder niedrige Konfidenz (manuelle Bestätigung empfohlen).
  ambiguous,

  /// Kein plausibler Plan gefunden (Aktivität ist eine Zusatzeinheit).
  noMatch,
}

/// Ergebnis der Soll-Ist-Zuordnungsanalyse.
class WorkoutMatchResult {
  final WorkoutMatchStatus status;
  final PlannedWorkout? matchedWorkout;
  final List<PlannedWorkoutCandidate> candidateRankings;

  const WorkoutMatchResult({
    required this.status,
    this.matchedWorkout,
    this.candidateRankings = const [],
  });

  bool get isAutoMatch =>
      status == WorkoutMatchStatus.autoMatch && matchedWorkout != null;
  bool get isAmbiguous => status == WorkoutMatchStatus.ambiguous;
  bool get isNoMatch => status == WorkoutMatchStatus.noMatch;
}

/// Ein bewerteter Planungskandidat mit Zuordnungs-Score.
class PlannedWorkoutCandidate {
  final PlannedWorkout workout;
  final int score;
  final String reason;

  const PlannedWorkoutCandidate({
    required this.workout,
    required this.score,
    required this.reason,
  });
}
