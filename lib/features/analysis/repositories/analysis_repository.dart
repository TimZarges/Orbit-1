import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_aggregate.dart';
import '../../calendar/models/planned_workout.dart';

/// Repository für Analysedaten und vorberechnete Aggregate.
class AnalysisRepository {
  final FirebaseFirestore _firestore;

  AnalysisRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Lädt vorberechnete Aggregate für einen bestimmten Datumsbereich.
  Future<List<DailyAggregate>> getAggregates({
    required String athleteId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(athleteId)
          .collection('aggregates')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDate)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endDate)
          .get();

      final list =
          snapshot.docs.map((doc) => DailyAggregate.fromDocument(doc)).toList();
      // Sortiere chronologisch aufsteigend
      list.sort((a, b) => a.localDate.compareTo(b.localDate));
      return list;
    } catch (e) {
      // Wenn offline oder keine Berechtigung, leere Liste
      return [];
    }
  }

  /// Lädt das aktuellste Aggregat für die Form-Ampel.
  Future<DailyAggregate?> getLatestAggregate(String athleteId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(athleteId)
          .collection('aggregates')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return DailyAggregate.fromDocument(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Ermittelt die Gesamtzahl erfasster Trainingstage.
  Future<int> getRecordedDaysCount(String athleteId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(athleteId)
          .collection('aggregates')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Lädt geplante Einheiten im Datumsbereich für den Soll-Ist-Vergleich.
  Future<List<PlannedWorkout>> getPlannedWorkouts({
    required String athleteId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('plannedWorkouts')
          .where('athleteId', isEqualTo: athleteId)
          .where('localDate', isGreaterThanOrEqualTo: startDate)
          .where('localDate', isLessThanOrEqualTo: endDate)
          .get();

      return snapshot.docs
          .map((doc) => PlannedWorkout.fromDocument(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Erzeugt konsistente, realistische Demo-Aggregatsdaten (z. B. für Demo-Modus oder Empty-State-Vorschau).
  ///
  /// Bildet einen typischen 12-Wochen-Trainingsaufbau eines Triathleten nach.
  static List<DailyAggregate> generateDemoAggregates({int days = 84}) {
    final list = <DailyAggregate>[];
    final now = DateTime.now();

    double ctl = 32.0;
    double atl = 28.0;

    final random = Random(42); // Fester Seed für deterministische Vorschau

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      // Wochentag (1 = Montag, 7 = Sonntag)
      final weekday = date.weekday;

      // Realistische Tagesbelastung
      double load = 0.0;
      final sports = <String, double>{};
      final zones = List<double>.filled(7, 0.0);
      int activityCount = 0;

      // Typisches Wochenmuster:
      // Mo: Ruhetag
      // Di: Lauf (Tempo)
      // Mi: Schwimmen
      // Do: Rad (Intervalle)
      // Fr: Schwimmen oder Ruhe
      // Sa: Langer Lauf / Koppel
      // So: Lange Radausfahrt
      if (weekday == 1) {
        // Ruhetag
        load = 0;
      } else if (weekday == 2) {
        // Lauf: ca. 60 min, 65 TSS
        load = 60 + random.nextDouble() * 15;
        sports['RUN'] = 3600;
        zones[0] = 600;
        zones[1] = 1800;
        zones[2] = 800;
        zones[3] = 400;
        activityCount = 1;
      } else if (weekday == 3) {
        // Schwimmen: ca. 45 min, 45 TSS
        load = 40 + random.nextDouble() * 10;
        sports['SWIM'] = 2700;
        zones[0] = 400;
        zones[1] = 1500;
        zones[2] = 600;
        zones[3] = 200;
        activityCount = 1;
      } else if (weekday == 4) {
        // Rad: ca. 75 min, 75 TSS
        load = 70 + random.nextDouble() * 15;
        sports['BIKE'] = 4500;
        zones[0] = 600;
        zones[1] = 2400;
        zones[2] = 900;
        zones[3] = 600;
        activityCount = 1;
      } else if (weekday == 5) {
        // Kraft oder lockeres Schwimmen
        load = 30 + random.nextDouble() * 10;
        sports['STRENGTH'] = 2400;
        zones[0] = 1200;
        zones[1] = 1200;
        activityCount = 1;
      } else if (weekday == 6) {
        // Langer Lauf: 90 min, 95 TSS
        load = 90 + random.nextDouble() * 20;
        sports['RUN'] = 5400;
        zones[0] = 600;
        zones[1] = 4200;
        zones[2] = 600;
        activityCount = 1;
      } else if (weekday == 7) {
        // Lange Ausfahrt: 150 min, 140 TSS
        load = 130 + random.nextDouble() * 25;
        sports['BIKE'] = 9000;
        zones[0] = 1200;
        zones[1] = 6600;
        zones[2] = 1200;
        activityCount = 1;
      }

      // Alle 4 Wochen eine Ruhewoche
      final weekIndex = (days - 1 - i) ~/ 7;
      if (weekIndex % 4 == 3) {
        load *= 0.55;
        activityCount = load > 0 ? 1 : 0;
      }

      // Exponentieller gleitender Durchschnitt
      // CTL TC = 42 Tage, ATL TC = 7 Tage
      final aCtl = exp(-1.0 / 42.0);
      final aAtl = exp(-1.0 / 7.0);
      ctl = load * (1.0 - aCtl) + ctl * aCtl;
      atl = load * (1.0 - aAtl) + atl * aAtl;
      final tsb = ctl - atl;

      list.add(DailyAggregate(
        localDate: dateStr,
        dailyLoad: load,
        ctl: ctl,
        atl: atl,
        tsb: tsb,
        orbitScore: 50 + (ctl / 2) - (atl / 4),
        metricsVersion: '1',
        sportsBreakdownSec: sports,
        zoneBreakdownSec: zones,
        activityCount: activityCount,
      ));
    }

    return list;
  }
}
