import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/template_seed_data.dart';
import '../models/workout_template.dart';

/// Repository für das Laden, Speichern und Verwalten von Workout-Vorlagen.
class WorkoutTemplateRepository {
  final FirebaseFirestore _firestore;

  WorkoutTemplateRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('workoutTemplates');

  /// Stream aller für den Nutzer relevanten Vorlagen (eigene Vorlagen und geteilte Vorlagen des Trainers).
  Stream<List<WorkoutTemplate>> watchTemplates({
    required String userId,
    String? coachId,
  }) {
    // Beobachtet primär eigene Vorlagen des Nutzers
    return _collection
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final userTemplates = snapshot.docs
              .map((doc) => WorkoutTemplate.fromFirestore(doc))
              .toList();

          // Falls ein Trainer zugewiesen ist, geteilte Trainer-Vorlagen laden
          if (coachId != null && coachId.isNotEmpty) {
            try {
              final coachSnapshot = await _collection
                  .where('ownerId', isEqualTo: coachId)
                  .where('visibility', isEqualTo: 'SHARED_WITH_MY_ATHLETES')
                  .get();

              final coachTemplates = coachSnapshot.docs
                  .map((doc) => WorkoutTemplate.fromFirestore(doc))
                  .toList();

              return [...userTemplates, ...coachTemplates];
            } catch (_) {
              return userTemplates;
            }
          }

          return userTemplates;
        });
  }

  /// Lädt Vorlagen einmalig mit optionalen Filtern (Sportart, Suchbegriff, Favoriten).
  Future<List<WorkoutTemplate>> getTemplates({
    required String userId,
    String? coachId,
    String? sport,
    String? searchQuery,
    bool? onlyFavorites,
  }) async {
    final query = _collection.where('ownerId', isEqualTo: userId);
    final snapshot = await query.get();

    var templates = snapshot.docs
        .map((doc) => WorkoutTemplate.fromFirestore(doc))
        .toList();

    // Trainer-Vorlagen ergänzen
    if (coachId != null && coachId.isNotEmpty) {
      try {
        final coachSnapshot = await _collection
            .where('ownerId', isEqualTo: coachId)
            .where('visibility', isEqualTo: 'SHARED_WITH_MY_ATHLETES')
            .get();

        templates.addAll(
          coachSnapshot.docs.map((doc) => WorkoutTemplate.fromFirestore(doc)),
        );
      } catch (_) {}
    }

    // Filter anwenden
    if (sport != null && sport.isNotEmpty && sport.toUpperCase() != 'ALL') {
      templates = templates
          .where((t) => t.sport.toUpperCase() == sport.toUpperCase())
          .toList();
    }

    if (onlyFavorites == true) {
      templates = templates.where((t) => t.isFavorite).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      templates = templates.where((t) {
        final titleMatch = t.title.toLowerCase().contains(q);
        final descMatch = t.description?.toLowerCase().contains(q) ?? false;
        final tagMatch = t.tags.any((tag) => tag.toLowerCase().contains(q));
        return titleMatch || descMatch || tagMatch;
      }).toList();
    }

    return templates;
  }

  /// Erstellt eine neue Vorlage in Firestore.
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    final docRef = _collection.doc();
    final toSave = template.copyWith(id: docRef.id);
    await docRef.set(toSave.toFirestore());
    return toSave;
  }

  /// Aktualisiert eine bestehende Vorlage.
  Future<void> updateTemplate(WorkoutTemplate template) async {
    await _collection.doc(template.id).update(template.toFirestore());
  }

  /// Löscht eine Vorlage.
  Future<void> deleteTemplate(String templateId) async {
    await _collection.doc(templateId).delete();
  }

  /// Schaltet den Favoritenstatus um.
  Future<void> toggleFavorite(String templateId, bool currentFavorite) async {
    await _collection.doc(templateId).update({
      'isFavorite': !currentFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Befüllt die Vorlagenbibliothek initial mit den 20 Startvorlagen, falls noch keine existieren.
  Future<int> seedInitialTemplatesIfEmpty(String userId) async {
    final existing = await _collection
        .where('ownerId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return 0; // Bereits Vorlagen vorhanden
    }

    final seeds = TemplateSeedData.getInitialTemplates(currentUserId: userId);
    final batch = _firestore.batch();

    for (final template in seeds) {
      final docRef = _collection.doc();
      final toSave = template.copyWith(id: docRef.id);
      batch.set(docRef, toSave.toFirestore());
    }

    await batch.commit();
    return seeds.length;
  }
}
