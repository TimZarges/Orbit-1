import 'package:flutter/material.dart';
import '../../calendar/models/planned_workout.dart';
import '../../health/models/daily_metrics.dart';
import '../../health/widgets/three_rings_hero_card.dart';

/// Zentrale Hero-Karte auf Deep-Navy-Hintergrund (#001F47) aus Phase 21 mit den 3 ORBIT-Ringen:
/// 1. Erholung (0–100 %)
/// 2. Tagesbelastung (0–100 inkl. Zielkorridor)
/// 3. Schlaf (0–100 %)
/// sowie dem ORBIT Gesamt-Score Badge und der tagesaktuellen Trainingsempfehlung.
class HomeHeroCard extends StatelessWidget {
  final double actualLoad;
  final PlannedWorkout? plannedWorkout;
  final VoidCallback? onWorkoutTap;
  final DailyMetrics? dailyMetrics;
  final VoidCallback? onOpenHealthCockpit;

  const HomeHeroCard({
    super.key,
    required this.actualLoad,
    this.plannedWorkout,
    this.onWorkoutTap,
    this.dailyMetrics,
    this.onOpenHealthCockpit,
  });

  @override
  Widget build(BuildContext context) {
    return ThreeRingsHeroCard(
      actualLoad: actualLoad,
      plannedWorkout: plannedWorkout,
      onWorkoutTap: onWorkoutTap,
      dailyMetrics: dailyMetrics,
      onOpenHealthCockpit: onOpenHealthCockpit,
    );
  }
}
