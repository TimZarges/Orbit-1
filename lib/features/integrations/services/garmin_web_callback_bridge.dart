/// @file garmin_web_callback_bridge.dart
/// @description Plattformunabhängige Schnittstelle für die Rückmeldung der Garmin-OAuth-Callback-Seite im Web.
library;

import 'garmin_web_callback_bridge_stub.dart'
    if (dart.library.js_interop) 'garmin_web_callback_bridge_web.dart' as impl;

/// Strukturierte Rückmeldung aus dem Browser-Callback-Tab für Garmin OAuth 1.0a.
class GarminWebCallbackEvent {
  /// Empfängt den von Garmin ausgestellten `oauth_verifier` (bei Bestätigung).
  final String? oauthVerifier;

  /// Empfängt das zugehörige temporäre `oauth_token`.
  final String? oauthToken;

  /// Gibt an, ob der Nutzer den Vorgang im Garmin-Tab abgebrochen/abgelehnt hat.
  final bool isCancelled;

  /// Optionaler Fehler-/Abbruchgrund aus den Callback-Parametern.
  final String? errorReason;

  /// Erzeugt ein unveränderliches Callback-Ereignis.
  const GarminWebCallbackEvent({
    this.oauthVerifier,
    this.oauthToken,
    this.isCancelled = false,
    this.errorReason,
  });
}

/// Callback-Typ für eingehende Web-OAuth-Rückmeldungen.
typedef GarminWebCallbackListener = void Function(GarminWebCallbackEvent event);

/// Stellt plattformabhängig (Web vs. Native) die OAuth-Tab-Kommunikation bereit.
abstract class GarminWebCallbackBridge {
  /// Markiert vor dem Öffnen von Garmin im Browser, dass der Start aus ORBIT Web erfolgte,
  /// damit die Callback-Seite zurück zu `/app/#/callback/garmin` statt `orbit://` leitet.
  static void markWebOAuthStart() => impl.markWebOAuthStart();

  /// Entfernt gespeicherte Web-Callback-Reste aus dem Browser-Speicher.
  static void clearPendingWebCallback() => impl.clearPendingWebCallback();

  /// Prüft synchron auf ein eventuell bereits im `localStorage` abgelegtes Callback-Ergebnis
  /// (z. B. nach Tab-Wechsel oder Safari-Fokuswechsel).
  static GarminWebCallbackEvent? consumePendingWebCallback() =>
      impl.consumePendingWebCallback();

  /// Abonniert Live-Nachrichten (`BroadcastChannel`, `postMessage`, `storage`, `focus`)
  /// und liefert eine Bereinigungsfunktion (`VoidCallback` bzw. `void Function()`) für `dispose()`.
  static void Function() listen(GarminWebCallbackListener onEvent) =>
      impl.listenGarminWebCallbacks(onEvent);
}
