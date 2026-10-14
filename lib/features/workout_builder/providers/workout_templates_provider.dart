import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_template.dart';
import '../repositories/workout_template_repository.dart';

/// Provider für das WorkoutTemplateRepository.
final workoutTemplateRepositoryProvider =
    Provider<WorkoutTemplateRepository>((ref) {
  return WorkoutTemplateRepository();
});

/// StreamProvider für die Workout-Vorlagen des aktuellen Nutzers.
final workoutTemplatesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  final repo = ref.watch(workoutTemplateRepositoryProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
  return repo.watchTemplates(userId: uid);
});
