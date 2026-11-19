/// Datei-Header: `lib/features/coach_link/providers/v1_coach_connection_provider.dart`
/// Zweck: Service und Riverpod-Provider für die V1.0.0 Coach-Athleten-Verbindung,
/// Einladungscodes, E-Mail-Anfragen, DSGVO-Datenfreigabe und Athleten-Auswahl
/// im Coach-Kalender (Phase 44).
/// Architektur-Einordnung: Geschäftslogik- und Service-Schicht
/// (`lib/features/coach_link/providers/`), strikt getrennt von UI-Widgets
/// (`AGENTS.md` Regel 10).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../models/v1_coach_athlete_link.dart';

/// Funktionssignatur für abstrahierte Cloud-Function-Aufrufe (ermöglicht Test-Mocks).
typedef CoachCallableInvoker = Future<Map<String, dynamic>> Function(
  String functionName,
  Map<String, dynamic> payload,
);

/// Service zur Verwaltung der V1.0.0 Coach-Athleten-Beziehung über
/// Cloud Functions (`europe-west3`) mit expliziter DSGVO-Einwilligung.
///
/// Was: Kapselt alle Schreibaktionen für Einladungscodes (`createInvite`,
/// `redeemInvite`), E-Mail-Verbindungsanfragen (`requestAthleteLinkByEmail`,
/// `respondToCoachLinkRequest`) und das sofortige Trennen (`revokeLink`).
/// Warum: Verhindert direkte Client-Schreibzugriffe auf `coachLinks`
/// (`firestore.rules` -> `allow write: if false`) und ermöglicht sauberes Mocking
/// in Widget- und Unit-Tests.
class V1CoachConnectionService {
  /// Injizierbarer Aufrufer für Cloud Functions in `europe-west3`.
  final CoachCallableInvoker _invoke;

  /// Erstellt einen [V1CoachConnectionService].
  ///
  /// [invoke]: Optionaler benutzerdefinierter Aufrufer für Tests.
  V1CoachConnectionService({CoachCallableInvoker? invoke})
      : _invoke = invoke ?? _defaultInvoker;

  /// Standard-Aufrufer gegen Firebase Cloud Functions (`europe-west3`).
  static Future<Map<String, dynamic>> _defaultInvoker(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
        .httpsCallable(functionName);
    final result = await callable.call(payload);
    final raw = result.data;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  /// Erzeugt für den eingeloggten Coach einen 6-stelligen Einladungscode.
  Future<String> createInviteCode() async {
    final data = await _invoke('createInvite', const {});
    return (data['code'] as String? ?? '').trim().toUpperCase();
  }

  /// Löst auf Athletenseite einen Einladungscode ein, nachdem die
  /// ausdrückliche DSGVO-Datenfreigabe bestätigt wurde.
  ///
  /// [code]: 6-stelliger Einladungscode des Coaches.
  /// [gdprConsent]: Muss zwingend `true` sein; sonst wird eine [ArgumentError] geworfen.
  Future<String> redeemInviteWithConsent({
    required String code,
    required bool gdprConsent,
  }) async {
    if (!gdprConsent) {
      throw ArgumentError('DSGVO-Datenfreigabe ist erforderlich.');
    }
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw ArgumentError('Einladungscode darf nicht leer sein.');
    }
    final data = await _invoke('redeemInvite', {'code': normalized});
    return (data['coachId'] as String? ?? '').trim();
  }

  /// Sendet auf Coach-Seite eine Verbindungsanfrage an die E-Mail-Adresse eines Athleten.
  Future<Map<String, dynamic>> requestAthleteByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw ArgumentError('Bitte eine gültige E-Mail-Adresse eingeben.');
    }
    return _invoke('requestAthleteLinkByEmail', {'email': normalized});
  }

  /// Beantwortet auf Athletenseite eine eingehende Verbindungsanfrage eines Coaches.
  ///
  /// [linkId]: Dokument-ID `{athleteId}_{coachId}`.
  /// [accept]: `true` zum Bestätigen, `false` zum Ablehnen.
  /// [gdprConsent]: Muss bei Annahme zwingend `true` sein.
  Future<void> respondToPendingRequest({
    required String linkId,
    required bool accept,
    required bool gdprConsent,
  }) async {
    if (accept && !gdprConsent) {
      throw ArgumentError('DSGVO-Datenfreigabe ist erforderlich.');
    }
    await _invoke('respondToCoachLinkRequest', {
      'linkId': linkId,
      'accept': accept,
      'gdprConsent': gdprConsent,
    });
  }

  /// Prüft serverseitig auf offene E-Mail-Einladungen (`coachInvites`) für den
  /// aktuell angemeldeten Athleten und überführt diese in `PENDING`-Anfragen.
  Future<int> claimPendingInvites() async {
    final data = await _invoke('claimPendingCoachInvites', const {});
    return (data['claimedCount'] as num?)?.toInt() ?? 0;
  }

  /// Zieht eine offene E-Mail-Einladung für noch nicht registrierte Athleten zurück.
  Future<void> revokePendingInvite(String inviteId) async {
    await _invoke('revokeCoachInvite', {'inviteId': inviteId});
  }

  /// Beendet eine bestehende Verbindung (oder zieht eine offene Anfrage zurück)
  /// und entzieht dem Coach sofort alle Leserechte.
  Future<void> revokeLink(String linkId) async {
    await _invoke('revokeLink', {'linkId': linkId});
  }
}

