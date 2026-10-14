import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/garmin_status.dart';

final garminStatusStreamProvider = StreamProvider<GarminStatus>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(const GarminStatus());
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('integrationStatus')
      .doc('garmin')
      .snapshots()
      .map((doc) => GarminStatus.fromMap(doc.data()));
});

final garminServiceProvider = Provider<GarminService>((ref) {
  return GarminService();
});

class GarminService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west3');

  /// Startet den OAuth-Flow bei Garmin und öffnet die Autorisierungsseite im Browser
  Future<String?> startGarminAuth() async {
    try {
      final callable = _functions.httpsCallable('garminAuthStart');
      final result = await callable.call();
      final authUrl = result.data['authUrl'] as String?;

      if (authUrl != null && authUrl.isNotEmpty) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return result.data['oauthToken'] as String?;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Schließt die Autorisierung mit dem erhaltenen Verifier-Code ab
  Future<void> completeGarminAuth({
    required String oauthVerifier,
    String? oauthToken,
  }) async {
    final callable = _functions.httpsCallable('garminAuthCallback');
    final Map<String, dynamic> data = {
      'oauthVerifier': oauthVerifier,
    };
    if (oauthToken != null && oauthToken.isNotEmpty) {
      data['oauthToken'] = oauthToken;
    }
    await callable.call(data);
  }

  /// Trennt die Garmin-Verbindung und löscht alle Tokens
  Future<void> disconnectGarmin() async {
    final callable = _functions.httpsCallable('garminDisconnect');
    await callable.call();
  }

  /// Fordert einen Aktivitäten-Backfill der letzten X Tage an
  Future<void> triggerBackfill({int days = 30}) async {
    final callable = _functions.httpsCallable('garminBackfill');
    await callable.call({'days': days});
  }
}
