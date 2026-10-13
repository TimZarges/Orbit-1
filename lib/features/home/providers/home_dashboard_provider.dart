import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/home_dashboard_data.dart';
import '../models/race_goal.dart';
import '../../calendar/models/planned_workout.dart';
import '../../activities/models/activity.dart';
import '../../analysis/models/daily_aggregate.dart';
import '../../analysis/domain/form_calculator.dart';
import '../../analysis/models/form_traffic_light.dart';

/// Gebündelter Provider für das Home-Dashboard („Heute").
/// Führt maximal 4 Firestore-Reads pro Aufruf durch und cacht das Ergebnis.
final homeDashboardProvider = FutureProvider.family<HomeDashboardData, String>((ref, athleteId) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    // 1. Tagesaggregat laden
    final aggDoc = await firestore
        .collection('users')
        .doc(athleteId)
        .collection('aggregates')
        .doc(todayStr)
        .get();
    final todayAgg = aggDoc.exists ? DailyAggregate.fromDocument(aggDoc) : null;

    // 2. Heutiges geplantes Workout laden
    final planSnap = await firestore
        .collection('plannedWorkouts')
        .where('athleteId', isEqualTo: athleteId)
        .where('localDate', isEqualTo: todayStr)
        .limit(1)
        .get();
    final todayPlan = planSnap.docs.isNotEmpty ? PlannedWorkout.fromDocument(planSnap.docs.first) : null;

    // 3. Letzte Aktivität laden
    final actSnap = await firestore
        .collection('activities')
        .where('athleteId', isEqualTo: athleteId)
        .orderBy('startTimeUtc', descending: true)
        .limit(1)
        .get();
    final latestAct = actSnap.docs.isNotEmpty ? Activity.fromFirestore(actSnap.docs.first) : null;

    // 4. Offene Schwellenwert-Vorschläge zählen
    final propSnap = await firestore
        .collection('users')
        .doc(athleteId)
        .collection('thresholdProposals')
        .where('status', isEqualTo: 'PENDING')
        .get();
    final pendingPropsCount = propSnap.docs.length;

    // 5. User-Doc für RaceGoal & Unread Messages laden
    final userDoc = await firestore.collection('users').doc(athleteId).get();
    final userData = userDoc.data() ?? {};
    final isDemo = userData['demo']?['enabled'] == true;

    RaceGoal? raceGoal;
    if (userData['profile']?['raceGoal'] != null) {
      raceGoal = RaceGoal.fromMap(Map<String, dynamic>.from(userData['profile']['raceGoal'] as Map));
    }

    // Form-Ampel berechnen, falls Aggregate vorliegen
    FormTrafficLight? formLight;
    if (todayAgg != null && (todayAgg.ctl > 0 || todayAgg.tsb != 0)) {
      formLight = const FormCalculator().calculate(
        ctl: todayAgg.ctl,
        tsb: todayAgg.tsb,
        recordedDaysCount: 28,
      );
    }

    final isBrandNew = !aggDoc.exists && planSnap.docs.isEmpty && actSnap.docs.isEmpty;

    return HomeDashboardData(
      todayLocalDate: todayStr,
      todayAggregate: todayAgg,
      todayPlannedWorkout: todayPlan,
      latestActivity: latestAct,
      pendingThresholdProposalsCount: pendingPropsCount,
      formTrafficLight: formLight,
      raceGoal: raceGoal,
      isDemo: isDemo,
      isBrandNewUser: isBrandNew,
    );
  } catch (e) {
    // Fallback für Demo- oder Offline-Modus
    return HomeDashboardData(
      todayLocalDate: todayStr,
      isBrandNewUser: false,
      isDemo: true,
      todayPlannedWorkout: PlannedWorkout(
        id: 'plan_demo',
        athleteId: athleteId,
        createdBy: athleteId,
        localDate: todayStr,
        sport: 'BIKE',
        title: '4x4min Schwellenintervalle Rad',
        description: 'Warmup 15 min, 4x 4 min Z4 mit 2 min Pause, Ausrollen 15 min.',
        plannedDurationSec: 3600,
        plannedLoad: 68.0,
        status: PlannedWorkoutStatus.planned,
        createdAt: now,
      ),
      raceGoal: RaceGoal(
        title: 'Ironman 70.3 Kraichgau',
        date: '${now.year}-06-15',
        distance: 'Mitteldistanz',
      ),
      formTrafficLight: const FormCalculator().calculate(
        ctl: 58.0,
        tsb: -8.0,
        recordedDaysCount: 42,
      ),
    );
  }
});
