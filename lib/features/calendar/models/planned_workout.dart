import 'package:cloud_firestore/cloud_firestore.dart';

/// Repräsentiert eine geplante Trainingseinheit im Kalender (`plannedWorkouts/{workoutId}`).
class PlannedWorkout {
  /// Eindeutige ID des Dokuments.
  final String id;

  /// ID des Athleten, dem diese Einheit zugeordnet ist.
  final String athleteId;

  /// Denormalisierte Trainer-ID (falls ein Trainer zugeordnet ist).
  final String? coachId;

  /// UID des Erstellers (Athlet selbst oder Trainer).
  final String createdBy;

  /// Lokales Datum am Ort des Athleten im Format `yyyy-MM-dd`.
  final String localDate;

  /// Haupt-Sportart: SWIM, BIKE, RUN, STRENGTH, MULTISPORT, OTHER.
  final String sport;

  /// Optionale Sub-Sportart (z. B. POOL, OPEN_WATER, INDOOR, TRAIL).
  final String? subSport;

  /// Titel der Einheit (z. B. "Grundlage GA1 90 min").
  final String title;

  /// Optionale Trainingsbeschreibung / Anweisungen.
  final String? description;

  /// Geplante Netto-Dauer in Sekunden.
  final int plannedDurationSec;

  /// Geplante Distanz in Metern.
  final double? plannedDistanceM;

  /// Geplante Belastung (TSS / ORBIT Score).
  final double? plannedLoad;

  /// Grobe Intensität: EASY, MODERATE, HARD, INTERVALS.
  final String? intensity;

  /// Strukturierte Intervalle / Blöcke (Schema v1).
  final Map<String, dynamic>? structure;

  /// Status der Einheit: PLANNED, COMPLETED, SKIPPED.
  final String status;

  /// Verknüpfte ID der absolvierten Aktivität (wenn COMPLETED).
  final String? activityId;

  /// Vorlagen-ID, falls aus Vorlage erstellt.
  final String? templateId;

  /// Zeitstempel der Erstellung.
  final DateTime? createdAt;

  /// Zeitstempel der letzten Bearbeitung.
  final DateTime? updatedAt;

  const PlannedWorkout({
    required this.id,
    required this.athleteId,
    this.coachId,
    required this.createdBy,
    required this.localDate,
    required this.sport,
    this.subSport,
    required this.title,
    this.description,
    required this.plannedDurationSec,
    this.plannedDistanceM,
    this.plannedLoad,
    this.intensity,
    this.structure,
    this.status = 'PLANNED',
    this.activityId,
    this.templateId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isSkipped => status == 'SKIPPED';
  bool get isPlanned => status == 'PLANNED';

  /// Gibt an, ob die Einheit von einem Trainer (und nicht vom Athleten selbst) geplant wurde.
  bool isPlannedByCoach(String currentAthleteId) =>
      createdBy != currentAthleteId;

  /// Formatierte geplante Dauer (z. B. "1h 30m" oder "45m").
  String get formattedDuration {
    final hours = plannedDurationSec ~/ 3600;
    final minutes = (plannedDurationSec % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  /// Formatierte geplante Distanz (z. B. "12.5 km" oder "2.500 m" beim Schwimmen).
  String? get formattedDistance {
    if (plannedDistanceM == null) return null;
    if (sport == 'SWIM') {
      return '${plannedDistanceM!.toStringAsFixed(0)} m';
    }
    final km = plannedDistanceM! / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Erstellt ein [PlannedWorkout] aus einem Firestore DocumentSnapshot.
  factory PlannedWorkout.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PlannedWorkout.fromMap(doc.id, data);
  }

  /// Erstellt ein [PlannedWorkout] aus einem generischen DocumentSnapshot.
  factory PlannedWorkout.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return PlannedWorkout.fromMap(doc.id, data);
  }

  /// Erstellt ein [PlannedWorkout] aus einer Map mit gegebener Dokument-ID.
  factory PlannedWorkout.fromMap(String id, Map<String, dynamic> map) {
    DateTime? created;
    DateTime? updated;

    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }

    final rawUpdated = map['updatedAt'];
    if (rawUpdated is Timestamp) {
      updated = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      updated = DateTime.tryParse(rawUpdated);
    }

    return PlannedWorkout(
      id: id,
      athleteId: (map['athleteId'] as String?) ?? '',
      coachId: map['coachId'] as String?,
      createdBy: (map['createdBy'] as String?) ?? '',
      localDate: (map['localDate'] as String?) ?? '',
      sport: (map['sport'] as String?) ?? 'OTHER',
      subSport: map['subSport'] as String?,
      title: (map['title'] as String?) ?? 'Trainingseinheit',
      description: map['description'] as String?,
      plannedDurationSec: (map['plannedDurationSec'] as num?)?.toInt() ?? 0,
      plannedDistanceM: (map['plannedDistanceM'] as num?)?.toDouble(),
      plannedLoad: (map['plannedLoad'] as num?)?.toDouble(),
      intensity: map['intensity'] as String?,
      structure: map['structure'] as Map<String, dynamic>?,
      status: (map['status'] as String?) ?? 'PLANNED',
      activityId: map['activityId'] as String?,
      templateId: map['templateId'] as String?,
      createdAt: created,
      updatedAt: updated,
    );
  }

  /// Konvertiert das Objekt in eine speicherbare Map für Firestore.
  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'coachId': coachId,
      'createdBy': createdBy,
      'localDate': localDate,
      'sport': sport,
      'subSport': subSport,
      'title': title,
      'description': description,
      'plannedDurationSec': plannedDurationSec,
      'plannedDistanceM': plannedDistanceM,
      'plannedLoad': plannedLoad,
      'intensity': intensity,
      'structure': structure,
      'status': status,
      'activityId': activityId,
      'templateId': templateId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PlannedWorkout copyWith({
    String? id,
    String? athleteId,
    String? coachId,
    String? createdBy,
    String? localDate,
    String? sport,
    String? subSport,
    String? title,
    String? description,
    int? plannedDurationSec,
    double? plannedDistanceM,
    double? plannedLoad,
    String? intensity,
    Map<String, dynamic>? structure,
    String? status,
    String? activityId,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlannedWorkout(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      coachId: coachId ?? this.coachId,
      createdBy: createdBy ?? this.createdBy,
      localDate: localDate ?? this.localDate,
      sport: sport ?? this.sport,
      subSport: subSport ?? this.subSport,
      title: title ?? this.title,
      description: description ?? this.description,
      plannedDurationSec: plannedDurationSec ?? this.plannedDurationSec,
      plannedDistanceM: plannedDistanceM ?? this.plannedDistanceM,
      plannedLoad: plannedLoad ?? this.plannedLoad,
      intensity: intensity ?? this.intensity,
      structure: structure ?? this.structure,
      status: status ?? this.status,
      activityId: activityId ?? this.activityId,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
