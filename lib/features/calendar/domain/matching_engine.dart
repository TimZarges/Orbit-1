import '../../activities/models/activity.dart';
import '../models/planned_workout.dart';
import '../models/workout_match_result.dart';

/// Sportwissenschaftlicher Zuordnungs-Algorithmus zwischen absolvierten Aktivitäten und geplanten Trainingseinheiten (Soll-Ist).
class MatchingEngine {
  /// Mindest-Score für einen automatischen Match.
  static const int autoMatchThreshold = 70;

  /// Mindest-Score, ab dem ein Kandidat als mehrdeutig/plausibel gelistet wird.
  static const int candidateThreshold = 45;

  /// Führt den Soll-Ist-Abgleich für eine gegebene [activity] gegen eine Liste von [plans] aus.
  ///
  /// Bewertungskriterien:
  /// - Gleicher `localDate`
  /// - Status des Plans ist `PLANNED`
  /// - Sportarten-Kompatibilität (exakt = 40 Pkt., Multisport = 25 Pkt.)
  /// - Dauernähe (bis zu 40 Pkt.)
  /// - Distanznähe / Titelnähe (bis zu 20 Pkt.)
  static WorkoutMatchResult matchActivityToPlan({
    required Activity activity,
    required List<PlannedWorkout> plans,
  }) {
    // 1. Kandidaten für denselben Tag vorfiltern, die noch offen sind
    final sameDayPlans = plans.where((p) {
      return p.localDate == activity.localDate && p.isPlanned;
    }).toList();

    if (sameDayPlans.isEmpty) {
      return const WorkoutMatchResult(status: WorkoutMatchStatus.noMatch);
    }

    final List<PlannedWorkoutCandidate> scoredCandidates = [];

    for (final plan in sameDayPlans) {
      final scoreData = _calculateScore(activity, plan);
      if (scoreData.score >= candidateThreshold) {
        scoredCandidates.add(PlannedWorkoutCandidate(
          workout: plan,
          score: scoreData.score,
          reason: scoreData.reason,
        ));
      }
    }

    if (scoredCandidates.isEmpty) {
      return const WorkoutMatchResult(status: WorkoutMatchStatus.noMatch);
    }

    // Nach Score absteigend sortieren
    scoredCandidates.sort((a, b) => b.score.compareTo(a.score));

    final bestCandidate = scoredCandidates.first;

    // Eindeutiger Treffer: Genau 1 Kandidat >= autoMatchThreshold ODER bester Kandidat hat mindestens 20 Punkte Vorsprung
    final isClearWinner = scoredCandidates.length == 1 ||
        (scoredCandidates.length > 1 && (bestCandidate.score - scoredCandidates[1].score >= 25));

    if (bestCandidate.score >= autoMatchThreshold && isClearWinner) {
      return WorkoutMatchResult(
        status: WorkoutMatchStatus.autoMatch,
        matchedWorkout: bestCandidate.workout,
        candidateRankings: scoredCandidates,
      );
    }

    // Mehrdeutig: Mehrere Kandidaten mit ähnlicher Punktzahl
    return WorkoutMatchResult(
      status: WorkoutMatchStatus.ambiguous,
      candidateRankings: scoredCandidates,
    );
  }

  /// Berechnet den Zuordnungs-Score (0 bis 100) zwischen einer Aktivität und einem Plan.
  static ({int score, String reason}) _calculateScore(Activity activity, PlannedWorkout plan) {
    int totalScore = 0;
    final reasons = <String>[];

    // A. Sportarten-Kompatibilität (max. 40 Punkte)
    if (activity.sport == plan.sport) {
      totalScore += 40;
      reasons.add('Gleiche Sportart (${plan.sport})');
    } else if (plan.sport == 'MULTISPORT' || activity.sport == 'MULTISPORT') {
      totalScore += 25;
      reasons.add('Multisport-Kompatibilität');
    } else {
      // Komplett inkompatible Sportarten (z. B. Schwimmen vs. Rad) -> Ausschluss
      return (score: 0, reason: 'Inkompatible Sportart');
    }

    // B. Dauerplausibilität (max. 40 Punkte)
    if (plan.plannedDurationSec > 0 && activity.durationSec > 0) {
      final ratio = activity.durationSec / plan.plannedDurationSec;

      // Verhältnis außerhalb von 0.4 bis 2.5 gilt als Ausreißer
      if (ratio < 0.4 || ratio > 2.5) {
        return (score: 0, reason: 'Dauer weicht extrem ab (${(ratio * 100).toStringAsFixed(0)}%)');
      }

      final diff = (1.0 - ratio).abs();
      if (diff <= 0.05) {
        totalScore += 40;
        reasons.add('Dauer exakt getroffen (±5%)');
      } else if (diff <= 0.15) {
        totalScore += 35;
        reasons.add('Dauer sehr nah (±15%)');
      } else if (diff <= 0.30) {
        totalScore += 25;
        reasons.add('Dauer im Rahmen (±30%)');
      } else if (diff <= 0.50) {
        totalScore += 15;
        reasons.add('Dauer mit Abweichung (±50%)');
      } else {
        totalScore += 5;
        reasons.add('Dauer grob passend');
      }
    }

    // C. Distanz / Titel-Übereinstimmung (max. 20 Punkte)
    if (plan.plannedDistanceM != null && plan.plannedDistanceM! > 0 && activity.distanceM > 0) {
      final distRatio = activity.distanceM / plan.plannedDistanceM!;
      final distDiff = (1.0 - distRatio).abs();
      if (distDiff <= 0.10) {
        totalScore += 20;
        reasons.add('Distanz nahezu identisch');
      } else if (distDiff <= 0.25) {
        totalScore += 12;
        reasons.add('Distanz ähnlich');
      }
    } else if (activity.title.toLowerCase().contains(plan.title.toLowerCase())) {
      totalScore += 15;
      reasons.add('Titel-Übereinstimmung');
    }

    return (
      score: totalScore.clamp(0, 100),
      reason: reasons.join(', '),
    );
  }
}
