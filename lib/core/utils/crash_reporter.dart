import 'package:flutter/foundation.dart';

/// Zentraler Crash-Reporter für ORBIT (strikt DSGVO-konform mit Opt-in).
///
/// Standardmäßig deaktiviert (`hasConsent = false`).
/// Erst nach expliziter Tester-Zustimmung im Onboarding oder in den Einstellungen aktiv.
/// Sendet niemals personenbezogene Daten (Namen, E-Mails) oder Art.-9-Gesundheitsdaten
/// (Herzfrequenzen, Watt, GPS-Tracks).
class CrashReporter {
  static bool _hasConsent = false;

  /// Prüft, ob der Nutzer der anonymen Fehlerübertragung zugestimmt hat.
  static bool get hasConsent => _hasConsent;

  /// Initialisiert den Crash-Reporter unter Berücksichtigung des Nutzer-Opt-ins.
  static Future<void> initialize({required bool hasConsent}) async {
    _hasConsent = hasConsent;

    FlutterError.onError = (FlutterErrorDetails details) {
      recordError(
        details.exception,
        details.stack ?? StackTrace.empty,
        reason: details.context?.toString(),
        fatal: true,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Ändert die Einwilligung zur Fehlerübertragung zur Laufzeit.
  static void setConsent(bool consent) {
    _hasConsent = consent;
    debugPrint('[CrashReporter] Crashlytics-Opt-in geändert: $_hasConsent');
  }

  /// Loggt einen Fehler, sofern Opt-in vorliegt.
  static void recordError(
    dynamic error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    if (!_hasConsent) {
      if (kDebugMode) {
        debugPrint('[CrashReporter - Opted Out] $error\nReason: $reason');
      }
      return;
    }

    // Bereinigung von sensiblen Daten (Sanitization)
    final sanitizedReason = _sanitize(reason);
    final sanitizedError = _sanitize(error.toString());

    if (kDebugMode) {
      debugPrint(
          '[CrashReporter - Consent Granted] Error: $sanitizedError\nReason: $sanitizedReason');
    }
  }

  /// Entfernt E-Mails, Tokens und verdächtige Muster aus Fehlermeldungen.
  static String? _sanitize(String? text) {
    if (text == null) return null;
    return text
        .replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
            '[REDACTED_EMAIL]')
        .replaceAll(
            RegExp(r'Bearer\s+[a-zA-Z0-9\-._~+/]+=*'), '[REDACTED_TOKEN]');
  }
}
