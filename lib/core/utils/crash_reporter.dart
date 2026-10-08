import 'package:flutter/foundation.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashReporter {
  /// Initialisiert Crashlytics und fängt alle unbehandelten Fehler.
  /// (Nur im Release-Modus aktiv, nach Consent-Check)
  static Future<void> initialize({required bool hasConsent}) async {
    if (kReleaseMode && hasConsent) {
      // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // PlatformDispatcher.instance.onError = (error, stack) {
      //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      //   return true;
      // };
    } else {
      // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
  }

  /// Loggt einen nicht-fatalen Fehler zur späteren Analyse.
  static void recordError(dynamic error, StackTrace stackTrace,
      {String? reason}) {
    if (kReleaseMode) {
      // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason);
    } else {
      debugPrint('Error: $error\nReason: $reason\nStack: $stackTrace');
    }
  }
}
