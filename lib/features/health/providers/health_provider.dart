import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/daily_metrics.dart';
import '../models/health_baseline.dart';
import '../domain/readiness_evaluator.dart';

/// Prüft, ob der aktuelle Nutzer (Athlet selbst oder Trainer) Leseberechtigung für Health-Daten des [athleteId] besitzt.
final coachHealthPermissionProvider =
    StreamProvider.family<bool, String>((ref, athleteId) {
  final currentUid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (currentUid == null) return Stream.value(false);

  // Der Athlet selbst hat immer Zugriff auf seine eigenen Daten
  if (currentUid == athleteId) {
    return Stream.value(true);
  }

  // Trainer: Link prüfen unter `coachLinks/{athleteId}_{coachId}`
  final linkId = '${athleteId}_$currentUid';
  return FirebaseFirestore.instance
      .collection('coachLinks')
      .doc(linkId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return false;
    final data = snapshot.data();
    final permissions = data?['permissions'] as Map<String, dynamic>?;
    return permissions?['health'] == true;
  });
});

/// Liefert die DailyMetrics-Historie der letzten 28 Tage für den angegebenen Athleten.
final athleteDailyMetricsHistoryProvider =
    StreamProvider.family<List<DailyMetrics>, String>((ref, athleteId) {
  // Sicherheitsprüfung: Darf der Nutzer Health-Daten lesen?
  final hasPermission =
      ref.watch(coachHealthPermissionProvider(athleteId)).valueOrNull ?? false;
  if (!hasPermission) {
    return Stream.value([]);
  }

  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 28));
  final startDateStr =
      "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

  return FirebaseFirestore.instance
      .collection('users')
      .doc(athleteId)
      .collection('dailyMetrics')
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDateStr)
      .snapshots()
      .map((snapshot) {
    // Falls keine echten Daten vorhanden sind, prüfen ob Demo-Modus aktiv ist oder Fallback anbieten
    if (snapshot.docs.isEmpty) {
      return <DailyMetrics>[];
    }

    return snapshot.docs.map((doc) => DailyMetrics.fromFirestore(doc)).toList()
      ..sort((a, b) => a.localDate.compareTo(b.localDate));
  });
});

/// Berechnet die [HealthBaseline] für den gegebenen [athleteId].
final healthBaselineProvider =
    Provider.family<HealthBaseline, String>((ref, athleteId) {
  final historyAsync = ref.watch(athleteDailyMetricsHistoryProvider(athleteId));
  final history = historyAsync.valueOrNull ?? [];
  return HealthBaseline.fromMetrics(history);
});

/// Liefert die Tagesform-Bewertung [ReadinessEvaluation] für heute.
final todayReadinessProvider =
    Provider.family<ReadinessEvaluation, String>((ref, athleteId) {
  final historyAsync = ref.watch(athleteDailyMetricsHistoryProvider(athleteId));
  final history = historyAsync.valueOrNull ?? [];
  final baseline = ref.watch(healthBaselineProvider(athleteId));

  final now = DateTime.now();
  final todayStr =
      "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  DailyMetrics? todayMetrics;
  for (final m in history) {
    if (m.localDate == todayStr) {
      todayMetrics = m;
      break;
    }
  }

  // Falls heute noch keine Messung eingegangen ist, aber gestern eine vorliegt:
  if (todayMetrics == null && history.isNotEmpty) {
    todayMetrics = history.last;
  }

  return ReadinessEvaluation.evaluate(
    baseline: baseline,
    today: todayMetrics,
  );
});
