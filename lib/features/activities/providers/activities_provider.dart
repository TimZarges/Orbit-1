import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../coach_link/providers/athlete_context_provider.dart';
import '../models/activity.dart';

/// Echtzeit-Stream-Provider für alle absolvierten Aktivitäten des aktuellen Athleten.
///
/// Berücksichtigt den [viewedAthleteIdProvider], sodass Trainer nahtlos
/// in den Kontext ihrer verknüpften Athleten wechseln können.
/// Liefert die Aktivitäten absteigend sortiert nach [startTimeUtc].
final activitiesProvider = StreamProvider.autoDispose<List<Activity>>((ref) {
  final athleteId = ref.watch(viewedAthleteIdProvider);
  if (athleteId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('activities')
      .where('athleteId', isEqualTo: athleteId)
      .orderBy('startTimeUtc', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Activity.fromDocument(doc)).toList();
  });
});
