import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_structure.dart';

/// Repräsentiert eine Vorlage für eine strukturierte Trainingseinheit (`workoutTemplates/{templateId}`).
class WorkoutTemplate {
  /// Eindeutige ID des Vorlagendokuments.
  final String id;

  /// UID des Besitzers (Athlet oder Trainer).
  final String ownerId;

  /// Sichtbarkeit: PRIVATE, SHARED_WITH_MY_ATHLETES, PUBLIC.
  final String visibility;

  /// Sportart: SWIM, BIKE, RUN, STRENGTH.
  final String sport;

  /// Titel der Vorlage (z. B. "4x4 Schwellenintervalle").
  final String title;

  /// Optionale Beschreibung oder Trainingshinweise.
  final String? description;

  /// Strukturierte Intervalle (Schema v1).
  final WorkoutStructure structure;

  /// Tags für Filterung und Kategorisierung (z. B. ['Sweet Spot', 'FTP', 'Schwellenbereich']).
  final List<String> tags;

  /// Gibt an, ob der aktuelle Nutzer diese Vorlage als Favorit markiert hat.
  final bool isFavorite;

  /// Erstellungszeitpunkt.
  final DateTime? createdAt;

  /// Letzter Aktualisierungszeitpunkt.
  final DateTime? updatedAt;

  const WorkoutTemplate({
    required this.id,
    required this.ownerId,
    this.visibility = 'PRIVATE',
    required this.sport,
    required this.title,
    this.description,
    required this.structure,
    this.tags = const [],
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Prüft, ob die Vorlage vom Trainer mit seinen Athleten geteilt ist.
  bool get isSharedWithAthletes => visibility == 'SHARED_WITH_MY_ATHLETES';

  WorkoutTemplate copyWith({
    String? id,
    String? ownerId,
    String? visibility,
    String? sport,
    String? title,
    String? description,
    WorkoutStructure? structure,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      visibility: visibility ?? this.visibility,
      sport: sport ?? this.sport,
      title: title ?? this.title,
      description: description ?? this.description,
      structure: structure ?? this.structure,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Konvertiert in eine Map für Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'visibility': visibility,
      'sport': sport.toUpperCase(),
      'title': title,
      if (description != null && description!.isNotEmpty) 'description': description,
      'structure': structure.toJson(),
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Erstellt eine Vorlage aus einem Firestore-Dokument.
  factory WorkoutTemplate.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawStructure = data['structure'] as Map<String, dynamic>? ?? {};
    final struct = rawStructure.isNotEmpty
        ? WorkoutStructure.migrateStructure(rawStructure)
        : WorkoutStructure(sport: data['sport'] as String? ?? 'BIKE', blocks: const []);

    final tagsList = (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return WorkoutTemplate(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      visibility: data['visibility'] as String? ?? 'PRIVATE',
      sport: (data['sport'] as String? ?? 'BIKE').toUpperCase(),
      title: data['title'] as String? ?? 'Unbenannte Vorlage',
      description: data['description'] as String?,
      structure: struct,
      tags: tagsList,
      isFavorite: data['isFavorite'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
