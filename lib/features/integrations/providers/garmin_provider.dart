/// @file garmin_provider.dart
/// @description Riverpod-Provider und Service-Schicht für die Garmin-Connect-OAuth-1.0a-Integration.
///
/// Steuert den Status-Stream (`integrationStatus/garmin`), den Start/Abbruch/Abschluss der
/// OAuth-Autorisierung über Cloud Functions in `europe-west3`, den Browser-Launch sowie
/// verständliche deutsche Fehlermeldungen.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/garmin_status.dart';
import '../services/garmin_web_callback_bridge.dart';

/// Live-Stream des öffentlichen Garmin-Verbindungsstatus aus `users/{uid}/integrationStatus/garmin`.
final garminStatusStreamProvider = StreamProvider<GarminStatus>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(const GarminStatus());
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('integrationStatus')
      .doc('garmin')
      .snapshots()
      .map((doc) => GarminStatus.fromMap(doc.data()));
});

/// Stellt die zentrale [GarminService]-Instanz für UI und Onboarding bereit.
final garminServiceProvider = Provider<GarminService>((ref) {
  return GarminService();
});

/// Ergebnis beim Start einer neuen Garmin-OAuth-1.0a-Sitzung.
class GarminAuthStartResult {
  /// Von `garminAuthStart` erzeugtes Request-Token.
  final String? oauthToken;

  /// Vollständige Garmin-Connect-Autorisierungs-URL (`connect.garmin.com/oauthConfirm?...`).
  final String authUrl;

  /// Erzeugt ein unveränderliches Startergebnis.
  const GarminAuthStartResult({
    required this.authUrl,
    this.oauthToken,
  });
}

/// Service zur Kommunikation mit den Garmin-Cloud-Functions in `europe-west3`.
class GarminService {
  final FirebaseFunctions? _functionsOverride;

  /// Erzeugt einen [GarminService] optional mit injizierter [FirebaseFunctions]-Instanz für Tests.
  GarminService({FirebaseFunctions? functions})
      : _functionsOverride = functions;

  /// Lazy-Zugriff auf die `europe-west3`-Functions-Instanz, damit Mocks ohne Firebase-Init lauffähig bleiben.
  FirebaseFunctions get _functions =>
      _functionsOverride ??
      FirebaseFunctions.instanceFor(region: 'europe-west3');

  /// Öffnet eine Garmin-Autorisierungs-URL im externen Browser (oder In-App-Browser-Fallback).
  Future<void> launchAuthUrl(String authUrl) async {
    final uri = Uri.parse(authUrl);
    if (kIsWeb) {
      // Im Web vor dem Öffnen markieren, damit `/callback/garmin` zurück zu `/app/` statt `orbit://` leitet.
      GarminWebCallbackBridge.markWebOAuthStart();
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      final fallbackLaunched =
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!fallbackLaunched) {
        throw Exception(
          'Browser für Garmin-Login konnte nicht geöffnet werden.',
        );
      }
    }
  }

  /// Startet den OAuth-Flow bei Garmin Connect, öffnet den Browser und gibt
  /// sowohl `oauthToken` als auch `authUrl` zurück (z. B. für „Browser erneut öffnen“).
  Future<GarminAuthStartResult?> startGarminAuthSession() async {
    final callable = _functions.httpsCallable('garminAuthStart');
    final result = await callable.call();
    final data = result.data as Map?;
    final authUrl = data?['authUrl'] as String?;
    final oauthToken = data?['oauthToken'] as String?;

    if (authUrl != null && authUrl.isNotEmpty) {
      await launchAuthUrl(authUrl);
      return GarminAuthStartResult(authUrl: authUrl, oauthToken: oauthToken);
    }
    return null;
  }

  /// Abwärtskompatibler Wrapper für Onboarding-Flows; gibt das erzeugte Request-Token zurück.
  Future<String?> startGarminAuth() async {
    final session = await startGarminAuthSession();
    return session?.oauthToken;
  }

  /// Bricht eine noch nicht bestätigte Garmin-Anmeldung sauber im Backend ab
  /// und bereinigt temporäre OAuth-Reste (`DISCONNECTED` bzw. Timeout-Hinweis).
  Future<void> cancelGarminAuth({String reason = 'cancelled'}) async {
    if (kIsWeb) {
      GarminWebCallbackBridge.clearPendingWebCallback();
    }
    final callable = _functions.httpsCallable('garminAuthCancel');
    await callable.call({'reason': reason});
  }

  /// Schließt die Autorisierung mit dem erhaltenen Verifier-Code ab.
  Future<void> completeGarminAuth({
    required String oauthVerifier,
    String? oauthToken,
  }) async {
    final callable = _functions.httpsCallable('garminAuthCallback');
    final Map<String, dynamic> data = {
      'oauthVerifier': oauthVerifier,
    };
    if (oauthToken != null && oauthToken.isNotEmpty) {
      data['oauthToken'] = oauthToken;
    }
    await callable.call(data);
    if (kIsWeb) {
      GarminWebCallbackBridge.clearPendingWebCallback();
    }
  }

  /// Trennt die Garmin-Verbindung und löscht alle Tokens sowie Webhook-Indizes.
  Future<void> disconnectGarmin() async {
    if (kIsWeb) {
      GarminWebCallbackBridge.clearPendingWebCallback();
    }
    final callable = _functions.httpsCallable('garminDisconnect');
    await callable.call();
  }

  /// Fordert einen Aktivitäten- und Gesundheits-Backfill der letzten X Tage an (Standard 90 Tage).
  Future<void> triggerBackfill({int days = 90}) async {
    final callable = _functions.httpsCallable('requestGarminBackfill');
    await callable.call({'days': days});
  }

  /// Führt eine sofortige aktive REST-Pull-Synchronisation aller historischen Aktivitäten
  /// und Gesundheitsdaten durch und speichert sie direkt in Firestore & Storage.
  Future<Map<String, dynamic>> syncActivitiesNow({int days = 90}) async {
    final callable = _functions.httpsCallable('syncGarminActivitiesNow');
    final result = await callable.call({'days': days});
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Übersetzt technische Cloud-Function- oder Netzwerkfehler in verständliches Deutsch.
  static String resolveErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'cancelled':
          return 'Garmin-Autorisierung wurde im Browser abgebrochen.';
        case 'not-found':
          return 'Keine offene Garmin-Anmeldesitzung gefunden. Bitte starte den Vorgang erneut.';
        case 'failed-precondition':
          return error.message ??
              'Die Garmin-Sitzung ist veraltet oder noch nicht konfiguriert.';
        case 'unauthenticated':
          return 'Bitte melde dich zuerst erneut bei ORBIT an.';
        case 'deadline-exceeded':
          return 'Garmin hat nicht rechtzeitig geantwortet. Bitte versuche es erneut.';
        default:
          return error.message ?? 'Verbindung zu Garmin fehlgeschlagen.';
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
