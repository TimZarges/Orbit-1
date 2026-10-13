import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../models/planned_workout.dart';

/// Reusable Karte für eine geplante Trainingseinheit im Kalender.
class WorkoutCard extends StatelessWidget {
  final PlannedWorkout workout;
  final VoidCallback? onTap;
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

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: cardBorder),
            right: BorderSide(color: cardBorder),
            bottom: BorderSide(color: cardBorder),
            left: BorderSide(color: sportColor, width: 4),
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getSportIcon(workout.sport), size: 16, color: sportColor),
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
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBadgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusBadgeColor),
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
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
                if (workout.formattedDistance != null) ...[
                  const Text(' · '),
                  Text(
                    workout.formattedDistance!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
                if (workout.plannedLoad != null) ...[
                  const Text(' · '),
                  Text(
                    '${workout.plannedLoad!.toStringAsFixed(0)} TSS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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

  IconData _getSportIcon(String sport) {
    switch (sport) {
      case 'SWIM':
        return Icons.pool;
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'STRENGTH':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }
}
