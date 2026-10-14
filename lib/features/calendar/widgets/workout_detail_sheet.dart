import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../activities/models/activity.dart';
import '../../activities/providers/activities_provider.dart';
import '../models/planned_workout.dart';
import '../providers/calendar_provider.dart';

/// Öffnet das Bottom Sheet mit den Details und Aktionen für ein [PlannedWorkout].
void showWorkoutDetailSheet(BuildContext context, PlannedWorkout workout) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => WorkoutDetailSheet(workout: workout),
  );
}

class WorkoutDetailSheet extends ConsumerWidget {
  final PlannedWorkout workout;

  const WorkoutDetailSheet({super.key, required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final repo = ref.watch(plannedWorkoutRepositoryProvider);
    final activitiesAsync = ref.watch(activitiesProvider);
    final activities = activitiesAsync.valueOrNull ?? [];

    // Verknüpfte Aktivität finden (falls vorhanden)
    Activity? linkedActivity;
    if (workout.activityId != null) {
      for (final a in activities) {
        if (a.id == workout.activityId) {
          linkedActivity = a;
          break;
        }
      }
    }

    // Unverknüpfte Aktivitäten am selben Tag (für manuelle Zuordnung)
    final sameDayUnmatched = activities.where((a) {
      return a.localDate == workout.localDate &&
          (a.plannedWorkoutId == null || a.plannedWorkoutId!.isEmpty);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header mit Sportart und Status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getSportColor(workout.sport).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workout.sport,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getSportColor(workout.sport),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  workout.localDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Einheit löschen?'),
                        content: const Text(
                            'Möchtest du diese geplante Einheit wirklich löschen?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Abbrechen')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await repo.delete(workout.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Titel
            Text(
              workout.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            if (workout.description != null &&
                workout.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                workout.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Geplante Werte
            Row(
              children: [
                _buildInfoColumn(
                    'Geplante Dauer', workout.formattedDuration, theme),
                if (workout.formattedDistance != null) ...[
                  const SizedBox(width: 24),
                  _buildInfoColumn(
                      'Distanz', workout.formattedDistance!, theme),
                ],
                if (workout.plannedLoad != null) ...[
                  const SizedBox(width: 24),
                  _buildInfoColumn('Belastung',
                      '${workout.plannedLoad!.toStringAsFixed(0)} TSS', theme),
                ],
              ],
            ),

            // Soll-Ist Abgleich (falls verknüpft)
            if (linkedActivity != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          'Absolviert: ${linkedActivity.title}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _buildComparisonText(workout, linkedActivity),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await repo.unlinkActivity(
                            workoutId: workout.id,
                            activityId: linkedActivity!.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.link_off, size: 16),
                      label: const Text('Zuordnung aufheben'),
                    ),
                  ],
                ),
              ),
            ],

            // Manuelle Zuordnung anbieten, falls noch offen und passende Aktivität vorliegt
            if (workout.isPlanned && sameDayUnmatched.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mögliche Aktivitäten vom selben Tag zuordnen:',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final act in sameDayUnmatched)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_run),
                  title: Text(act.title),
                  subtitle: Text(
                      '${(act.durationSec / 60).toStringAsFixed(0)} min · ${act.sport}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await repo.linkActivity(
                          workoutId: workout.id,
                          activityId: act.id,
                          matchStatus: 'MANUAL');
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Zuordnen'),
                  ),
                ),
            ],

            const SizedBox(height: 20),

            // Aktionen: Verschieben & Status
            Text(
              'Aktionen',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Auf morgen verschieben'),
                  onPressed: () async {
                    final current =
                        DateTime.tryParse(workout.localDate) ?? DateTime.now();
                    final tomorrow = current.add(const Duration(days: 1));
                    final dateStr = DateFormat('yyyy-MM-dd').format(tomorrow);
                    await repo.reschedule(
                        workoutId: workout.id, newLocalDate: dateStr);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: const Text('Datum wählen...'),
                  onPressed: () async {
                    final initial =
                        DateTime.tryParse(workout.localDate) ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
                      await repo.reschedule(
                          workoutId: workout.id, newLocalDate: dateStr);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                if (!workout.isSkipped && !workout.isCompleted)
                  ActionChip(
                    avatar: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Als übersprungen markieren'),
                    onPressed: () async {
                      await repo.markSkipped(workout.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                if (workout.isSkipped)
                  ActionChip(
                    avatar: const Icon(Icons.refresh, size: 16),
                    label: const Text('Wieder öffnen'),
                    onPressed: () async {
                      await repo.markPlanned(workout.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: const Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _buildComparisonText(PlannedWorkout plan, Activity act) {
    if (plan.plannedDurationSec == 0)
      return 'Dauer: ${(act.durationSec / 60).toStringAsFixed(0)} min';
    final percent = (act.durationSec / plan.plannedDurationSec) * 100;
    return '${percent.toStringAsFixed(0)} % der geplanten Dauer (${(act.durationSec / 60).toStringAsFixed(0)} min absolviert).';
  }

  Color _getSportColor(String sport) {
    switch (sport) {
      case 'SWIM':
        return AppColors.sportSwim;
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'STRENGTH':
        return AppColors.sportStrength;
      default:
        return AppColors.navyLight;
    }
  }
}
