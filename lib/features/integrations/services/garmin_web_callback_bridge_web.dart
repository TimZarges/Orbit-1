/// @file garmin_web_callback_bridge_web.dart
/// @description Browser-Implementierung der Garmin-OAuth-Callback-Bridge für ORBIT Web (Safari & Chrome).
///
/// Verbindet `/callback/garmin/index.html` über `BroadcastChannel`, `window.postMessage`,
/// `localStorage`-Events sowie Fenster-Fokus-Prüfungen zuverlässig mit dem offenen Flutter-Web-Tab.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'garmin_web_callback_bridge.dart';

/// Schlüssel im `localStorage`, über den `callback/garmin/index.html` Web-Flows erkennt.
const String _kPlatformStorageKey = 'orbit_garmin_oauth_platform';

/// Schlüssel im `localStorage` für die exakte Rücksprung-Origin (`/app/#/callback/garmin`).
const String _kOriginStorageKey = 'orbit_garmin_oauth_origin';

/// Schlüssel im `localStorage` für das zwischengespeicherte OAuth-Ergebnis.
const String _kCallbackStorageKey = 'orbit_garmin_oauth_callback';

/// Name des verwendeten `BroadcastChannel`.
const String _kBroadcastChannelName = 'orbit_garmin_auth';

/// Maximales Alter eines gespeicherten Web-Callbacks (10 Minuten), um veraltete Wiederholungen auszuschließen.
const int _kCallbackMaxAgeMs = 10 * 60 * 1000;

/// Setzt beim Start in ORBIT Web die Herkunfts-Markierungen im `localStorage`.
void markWebOAuthStart() {
  try {
    web.window.localStorage.setItem(_kPlatformStorageKey, 'web');
    web.window.localStorage
        .setItem(_kOriginStorageKey, web.window.location.origin);
    web.window.localStorage.removeItem(_kCallbackStorageKey);
  } catch (_) {
    // Im geschützten Inkognito-Modus kann `localStorage` blockiert sein; BroadcastChannel greift dann als Primärkanal.
  }
}

/// Entfernt gespeicherte Markierungen und Zwischenergebnisse aus dem `localStorage`.
void clearPendingWebCallback() {
  try {
    web.window.localStorage.removeItem(_kCallbackStorageKey);
    web.window.localStorage.removeItem(_kPlatformStorageKey);
    web.window.localStorage.removeItem(_kOriginStorageKey);
  } catch (_) {
    // Ignorieren, falls Browser-Speicher deaktiviert ist.
  }
}

/// Parst ein strukturiertes Payload-Objekt aus `BroadcastChannel`, `postMessage` oder `localStorage`.
GarminWebCallbackEvent? _parsePayload(Object? raw) {
  if (raw is! Map) return null;

  final type = raw['type']?.toString();
  final timestampNum = raw['timestamp'];
  if (timestampNum is num) {
    final ageMs = DateTime.now().millisecondsSinceEpoch - timestampNum.toInt();
    if (ageMs > _kCallbackMaxAgeMs) {
      return null;
    }
  }

  final token = raw['oauthToken']?.toString().trim();
  final cleanToken = (token != null && token.isNotEmpty) ? token : null;

  if (type == 'GARMIN_AUTH_CANCELLED') {
    return GarminWebCallbackEvent(
      oauthToken: cleanToken,
      isCancelled: true,
      errorReason: raw['reason']?.toString(),
    );
  }

  if (type == 'GARMIN_AUTH_CALLBACK' || raw.containsKey('oauthVerifier')) {
    final verifier = raw['oauthVerifier']?.toString().trim() ?? '';
    final lower = verifier.toLowerCase();
    if (verifier.isEmpty ||
        lower == 'null' ||
        lower == 'undefined' ||
        lower == 'denied') {
      return GarminWebCallbackEvent(
        oauthToken: cleanToken,
        isCancelled: true,
        errorReason: 'cancelled',
      );
    }
    return GarminWebCallbackEvent(
      oauthVerifier: verifier,
      oauthToken: cleanToken,
    );
  }

  return null;
}

/// Prüft synchron, ob bereits ein frisches Callback-Ergebnis im `localStorage` vorliegt, und konsumiert es einmalig.
GarminWebCallbackEvent? consumePendingWebCallback() {
  try {
    final rawJson = web.window.localStorage.getItem(_kCallbackStorageKey);
    if (rawJson == null || rawJson.isEmpty) return null;
    web.window.localStorage.removeItem(_kCallbackStorageKey);
    final decoded = jsonDecode(rawJson);
    return _parsePayload(decoded);
  } catch (_) {
    return null;
  }
}

/// Registriert alle Browser-Kanäle (`BroadcastChannel`, `message`, `storage`, `focus`) und gibt eine Dispose-Funktion zurück.
void Function() listenGarminWebCallbacks(GarminWebCallbackListener onEvent) {
  var isDisposed = false;

  void dispatchIfValid(GarminWebCallbackEvent? event) {
    if (isDisposed || event == null) return;
    // Gespeichertes Storage-Item direkt konsumieren, damit derselbe Code nicht mehrfach verarbeitet wird
    try {
      web.window.localStorage.removeItem(_kCallbackStorageKey);
    } catch (_) {}
    onEvent(event);
  }

  // 1. BroadcastChannel (gleiche Origin, z. B. Safari-Tab ohne window.opener)
  web.BroadcastChannel? channel;
  try {
    channel = web.BroadcastChannel(_kBroadcastChannelName);
    channel.onmessage = ((web.MessageEvent event) {
      dispatchIfValid(_parsePayload(event.data?.dartify()));
    }).toJS;
  } catch (_) {
    channel = null;
  }

  // 2. window.postMessage (Popup / Tab mit aktivem window.opener, Origin-geprüft)
  final jsMessageListener = ((web.MessageEvent event) {
    final origin = event.origin;
    final currentOrigin = web.window.location.origin;
    final isAllowedOrigin = origin == currentOrigin ||
        origin == 'https://orbit-app-mvp.web.app' ||
        origin == 'https://orbit-app-mvp.firebaseapp.com' ||
        origin == 'https://app.orbit.training';
    if (!isAllowedOrigin) return;
    dispatchIfValid(_parsePayload(event.data?.dartify()));
  }).toJS;
  web.window.addEventListener('message', jsMessageListener);

  // 3. localStorage `storage`-Event (Tab-übergreifende Zustellung in Safari/Chrome)
  final jsStorageListener = ((web.StorageEvent event) {
    if (event.key != _kCallbackStorageKey || event.newValue == null) return;
    try {
      final decoded = jsonDecode(event.newValue!);
      dispatchIfValid(_parsePayload(decoded));
    } catch (_) {}
  }).toJS;
  web.window.addEventListener('storage', jsStorageListener);

  // 4. Fokus-Rückkehr prüfen (falls Tab im Hintergrund gedrosselt war)
  final jsFocusListener = ((web.Event _) {
    dispatchIfValid(consumePendingWebCallback());
  }).toJS;
  web.window.addEventListener('focus', jsFocusListener);

  // Vollständiges Aufräumen beim Verlassen des Screens (verhindert Memory-Leaks)
  return () {
    isDisposed = true;
    try {
      channel?.onmessage = null;
      channel?.close();
    } catch (_) {}
    web.window.removeEventListener('message', jsMessageListener);
    web.window.removeEventListener('storage', jsStorageListener);
    web.window.removeEventListener('focus', jsFocusListener);
  };
}
