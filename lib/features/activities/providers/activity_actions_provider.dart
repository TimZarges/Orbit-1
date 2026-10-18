import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../coach_link/providers/athlete_context_provider.dart';

/// Kapselt clientseitige Aktionen auf Aktivitäten, wie etwa das endgültige Löschen.
class ActivityActions {
  /// Riverpod-Referenz für Kontext- und Provider-Abfragen.
  final Ref ref;

  /// Erstellt eine neue Instanz von [ActivityActions].
  ActivityActions(this.ref);

  /// Löscht eine Aktivität endgültig über die Cloud Function `deleteActivity` (europe-west3).
  ///
  /// Bereinigt das Aktivitätsdokument in Firestore, die Telemetrie-Streams in Storage
  /// und triggert die Neuberechnung des täglichen Belastungsaggregats.
  Future<void> deleteActivity(String activityId) async {
    final athleteId = ref.read(viewedAthleteIdProvider);
    if (athleteId == null) throw Exception("No athlete context");

    final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
        .httpsCallable('deleteActivity');
    await callable.call({
      'activityId': activityId,
      'athleteId': athleteId,
    });
  }
}

/// Provider für den Zugriff auf [ActivityActions].
final activityActionsProvider = Provider<ActivityActions>((ref) {
  return ActivityActions(ref);
});
