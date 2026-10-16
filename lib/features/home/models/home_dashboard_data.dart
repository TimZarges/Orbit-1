import '../../calendar/models/planned_workout.dart';
import '../../activities/models/activity.dart';
import '../../analysis/models/daily_aggregate.dart';
import '../../analysis/models/form_traffic_light.dart';
import '../../health/models/daily_metrics.dart';
import 'race_goal.dart';

/// Aggregiertes Datenbündel für den Home-Tab („Heute").
class HomeDashboardData {
  final String todayLocalDate;
  final DailyAggregate? todayAggregate;
  final PlannedWorkout? todayPlannedWorkout;
  final Activity? latestActivity;
  final DailyMetrics? todayDailyMetrics;
  final int unreadMessagesCount;
  final int pendingThresholdProposalsCount;
  final int unmatchedActivitiesCount;
  final FormTrafficLight? formTrafficLight;
  final RaceGoal? raceGoal;
  final bool isDemo;
  final bool isBrandNewUser;

  const HomeDashboardData({
    required this.todayLocalDate,
    this.todayAggregate,
    this.todayPlannedWorkout,
    this.latestActivity,
    this.todayDailyMetrics,
    this.unreadMessagesCount = 0,
    this.pendingThresholdProposalsCount = 0,
    this.unmatchedActivitiesCount = 0,
    this.formTrafficLight,
    this.raceGoal,
    this.isDemo = false,
    this.isBrandNewUser = false,
  });

  double get actualLoadToday => todayAggregate?.dailyLoad ?? 0.0;
  double get plannedLoadToday => todayPlannedWorkout?.plannedLoad ?? 0.0;
  bool get isRestDay => todayPlannedWorkout == null && actualLoadToday == 0.0;
}
