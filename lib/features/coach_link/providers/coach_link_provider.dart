import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoachLinkData {
  final String athleteId;
  final String coachId;
  final String status;
  final bool shareActivities;
  final bool shareCalendar;
  final bool shareHealth;
  final bool shareBodyWeightAndNotes;

  const CoachLinkData({
    required this.athleteId,
    required this.coachId,
    required this.status,
    this.shareActivities = true,
    this.shareCalendar = true,
    this.shareHealth = false,
    this.shareBodyWeightAndNotes = false,
  });

  factory CoachLinkData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final permissions = data['permissions'] as Map<String, dynamic>? ?? {};

    return CoachLinkData(
      athleteId: data['athleteId'] as String? ?? '',
      coachId: data['coachId'] as String? ?? '',
      status: data['status'] as String? ?? 'ACTIVE',
      shareActivities: permissions['activities'] as bool? ?? true,
      shareCalendar: permissions['calendar'] as bool? ?? true,
      shareHealth: permissions['health'] as bool? ?? false,
      shareBodyWeightAndNotes:
          permissions['bodyWeightAndNotes'] as bool? ?? false,
    );
  }
}

/// Stream-Provider für das aktive coachLinks-Dokument des Athleten
final coachLinkStreamProvider =
    StreamProvider.family<CoachLinkData?, String>((ref, linkId) {
  if (linkId.isEmpty) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('coachLinks')
      .doc(linkId)
      .snapshots()
      .map((doc) => doc.exists ? CoachLinkData.fromDoc(doc) : null);
});

final coachLinkServiceProvider = Provider<CoachLinkService>((ref) {
  return CoachLinkService();
});

class CoachLinkService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west3');

  /// Löst einen 6-stelligen Einladungscode des Trainers ein
  Future<String> redeemInvite(String code) async {
    final callable = _functions.httpsCallable('redeemInvite');
    final result = await callable.call({'code': code.trim().toUpperCase()});
    return result.data['coachId'] as String? ?? '';
  }

  /// Aktualisiert die granularen Art. 9 DSGVO-Freigaben für den Trainer
  Future<void> updatePermissions({
    required String coachId,
    required bool shareActivities,
    required bool shareCalendar,
    required bool shareHealth,
    bool shareBodyWeightAndNotes = false,
  }) async {
    final callable = _functions.httpsCallable('updatePermissions');
    await callable.call({
      'coachId': coachId,
      'permissions': {
        'activities': shareActivities,
        'calendar': shareCalendar,
        'health': shareHealth,
        'bodyWeightAndNotes': shareBodyWeightAndNotes,
      },
    });
  }

  /// Beendet die Verknüpfung mit dem Trainer und entzieht sofort alle Rechte
  Future<void> revokeLink(String linkId) async {
    final callable = _functions.httpsCallable('revokeLink');
    await callable.call({'linkId': linkId});
  }
}
