import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_device.dart';

/// Repository zur Registrierung von Push-Tokens und Verwaltung von Benachrichtigungseinstellungen.
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Registriert ein Gerät für Push-Benachrichtigungen.
  Future<void> registerDevice({
    required String uid,
    required String deviceId,
    required String fcmToken,
    required String platform,
    String appVersion = '1.0.0',
    String language = 'de',
  }) async {
    final device = UserDevice(
      deviceId: deviceId,
      fcmToken: fcmToken,
      platform: platform,
      appVersion: appVersion,
      language: language,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .set(device.toMap(), SetOptions(merge: true));
  }

  /// Entfernt ein Gerät bei Abmeldung / Logout.
  Future<void> unregisterDevice({
    required String uid,
    required String deviceId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceId)
          .delete();
    } catch (_) {
      // Fehler fangen
    }
  }

  /// Aktualisiert Benachrichtigungseinstellungen und Ruhezeiten.
  Future<void> updateNotificationSettings({
    required String uid,
    required Map<String, bool> categories,
    Map<String, String>? quietHours,
  }) async {
    final updates = <String, dynamic>{
      'settings.notifications': categories,
    };
    if (quietHours != null) {
      updates['settings.quietHours'] = quietHours;
    }

    await _firestore.collection('users').doc(uid).update(updates);
  }
}
