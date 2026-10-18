import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/utils/orbit_date_formatter.dart';
import '../../activities/models/activity.dart';
import '../../activities/providers/activities_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../workout_builder/domain/workout_calculator.dart';
import '../domain/workout_block_extractor.dart';
import '../models/planned_workout.dart';
import '../providers/calendar_provider.dart';

/// Öffnet das Bottom Sheet mit den Details, Blöcken und Aktionen für ein [PlannedWorkout] (Phase 37.2).
void showWorkoutDetailSheet(BuildContext context, PlannedWorkout workout) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF001F47), // Deep Navy
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => WorkoutDetailSheet(workout: workout),
  );
}

/// Detaillierte Ansicht einer geplanten Einheit mit visueller Block-Grafik, Schritt-für-Schritt
/// Zielwert-Tabelle (Watt, Pace, Puls) und reaktiven Workout-Aktionen (Phase 37.2).
class WorkoutDetailSheet extends ConsumerWidget {
  /// Das anzuzeigende geplante Workout.
  final PlannedWorkout workout;

  const WorkoutDetailSheet({super.key, required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(plannedWorkoutRepositoryProvider);
    final activitiesAsync = ref.watch(activitiesProvider);
    final activities = activitiesAsync.valueOrNull ?? [];

    // Schwellenwerte des Athleten abrufen für individuelle Ziel-Berechnungen
    final userDoc = ref.watch(userDocumentProvider).valueOrNull;
    final thresholdsMap = userDoc?['thresholds'] as Map<String, dynamic>?;
    final ftp = (userDoc?['ftp'] as num?)?.toDouble() ??
        (thresholdsMap?['ftp'] as num?)?.toDouble();
    final lthr = (userDoc?['lthr'] as num?)?.toInt() ??
        (thresholdsMap?['lthr'] as num?)?.toInt();
    final runPace = (userDoc?['runThresholdPace'] as num?)?.toInt() ??
        (thresholdsMap?['runThresholdPace'] as num?)?.toInt();
    final css = (userDoc?['css'] as num?)?.toInt() ??
        (thresholdsMap?['css'] as num?)?.toInt();

    final thresholds = AthleteThresholds(
      ftp: ftp,
      lthr: lthr,
      runThresholdPaceSecPerKm: runPace,
      cssSecPer100m: css,
    );
    final maxHr = (userDoc?['maxHeartRate'] as num?)?.toInt();

    // 1:1 strukturierte Trainingsblöcke extrahieren
    final steps = WorkoutBlockExtractor.extractSteps(
      workout,
      thresholds: thresholds,
      maxHr: maxHr,
    );

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

    final sportColor = _getSportColor(workout.sport);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header mit Sportart, Datum und Lösch-Button
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sportColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: sportColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getSportIcon(workout.sport),
                            size: 14, color: sportColor),
                        const SizedBox(width: 6),
                        Text(
                          workout.sport,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sportColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatLocalDate(workout.localDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.coral),
                    tooltip: 'Einheit löschen',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF002A5C),
                          title: const Text('Einheit löschen?',
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'Möchtest du diese geplante Einheit wirklich aus deinem Trainingsplan entfernen?',
                            style: TextStyle(color: Color(0xFFCBD5E1)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Abbrechen',
                                  style: TextStyle(color: Color(0xFF94A3B8))),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.coral),
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

              const SizedBox(height: 8),

              // Titel
              Text(
                workout.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              if (workout.description != null &&
                  workout.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  workout.description!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Geplante Kennzahlen (Dauer, Distanz, Belastung)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF002A5C), // Navy Card
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF003D82)),
                ),
                child: Row(
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
                      _buildInfoColumn(
                          'Belastung',
                          '${workout.plannedLoad!.toStringAsFixed(0)} Load',
                          theme),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Visuelle Block-Grafik (Gesamtprofil)
              Text(
                'Trainingsprofil (${steps.length} Blöcke)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              _buildFullWidthBlockBar(steps),

              const SizedBox(height: 18),

              // Detaillierte Schritt-für-Schritt Blockliste
              Text(
                'Detaillierte Block-Schritte & Zielwerte',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...steps.map((step) => _buildStepTile(step, theme)),

              // Soll-Ist Abgleich (falls verknüpft)
              if (linkedActivity != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Absolviert: ${linkedActivity.title}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _buildComparisonText(workout, linkedActivity),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFFCBD5E1)),
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
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ],

              // Manuelle Zuordnung anbieten, falls noch offen und passende Aktivität vorliegt
              if (workout.isPlanned && sameDayUnmatched.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Aktivität von heute zuordnen:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                for (final act in sameDayUnmatched)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002A5C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF003D82)),
                    ),
                    child: Row(
                      children: [
                        Icon(_getSportIcon(act.sport),
                            color: _getSportColor(act.sport), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(act.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(
                                '${(act.durationSec / 60).toStringAsFixed(0)} min · ${act.sport}',
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.volt,
                            foregroundColor: AppColors.navy,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                          onPressed: () async {
                            await repo.linkActivity(
                                workoutId: workout.id,
                                activityId: act.id,
                                matchStatus: 'MANUAL');
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Zuordnen',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 22),

              // Reaktive Workout-Aktionen
              Text(
                'Aktionen',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    key: const Key('workout_action_postpone_tomorrow'),
                    backgroundColor: const Color(0xFF002A5C),
                    avatar: const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.volt),
                    label: const Text('Auf morgen verschieben',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final current = DateTime.tryParse(workout.localDate) ??
                          DateTime.now();
                      final tomorrow = current.add(const Duration(days: 1));
                      final dateStr = DateFormat('yyyy-MM-dd').format(tomorrow);
                      await repo.reschedule(
                          workoutId: workout.id, newLocalDate: dateStr);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ActionChip(
                    key: const Key('workout_action_pick_date'),
                    backgroundColor: const Color(0xFF002A5C),
                    avatar: const Icon(Icons.date_range,
                        size: 16, color: AppColors.volt),
                    label: const Text('Datum wählen...',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final initial = DateTime.tryParse(workout.localDate) ??
                          DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                        builder: (ctx, child) {
                          return Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.volt,
                                onPrimary: AppColors.navy,
                                surface: Color(0xFF002A5C),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
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
                      key: const Key('workout_action_mark_skipped'),
                      backgroundColor: const Color(0xFF002A5C),
                      avatar: const Icon(Icons.cancel_outlined,
                          size: 16, color: AppColors.coral),
                      label: const Text('Als übersprungen markieren',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        await repo.markSkipped(workout.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  if (workout.isSkipped)
                    ActionChip(
                      key: const Key('workout_action_reopen'),
                      backgroundColor: const Color(0xFF002A5C),
                      avatar: const Icon(Icons.refresh,
                          size: 16, color: AppColors.volt),
                      label: const Text('Wieder öffnen',
                          style: TextStyle(color: Colors.white)),
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
      ),
    );
  }

  /// Rendert den durchgehenden, proportionalen Block-Balken über die volle Breite.
  Widget _buildFullWidthBlockBar(List<ExtractedWorkoutStep> steps) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF001F47),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF003D82)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Row(
          children: steps.map((s) {
            final flexVal = (s.durationSec / 20).clamp(1, 200).toInt();
            return Expanded(
              flex: flexVal,
              child: Container(
                color: s.color,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                child: Center(
                  child: s.durationSec >= 180
                      ? Text(
                          'Z${s.zone}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: s.zone >= 4 ? Colors.black : Colors.white,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Rendert eine einzelne Block-Kachel mit Detailangaben und berechneten Zielwerten.
  Widget _buildStepTile(ExtractedWorkoutStep step, ThemeData theme) {
    return Container(
      key: Key('workout_step_${step.stepIndex}'),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF002A5C), // Navy Card
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF003D82)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: step.color),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Block-Nummer & Bezeichnung
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${step.stepIndex} ${step.label}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.formattedDuration,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Zone & % Intensität
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: step.color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Z${step.zone} (${step.intensityPercentLabel})',
                        style: TextStyle(
                          color: step.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Konkrete Zielwerte (Watt / Pace / HR)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (step.targetWattsLabel != null)
                            Text(
                              step.targetWattsLabel!,
                              style: const TextStyle(
                                color: AppColors.volt,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          if (step.targetPaceLabel != null)
                            Text(
                              step.targetPaceLabel!,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8), // Sky Blue
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          if (step.targetHrLabel != null)
                            Text(
                              step.targetHrLabel!,
                              style: const TextStyle(
                                color: Color(0xFFF43F5E), // Rose
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  String _formatLocalDate(String dateStr) {
    return OrbitDateFormatter.formatDateString(dateStr);
  }

  String _buildComparisonText(PlannedWorkout plan, Activity act) {
    if (plan.plannedDurationSec == 0) {
      return 'Dauer: ${(act.durationSec / 60).toStringAsFixed(0)} min';
    }
    final percent = (act.durationSec / plan.plannedDurationSec) * 100;
    return '${percent.toStringAsFixed(0)} % der geplanten Dauer (${(act.durationSec / 60).toStringAsFixed(0)} min absolviert).';
  }

  Color _getSportColor(String sport) {
    switch (sport.toUpperCase()) {
      case 'SWIM':
        return AppColors.sportSwim;
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'STRENGTH':
        return AppColors.sportStrength;
      case 'TRIATHLON':
        return AppColors.volt;
      default:
        return AppColors.navyLight;
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'SWIM':
        return Icons.pool;
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'STRENGTH':
        return Icons.fitness_center;
      case 'TRIATHLON':
        return Icons.layers;
      default:
        return Icons.sports;
    }
  }
}