/// Modell einer offenen Coach-E-Mail-Einladung für noch nicht registrierte Athleten.
class V1PendingCoachEmailInvite {
  /// Dokument-ID in `coachInvites`.
  final String inviteId;

  /// Normalisierte E-Mail-Adresse des eingeladenen Athleten.
  final String athleteEmail;

  /// Zugehöriger 6-stelliger Einladungscode des Coaches.
  final String inviteCode;

  /// Status (`'PENDING_REGISTRATION'`).
  final String status;

  /// Erstellt ein [V1PendingCoachEmailInvite].
  const V1PendingCoachEmailInvite({
    required this.inviteId,
    required this.athleteEmail,
    required this.inviteCode,
    required this.status,
  });

  /// Erzeugt das Modell aus einem Firestore-Dokument.
  factory V1PendingCoachEmailInvite.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return V1PendingCoachEmailInvite(
      inviteId: id,
      athleteEmail: (map['athleteEmail'] as String? ?? '').trim(),
      inviteCode: (map['inviteCode'] as String? ?? '').trim().toUpperCase(),
      status: (map['status'] as String? ?? 'PENDING_REGISTRATION').trim(),
    );
  }
}

/// Stream aller noch unbeanspruchten E-Mail-Einladungen (`coachInvites`) eines Coaches.
///
/// Verwendet bewusst eine Einzel-Feld-Query (`coachId == uid`) mit clientseitiger
/// Statusfilterung, damit auf Live-Firestore niemals ein fehlender Composite Index
/// die Liste blockiert.
final v1CoachPendingEmailInvitesStreamProvider =
    StreamProvider.autoDispose<List<V1PendingCoachEmailInvite>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection('coachInvites')
      .where('coachId', isEqualTo: uid)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => V1PendingCoachEmailInvite.fromMap(d.id, d.data()))
            .where((inv) => inv.status == 'PENDING_REGISTRATION')
            .toList(growable: false),
      );
});

/// Automatische Übernahme offener Coach-E-Mail-Einladungen (`coachInvites`) für
/// angemeldete Athleten, unabhängig davon, ob das Profil bereits geöffnet wurde.
final v1AutoClaimCoachInvitesProvider = FutureProvider.autoDispose<int>((ref) async {
  if (Firebase.apps.isEmpty) return 0;
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) return 0;
  final userDoc = ref.watch(userDocumentProvider).valueOrNull;
  if (userDoc?['role'] == 'TRAINER') return 0;

  try {
    return await ref
        .read(v1CoachConnectionServiceProvider)
        .claimPendingInvites();
  } catch (_) {
    return 0;
  }
});

/// Riverpod-Provider für den [V1CoachConnectionService].
final v1CoachConnectionServiceProvider =
    Provider<V1CoachConnectionService>((ref) {
  return V1CoachConnectionService();
});

/// Aktiver Tab-Index der V1.0.0 Coach-3-Tab-Navigation
/// (`0 = Athleten`, `1 = Kalender`, `2 = Profil`).
final v1CoachTabIndexProvider = StateProvider<int>((ref) => 0);

/// Aktuell ausgewählter Athlet im V1.0.0 Coach-Kalender (Tab 2).
final v1SelectedCoachAthleteIdProvider = StateProvider<String?>((ref) => null);

/// Echtzeit-Stream aller aktiven und offenen Athleten-Verbindungen des Coaches.
///
/// Was: Überwacht `coachLinks` mit Einzel-Feld-Query `coachId == currentUid`,
/// filtert `ACTIVE`/`PENDING` lokal und reichert aktive Athleten mit Profildaten
/// (Name, E-Mail, Hauptsportarten inkl. `TRIATHLON`) sowie dem Datum der letzten
/// absolvierten Aktivität an.
/// Warum: Hält die Coach-Athletenliste ohne Composite-Index-Abhängigkeit immer synchron.
final v1CoachAthletesStreamProvider =
    StreamProvider.autoDispose<List<V1CoachAthleteLink>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) return Stream.value(const []);

  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('coachLinks')
      .where('coachId', isEqualTo: uid)
      .snapshots()
      .asyncMap((snapshot) async {
        final links = snapshot.docs
            .map((doc) => V1CoachAthleteLink.fromMap(doc.id, doc.data()))
            .where((l) => l.isActive || l.isPending)
            .toList();

        // Athleten-Metadaten (Profil & letzte Aktivität) parallel nachladen
        final enriched = await Future.wait(
          links.map((link) => _enrichLinkForCoach(firestore, link)),
        );

        // Aktive Athleten zuerst, danach alphabetisch nach Name sortieren
        enriched.sort((a, b) {
          if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
          return a.athleteName
              .toLowerCase()
              .compareTo(b.athleteName.toLowerCase());
        });
        return enriched;
      });
});

