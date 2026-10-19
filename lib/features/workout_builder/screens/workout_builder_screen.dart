import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../calendar/models/planned_workout.dart';
import '../../calendar/providers/calendar_provider.dart';
import '../controllers/workout_builder_controller.dart';
import '../models/workout_builder_models.dart';
import '../models/workout_template.dart';
import '../repositories/workout_template_repository.dart';
import '../widgets/workout_profile_chart.dart';
import '../../auth/providers/user_provider.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../home/providers/home_dashboard_provider.dart';

/// Screen für die Erstellung und Bearbeitung strukturierter Trainingseinheiten.
class WorkoutBuilderScreen extends ConsumerStatefulWidget {
  final String sport;
  final String? initialText;
  final WorkoutStructure? initialStructure;
  final String? targetLocalDate;
  final String? athleteId;

  const WorkoutBuilderScreen({
    super.key,
    this.sport = 'BIKE',
    this.initialText,
    this.initialStructure,
    this.targetLocalDate,
    this.athleteId,
  });

  @override
  ConsumerState<WorkoutBuilderScreen> createState() =>
      _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends ConsumerState<WorkoutBuilderScreen> {
  late final TextEditingController _textController;
  late final WorkoutBuilderParams _params;
  bool _isSyncing = false;
  bool _showTextEditor = false;

  @override
  void initState() {
    super.initState();
    _params = WorkoutBuilderParams(
      sport: widget.sport,
      initialText: widget.initialText,
      initialStructure: widget.initialStructure,
    );
    _textController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutBuilderProvider(_params));
    final notifier = ref.read(workoutBuilderProvider(_params).notifier);

    // Synchronisiere Controller-Text wenn er vom Block-Editor geändert wurde
    if (!_isSyncing && _textController.text != state.text) {
      final oldSelection = _textController.selection;
      _textController.text = state.text;
      if (oldSelection.start <= state.text.length &&
          oldSelection.end <= state.text.length) {
        _textController.selection = oldSelection;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Builder'),
        actions: [
          // Undo
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Rückgängig',
            onPressed: state.canUndo ? () => notifier.undo() : null,
          ),
          // Redo
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Wiederherstellen',
            onPressed: state.canRedo ? () => notifier.redo() : null,
          ),
          // Als Vorlage speichern
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Als Vorlage speichern',
            onPressed: state.isValid
                ? () => _showSaveTemplateDialog(context, state)
                : null,
          ),
          const BetaBugReportIconButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Sportart-Auswahl
            _buildSportSelector(state.sport, notifier),
            const SizedBox(height: 12),

            // Modus-Umschalter: Reiner visueller Block-Modus (Standard) vs. Text-Code
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.view_agenda_outlined, size: 16),
                  label: Text('Visuelle Blöcke'),
                ),
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.code, size: 16),
                  label: Text('Text-Code'),
                ),
              ],
              selected: {_showTextEditor},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  setState(() => _showTextEditor = set.first);
                }
              },
            ),
            const SizedBox(height: 14),

            // 2. Live-Profilgrafik
            WorkoutProfileChart(
              structure: state.structure,
              height: 130,
            ),
            const SizedBox(height: 12),

            // 3. Kennzahlen-Leiste (Dauer, Distanz, ORBIT Score)
            _buildMetricsSummaryBar(state),
            const SizedBox(height: 14),

            // 4. Haupt-Editor je nach Modus
            if (_showTextEditor)
              _buildTextInputCard(state, notifier)
            else
              _buildDirectBlockEditor(context, state, notifier),

            const SizedBox(height: 14),

            // 5. Zonenverteilung
            _buildZoneDistributionCard(state),
            const SizedBox(height: 12),

            // 6. Berechnete Annahmen & Warnungen
            if (state.calculation.assumptions.isNotEmpty ||
                state.calculation.missingThresholdWarnings.isNotEmpty) ...[
              _buildAssumptionsCard(state),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.volt,
              foregroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text(
              'Im Kalender einplanen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: state.isValid
                ? () => _scheduleInCalendar(context, state)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSportSelector(
      String currentSport, WorkoutBuilderNotifier notifier) {
    const sports = [
      ('BIKE', 'Rad', Icons.directions_bike),
      ('RUN', 'Lauf', Icons.directions_run),
      ('SWIM', 'Schwimmen', Icons.pool),
      ('STRENGTH', 'Kraft', Icons.fitness_center),
    ];

    return SegmentedButton<String>(
      segments: sports.map((s) {
        return ButtonSegment<String>(
          value: s.$1,
          label: Text(s.$2),
          icon: Icon(s.$3, size: 16),
        );
      }).toList(),
      selected: {currentSport.toUpperCase()},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) {
          notifier.setSport(set.first);
        }
      },
    );
  }

  Widget _buildTextInputCard(
      WorkoutBuilderState state, WorkoutBuilderNotifier notifier) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: state.errors.isNotEmpty
              ? Colors.red.shade400
              : AppColors.cardBorder,
          width: state.errors.isNotEmpty ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, size: 18, color: AppColors.navy),
                const SizedBox(width: 6),
                const Text(
                  'Text-Kurzeingabe',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                if (state.isValid)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Gültig',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _textController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: "z. B. 10' Z1, 4x(4' Z4 / 2' Z1), 10' Z1",
                border: InputBorder.none,
                isDense: true,
                filled: true,
                fillColor: AppColors.cockpit.withValues(alpha: 0.03),
              ),
              onChanged: (val) {
                _isSyncing = true;
                notifier.updateText(val);
                _isSyncing = false;
              },
            ),

            // Syntax-Bausteine
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _getQuickChips(state.sport).map((snippet) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ActionChip(
                      label:
                          Text(snippet, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: () {
                        final current = _textController.text;
                        final newText =
                            current.isEmpty ? snippet : '$current, $snippet';
                        _textController.text = newText;
                        notifier.updateText(newText);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Fehleranzeige
            if (state.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: state.errors.map((e) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e.messageDe,
                            style: TextStyle(
                                color: Colors.red.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _getQuickChips(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return [
          "10' Z1",
          "4x(4' Z4 / 2' Z1)",
          "3x(10' 90%FTP / 4' Z1)",
          "15' Z2",
          "@90rpm"
        ];
      case 'RUN':
        return [
          "2km Z1",
          "5x(1000m @4:30/km / 90\")",
          "6x(3' Z4 / 2' Z2)",
          "15' Z2",
          "1.5km Z1"
        ];
      case 'SWIM':
        return [
          "400m Z1",
          "8x(100m CSS / 20\")",
          "4x(100m CSS+4\" / 15\")",
          "3x(4x(50m Z5 / 15\") / 2')",
          "200m Z1"
        ];
      case 'STRENGTH':
        return [
          "5' Z1",
          "3x(45\" frei [Plank] / 15\")",
          "3x(45\" frei [Side Plank] / 15\")",
          "5' frei [Stretching]"
        ];
      default:
        return ["10' Z1", "4x(4' Z4 / 2' Z1)", "10' Z1"];
    }
  }

  Widget _buildMetricsSummaryBar(WorkoutBuilderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem('Dauer', state.calculation.formattedDuration,
              Icons.timer_outlined),
          _buildMetricItem('Distanz', state.calculation.formattedDistance,
              Icons.straighten_outlined),
          _buildMetricItem('ORBIT Score', state.calculation.formattedLoad,
              Icons.bolt_outlined),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildZoneDistributionCard(WorkoutBuilderState state) {
    final zones = state.calculation.timeInZonesSec;
    final totalSec = state.calculation.totalDurationSec;
    if (totalSec <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Zeit je Zone',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (int z = 1; z <= 7; z++)
                    if ((zones[z] ?? 0) > 0)
                      Expanded(
                        flex: zones[z]!,
                        child: Container(color: AppColors.zoneColor(z)),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (int z = 1; z <= 7; z++)
                if ((zones[z] ?? 0) > 0)
                  Text(
                    'Z$z: ${zones[z]! ~/ 60}m',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.zoneColor(z),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssumptionsCard(WorkoutBuilderState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber),
              SizedBox(width: 6),
              Text(
                'Berechnete Annahmen',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final a in state.calculation.assumptions)
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text('• $a',
                  style: const TextStyle(fontSize: 11, color: Colors.black87)),
            ),
          for (final w in state.calculation.missingThresholdWarnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text('⚠ $w',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade900)),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectBlockEditor(
    BuildContext context,
    WorkoutBuilderState state,
    WorkoutBuilderNotifier notifier,
  ) {
    final blocks = state.structure?.blocks ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Schnell-Bausteine Leiste
        const Row(
          children: [
            Icon(Icons.bolt, size: 16, color: AppColors.volt),
            SizedBox(width: 6),
            Text(
              'Baustein hinzufügen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickAddButton(
                key: const Key('quick_add_warmup'),
                label: '+ Aufwärmen',
                color: const Color(0xFF0284C7), // Türkis/Blau
                onTap: () => notifier.addBlock(
                  const StepBlock(
                    role: WorkoutRole.warmup,
                    target: WorkoutTarget.duration(600), // 10 min
                    intensity: ZoneIntensity.single(1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                key: const Key('quick_add_work'),
                label: '+ Intervall (Z4)',
                color: AppColors.volt,
                textColor: AppColors.navy,
                onTap: () => notifier.addBlock(
                  const StepBlock(
                    role: WorkoutRole.work,
                    target: WorkoutTarget.duration(240), // 4 min
                    intensity: ZoneIntensity.single(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                key: const Key('quick_add_rest'),
                label: '+ Pause (Z1)',
                color: const Color(0xFF64748B), // Dezentes Slate
                onTap: () => notifier.addBlock(
                  const StepBlock(
                    role: WorkoutRole.rest,
                    target: WorkoutTarget.duration(120), // 2 min
                    intensity: ZoneIntensity.single(1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                key: const Key('quick_add_repeat'),
                label: '+ Wiederholungs-Serie (4x)',
                color: const Color(0xFF003D82),
                onTap: () => notifier.addBlock(
                  const RepeatBlock(
                    count: 4,
                    blocks: [
                      StepBlock(
                        role: WorkoutRole.work,
                        target: WorkoutTarget.duration(180), // 3 min
                        intensity: ZoneIntensity.single(4),
                      ),
                      StepBlock(
                        role: WorkoutRole.rest,
                        target: WorkoutTarget.duration(120), // 2 min
                        intensity: ZoneIntensity.single(1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                key: const Key('quick_add_cooldown'),
                label: '+ Ausrollen',
                color: const Color(0xFF10B981), // Grün
                onTap: () => notifier.addBlock(
                  const StepBlock(
                    role: WorkoutRole.cooldown,
                    target: WorkoutTarget.duration(600), // 10 min
                    intensity: ZoneIntensity.single(1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                key: const Key('quick_add_custom'),
                label: '+ Eigener Block...',
                color: AppColors.navy,
                textColor: AppColors.volt,
                onTap: () => _showBlockEditorSheet(
                  context,
                  null,
                  null,
                  notifier,
                  state.sport,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Liste der Trainingsblöcke
        if (blocks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Center(
              child: Text(
                'Keine Blöcke vorhanden. Wähle oben einen Baustein aus!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          for (int i = 0; i < blocks.length; i++) ...[
            _buildInteractiveBlockCard(
              context: context,
              block: blocks[i],
              index: i,
              totalBlocks: blocks.length,
              notifier: notifier,
              sport: state.sport,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildQuickAddButton({
    Key? key,
    required String label,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveBlockCard({
    required BuildContext context,
    required WorkoutBlock block,
    required int index,
    required int totalBlocks,
    required WorkoutBuilderNotifier notifier,
    required String sport,
  }) {
    if (block is StepBlock) {
      final zoneNum = block.intensity is ZoneIntensity
          ? (block.intensity as ZoneIntensity).low
          : 2;
      final color = AppColors.zoneColor(zoneNum);
      final durationMin =
          ((block.target.durationSec ?? 300) / 60).toStringAsFixed(0);

      String roleName;
      Color roleColor;
      switch (block.role) {
        case WorkoutRole.warmup:
          roleName = 'Aufwärmen';
          roleColor = const Color(0xFF0284C7); // Türkis/Blau
          break;
        case WorkoutRole.work:
          roleName = 'Intervall / Belastung';
          roleColor = color;
          break;
        case WorkoutRole.rest:
          roleName = 'Erholung / Pause';
          roleColor = const Color(0xFF64748B); // Slate
          break;
        case WorkoutRole.cooldown:
          roleName = 'Ausrollen';
          roleColor = const Color(0xFF10B981); // Grün
          break;
        default:
          roleName = 'Intervall';
          roleColor = color;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: roleColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                roleName,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _showBlockEditorSheet(
                  context,
                  block,
                  index,
                  notifier,
                  sport,
                ),
                child: Text(
                  '$durationMin min @ Z$zoneNum',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            IconButton(
              key: Key('edit_block_$index'),
              icon: const Icon(Icons.tune, size: 18, color: AppColors.navy),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Bearbeiten',
              onPressed: () => _showBlockEditorSheet(
                context,
                block,
                index,
                notifier,
                sport,
              ),
            ),
            const SizedBox(width: 6),
            if (index > 0)
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => notifier.moveBlock(index, index - 1),
                tooltip: 'Nach oben',
              ),
            const SizedBox(width: 6),
            if (index < totalBlocks - 1)
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => notifier.moveBlock(index, index + 1),
                tooltip: 'Nach unten',
              ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => notifier.duplicateBlock(index),
              tooltip: 'Duplizieren',
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.redAccent),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => notifier.deleteBlock(index),
              tooltip: 'Löschen',
            ),
          ],
        ),
      );
    } else if (block is RepeatBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Stepper für Wiederholungen 2x bis 30x (Phase 37.3)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.volt.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.volt),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('repeat_decrement_$index'),
                        icon: const Icon(Icons.remove,
                            size: 16, color: AppColors.navy),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        constraints: const BoxConstraints(),
                        tooltip: 'Wiederholungen verringern',
                        onPressed: block.count > 2
                            ? () => notifier.replaceBlock(
                                  index,
                                  block.copyWith(count: block.count - 1),
                                )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          '${block.count}x Serie',
                          key: Key('repeat_count_text_$index'),
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        key: Key('repeat_increment_$index'),
                        icon: const Icon(Icons.add,
                            size: 16, color: AppColors.navy),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        constraints: const BoxConstraints(),
                        tooltip: 'Wiederholungen erhöhen',
                        onPressed: block.count < 30
                            ? () => notifier.replaceBlock(
                                  index,
                                  block.copyWith(count: block.count + 1),
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: Key('edit_repeat_$index'),
                  icon: const Icon(Icons.tune, size: 18, color: AppColors.navy),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Serie konfigurieren',
                  onPressed: () => _showBlockEditorSheet(
                    context,
                    block,
                    index,
                    notifier,
                    sport,
                  ),
                ),
                const SizedBox(width: 6),
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => notifier.moveBlock(index, index - 1),
                  ),
                const SizedBox(width: 6),
                if (index < totalBlocks - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => notifier.moveBlock(index, index + 1),
                  ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => notifier.duplicateBlock(index),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => notifier.deleteBlock(index),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: block.blocks.map((sub) {
                if (sub is StepBlock) {
                  final z = sub.intensity is ZoneIntensity
                      ? (sub.intensity as ZoneIntensity).low
                      : 4;
                  final dur =
                      ((sub.target.durationSec ?? 180) / 60).toStringAsFixed(0);
                  return Chip(
                    label: Text('$dur m @ Z$z'),
                    backgroundColor:
                        AppColors.zoneColor(z).withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.zoneColor(z),
                    ),
                    padding: EdgeInsets.zero,
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _scheduleInCalendar(
      BuildContext context, WorkoutBuilderState state) async {
    final now = DateTime.now();
    DateTime chosenDate = widget.targetLocalDate != null
        ? (DateTime.tryParse(widget.targetLocalDate!) ?? now)
        : now;

    final titleController = TextEditingController(
      text: state.text.isNotEmpty
          ? state.text.split(',').first.trim()
          : '${state.sport} Einheit',
    );
    final descController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final dateStr =
              "${chosenDate.year}-${chosenDate.month.toString().padLeft(2, '0')}-${chosenDate.day.toString().padLeft(2, '0')}";
          return AlertDialog(
            title: const Text('Einheit im Kalender einplanen'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('plan_workout_title_field'),
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titel der Einheit',
                      hintText: 'z. B. 4x4min VO2max Intervalle',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text('Datum: $dateStr',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        key: const Key('plan_workout_date_picker'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogCtx,
                            initialDate: chosenDate,
                            firstDate: now.subtract(const Duration(days: 30)),
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => chosenDate = picked);
                          }
                        },
                        child: const Text('Ändern'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('plan_workout_description_field'),
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Allgemeine Trainerhinweise',
                      hintText: 'Ziele, Vorgaben & Durchführung',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('plan_workout_notes_field'),
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Einheitsspezifische Notiz',
                      hintText: 'Optionale persönliche Notiz',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                key: const Key('plan_workout_submit_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.volt,
                  foregroundColor: AppColors.navy,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Einplanen'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final localDateStr =
        "${chosenDate.year}-${chosenDate.month.toString().padLeft(2, '0')}-${chosenDate.day.toString().padLeft(2, '0')}";

    final athleteId = widget.athleteId ?? 'me';
    final repo = ref.read(plannedWorkoutRepositoryProvider);

    final planned = PlannedWorkout(
      id: '',
      athleteId: athleteId,
      createdBy: athleteId,
      localDate: localDateStr,
      sport: state.sport,
      title: titleController.text.trim().isNotEmpty
          ? titleController.text.trim()
          : 'Geplantes ${state.sport}-Training',
      description: descController.text.trim().isNotEmpty
          ? descController.text.trim()
          : null,
      plannedDurationSec: state.calculation.totalDurationSec,
      plannedDistanceM: state.calculation.totalDistanceM > 0
          ? state.calculation.totalDistanceM.toDouble()
          : null,
      plannedLoad: state.calculation.estimatedLoad,
      status: 'PLANNED',
      structure: state.structure?.toJson(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.create(planned);

    ref.invalidate(homeDashboardProvider(athleteId));
    ref.invalidate(athleteCurrentWeekWorkoutsProvider(athleteId));
    ref.invalidate(athleteCurrentMonthWorkoutsProvider(athleteId));
    ref.invalidate(weekSummaryProvider(athleteId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Einheit für $localDateStr im Kalender eingeplant!')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _showSaveTemplateDialog(
      BuildContext context, WorkoutBuilderState state) async {
    final titleController =
        TextEditingController(text: '${state.sport} Einheit');
    final descController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Als Vorlage speichern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titel der Vorlage'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration:
                  const InputDecoration(labelText: 'Optionale Beschreibung'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Abbrechen')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Speichern')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = WorkoutTemplateRepository();
      final template = WorkoutTemplate(
        id: '',
        ownerId: widget.athleteId ?? 'me',
        visibility: 'PRIVATE',
        sport: state.sport,
        title: titleController.text.trim().isNotEmpty
            ? titleController.text.trim()
            : 'Vorlage',
        description: descController.text.trim().isNotEmpty
            ? descController.text.trim()
            : null,
        structure: state.structure!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTemplate(template);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vorlage erfolgreich gespeichert!')),
      );
    }
  }

  void _showBlockEditorSheet(
    BuildContext context,
    WorkoutBlock? block,
    int? index,
    WorkoutBuilderNotifier notifier,
    String sport,
  ) {
    final userData = ref.read(userDocumentProvider).value;
    final ftpNum = userData?['metrics']?['ftpWatts'] ?? userData?['ftp'] ?? 250;
    final ftp = (ftpNum as num).toDouble();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BlockEditorBottomSheet(
        initialBlock: block,
        sport: sport,
        thresholdPower: ftp > 50 ? ftp : 250.0,
        onSave: (newBlock) {
          if (index != null) {
            notifier.updateBlock(index, newBlock);
          } else {
            notifier.addBlock(newBlock);
          }
        },
      ),
    );
  }
}

/// Modal-BottomSheet zur interaktiven Konfiguration eines Trainingsblocks (#ORB-018).
class _BlockEditorBottomSheet extends StatefulWidget {
  final WorkoutBlock? initialBlock;
  final String sport;
  final double thresholdPower;
  final void Function(WorkoutBlock block) onSave;

  const _BlockEditorBottomSheet({
    this.initialBlock,
    required this.sport,
    this.thresholdPower = 250.0,
    required this.onSave,
  });

  @override
  State<_BlockEditorBottomSheet> createState() =>
      _BlockEditorBottomSheetState();
}

class _BlockEditorBottomSheetState extends State<_BlockEditorBottomSheet> {
  late bool _isRepeat;
  late WorkoutRole _role;
  late int _durationMin;
  late int _durationSec;
  late bool _isPctFtp;
  late int _zone;
  late int _pctFtp;
  late int _repeatCount;
  late int _restMin;
  late int _restSec;
  late int _restZone;

  @override
  void initState() {
    super.initState();
    final block = widget.initialBlock;
    if (block is RepeatBlock) {
      _isRepeat = true;
      _repeatCount = block.count;
      final first = block.blocks.isNotEmpty ? block.blocks.first : null;
      final second = block.blocks.length > 1 ? block.blocks[1] : null;

      if (first is StepBlock) {
        _role = first.role;
        final d = first.target.durationSec ?? 180;
        _durationMin = d ~/ 60;
        _durationSec = d % 60;
        if (first.intensity is PctFtpIntensity) {
          _isPctFtp = true;
          _pctFtp = (first.intensity as PctFtpIntensity).low;
          _zone = 4;
        } else if (first.intensity is ZoneIntensity) {
          _isPctFtp = false;
          _zone = (first.intensity as ZoneIntensity).low;
          _pctFtp = 90;
        } else {
          _isPctFtp = false;
          _zone = 4;
          _pctFtp = 90;
        }
      } else {
        _role = WorkoutRole.work;
        _durationMin = 3;
        _durationSec = 0;
        _isPctFtp = false;
        _zone = 4;
        _pctFtp = 90;
      }

      if (second is StepBlock) {
        final d = second.target.durationSec ?? 120;
        _restMin = d ~/ 60;
        _restSec = d % 60;
        _restZone = second.intensity is ZoneIntensity
            ? (second.intensity as ZoneIntensity).low
            : 1;
      } else {
        _restMin = 2;
        _restSec = 0;
        _restZone = 1;
      }
    } else if (block is StepBlock) {
      _isRepeat = false;
      _repeatCount = 4;
      _role = block.role;
      final d = block.target.durationSec ?? 300;
      _durationMin = d ~/ 60;
      _durationSec = d % 60;
      if (block.intensity is PctFtpIntensity) {
        _isPctFtp = true;
        _pctFtp = (block.intensity as PctFtpIntensity).low;
        _zone = 4;
      } else if (block.intensity is ZoneIntensity) {
        _isPctFtp = false;
        _zone = (block.intensity as ZoneIntensity).low;
        _pctFtp = 90;
      } else {
        _isPctFtp = false;
        _zone = 2;
        _pctFtp = 70;
      }
      _restMin = 2;
      _restSec = 0;
      _restZone = 1;
    } else {
      _isRepeat = false;
      _repeatCount = 4;
      _role = WorkoutRole.work;
      _durationMin = 5;
      _durationSec = 0;
      _isPctFtp = false;
      _zone = 4;
      _pctFtp = 90;
      _restMin = 2;
      _restSec = 0;
      _restZone = 1;
    }
  }

  int get _liveWatts => ((widget.thresholdPower * _pctFtp) / 100.0).round();

  void _save() {
    final totalSec = (_durationMin * 60) + _durationSec;
    final targetSec = totalSec > 0 ? totalSec : 60;

    final intensity = _isPctFtp
        ? PctFtpIntensity(low: _pctFtp, high: _pctFtp)
        : ZoneIntensity.single(_zone);

    if (_isRepeat) {
      final restTotalSec = (_restMin * 60) + _restSec;
      final validRestSec = restTotalSec > 0 ? restTotalSec : 30;

      final repeatBlock = RepeatBlock(
        count: _repeatCount.clamp(2, 30),
        blocks: [
          StepBlock(
            role: WorkoutRole.work,
            target: WorkoutTarget.duration(targetSec),
            intensity: intensity,
          ),
          StepBlock(
            role: WorkoutRole.rest,
            target: WorkoutTarget.duration(validRestSec),
            intensity: ZoneIntensity.single(_restZone),
          ),
        ],
      );
      widget.onSave(repeatBlock);
    } else {
      final stepBlock = StepBlock(
        role: _role,
        target: WorkoutTarget.duration(targetSec),
        intensity: intensity,
      );
      widget.onSave(stepBlock);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final maxScrollExtent = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxScrollExtent),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.volt),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Trainingsblock anpassen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Typ-Auswahl (Einzelschritt vs Wiederholungs-Serie)
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Einzelschritt'),
                    selected: !_isRepeat,
                    onSelected: (sel) {
                      if (sel) setState(() => _isRepeat = false);
                    },
                    selectedColor: AppColors.navy,
                    labelStyle: TextStyle(
                      color: !_isRepeat ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Wiederholung (Serie)'),
                    selected: _isRepeat,
                    onSelected: (sel) {
                      if (sel) setState(() => _isRepeat = true);
                    },
                    selectedColor: AppColors.navy,
                    labelStyle: TextStyle(
                      color: _isRepeat ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Wenn Wiederholung: Stepper für Count (2x bis 30x)
            if (_isRepeat) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, color: AppColors.volt, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Wiederholungen:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _repeatCount > 2
                          ? () => setState(() => _repeatCount--)
                          : null,
                    ),
                    Text(
                      '$_repeatCount x',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.volt,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _repeatCount < 30
                          ? () => setState(() => _repeatCount++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Rolle auswählen
              const Text(
                'Funktion des Schritts:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Aufwärmen'),
                    selected: _role == WorkoutRole.warmup,
                    onSelected: (sel) =>
                        setState(() => _role = WorkoutRole.warmup),
                  ),
                  ChoiceChip(
                    label: const Text('Belastung'),
                    selected: _role == WorkoutRole.work,
                    onSelected: (sel) =>
                        setState(() => _role = WorkoutRole.work),
                  ),
                  ChoiceChip(
                    label: const Text('Pause'),
                    selected: _role == WorkoutRole.rest,
                    onSelected: (sel) =>
                        setState(() => _role = WorkoutRole.rest),
                  ),
                  ChoiceChip(
                    label: const Text('Ausrollen'),
                    selected: _role == WorkoutRole.cooldown,
                    onSelected: (sel) =>
                        setState(() => _role = WorkoutRole.cooldown),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Dauer des Schritts (oder Belastungsintervalls)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRepeat
                        ? 'Dauer des Belastungsintervalls:'
                        : 'Dauer des Schritts:',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_durationMin.toString().padLeft(2, '0')}:${_durationSec.toString().padLeft(2, '0')} min',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.volt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _durationMin > 0
                            ? () => setState(() =>
                                _durationMin = (_durationMin - 1).clamp(0, 300))
                            : null,
                        child: const Text('-1 min'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() =>
                            _durationMin = (_durationMin + 1).clamp(0, 300)),
                        child: const Text('+1 min'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _durationSec =
                            (_durationSec == 0 ? 45 : _durationSec - 15)),
                        child: const Text('-15s'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _durationSec =
                            (_durationSec == 45 ? 0 : _durationSec + 15)),
                        child: const Text('+15s'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Intensitäts-Konfiguration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Intensität:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const Spacer(),
                      // Umschalter Zone vs % FTP
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                              value: false, label: Text('Zone (Z1-Z7)')),
                          ButtonSegment(value: true, label: Text('% FTP')),
                        ],
                        selected: {_isPctFtp},
                        onSelectionChanged: (set) {
                          setState(() => _isPctFtp = set.first);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!_isPctFtp) ...[
                    // Zonen-Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: List.generate(7, (i) {
                        final z = i + 1;
                        final color = AppColors.zoneColor(z);
                        final isSel = _zone == z;
                        return FilterChip(
                          showCheckmark: false,
                          selected: isSel,
                          backgroundColor: color.withValues(alpha: 0.15),
                          selectedColor: color,
                          label: Text(
                            'Z$z',
                            style: TextStyle(
                              color: isSel ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSelected: (_) => setState(() => _zone = z),
                        );
                      }),
                    ),
                  ] else ...[
                    // % FTP Stepper + Watt-Vorschau (#ORB-018)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_pctFtp % FTP',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.volt,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.volt.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '~ $_liveWatts Watt (bei ${widget.thresholdPower.toInt()}W FTP)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.volt,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _pctFtp.toDouble().clamp(40, 160),
                      min: 40,
                      max: 160,
                      divisions: 120,
                      activeColor: AppColors.volt,
                      onChanged: (val) => setState(() => _pctFtp = val.round()),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(
                              () => _pctFtp = (_pctFtp - 5).clamp(40, 160)),
                          child: const Text('-5%'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(
                              () => _pctFtp = (_pctFtp - 1).clamp(40, 160)),
                          child: const Text('-1%'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(
                              () => _pctFtp = (_pctFtp + 1).clamp(40, 160)),
                          child: const Text('+1%'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(
                              () => _pctFtp = (_pctFtp + 5).clamp(40, 160)),
                          child: const Text('+5%'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Wenn Wiederholung: Konfiguration des Pausen-Schritts
            if (_isRepeat) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pause zwischen den Intervallen:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_restMin.toString().padLeft(2, '0')}:${_restSec.toString().padLeft(2, '0')} min',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _restMin > 0
                              ? () => setState(() => _restMin--)
                              : null,
                          child: const Text('-1 min'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() => _restMin++),
                          child: const Text('+1 min'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() =>
                              _restSec = (_restSec == 0 ? 45 : _restSec - 15)),
                          child: const Text('-15s'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() =>
                              _restSec = (_restSec == 45 ? 0 : _restSec + 15)),
                          child: const Text('+15s'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Speichern-Button
            ElevatedButton(
              key: const Key('apply_block_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.volt,
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _save,
              child: const Text(
                'Block anwenden',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
