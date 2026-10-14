import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../controllers/workout_builder_controller.dart';
import '../models/workout_builder_models.dart';

/// Interaktives Bottom Sheet zur visuellen Bearbeitung aller Trainingsblöcke.
class WorkoutBlockEditorSheet extends ConsumerWidget {
  final WorkoutBuilderParams params;

  const WorkoutBlockEditorSheet({
    super.key,
    required this.params,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutBuilderProvider(params));
    final notifier = ref.read(workoutBuilderProvider(params).notifier);
    final blocks = state.structure?.blocks ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Sheet Header mit Drag-Handle und Schließen-Button
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Block-Editor (${blocks.length} Blöcke)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Schließen',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Liste der Blöcke
              Expanded(
                child: blocks.isEmpty
                    ? const Center(
                        child: Text(
                          'Keine Blöcke vorhanden. Füge den ersten Block hinzu!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        itemCount: blocks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final block = blocks[index];
                          return _buildBlockCard(
                            context: context,
                            block: block,
                            index: index,
                            totalBlocks: blocks.length,
                            notifier: notifier,
                            sport: state.sport,
                          );
                        },
                      ),
              ),

              // Untere Aktionsleiste: Neuer Block
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Schritt hinzufügen'),
                          onPressed: () {
                            notifier.addBlock(
                              const StepBlock(
                                role: WorkoutRole.work,
                                target: WorkoutTarget.duration(300),
                                intensity: ZoneIntensity.single(2),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.repeat),
                          label: const Text('Wiederholung'),
                          onPressed: () {
                            notifier.addBlock(
                              const RepeatBlock(
                                count: 4,
                                blocks: [
                                  StepBlock(
                                    role: WorkoutRole.work,
                                    target: WorkoutTarget.duration(240),
                                    intensity: ZoneIntensity.single(4),
                                  ),
                                  StepBlock(
                                    role: WorkoutRole.rest,
                                    target: WorkoutTarget.duration(120),
                                    intensity: ZoneIntensity.single(1),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockCard({
    required BuildContext context,
    required WorkoutBlock block,
    required int index,
    required int totalBlocks,
    required WorkoutBuilderNotifier notifier,
    required String sport,
  }) {
    if (block is StepBlock) {
      return _buildStepCard(
        context: context,
        step: block,
        index: index,
        totalBlocks: totalBlocks,
        notifier: notifier,
        sport: sport,
      );
    } else if (block is RepeatBlock) {
      return _buildRepeatCard(
        context: context,
        repeat: block,
        index: index,
        totalBlocks: totalBlocks,
        notifier: notifier,
        sport: sport,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStepCard({
    required BuildContext context,
    required StepBlock step,
    required int index,
    required int totalBlocks,
    required WorkoutBuilderNotifier notifier,
    required String sport,
  }) {
    final zoneNum = step.intensity is ZoneIntensity
        ? (step.intensity as ZoneIntensity).low
        : 2;
    final color = AppColors.zoneColor(zoneNum);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zeile 1: Rolle-Badge, Beschriftung und Aktionen
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    step.role.displayNameDe.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${step.target.formattedDisplay} ${step.intensity.formattedDisplay}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),

                // Auf / Ab Pfeile
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  tooltip: 'Nach oben verschieben',
                  onPressed: index > 0
                      ? () => notifier.moveBlock(index, index - 1)
                      : null,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  tooltip: 'Nach unten verschieben',
                  onPressed: index < totalBlocks - 1
                      ? () => notifier.moveBlock(index, index + 1)
                      : null,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Duplizieren',
                  onPressed: () => notifier.duplicateBlock(index),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  tooltip: 'Löschen',
                  onPressed: () => notifier.deleteBlock(index),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Stepper für Dauer/Distanz
            Row(
              children: [
                const Text('Ziel: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                if (step.target.isDuration) ...[
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      final current = step.target.durationSec ?? 60;
                      if (current > 30) {
                        notifier.moveBlock(index, index); // Trigger update
                        final updated = step.copyWith(
                          target: WorkoutTarget.duration(current - 30),
                        );
                        _replaceStepInStructure(notifier, index, updated);
                      }
                    },
                  ),
                  Text(
                    step.target.formattedDisplay,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () {
                      final current = step.target.durationSec ?? 60;
                      final updated = step.copyWith(
                        target: WorkoutTarget.duration(current + 30),
                      );
                      _replaceStepInStructure(notifier, index, updated);
                    },
                  ),
                ] else if (step.target.isDistance) ...[
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      final current = step.target.distanceM ?? 100;
                      if (current > 50) {
                        final updated = step.copyWith(
                          target: WorkoutTarget.distance(current - 50),
                        );
                        _replaceStepInStructure(notifier, index, updated);
                      }
                    },
                  ),
                  Text(
                    step.target.formattedDisplay,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () {
                      final current = step.target.distanceM ?? 100;
                      final updated = step.copyWith(
                        target: WorkoutTarget.distance(current + 50),
                      );
                      _replaceStepInStructure(notifier, index, updated);
                    },
                  ),
                ],

                const Spacer(),

                // In Wiederholung umschließen
                TextButton.icon(
                  icon: const Icon(Icons.repeat, size: 16),
                  label: const Text('Als 4x Serie',
                      style: TextStyle(fontSize: 12)),
                  onPressed: () =>
                      notifier.wrapBlockInRepeat(index, repeatCount: 4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatCard({
    required BuildContext context,
    required RepeatBlock repeat,
    required int index,
    required int totalBlocks,
    required WorkoutBuilderNotifier notifier,
    required String sport,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cockpit.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.navy.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Wiederholungszähler & Aktionen
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${repeat.count}× WIEDERHOLUNG',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Stepper für count
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: repeat.count > 2
                    ? () {
                        final updated =
                            repeat.copyWith(count: repeat.count - 1);
                        _replaceStepInStructure(notifier, index, updated);
                      }
                    : null,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '${repeat.count}x',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: repeat.count < 99
                    ? () {
                        final updated =
                            repeat.copyWith(count: repeat.count + 1);
                        _replaceStepInStructure(notifier, index, updated);
                      }
                    : null,
                visualDensity: VisualDensity.compact,
              ),

              const Spacer(),

              // Serie auflösen
              IconButton(
                icon: const Icon(Icons.call_split, size: 18),
                tooltip: 'Wiederholung auflösen',
                onPressed: () => notifier.unwrapRepeat(index),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                tooltip: 'Löschen',
                onPressed: () => notifier.deleteBlock(index),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Enthaltene Einzelschritte
          ...repeat.blocks.map((child) {
            if (child is StepBlock) {
              return Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${child.role.displayNameDe}: ${child.target.formattedDisplay} ${child.intensity.formattedDisplay}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  void _replaceStepInStructure(
    WorkoutBuilderNotifier notifier,
    int index,
    WorkoutBlock newBlock,
  ) {
    notifier.replaceBlock(index, newBlock);
  }
}