/// Echtzeit-Stream aller aktiven und eingehenden Coach-Verbindungen des Athleten.
///
/// Was: Überwacht `coachLinks` über Einzel-Feld-Query `athleteId == currentUid`,
/// filtert `ACTIVE`/`PENDING` lokal (ohne Zwang zu einem Composite Index) und
/// ergänzt bei Bedarf den Coach-Namen sowie die E-Mail-Adresse aus `users/{coachId}`.
final v1AthleteCoachLinksStreamProvider =
    StreamProvider.autoDispose<List<V1CoachAthleteLink>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) return Stream.value(const []);

  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('coachLinks')
      .where('athleteId', isEqualTo: uid)
      .snapshots()
      .asyncMap((snapshot) async {
        final links = snapshot.docs
            .map((doc) => V1CoachAthleteLink.fromMap(doc.id, doc.data()))
            .where((l) => l.isActive || l.isPending)
            .toList();

        return Future.wait(
          links.map((link) => _enrichLinkForAthlete(firestore, link)),
        );
      });
});

/// Lädt für einen Coach-Link Profildaten (`users/{athleteId}`) und das Datum
/// der jüngsten Aktivität (`activities`, Limit 1) sparsam nach.
Future<V1CoachAthleteLink> _enrichLinkForCoach(
  FirebaseFirestore firestore,
  V1CoachAthleteLink link,
) async {
  var result = link;
  if (!link.isActive) {
    return result;
  }

  // 1. Athleten-Profil nachladen (Name, E-Mail, Hauptsportarten)
  try {
    final userDoc =
        await firestore.collection('users').doc(link.athleteId).get();
    if (userDoc.exists) {
      final data = userDoc.data() ?? const {};
      final profile = data['profile'] as Map<String, dynamic>? ?? const {};
      final firstName = (profile['firstName'] as String? ?? '').trim();
      final lastName = (profile['lastName'] as String? ?? '').trim();
      final displayName = (profile['displayName'] as String? ?? '').trim();
      final fullName =
          [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
      final resolvedName = fullName.isNotEmpty
          ? fullName
          : (displayName.isNotEmpty
              ? displayName
              : (data['email'] as String? ?? link.athleteName));
      final email = (data['email'] as String? ?? link.athleteEmail).trim();
      final rawSports = profile['sports'] ?? profile['sportTypes'];
      final sports = rawSports is List
          ? rawSports.map((e) => e.toString().toUpperCase()).toList()
          : link.athleteSports;

      result = result.copyWith(
        athleteName: resolvedName,
        athleteEmail: email,
        athleteSports: sports,
      );
    }
  } catch (_) {
    // Bei fehlenden Leserechten Fallback auf denormalisierte Link-Felder
  }

  // 2. Letzte absolvierte Aktivität abrufen (sparend mit limit(1))
  try {
    final actSnap = await firestore
        .collection('activities')
        .where('athleteId', isEqualTo: link.athleteId)
        .orderBy('startTimeUtc', descending: true)
        .limit(1)
        .get();
    if (actSnap.docs.isNotEmpty) {
      final actData = actSnap.docs.first.data();
      final rawStart = actData['startTimeUtc'];
      DateTime? lastAt;
      if (rawStart is Timestamp) {
        lastAt = rawStart.toDate();
      } else if (rawStart is String) {
        lastAt = DateTime.tryParse(rawStart);
      }
      if (lastAt != null) {
        result = result.copyWith(lastActivityAt: lastAt);
      }
    }
  } catch (_) {
    // Keine Aktivität oder fehlender Index -> lastActivityAt bleibt optional
  }

  return result;
}

/// Lädt für den Athleten fehlende Coach-Stammdaten (`users/{coachId}`) nach.
Future<V1CoachAthleteLink> _enrichLinkForAthlete(
  FirebaseFirestore firestore,
  V1CoachAthleteLink link,
) async {
  if (link.coachName.isNotEmpty && link.coachEmail.isNotEmpty) {
    return link;
  }
  try {
    final coachDoc =
        await firestore.collection('users').doc(link.coachId).get();
    if (coachDoc.exists) {
      final data = coachDoc.data() ?? const {};
      final profile = data['profile'] as Map<String, dynamic>? ?? const {};
      final firstName = (profile['firstName'] as String? ?? '').trim();
      final lastName = (profile['lastName'] as String? ?? '').trim();
      final displayName = (profile['displayName'] as String? ?? '').trim();
      final fullName =
          [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
      final resolvedName = fullName.isNotEmpty
          ? fullName
          : (displayName.isNotEmpty
              ? displayName
              : (data['email'] as String? ?? 'Coach'));
      final email = (data['email'] as String? ?? link.coachEmail).trim();
      return link.copyWith(coachName: resolvedName, coachEmail: email);
    }
  } catch (_) {
    // Fallback auf Link-Metadaten
  }
  return link;
}
