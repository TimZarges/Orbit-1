import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/threshold_proposal.dart';
import '../models/threshold_entry.dart';
import '../repositories/diagnostics_repository.dart';

/// Provider für das DiagnosticsRepository.
final diagnosticsRepositoryProvider = Provider<DiagnosticsRepository>((ref) {
  return DiagnosticsRepository();
});

/// Stream-Provider für alle offenen Schwellenwert-Vorschläge eines Athleten.
final pendingProposalsProvider =
    StreamProvider.family<List<ThresholdProposal>, String>((ref, athleteId) {
  final repository = ref.watch(diagnosticsRepositoryProvider);
  return repository.watchPendingProposals(athleteId);
});

/// Stream-Provider für die chronologische Schwellenwert-Historie.
final thresholdHistoryProvider =
    StreamProvider.family<List<ThresholdEntry>, String>((ref, athleteId) {
  final repository = ref.watch(diagnosticsRepositoryProvider);
  return repository.watchThresholdHistory(athleteId);
});

/// Future-Provider für den aktuellsten Schwellenwert-Stand.
final latestThresholdsProvider =
    FutureProvider.family<ThresholdEntry?, String>((ref, athleteId) {
  final repository = ref.watch(diagnosticsRepositoryProvider);
  return repository.getLatestThresholds(athleteId);
});
