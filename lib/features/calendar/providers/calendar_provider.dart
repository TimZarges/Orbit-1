import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../activities/models/activity.dart';
import '../../activities/providers/activities_provider.dart';
import '../models/planned_workout.dart';
import '../repositories/planned_workout_repository.dart';

/// Ansichtsmodus des Kalenders.
enum CalendarViewMode {
  /// Wochenansicht (Standard, mobiler Fokus).
  week,

  /// Monatsübersicht mit Belegungsindikatoren.
  month,

  /// Listenansicht kommender Einheiten.
  list,
}

/// Provider für das [PlannedWorkoutRepository].
final plannedWorkoutRepositoryProvider = Provider<PlannedWorkoutRepository>((ref) {
  return PlannedWorkoutRepository();
});

/// Aktuell im Kalender ausgewähltes Datum (Standard: Heute).
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Aktueller Kalender-Ansichtsmodus (Woche, Monat, Liste).
final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) {
  return CalendarViewMode.week;
});

/// Liefert geplante Einheiten für einen beliebigen Datumsbereich.
final athleteWorkoutsRangeProvider = StreamProvider.family<List<PlannedWorkout>, ({String athleteId, String startDate, String endDate})>((ref, arg) {
  final repo = ref.watch(plannedWorkoutRepositoryProvider);
  return repo.watchWorkoutsForAthlete(
    athleteId: arg.athleteId,
    startDate: arg.startDate,
    endDate: arg.endDate,
  );
});

/// Liefert die geplanten Workouts für die aktuell ausgewählte Woche (Montag bis Sonntag).
final athleteCurrentWeekWorkoutsProvider = StreamProvider.family<List<PlannedWorkout>, String>((ref, athleteId) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  
  // Montag der Woche ermitteln (DateTime: Montag = 1, Sonntag = 7)
  final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));

  final startStr = _formatDate(monday);
  final endStr = _formatDate(sunday);

  return ref.watch(athleteWorkoutsRangeProvider((
    athleteId: athleteId,
    startDate: startStr,
    endDate: endStr,
  )).stream);
});

/// Liefert die geplanten Workouts für den aktuell ausgewählten Monat (inkl. Puffer für Randtage).
final athleteCurrentMonthWorkoutsProvider = StreamProvider.family<List<PlannedWorkout>, String>((ref, athleteId) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);

  final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
  final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

  // Jeweils bis zum Wochenanfang/ende erweitern für saubere Kalenderansicht
  final start = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
  final end = lastDayOfMonth.add(Duration(days: 7 - lastDayOfMonth.weekday));

  return ref.watch(athleteWorkoutsRangeProvider((
    athleteId: athleteId,
    startDate: _formatDate(start),
    endDate: _formatDate(end),
  )).stream);
});

/// Berechnet die Wochensummen (Soll vs. Ist) für die ausgewählte Woche.
final weekSummaryProvider = Provider.family<WeekSummary, String>((ref, athleteId) {
  final workouts = ref.watch(athleteCurrentWeekWorkoutsProvider(athleteId)).valueOrNull ?? [];
  final activities = ref.watch(activitiesProvider).valueOrNull ?? [];

  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  final startStr = _formatDate(monday);
  final endStr = _formatDate(sunday);

  // Aktivitäten der aktuellen Woche filtern
  final weekActivities = activities.where((a) {
    return a.localDate.compareTo(startStr) >= 0 && a.localDate.compareTo(endStr) <= 0;
  }).toList();

  int plannedDurationSec = 0;
  double plannedDistanceM = 0;
  double plannedLoad = 0;

  for (final w in workouts) {
    plannedDurationSec += w.plannedDurationSec;
    if (w.plannedDistanceM != null) plannedDistanceM += w.plannedDistanceM!;
    if (w.plannedLoad != null) plannedLoad += w.plannedLoad!;
  }

  int actualDurationSec = 0;
  double actualDistanceM = 0;
  final Set<String> activeDays = {};

  for (final a in weekActivities) {
    actualDurationSec += a.durationSec.toInt();
    actualDistanceM += a.distanceM;
    activeDays.add(a.localDate);
  }

  return WeekSummary(
    plannedDurationSec: plannedDurationSec,
    actualDurationSec: actualDurationSec,
    plannedDistanceM: plannedDistanceM,
    actualDistanceM: actualDistanceM,
    plannedLoad: plannedLoad,
    trainingDaysCount: activeDays.length,
    completedWorkoutsCount: workouts.where((w) => w.isCompleted).length,
    totalPlannedWorkoutsCount: workouts.length,
  );
});

class WeekSummary {
  final int plannedDurationSec;
  final int actualDurationSec;
  final double plannedDistanceM;
  final double actualDistanceM;
  final double plannedLoad;
  final int trainingDaysCount;
  final int completedWorkoutsCount;
  final int totalPlannedWorkoutsCount;

  const WeekSummary({
    required this.plannedDurationSec,
    required this.actualDurationSec,
    required this.plannedDistanceM,
    required this.actualDistanceM,
    required this.plannedLoad,
    required this.trainingDaysCount,
    required this.completedWorkoutsCount,
    required this.totalPlannedWorkoutsCount,
  });

  /// Verhältnis der tatsächlichen Dauer zur geplanten Dauer in Prozent (z. B. 95%).
  double get durationCompliancePercentage {
    if (plannedDurationSec == 0) return 100.0;
    return (actualDurationSec / plannedDurationSec) * 100.0;
  }
}

String _formatDate(DateTime dt) {
  return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
}
