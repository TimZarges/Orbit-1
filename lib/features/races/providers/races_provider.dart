import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../coach_link/providers/athlete_context_provider.dart';
import '../models/race.dart';
import '../repositories/race_repository.dart';

final raceRepositoryProvider = Provider<RaceRepository>((ref) {
  return RaceRepository();
});

/// Stream aller Wettkämpfe des aktuell aktiven oder eingesehenen Athleten.
final racesStreamProvider = StreamProvider.autoDispose<List<Race>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).valueOrNull;
  final currentUid = authUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
  final viewedAthleteId = ref.watch(viewedAthleteIdProvider);
  final targetUid = viewedAthleteId ?? currentUid;

  if (targetUid == null || targetUid.isEmpty) {
    return Stream.value([]);
  }

  final repo = ref.watch(raceRepositoryProvider);
  return repo.watchRaces(targetUid);
});

/// Provider für das nächste anstehende A-Rennen (bzw. wichtigste anstehende Rennen).
final nextARaceProvider = Provider.autoDispose<Race?>((ref) {
  final racesAsync = ref.watch(racesStreamProvider);
  final races = racesAsync.valueOrNull ?? [];
  if (races.isEmpty) return null;

  final nowStr = DateTime.now().toIso8601String().split('T')[0];
  final futureRaces =
      races.where((r) => r.date.compareTo(nowStr) >= 0).toList();
  if (futureRaces.isEmpty) return null;

  // Primär nach A-Rennen suchen
  final aRaces =
      futureRaces.where((r) => r.priority == RacePriority.a).toList();
  if (aRaces.isNotEmpty) return aRaces.first;

  // Sekundär nach B-Rennen suchen
  final bRaces =
      futureRaces.where((r) => r.priority == RacePriority.b).toList();
  if (bRaces.isNotEmpty) return bRaces.first;

  return futureRaces.first;
});
