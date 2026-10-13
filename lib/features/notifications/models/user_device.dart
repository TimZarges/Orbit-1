import 'package:cloud_firestore/cloud_firestore.dart';

/// Modell für ein registriertes Nutzergerät mit Push-Token (`users/{uid}/devices/{deviceId}`).
class UserDevice {
  final String deviceId;
  final String fcmToken;
  final String platform; // "android" | "ios" | "web"
  final String appVersion;
  final String language; // "de" | "en"
  final DateTime updatedAt;

  const UserDevice({
    required this.deviceId,
    required this.fcmToken,
    required this.platform,
    required this.appVersion,
    this.language = 'de',
    required this.updatedAt,
  });

  factory UserDevice.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserDevice(
      deviceId: doc.id,
      fcmToken: data['fcmToken'] as String? ?? '',
      platform: data['platform'] as String? ?? 'android',
      appVersion: data['appVersion'] as String? ?? '1.0.0',
      language: data['language'] as String? ?? 'de',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fcmToken': fcmToken,
      'platform': platform,
      'appVersion': appVersion,
      'language': language,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
