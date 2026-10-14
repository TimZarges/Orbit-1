import 'package:intl/intl.dart';
import '../models/planned_workout.dart';
import '../repositories/planned_workout_repository.dart';

/// Seeder für realistische geplante Trainingseinheiten im Demo-Modus.
class CalendarDemoSeeder {
  /// Schreibt realistische geplante Einheiten für den Athleten [athleteId] in Firestore.
  static Future<void> seedDemoWorkoutsForAthlete(String athleteId,
      {String? coachId}) async {
    final now = DateTime.now();
    final repo = PlannedWorkoutRepository();

    final List<PlannedWorkout> demoList = [
      // 1. Vor 3 Tagen: Abgeschlossener Dauerlauf
      PlannedWorkout(
        id: '',
        athleteId: athleteId,
        coachId: coachId,
        createdBy: athleteId,
        localDate: DateFormat('yyyy-MM-dd')
            .format(now.subtract(const Duration(days: 3))),
        sport: 'RUN',
        title: 'GA1 Grundlagendauerlauf',
        description: 'Lockerer Lauf im aeroben Bereich, HF < 145 bpm.',
        plannedDurationSec: 3600,
        plannedDistanceM: 10000,
        plannedLoad: 52,
        intensity: 'MODERATE',
        status: 'COMPLETED',
      ),

      // 2. Vor 2 Tagen: Ausgefallene / übersprungene Einheit
      PlannedWorkout(
        id: '',
        athleteId: athleteId,
        coachId: coachId,
        createdBy: coachId ?? athleteId,
        localDate: DateFormat('yyyy-MM-dd')
            .format(now.subtract(const Duration(days: 2))),
        sport: 'STRENGTH',
        title: 'Rumpfstabilität & Kraftzirkel',
        description: '3 Durchgänge Rumpf & Beine.',
        plannedDurationSec: 2700,
        plannedLoad: 35,
        intensity: 'EASY',
        status: 'SKIPPED',
      ),

      // 3. Gestern: Abgeschlossene Radeinheit
      PlannedWorkout(
        id: '',
        athleteId: athleteId,
        coachId: coachId,
        createdBy: coachId ?? athleteId,
        localDate: DateFormat('yyyy-MM-dd')
            .format(now.subtract(const Duration(days: 1))),
        sport: 'BIKE',
        title: 'Rad Grundlagenausdauer',
        description: 'Gleichmäßiges Kurbeln, 85-95 rpm Trittfrequenz.',
        plannedDurationSec: 5400,
        plannedDistanceM: 42000,
        plannedLoad: 75,
        intensity: 'MODERATE',
        status: 'COMPLETED',
      ),

      // 4. Heute: Geplanter Lauf
      PlannedWorkout(
        id: '',
        athleteId: athleteId,
        coachId: coachId,
        createdBy: athleteId,
        localDate: DateFormat('yyyy-MM-dd').format(now),
        sport: 'RUN',
        title: 'Lauf Tempowechsel / Fahrtspiel',
        description:
            '15 min Einlaufen, 6x 2 min flott mit 2 min Trabpause, 15 min Auslaufen.',
        plannedDurationSec: 3600,
        plannedDistanceM: 9500,
        plannedLoad: 65,
        intensity: 'HARD',
        status: 'PLANNED',
      ),

      // 5. Morgen: Geplantes Schwimmen (vom Coach geplant)
      PlannedWorkout(
        id: '',
        athleteId: athleteId,
        coachId: coachId,
        createdBy: coachId ?? 'coach_sample',
        localDate:
            DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1))),
        sport: 'SWIM',
        title: 'Schwimmen Technik & CSS-Intervalle',
        description: 'Fokus auf hohen Ellenbogen und Wassergefühl.',
        plannedDurationSec: 2700,
        plannedDistanceM: 2200,
        plannedLoad: 45,
        intensity: 'MODERATE',
        status: 'PLANNED',
      ),

      // 6. In 2 Tagen: Lange Radeinheit
      PlannedWorkout(
        id: '',
        athleteId: athleteId,
        coachId: coachId,
        createdBy: coachId ?? athleteId,
        localDate:
            DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 2))),
        sport: 'BIKE',
        title: 'Lange Ausfahrt GA1/GA2',
        description: 'Verpflegung im 20-Minuten-Takt üben.',
        plannedDurationSec: 9000,
        plannedDistanceM: 75000,
        plannedLoad: 110,
        intensity: 'MODERATE',
        status: 'PLANNED',
      ),

      // 7. In 3 Tagen: Ruhetag / Erholung
      PlannedWorkout(
        id: '',
        athleteId: athleteId,
        coachId: coachId,
        createdBy: athleteId,
        localDate:
            DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 3))),
        sport: 'OTHER',
        title: 'Aktive Regeneration & Mobility',
        description: 'Faszienrolle und leichtes Dehnen.',
        plannedDurationSec: 1800,
        plannedLoad: 15,
        intensity: 'EASY',
        status: 'PLANNED',
      ),
    ];

    for (final workout in demoList) {
      await repo.create(workout);
    }
  }
}
