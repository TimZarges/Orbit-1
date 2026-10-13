import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/design/app_spacing.dart';
import '../models/coach_dashboard_athlete.dart';
import '../models/coach_view_preference.dart';
import '../providers/coach_dashboard_provider.dart';
import '../widgets/coach_athletes_table.dart';
import '../widgets/multi_athlete_week_grid.dart';
import '../widgets/batch_assign_dialog.dart';
import '../widgets/create_threshold_proposal_dialog.dart';
import '../widgets/keyboard_shortcuts_dialog.dart';
import 'athlete_context_wrapper.dart';
import '../../calendar/screens/calendar_screen.dart';

enum CoachViewMode {
  table,
  weekGrid,
}

/// Professionelles Coach-Desktop- und Web-Dashboard für Trainer.
///
/// Unterstützt:
/// - O(1) Reads via serverseitig aggregiertem `coachDashboard/{coachId}/athletes`
/// - Umschaltung zwischen Kader-Tabelle und Mehrathleten-Wochenraster
/// - Drag & Drop und Alt-Kopieren im Wochenraster
/// - Massenzuweisung von Workouts mit Vorschau
/// - Erstellung von Schwellenwert-Vorschlägen durch den Trainer
/// - Vollständige Tastatur-Bedienung (`?`, `Cmd+K`, `/`, Pfeiltasten)
class TrainerAthletesTabScreen extends ConsumerStatefulWidget {
  const TrainerAthletesTabScreen({super.key});

  @override
  ConsumerState<TrainerAthletesTabScreen> createState() => _TrainerAthletesTabScreenState();
}

class _TrainerAthletesTabScreenState extends ConsumerState<TrainerAthletesTabScreen> {
  CoachViewMode _viewMode = CoachViewMode.table;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String? _inviteCode;
  bool _isCreatingInvite = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _generateInvite() async {
    setState(() => _isCreatingInvite = true);
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('createInvite')
          .call();
      setState(() {
        _inviteCode = result.data['code'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreatingInvite = false);
    }
  }

  void _openAthleteContext(String athleteId, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AthleteContextWrapper(
          athleteId: athleteId,
          athleteName: name,
          child: CalendarScreen(athleteId: athleteId),
        ),
      ),
    );
  }

  void _openThresholdProposal(String coachId, CoachDashboardAthlete athlete) {
    CreateThresholdProposalDialog.show(
      context,
      coachId: coachId,
      athleteId: athlete.athleteId,
      athleteName: athlete.name,
    );
  }

  void _openBatchAssign(String coachId, List<String> athleteIds) {
    BatchAssignDialog.show(
      context,
      coachId: coachId,
      athleteIds: athleteIds,
      onCompleted: () {
        ref.read(coachSelectedAthleteIdsProvider.notifier).state = {};
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coachId = FirebaseAuth.instance.currentUser?.uid ?? 'coach_demo';
    final athletes = ref.watch(coachFilteredAthletesProvider(coachId));
    final selectedIds = ref.watch(coachSelectedAthleteIdsProvider);
    final activePref = ref.watch(coachActivePreferenceProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.slash, shift: true): () {
          KeyboardShortcutsDialog.show(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            title: const Text('Kader & Athleten'),
            actions: [
              // Einladungscode
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                tooltip: 'Athleten einladen',
                onPressed: () => _showInviteDialog(context),
              ),
              // Tastaturkürzel
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Tastaturkürzel (?)',
                onPressed: () => KeyboardShortcutsDialog.show(context),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= AppSpacing.breakpointCompact;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Toolbar: Suche, Filter & Ansichten-Umschalter
                  _buildToolbar(context, coachId, selectedIds, activePref, isWide),

                  const Divider(height: 1),

                  // Hauptansicht: Tabelle oder Wochenraster
                  Expanded(
                    child: _viewMode == CoachViewMode.table
                        ? CoachAthletesTable(
                            athletes: athletes,
                            onAthleteOpen: _openAthleteContext,
                            onCreateProposal: (athlete) => _openThresholdProposal(coachId, athlete),
                          )
                        : MultiAthleteWeekGrid(
                            athletes: athletes,
                            coachId: coachId,
                            onDrop: (workout, targetAthleteId, targetDate, isCopy) {
                              // Drop-Aktion verarbeiten
                            },
                            onAthleteClick: _openAthleteContext,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    String coachId,
    Set<String> selectedIds,
    CoachViewPreference activePref,
    bool isWide,
  ) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Suche
          SizedBox(
            width: isWide ? 240 : double.infinity,
            height: 38,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Suche (/ oder ⌘K)...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(coachAthleteSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                filled: true,
                fillColor: AppColors.techGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                ref.read(coachAthleteSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Ansichten-Segment (Tabelle vs. Raster)
          SegmentedButton<CoachViewMode>(
            segments: const [
              ButtonSegment(
                value: CoachViewMode.table,
                icon: Icon(Icons.table_chart_outlined, size: 16),
                label: Text('Tabelle', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: CoachViewMode.weekGrid,
                icon: Icon(Icons.calendar_view_week_outlined, size: 16),
                label: Text('Wochenraster', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (set) => setState(() => _viewMode = set.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.navy,
              selectedForegroundColor: AppColors.white,
            ),
          ),

          // Sportart-Filter
          DropdownButton<String?>(
            value: activePref.filterSport,
            hint: const Text('Alle Sportarten', style: TextStyle(fontSize: 12)),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: null, child: Text('Alle Sportarten', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'TRIATHLON', child: Text('Triathlon', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'RUN', child: Text('Lauf', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'BIKE', child: Text('Rad', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'SWIM', child: Text('Schwimmen', style: TextStyle(fontSize: 12))),
            ],
            onChanged: (sport) {
              ref.read(coachActivePreferenceProvider.notifier).state = activePref.copyWith(filterSport: sport);
            },
          ),

          // Alerts-Filter Chip
          FilterChip(
            label: const Text('Nur Auffälligkeiten', style: TextStyle(fontSize: 12)),
            selected: activePref.alertOnly,
            selectedColor: AppColors.volt.withValues(alpha: 0.25),
            checkmarkColor: AppColors.navy,
            onSelected: (val) {
              ref.read(coachActivePreferenceProvider.notifier).state = activePref.copyWith(alertOnly: val);
            },
          ),

          // Massenzuweisungs-Button (wenn Athleten ausgewählt sind)
          if (selectedIds.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: () => _openBatchAssign(coachId, selectedIds.toList()),
              icon: const Icon(Icons.group_add, size: 16),
              label: Text('Massenzuweisung (${selectedIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.volt,
                foregroundColor: AppColors.navy,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Neuen Athleten einladen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Erzeuge einen 7 Tage gültigen Einladungscode für deinen Athleten.'),
                const SizedBox(height: 16),
                if (_inviteCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.techGrey,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: SelectableText(
                        _inviteCode!,
                        style: AppTypography.headline.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Der Athlet gibt diesen Code in seinem Profil ein.', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Schließen'),
              ),
              if (_inviteCode == null)
                ElevatedButton(
                  onPressed: _isCreatingInvite
                      ? null
                      : () async {
                          setDialogState(() => _isCreatingInvite = true);
                          await _generateInvite();
                          setDialogState(() => _isCreatingInvite = false);
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: AppColors.white),
                  child: _isCreatingInvite
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Code generieren'),
                ),
            ],
          );
        },
      ),
    );
  }
}
