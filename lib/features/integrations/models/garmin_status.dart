/// @file garmin_status.dart
/// @description Datenmodell für den Verbindungs- und Synchronisationsstatus von Garmin Connect.
library;

/// Verbindungszustände der Garmin-Connect-Integration in Firestore (`integrationStatus/garmin`).
enum GarminConnectionState {
  /// Keine aktive Verknüpfung vorhanden.
  disconnected,

  /// OAuth-1.0a-Anfrage wurde gestartet; Wartezeit auf Nutzerbestätigung im Browser.
  connecting,

  /// Dauerhafte OAuth-Tokens hinterlegt; Synchronisation aktiv.
  connected,

  /// Fehler oder Zeitüberschreitung beim letzten Verbindungs- bzw. Sync-Versuch.
  error,
}

/// Repräsentiert den öffentlichen Synchronisations- und Verbindungsstatus eines Athleten für Garmin Connect.
class GarminStatus {
  /// Aktueller Verbindungszustand.
  final GarminConnectionState state;

  /// Eindeutige Garmin-Nutzer-ID (für Push-Webhook-Zuordnung).
  final String? garminUserId;

  /// Zeitpunkt der erfolgreichen Kopplung.
  final DateTime? connectedAt;

  /// Zeitpunkt, zu dem der letzte offene Verbindungsversuch gestartet wurde.
  final DateTime? authStartedAt;

  /// Zeitpunkt der letzten abgeschlossenen Aktivitäts- oder Health-Synchronisation.
  final DateTime? lastSyncAt;

  /// Anzahl der beim letzten Lauf synchronisierten Aktivitäten.
  final int lastSyncCount;

  /// Menschlesbare Statusmeldung des letzten Synchronisationslaufs.
  final String? lastSyncMessage;

  /// Gibt an, ob aktuell ein historischer Backfill über Garmin läuft.
  final bool isBackfillInProgress;

  /// Anzahl bisher über den Backfill eingegangener Aktivitäten.
  final int receivedActivities;

  /// Anzahl bisher über den Backfill eingegangener Gesundheitstage.
  final int receivedHealthDays;

  /// Ziel-Zeitraum des angeforderten Backfills in Tagen.
  final int targetDays;

  /// Verständliche Fehlermeldung bei Verbindungs- oder Sync-Problemen.
  final String? errorMessage;

  /// Erzeugt ein unveränderliches [GarminStatus]-Objekt.
  const GarminStatus({
    this.state = GarminConnectionState.disconnected,
    this.garminUserId,
    this.connectedAt,
    this.authStartedAt,
    this.lastSyncAt,
    this.lastSyncCount = 0,
    this.lastSyncMessage,
    this.isBackfillInProgress = false,
    this.receivedActivities = 0,
    this.receivedHealthDays = 0,
    this.targetDays = 90,
    this.errorMessage,
  });

  /// Wandelt Firestore-`Timestamp`, ISO-Strings oder `DateTime` sicher in ein [DateTime] um.
  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    try {
      // Firestore `Timestamp` stellt `.toDate()` bereit ohne direkte Cloud-Firestore-Abhängigkeit im Modell.
      final dynamic converted = (raw as dynamic).toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Fallback über String-Parsing für sonstige Datumsformate.
    }
    return DateTime.tryParse(raw.toString());
  }

  /// Erstellt eine [GarminStatus]-Instanz aus einem Firestore-Dokument.
  factory GarminStatus.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GarminStatus();

    final stateStr = data['state'] as String?;
    final GarminConnectionState state;
    switch (stateStr) {
      case 'CONNECTED':
        state = GarminConnectionState.connected;
        break;
      case 'CONNECTING':
        state = GarminConnectionState.connecting;
        break;
      case 'ERROR':
        state = GarminConnectionState.error;
        break;
      default:
        state = GarminConnectionState.disconnected;
    }

    final backfillData = data['backfill'] as Map<String, dynamic>?;
    final isBackfill = backfillData?['state'] == 'IN_PROGRESS';
    final receivedActivities =
        (backfillData?['receivedActivities'] as num?)?.toInt() ?? 0;
    final receivedHealthDays =
        (backfillData?['receivedHealthDays'] as num?)?.toInt() ?? 0;
    final targetDays = (backfillData?['targetDays'] as num?)?.toInt() ?? 90;

    return GarminStatus(
      state: state,
      garminUserId: data['garminUserId'] as String?,
      connectedAt: _parseTimestamp(data['connectedAt']),
      authStartedAt: _parseTimestamp(data['authStartedAt']),
      lastSyncAt: _parseTimestamp(data['lastSyncAt']),
      lastSyncCount: (data['lastSyncCount'] as num?)?.toInt() ?? 0,
      lastSyncMessage: data['lastSyncMessage'] as String?,
      isBackfillInProgress: isBackfill,
      receivedActivities: receivedActivities,
      receivedHealthDays: receivedHealthDays,
      targetDays: targetDays,
      errorMessage: data['errorMessage'] as String?,
    );
  }
}

/// Normalisierte Parameter eines Garmin-OAuth-Callbacks aus Deep-Link oder Web-URL.
class GarminCallbackParams {
  /// Bereinigter `oauth_verifier` (null bei Abbruch, fehlendem Parameter oder `'null'`).
  final String? verifier;

  /// Optionaler `oauth_token`.
  final String? token;

  /// Verständlicher Abbruch-/Fehlercode (z. B. `'cancelled'`), falls der Vorgang abgebrochen wurde.
  final String? error;

  /// Erzeugt ein unveränderliches Ergebnis-Objekt.
  const GarminCallbackParams({
    this.verifier,
    this.token,
    this.error,
  });

  /// Gibt `true` zurück, wenn ein valider Bestätigungscode vorliegt.
  bool get hasValidVerifier => verifier != null && verifier!.isNotEmpty;

  /// Gibt `true` zurück, wenn der Vorgang explizit abgebrochen oder fehlerhaft war.
  bool get isCancelledOrError => error != null && error!.isNotEmpty;
}

/// Extrahiert und bereinigt Garmin-Callback-Parameter (`oauth_verifier`, `oauth_token`, `error`/`denied`)
/// deterministisch aus einer eingehenden Deep-Link- oder Web-Router-URI.
GarminCallbackParams parseGarminCallbackUri(Uri uri) {
  final rawToken = (uri.queryParameters['oauth_token'] ?? '').trim();
  final rawVerifier = (uri.queryParameters['oauth_verifier'] ?? '').trim();
  final rawDenied = (uri.queryParameters['denied'] ?? '').trim();
  final rawError = (uri.queryParameters['error'] ?? '').trim();

  final cleanToken = rawToken.isNotEmpty ? rawToken : null;
  final lowerVerifier = rawVerifier.toLowerCase();
  final isInvalidVerifierString = lowerVerifier == 'null' ||
      lowerVerifier == 'undefined' ||
      lowerVerifier == 'denied';

  if (rawDenied.isNotEmpty ||
      rawError.isNotEmpty ||
      (rawVerifier.isNotEmpty && isInvalidVerifierString)) {
    return GarminCallbackParams(
      token: cleanToken,
      error: rawError.isNotEmpty
          ? rawError
          : (rawDenied.isNotEmpty ? rawDenied : 'cancelled'),
    );
  }

  return GarminCallbackParams(
    verifier: rawVerifier.isNotEmpty ? rawVerifier : null,
    token: cleanToken,
  );
}
