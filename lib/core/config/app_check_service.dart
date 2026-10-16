import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Service zur Aktivierung von Firebase App Check (Play Integrity auf Android,
/// Debug-Provider im Entwicklungs-, Test- und Emulator-Modus).
class AppCheckService {
  static Future<void> initialize() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
      debugPrint('[AppCheck] Firebase App Check initialisiert.');
    } catch (e) {
      // Fängt Fehler in Umgebungen ohne Google Play Services / Emulatoren ab
      debugPrint('[AppCheck] Hinweis: App Check nicht aktiv ($e)');
    }
  }
}
