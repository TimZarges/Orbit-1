import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../calendar/models/planned_workout.dart';
import 'daily_ring_widget.dart';

/// Zentrale Hero-Karte auf Deep-Navy-Hintergrund (#0F172A) mit Daily Ring und heutigem Training.
class HomeHeroCard extends StatelessWidget {
  final double actualLoad;
  final PlannedWorkout? plannedWorkout;
  final VoidCallback? onWorkoutTap;

  const HomeHeroCard({
    super.key,
    required this.actualLoad,
    this.plannedWorkout,
    this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlan = plannedWorkout != null;
    final isRestDay = !hasPlan && actualLoad == 0;
    final targetLoad = plannedWorkout?.plannedLoad ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Deep Navy Hero
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. Ring
          DailyRingWidget(
            actualLoad: actualLoad,
            targetLoad: targetLoad,
            isRestDay: isRestDay,
            size: 150,
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),

          // 2. Heutiges Training oder Ruhetag
          if (hasPlan) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getSportColor(plannedWorkout!.sport).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSportIcon(plannedWorkout!.sport),
                    color: _getSportColor(plannedWorkout!.sport),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plannedWorkout!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDuration(plannedWorkout!.plannedDurationSec)}'
                        '${plannedWorkout!.plannedLoad != null ? " · ${plannedWorkout!.plannedLoad!.round()} TSS" : ""}',
                        style: AppTypography.label.copyWith(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onWorkoutTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.volt,
                    foregroundColor: AppColors.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Details',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.self_improvement, color: AppColors.volt, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kein Training geplant',
                        style: AppTypography.title.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Genieße deinen Ruhetag oder absolviere lockeres Dehnen.',
                        style: AppTypography.label.copyWith(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getSportColor(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'SWIM':
        return AppColors.sportSwim;
      default:
        return AppColors.navyLight;
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatDuration(int? sec) {
    if (sec == null || sec <= 0) return '–';
    final m = sec ~/ 60;
    return '$m min';
  }
}
