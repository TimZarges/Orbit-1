import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Service zur Aktivierung von Firebase App Check (Play Integrity auf Android,
/// Debug-Provider im Entwicklungs-, Test- und Emulator-Modus).
class AppCheckService {
  static Future<void> initialize() async {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleDeviceCheckProvider(),
      );
      debugPrint('[AppCheck] Firebase App Check initialisiert.');
    } catch (e) {
      // Fängt Fehler in Umgebungen ohne Google Play Services / Emulatoren ab
      debugPrint('[AppCheck] Hinweis: App Check nicht aktiv ($e)');
    }
  }
}
