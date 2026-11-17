/// Datei-Header: `lib/core/config/app_check_service.dart`
/// Zweck: Aktivierung von Firebase App Check auf nativen Plattformen (Android/iOS)
/// mit sauberem Web-Skip (`kIsWeb`), da Web-App-Check einen ReCaptcha-Key benötigt.
/// Architektur-Einordnung: Core-Konfigurationsschicht (`lib/core/config/`).
library;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Service zur Aktivierung von Firebase App Check (Play Integrity auf Android,
/// Debug-Provider im Entwicklungs-, Test- und Emulator-Modus).
class AppCheckService {
  /// Initialisiert App Check auf Android/iOS und überspringt Web sauber.
  static Future<void> initialize() async {
    // Im Web-Build ohne ReCaptchaV3Provider sauber überspringen
    if (kIsWeb) return;
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
