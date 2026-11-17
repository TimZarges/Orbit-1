/// Datei-Header: `lib/features/activities/providers/activities_provider.dart`
/// Zweck: Echtzeit-Stream-Provider für absolvierte Aktivitäten eines Athleten aus
/// Firestore (`activities` Collection), mit strikter Trennung zwischen Athleten-
/// und Coach-Kontext (Phase 45).
/// Architektur-Einordnung: Datenhaltungs- & Provider-Schicht
/// (`lib/features/activities/providers/`), stellt sicher, dass ein Coach im
/// Kalender niemals seine eigene UID abfragt, sondern ausschließlich den
/// ausgewählten Athleten (`v1SelectedCoachAthleteIdProvider` / `viewedAthleteIdProvider`).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../coach_link/providers/athlete_context_provider.dart';
import '../../coach_link/providers/v1_coach_connection_provider.dart';
import '../models/activity.dart';

/// Echtzeit-Stream-Provider für alle absolvierten Aktivitäten des aktuellen Athleten.
///
/// Was: Überwacht `activities` absteigend sortiert nach `startTimeUtc`.
/// Bei eingeloggten Coaches (`role == 'TRAINER'`) wird zwingend die über
/// [v1SelectedCoachAthleteIdProvider] bzw. explizite [viewedAthleteIdProvider]-
/// Zuweisung gewählte Athleten-ID genutzt und niemals auf die eigene Coach-UID
/// zurückgefallen.
/// Warum: Verhindert leere oder falsche Aktivitätslisten im Coach-Kalender sowie
/// unnötige Firestore-Abfragen ohne gültige Athleten-ID (`AGENTS.md` Regel 10).
final activitiesProvider = StreamProvider.autoDispose<List<Activity>>((ref) {
  final role = ref.watch(
    userDocumentProvider.select((asyncDoc) => asyncDoc.valueOrNull?['role']),
  );
  final authUid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  final coachSelectedId = ref.watch(v1SelectedCoachAthleteIdProvider);
  final viewedId = ref.watch(viewedAthleteIdProvider);

  // Für Coaches niemals auf die eigene Trainer-UID zurückfallen
  final bool isTrainer = role == 'TRAINER';
  final String? athleteId = isTrainer
      ? (coachSelectedId ?? (viewedId != authUid ? viewedId : null))
      : viewedId;

  if (athleteId == null || athleteId.isEmpty) {
    return Stream.value(const []);
  }

  return FirebaseFirestore.instance
      .collection('activities')
      .where('athleteId', isEqualTo: athleteId)
      .orderBy('startTimeUtc', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Activity.fromDocument(doc)).toList();
  });
});
