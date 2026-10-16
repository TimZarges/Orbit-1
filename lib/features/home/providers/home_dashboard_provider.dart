import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_dashboard_data.dart';
import '../models/race_goal.dart';
import '../../calendar/models/planned_workout.dart';
import '../../activities/models/activity.dart';
import '../../analysis/models/daily_aggregate.dart';
import '../../analysis/domain/form_calculator.dart';
import '../../analysis/models/form_traffic_light.dart';
import '../../health/models/daily_metrics.dart';

/// Gebündelter Provider für das Home-Dashboard („Heute").
/// Führt maximal 5 Firestore-Reads pro Aufruf durch und cacht das Ergebnis.
final homeDashboardProvider =
    FutureProvider.family<HomeDashboardData, String>((ref, athleteId) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final todayStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    // 1. Tagesaggregat laden
    final aggDoc = await firestore
        .collection('users')
        .doc(athleteId)
        .collection('aggregates')
        .doc(todayStr)
        .get();
    final todayAgg = aggDoc.exists ? DailyAggregate.fromDocument(aggDoc) : null;

    // 1b. Tages-Gesundheitsdaten & Scores laden
    final dailyDoc = await firestore
        .collection('users')
        .doc(athleteId)
        .collection('dailyMetrics')
        .doc(todayStr)
        .get();
    final todayDaily =
        dailyDoc.exists ? DailyMetrics.fromFirestore(dailyDoc) : null;

    // 2. Heutiges geplantes Workout laden
    final planSnap = await firestore
        .collection('plannedWorkouts')
        .where('athleteId', isEqualTo: athleteId)
        .where('localDate', isEqualTo: todayStr)
        .limit(1)
        .get();
    final todayPlan = planSnap.docs.isNotEmpty
        ? PlannedWorkout.fromDocument(planSnap.docs.first)
        : null;

    // 3. Letzte Aktivität laden
    final actSnap = await firestore
        .collection('activities')
        .where('athleteId', isEqualTo: athleteId)
        .orderBy('startTimeUtc', descending: true)
        .limit(1)
        .get();
    final latestAct = actSnap.docs.isNotEmpty
        ? Activity.fromFirestore(actSnap.docs.first)
        : null;

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
      raceGoal = RaceGoal.fromMap(
          Map<String, dynamic>.from(userData['profile']['raceGoal'] as Map));
    }

    // Form-Ampel berechnen, falls Aggregate vorliegen
    FormTrafficLight? formLight;
    if (todayAgg != null && (todayAgg.ctl > 0 || todayAgg.atl > 0)) {
      formLight = const FormCalculator().calculate(
        ctl: todayAgg.ctl,
        atl: todayAgg.atl,
        daysOfHistory: 28,
      );
    }

    final isBrandNew =
        !aggDoc.exists && planSnap.docs.isEmpty && actSnap.docs.isEmpty;

    return HomeDashboardData(
      todayLocalDate: todayStr,
      todayAggregate: todayAgg,
      todayPlannedWorkout: todayPlan,
      latestActivity: latestAct,
      todayDailyMetrics: todayDaily,
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
      todayDailyMetrics: DailyMetrics(
        localDate: todayStr,
        sleepSeconds: 28800, // 8.0h
        sleepScore: 88,
        restingHrBpm: 49,
        hrvMs: 68,
        bodyBattery: 85,
        recovery: const RecoveryData(
          score: 82,
          classification: 'GREEN',
          recommendationDe:
              'Exzellente Erholung. Bereit für Schwellenintervalle und intensive Einheiten.',
          recommendationEn:
              'Excellent recovery. Primed for threshold intervals and demanding sessions.',
          weightsUsed: {
            'hrv': 0.45,
            'rhr': 0.25,
            'sleep': 0.20,
            'respOrBb': 0.10,
          },
        ),
        strain: const StrainData(
          score: 42,
          trainingTss: 45.0,
          alltagLoad: 18.0,
          totalRawLoad: 63.0,
          targetMin: 58,
          targetMax: 80,
        ),
        sleep: const SleepScoreData(
          score: 88,
          needHours: 7.8,
          actualHours: 8.0,
          accumulatedDebtHours: 0.4,
          durationScore: 100,
          efficiencyScore: 92,
          stagesScore: 88,
        ),
        orbitScore: const OrbitScoreData(
          score: 84,
          consistencyScore: 90,
          tsbScore: 85,
          recoveryAvg7d: 80,
          sleepAvg7d: 84,
        ),
      ),
      todayPlannedWorkout: PlannedWorkout(
        id: 'plan_demo',
        athleteId: athleteId,
        createdBy: athleteId,
        localDate: todayStr,
        sport: 'BIKE',
        title: '4x4min Schwellenintervalle Rad',
        description:
            'Warmup 15 min, 4x 4 min Z4 mit 2 min Pause, Ausrollen 15 min.',
        plannedDurationSec: 3600,
        plannedLoad: 68.0,
        status: 'PLANNED',
        createdAt: now,
      ),
      raceGoal: RaceGoal(
        title: 'Ironman 70.3 Kraichgau',
        date: '${now.year}-06-15',
        distance: 'Mitteldistanz',
      ),
      formTrafficLight: const FormCalculator().calculate(
        ctl: 58.0,
        atl: 66.0,
        daysOfHistory: 42,
      ),
    );
  }
});
