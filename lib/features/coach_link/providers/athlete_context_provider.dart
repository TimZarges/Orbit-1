import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Hält die ID des aktuell im Kontext betrachteten Athleten.
/// Für Athleten ist das immer ihre eigene ID.
/// Für Trainer ist das die ID des Athleten, dessen Profil sie gerade öffnen.
final viewedAthleteIdProvider = StateProvider<String?>((ref) {
  // Fallback auf die eigene UID, bis explizit ein anderer Athlet gesetzt wird.
  return ref.watch(authStateChangesProvider).valueOrNull?.uid;
});

/// Liefert zwingend die aktuelle athleteId für Datenabfragen (wirft Error falls null)
final currentAthleteIdProvider = Provider<String>((ref) {
  final id = ref.watch(viewedAthleteIdProvider);
  if (id == null) {
    throw Exception(
        "currentAthleteIdProvider wurde aufgerufen, obwohl kein Athlet im Kontext ist (nicht eingeloggt oder Fehler).");
  }
  return id;
});
