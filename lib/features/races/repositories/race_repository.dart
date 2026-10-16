import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/race.dart';

/// Repository zur Verwaltung von Saison-Zielen und Wettkämpfen (`users/{uid}/races/{raceId}`).
class RaceRepository {
  final FirebaseFirestore _firestore;

  RaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _racesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('races');
  }

  /// Beobachtet alle geplanten Wettkämpfe eines Athleten, chronologisch sortiert.
  Stream<List<Race>> watchRaces(String userId) {
    return _racesCollection(userId).orderBy('date').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Race.fromDocument(doc)).toList();
    });
  }

  /// Lädt alle Wettkämpfe eines Athleten einmalig.
  Future<List<Race>> getRaces(String userId) async {
    final snap = await _racesCollection(userId).orderBy('date').get();
    return snap.docs.map((doc) => Race.fromDocument(doc)).toList();
  }

  /// Ermittelt das nächste anstehende A-Rennen (oder alternativ den nächsten anstehenden Wettkampf).
  Future<Race?> getNextRace(String userId, {bool onlyA = true}) async {
    final nowStr = DateTime.now().toIso8601String().split('T')[0];
    final snap = await _racesCollection(userId)
        .where('date', isGreaterThanOrEqualTo: nowStr)
        .orderBy('date')
        .get();

    final races = snap.docs.map((doc) => Race.fromDocument(doc)).toList();
    if (races.isEmpty) return null;

    if (onlyA) {
      final aRaces = races.where((r) => r.priority == RacePriority.a).toList();
      if (aRaces.isNotEmpty) return aRaces.first;
    }

    return races.first;
  }

  /// Speichert oder aktualisiert ein Rennen.
  Future<void> saveRace(Race race) async {
    final docRef = race.id.isNotEmpty
        ? _racesCollection(race.userId).doc(race.id)
        : _racesCollection(race.userId).doc();

    final data = race.toMap();
    data['id'] = docRef.id;

    await docRef.set(data, SetOptions(merge: true));

    // Falls es ein A-Rennen ist, auch das denormalisierte profile.raceGoal aktualisieren
    if (race.priority == RacePriority.a) {
      await _firestore.collection('users').doc(race.userId).set({
        'profile': {
          'raceGoal': {
            'id': docRef.id,
            'title': race.title,
            'date': race.date,
            'distance': race.distanceLabel,
            'priority': 'A',
            'sport': race.sport,
            if (race.formattedTargetTime != null)
              'targetTime': race.formattedTargetTime,
            if (race.targetPowerWatts != null)
              'targetPowerWatts': race.targetPowerWatts,
          },
        },
      }, SetOptions(merge: true));
    }
  }

  /// Löscht ein Rennen.
  Future<void> deleteRace(String userId, String raceId) async {
    await _racesCollection(userId).doc(raceId).delete();
  }
}
