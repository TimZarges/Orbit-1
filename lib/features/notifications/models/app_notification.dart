import 'package:cloud_firestore/cloud_firestore.dart';

/// Typen von System- und Trainings-Benachrichtigungen in der ORBIT-Applikation.
enum NotificationType {
  /// Neuer sportwissenschaftlicher Schwellenwert erkannt (z. B. FTP, CSS).
  thresholdFound,

  /// Neuer persönlicher Rekord (z. B. 5-Min-Power, 5-km-Pace).
  prAchieved,

  /// Garmin-Synchronisation erfolgreich abgeschlossen.
  garminSynced,

  /// Neues Workout vom Trainer zugewiesen.
  workoutAssigned,

  /// Kommentar des Trainers zu einem Workout.
  coachComment,

  /// Allgemeine System- oder Sicherheitsmitteilung.
  system;

  /// Wandelt den String-Code aus Firestore in das Enum um.
  static NotificationType fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'THRESHOLD_FOUND':
        return NotificationType.thresholdFound;
      case 'PR_ACHIEVED':
        return NotificationType.prAchieved;
      case 'GARMIN_SYNCED':
        return NotificationType.garminSynced;
      case 'WORKOUT_ASSIGNED':
        return NotificationType.workoutAssigned;
      case 'COACH_COMMENT':
        return NotificationType.coachComment;
      default:
        return NotificationType.system;
    }
  }

  /// Gibt den Firestore-kompatiblen String-Schlüssel zurück.
  String toDbString() {
    switch (this) {
      case NotificationType.thresholdFound:
        return 'THRESHOLD_FOUND';
      case NotificationType.prAchieved:
        return 'PR_ACHIEVED';
      case NotificationType.garminSynced:
        return 'GARMIN_SYNCED';
      case NotificationType.workoutAssigned:
        return 'WORKOUT_ASSIGNED';
      case NotificationType.coachComment:
        return 'COACH_COMMENT';
      case NotificationType.system:
        return 'SYSTEM';
    }
  }
}

/// Datenmodell für eine Mitteilung im ORBIT Notification Center.
///
/// Dient der zentralen Bündelung aller systemischen Ereignisse
/// (PRs, Diagnostik, Garmin-Sync, Coaching-Updates) getrennt vom 1:1 Coach-Chat.
class AppNotification {
  /// Eindeutige ID des Dokuments.
  final String id;

  /// Überschrift der Mitteilung.
  final String title;

  /// Fließtext oder Details.
  final String body;

  /// Typ der Mitteilung für Icon und Farbkodierung.
  final NotificationType type;

  /// Optionales Deep-Link-Ziel (z. B. `/diagnostics`, `/calendar`, `/activities/xyz`).
  final String? route;

  /// Status, ob die Mitteilung bereits gelesen wurde.
  final bool read;

  /// Zeitstempel der Erstellung.
  final DateTime createdAt;

  /// Erstellt eine AppNotification Instanz.
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.route,
    this.read = false,
    required this.createdAt,
  });

  /// Erstellt eine Instanz aus Firestore-Daten.
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification.fromMap(doc.id, data);
  }

  /// Erstellt eine Instanz aus einer Map.
  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    DateTime created;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    return AppNotification(
      id: id,
      title: data['title'] as String? ?? 'Mitteilung',
      body: data['body'] as String? ?? '',
      type: NotificationType.fromString(data['type'] as String?),
      route: data['route'] as String?,
      read: data['read'] as bool? ?? false,
      createdAt: created,
    );
  }

  /// Wandelt das Modell in eine speicherbare Firestore-Map um.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.toDbString(),
      if (route != null) 'route': route,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Erzeugt eine Kopie mit veränderten Feldern.
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? route,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      route: route ?? this.route,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
