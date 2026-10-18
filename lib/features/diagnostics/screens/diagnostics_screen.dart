import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/threshold_proposal.dart';
import '../models/threshold_entry.dart';
import '../models/guided_test_info.dart';
import '../providers/diagnostics_providers.dart';
import '../widgets/threshold_proposal_card.dart';
import '../widgets/guided_test_card.dart';
import '../widgets/recompute_confirmation_dialog.dart';
import '../widgets/threshold_history_chart.dart';
import '../../calendar/repositories/planned_workout_repository.dart';
import '../../calendar/models/planned_workout.dart';

/// Screen für Leistungsdiagnostik, Schwellenwert-Vorschläge und geführte Feldtests.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  final String athleteId;

  const DiagnosticsScreen({
    super.key,
    required this.athleteId,
  });

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isCoachView = currentUid != null && currentUid != widget.athleteId;

    final proposalsAsync =
        ref.watch(pendingProposalsProvider(widget.athleteId));
    final historyAsync = ref.watch(thresholdHistoryProvider(widget.athleteId));

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        title: Text(
          'Leistungsdiagnostik',
          style: AppTypography.headline
              .copyWith(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppColors.navy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.volt,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.volt,
          indicatorWeight: 3,
          labelStyle: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.directions_bike), text: 'Rad'),
            Tab(icon: Icon(Icons.directions_run), text: 'Lauf'),
            Tab(icon: Icon(Icons.pool), text: 'Schwimmen'),
          ],
        ),
      ),
      body: proposalsAsync.when(
        data: (proposals) => historyAsync.when(
          data: (history) => TabBarView(
            controller: _tabController,
            children: [
              _buildSportTab(
                sport: 'BIKE',
                thresholdType: ThresholdType.ftp,
                proposals: proposals
                    .where((p) => p.sport.toUpperCase() == 'BIKE')
                    .toList(),
                history: history,
                isCoachView: isCoachView,
              ),
              _buildSportTab(
                sport: 'RUN',
                thresholdType: ThresholdType.lthr,
                proposals: proposals
                    .where((p) => p.sport.toUpperCase() == 'RUN')
                    .toList(),
                history: history,
                isCoachView: isCoachView,
              ),
              _buildSportTab(
                sport: 'SWIM',
                thresholdType: ThresholdType.css,
                proposals: proposals
                    .where((p) => p.sport.toUpperCase() == 'SWIM')
                    .toList(),
                history: history,
                isCoachView: isCoachView,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text('Fehler beim Laden der Historie: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Fehler beim Laden der Vorschläge: $err')),
      ),
    );
  }

  Widget _buildSportTab({
    required String sport,
    required ThresholdType thresholdType,
    required List<ThresholdProposal> proposals,
    required List<ThresholdEntry> history,
    required bool isCoachView,
  }) {
    final latest = history.isNotEmpty ? history.last : null;
    final tests = GuidedTestInfo.standardTests
        .where((t) => t.sport.toUpperCase() == sport)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Aktueller Schwellenwert
        _buildCurrentThresholdCard(latest, thresholdType),
        const SizedBox(height: 16),

        // 2. Schwellenwert-Vorschläge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Erkannte Vorschläge',
              style: AppTypography.title.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            if (proposals.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${proposals.length} NEU',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (proposals.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF003875)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.volt, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aktuell keine neuen Schwellenwert-Vorschläge. Deine hinterlegten Werte stimmen gut mit deinen Leistungen überein.',
                    style: AppTypography.label.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          )
        else
          ...proposals.map((proposal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ThresholdProposalCard(
                  proposal: proposal,
                  isCoachView: isCoachView,
                  onAccept: () => _handleAcceptProposal(proposal),
                  onReject: () => _handleRejectProposal(proposal),
                ),
              )),
        const SizedBox(height: 16),

        // 3. Schwellenwert-Verlauf
        ThresholdHistoryChart(
          entries: history,
          type: thresholdType,
        ),
        const SizedBox(height: 20),

        // 4. Geführte Tests
        Text(
          'Geführte Feldtests',
          style: AppTypography.title.copyWith(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Standardisierte Protokolle für verlässliche Testergebnisse ohne Labor.',
          style: AppTypography.label.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        ...tests.map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GuidedTestCard(
                testInfo: test,
                onSchedule: () => _scheduleGuidedTest(test),
              ),
            )),
      ],
    );
  }

  Widget _buildCurrentThresholdCard(
      ThresholdEntry? latest, ThresholdType type) {
    String valueStr = 'Nicht hinterlegt';
    String effectiveStr = '–';
    String sourceStr = '–';

    if (latest != null) {
      effectiveStr = latest.effectiveFrom;
      sourceStr = latest.source == 'ESTIMATED'
          ? 'Automatisch geschätzt'
          : 'Manuell hinterlegt';

      switch (type) {
        case ThresholdType.ftp:
          if (latest.ftpW != null) valueStr = '${latest.ftpW!.round()} W';
          break;
        case ThresholdType.lthr:
          if (latest.thresholdHrBpm != null) {
            valueStr = '${latest.thresholdHrBpm!.round()} bpm';
          }
          break;
        case ThresholdType.thresholdPace:
          if (latest.runThresholdPaceSecPerKm != null) {
            final m = latest.runThresholdPaceSecPerKm!.toInt() ~/ 60;
            final s = (latest.runThresholdPaceSecPerKm! % 60).round();
            valueStr = '$m:${s.toString().padLeft(2, '0')} /km';
          }
          break;
        case ThresholdType.css:
          if (latest.swimCssSecPer100m != null) {
            final m = latest.swimCssSecPer100m!.toInt() ~/ 60;
            final s = (latest.swimCssSecPer100m! % 60).round();
            valueStr = '$m:${s.toString().padLeft(2, '0')} /100m';
          }
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF003875)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktueller Schwellenwert',
                style: AppTypography.label.copyWith(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF001F47),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF003875)),
                ),
                child: Text(
                  sourceStr,
                  style: AppTypography.label
                      .copyWith(fontSize: 10, color: AppColors.volt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valueStr,
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gültig seit: $effectiveStr',
            style: AppTypography.label.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  void _handleAcceptProposal(ThresholdProposal proposal) {
    showDialog(
      context: context,
      builder: (ctx) => RecomputeConfirmationDialog(
        proposal: proposal,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: (recomputePast) async {
          Navigator.of(ctx).pop();
          try {
            await ref.read(diagnosticsRepositoryProvider).acceptProposal(
                  athleteId: widget.athleteId,
                  proposal: proposal,
                  triggerRecompute: recomputePast,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    recomputePast
                        ? 'Schwellenwert übernommen. Neuberechnung vergangener Einheiten angestoßen.'
                        : 'Schwellenwert erfolgreich übernommen (ab heute gültig).',
                  ),
                  backgroundColor: AppColors.navy,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fehler beim Übernehmen: $e'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleRejectProposal(ThresholdProposal proposal) async {
    try {
      await ref.read(diagnosticsRepositoryProvider).rejectProposal(
            athleteId: widget.athleteId,
            proposalId: proposal.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vorschlag ignoriert.'),
            backgroundColor: AppColors.navy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Ignorieren: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _scheduleGuidedTest(GuidedTestInfo test) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.navy,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final localDateStr =
        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

    final plannedWorkout = PlannedWorkout(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      athleteId: widget.athleteId,
      createdBy: FirebaseAuth.instance.currentUser?.uid ?? widget.athleteId,
      localDate: localDateStr,
      sport: test.sport,
      title: test.titleDe,
      description: test.protocolDe,
      plannedDurationSec: test.durationMinutes * 60,
      status: 'PLANNED',
      structure: {
        'version': 1,
        'blocks': [
          {'type': 'WARMUP', 'durationSec': 1200},
          {'type': 'WORK', 'durationSec': 1200, 'intensity': 'ALL_OUT'},
          {'type': 'COOLDOWN', 'durationSec': 600},
        ],
      },
      createdAt: DateTime.now(),
    );

    try {
      await PlannedWorkoutRepository().create(plannedWorkout);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Test "${test.titleDe}" erfolgreich für $localDateStr eingeplant.'),
            backgroundColor: AppColors.navy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Einplanen: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
