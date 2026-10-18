import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../workout_builder/models/workout_builder_models.dart';
import '../../workout_builder/widgets/workout_profile_chart.dart';
import '../domain/workout_block_extractor.dart';
import '../models/planned_workout.dart';

/// Einheitliche, wiederverwendbare Karte für geplante Trainingseinheiten im Kalender (Phase 37.1).
///
/// Folgt dem ORBIT Design-System (`#002A5C` Navy Card, `#003D82` Rahmen, linksbündiger
/// Disziplin-Farbstreifen) und rendert für JEDE Einheit eine konsistente Mini-Block-Vorschau.
class WorkoutCard extends StatelessWidget {
  /// Das anzuzeigende geplante Workout.
  final PlannedWorkout workout;

  /// Optionaler Klick-Handler (z. B. zum Öffnen des WorkoutDetailSheet).
  final VoidCallback? onTap;

  /// Ob das Datum zusätzlich angezeigt werden soll (z. B. in Listenansichten).
  final bool showDate;

  const WorkoutCard({
    super.key,
    required this.workout,
    this.onTap,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sportColor = _getSportColor(workout.sport);

    Color statusBadgeColor;
    String statusText;
    IconData statusIcon;

    if (workout.isCompleted) {
      statusBadgeColor = const Color(0xFF10B981);
      statusText = 'Erledigt';
      statusIcon = Icons.check_circle_outline;
    } else if (workout.isSkipped) {
      statusBadgeColor = const Color(0xFF94A3B8);
      statusText = 'Übersprungen';
      statusIcon = Icons.cancel_outlined;
    } else {
      statusBadgeColor = const Color(0xFFF59E0B);
      statusText = 'Geplant';
      statusIcon = Icons.schedule;
    }

    // Einheitliches ORBIT Card-Styling (Navy #002A5C)
    final cardBg = isDark ? const Color(0xFF002A5C) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF003D82) : const Color(0xFFE2E8F0);

    // Blöcke für die Mini-Vorschau extrahieren
    final extractedSteps = WorkoutBlockExtractor.extractSteps(workout);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Links-bündiger Disziplin-Farbbalken
                Container(width: 4, color: sportColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getSportIcon(workout.sport),
                                size: 16, color: sportColor),
                            const SizedBox(width: 6),
                            Text(
                              workout.sport,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: sportColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (showDate) ...[
                              const SizedBox(width: 8),
                              Text(
                                workout.localDate,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusBadgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      size: 12, color: statusBadgeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusBadgeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          workout.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              workout.formattedDuration,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            if (workout.formattedDistance != null) ...[
                              const Text(' · '),
                              Text(
                                workout.formattedDistance!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                            if (workout.plannedLoad != null) ...[
                              const Text(' · '),
                              Text(
                                '${workout.plannedLoad!.toStringAsFixed(0)} Load',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Konsistente Mini-Blockleiste
                        _buildMiniBlockBar(extractedSteps),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Baut einen farbkodierten Mini-Blockbalken, der die Struktur des Workouts visualisiert.
  Widget _buildMiniBlockBar(List<ExtractedWorkoutStep> steps) {
    if (steps.isEmpty) return const SizedBox.shrink();

    // Falls ein klassisches WorkoutProfileChart verfügbar ist, bevorzugen wir dies
    if (workout.structure != null) {
      try {
        final struct = WorkoutStructure.migrateStructure(workout.structure!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: WorkoutProfileChart(
            structure: struct,
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          ),
        );
      } catch (_) {}
    }

    // Konsistente lineare Segment-Vorschau aus den extrahierten Schritten
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          children: steps.map((s) {
            final flexVal = (s.durationSec / 30).clamp(1, 100).toInt();
            return Expanded(
              flex: flexVal,
              child: Container(
                color: s.color,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Liefert die Primärfarbe für die jeweilige Sportart.
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

  /// Liefert das Disziplin-Icon.
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
