/// Datei-Header: `lib/features/coach_link/models/v1_coach_athlete_link.dart`
/// Zweck: Schlankes, unveränderliches Datenmodell für Coach-Athleten-Verbindungen
/// und offene Verbindungsanfragen im V1.0.0-Scope (Phase 44).
/// Architektur-Einordnung: Modellschicht (`lib/features/coach_link/models/`),
/// trennt Firestore-Dokumentdaten sauber von UI-Widgets (`AGENTS.md` Regel 10).
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Repräsentiert eine aktive oder ausstehende Coach-Athleten-Verbindung in V1.0.0.
///
/// Was: Kapselt die Verknüpfungsdaten aus `coachLinks/{athleteId}_{coachId}`
/// inklusive angereicherter Profil- und Aktivitäts-Metadaten (Name, E-Mail,
/// Hauptsportarten inkl. `TRIATHLON`, Datum der letzten Aktivität).
/// Warum: Ermöglicht sowohl dem Coach (Athletenliste & Kalenderwechsel) als auch
/// dem Athleten (Coach-Verbindungsbereich im „Profil Einfach“) eine einheitliche,
/// typsichere Darstellung ohne direkte Firestore-Maps im Widget-Code.
class V1CoachAthleteLink {
  /// Dokument-ID (`{athleteId}_{coachId}`).
  final String linkId;

  /// UID des Athleten.
  final String athleteId;

  /// UID des Coaches.
  final String coachId;

  /// Verknüpfungsstatus (`'ACTIVE'`, `'PENDING'`, `'REVOKED'`).
  final String status;

  /// Anzeigename des Athleten.
  final String athleteName;

  /// E-Mail-Adresse des Athleten.
  final String athleteEmail;

  /// Anzeigename des Coaches.
  final String coachName;

  /// E-Mail-Adresse des Coaches.
  final String coachEmail;

  /// Hauptsportarten des Athleten (z. B. `['TRIATHLON', 'BIKE', 'RUN']`).
  final List<String> athleteSports;

  /// Zeitstempel der zuletzt absolvierten Aktivität des Athleten (optional).
  final DateTime? lastActivityAt;

  /// Ob der Athlet dem Coach Zugriff auf absolvierte Trainings & `.fit`-Dateien gewährt hat.
  final bool shareActivities;

  /// Ob der Athlet dem Coach Zugriff auf den Kalender gewährt hat.
  final bool shareCalendar;

  /// Erstellt ein unveränderliches [V1CoachAthleteLink]-Objekt.
  const V1CoachAthleteLink({
    required this.linkId,
    required this.athleteId,
    required this.coachId,
    required this.status,
    this.athleteName = '',
    this.athleteEmail = '',
    this.coachName = '',
    this.coachEmail = '',
    this.athleteSports = const [],
    this.lastActivityAt,
    this.shareActivities = false,
    this.shareCalendar = false,
  });

  /// Ob die Verbindung aktiv und vom Athleten per DSGVO freigegeben ist.
  bool get isActive => status == 'ACTIVE';

  /// Ob es sich um eine offene, noch nicht bestätigte Verbindungsanfrage handelt.
  bool get isPending => status == 'PENDING';

  /// Erzeugt eine Kopie mit aktualisierten Feldern (z. B. nach Profil-Anreicherung).
  V1CoachAthleteLink copyWith({
    String? athleteName,
    String? athleteEmail,
    String? coachName,
    String? coachEmail,
    List<String>? athleteSports,
    DateTime? lastActivityAt,
  }) {
    return V1CoachAthleteLink(
      linkId: linkId,
      athleteId: athleteId,
      coachId: coachId,
      status: status,
      athleteName: athleteName ?? this.athleteName,
      athleteEmail: athleteEmail ?? this.athleteEmail,
      coachName: coachName ?? this.coachName,
      coachEmail: coachEmail ?? this.coachEmail,
      athleteSports: athleteSports ?? this.athleteSports,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      shareActivities: shareActivities,
      shareCalendar: shareCalendar,
    );
  }

  /// Erstellt ein [V1CoachAthleteLink] aus einem Firestore-`coachLinks`-Dokument.
  factory V1CoachAthleteLink.fromMap(
    String docId,
    Map<String, dynamic> data,
  ) {
    final permissions = data['permissions'] as Map<String, dynamic>? ?? const {};
    final rawLast = data['lastActivityAt'];
    DateTime? parsedLast;
    if (rawLast is Timestamp) {
      parsedLast = rawLast.toDate();
    } else if (rawLast is String) {
      parsedLast = DateTime.tryParse(rawLast);
    }

    return V1CoachAthleteLink(
      linkId: docId,
      athleteId: data['athleteId'] as String? ?? '',
      coachId: data['coachId'] as String? ?? '',
      status: (data['status'] as String? ?? 'ACTIVE').toUpperCase(),
      athleteName: (data['athleteName'] as String? ?? '').trim(),
      athleteEmail: (data['athleteEmail'] as String? ?? '').trim(),
      coachName: (data['coachName'] as String? ?? '').trim(),
      coachEmail: (data['coachEmail'] as String? ?? '').trim(),
      athleteSports: (data['athleteSports'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          const [],
      lastActivityAt: parsedLast,
      shareActivities: permissions['activities'] as bool? ?? false,
      shareCalendar: permissions['calendar'] as bool? ?? false,
    );
  }
}
