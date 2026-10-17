import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../calendar/models/planned_workout.dart';
import '../../calendar/repositories/planned_workout_repository.dart';
import '../controllers/workout_builder_controller.dart';
import '../models/workout_builder_models.dart';
import '../models/workout_template.dart';
import '../repositories/workout_template_repository.dart';
import '../widgets/workout_profile_chart.dart';

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
                label: '+ Warmup',
                color: AppColors.z2,
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
                label: '+ Intervall (Z4)',
                color: AppColors.z4,
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
                label: '+ Pause (Z1)',
                color: AppColors.z1,
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
                label: '+ 4x Schleife',
                color: AppColors.volt,
                textColor: AppColors.navy,
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
                label: '+ Cooldown',
                color: AppColors.z1,
                onTap: () => notifier.addBlock(
                  const StepBlock(
                    role: WorkoutRole.cooldown,
                    target: WorkoutTarget.duration(600), // 10 min
                    intensity: ZoneIntensity.single(1),
                  ),
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
    required String label,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
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
      switch (block.role) {
        case WorkoutRole.warmup:
          roleName = 'Warmup';
          break;
        case WorkoutRole.work:
          roleName = 'Belastung';
          break;
        case WorkoutRole.rest:
          roleName = 'Pause';
          break;
        case WorkoutRole.cooldown:
          roleName = 'Cooldown';
          break;
        default:
          roleName = 'Intervall';
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                roleName,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$durationMin min @ Z$zoneNum',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.volt.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.volt),
                  ),
                  child: Text(
                    '${block.count}x Wiederholung',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.targetLocalDate != null
          ? DateTime.parse(widget.targetLocalDate!)
          : now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final localDateStr =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

    final athleteId = widget.athleteId ?? 'me';
    final repo = PlannedWorkoutRepository();

    final planned = PlannedWorkout(
      id: '',
      athleteId: athleteId,
      createdBy: athleteId,
      localDate: localDateStr,
      sport: state.sport,
      title: 'Geplantes ${state.sport}-Training',
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

    if (mounted) {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vorlage erfolgreich gespeichert!')),
        );
      }
    }
  }
}
