/// @file garmin_web_callback_bridge_stub.dart
/// @description No-Op-Implementierung der Web-Callback-Bridge für Android, iOS und VM-Unit-Tests.
library;

import 'garmin_web_callback_bridge.dart';

/// Auf nativen Plattformen (Android/iOS) läuft die Rückkehr über Deep-Links und Lifecycle-Events.
void markWebOAuthStart() {}

/// Auf nativen Plattformen gibt es keinen Browser-`localStorage` zu bereinigen.
void clearPendingWebCallback() {}

/// Auf nativen Plattformen existiert kein Browser-`localStorage`.
GarminWebCallbackEvent? consumePendingWebCallback() => null;

/// Gibt auf nativen Plattformen eine leere Aufräumfunktion zurück.
void Function() listenGarminWebCallbacks(GarminWebCallbackListener onEvent) {
  return () {};
}
