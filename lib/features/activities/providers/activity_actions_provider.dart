import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../coach_link/providers/athlete_context_provider.dart';

class ActivityActions {
  final Ref ref;
  ActivityActions(this.ref);

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

final activityActionsProvider = Provider<ActivityActions>((ref) {
  return ActivityActions(ref);
});
