import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/user_provider.dart';
import '../models/analysis_timeframe.dart';
import '../models/daily_aggregate.dart';
import '../models/form_traffic_light.dart';
import '../models/weekly_load_summary.dart';
import '../models/consistency_summary.dart';
import '../models/sport_distribution.dart';
import '../models/zone_distribution.dart';
import '../domain/form_calculator.dart';
import '../domain/aggregates_calculator.dart';
import '../repositories/analysis_repository.dart';

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepository();
});

/// Aktuell ausgewählter Analyse-Zeitraum (Woche, Monat, Saison).
final selectedAnalysisTimeframeProvider =
    StateProvider<AnalysisTimeframe>((ref) {
  return AnalysisTimeframe.week;
});

/// Aktuelle Athleten-ID (kann von einem Trainer überschrieben werden).
final analysisAthleteIdOverrideProvider = StateProvider<String?>((ref) => null);

/// Die effektiv zu betrachtende Athleten-ID.
final effectiveAnalysisAthleteIdProvider = Provider<String>((ref) {
  final overrideId = ref.watch(analysisAthleteIdOverrideProvider);
  if (overrideId != null && overrideId.isNotEmpty) {
    return overrideId;
  }
  final user = ref.watch(userProvider).valueOrNull;
  return user?.uid ?? '';
});

/// Vollständiger Zustand der Analyse-Ansicht für einen Athleten und Zeitraum.
class AnalysisViewState {
  final AnalysisTimeframe timeframe;
  final FormTrafficLight formTrafficLight;
  final WeeklyLoadSummary weeklyLoad;
  final ConsistencySummary consistency;
  final SportDistributionSummary sportDistribution;
  final ZoneDistributionSummary zoneDistribution;
  final List<WeeklyLoadTrendPoint> weeklyTrend;
  final String weeklyTrendDescription;
  final List<FitnessFatiguePoint> fitnessFatiguePoints;
  final bool isDemo;
  final bool hasData;

  const AnalysisViewState({
    required this.timeframe,
    required this.formTrafficLight,
    required this.weeklyLoad,
    required this.consistency,
    required this.sportDistribution,
    required this.zoneDistribution,
    required this.weeklyTrend,
    required this.weeklyTrendDescription,
    required this.fitnessFatiguePoints,
    required this.isDemo,
    required this.hasData,
  });
}

/// Lädt und berechnet alle Daten für den Analyse-Tab.
final analysisStateProvider =
    FutureProvider.autoDispose<AnalysisViewState>((ref) async {
  final athleteId = ref.watch(effectiveAnalysisAthleteIdProvider);
  final timeframe = ref.watch(selectedAnalysisTimeframeProvider);
  final repository = ref.watch(analysisRepositoryProvider);

  if (athleteId.isEmpty) {
    // Leerer Zustand
    return _buildEmptyState(timeframe);
  }

  // Zeitraum-Begrenzung berechnen
  final now = DateTime.now();
  final int days;
  switch (timeframe) {
    case AnalysisTimeframe.week:
      days = 7;
      break;
    case AnalysisTimeframe.month:
      days = 28;
      break;
    case AnalysisTimeframe.season:
      days = 84;
      break;
  }

  final startDate = now.subtract(Duration(days: days - 1));
  final startStr = _formatDate(startDate);
  final endStr = _formatDate(now);

  // Wir laden auch 8 Wochen Historie für den Trend
  final trendStart = now.subtract(const Duration(days: 56));
  final trendStartStr = _formatDate(trendStart);

  // Firestore-Daten laden
  var aggregates = await repository.getAggregates(
    athleteId: athleteId,
    startDate: trendStartStr,
    endDate: endStr,
  );

  final plannedWorkouts = await repository.getPlannedWorkouts(
    athleteId: athleteId,
    startDate: startStr,
    endDate: endStr,
  );

  final totalRecordedDays = await repository.getRecordedDaysCount(athleteId);

  // Prüfen, ob Demo-Modus aktiv ist oder ob die Collection noch leer ist
  final userDoc = ref.watch(userDocumentProvider).valueOrNull;
  final isDemoMode =
      (userDoc?['demo'] is Map && userDoc?['demo']['enabled'] == true) ||
          aggregates.isEmpty;

  bool isDemo = false;
  if (aggregates.isEmpty && isDemoMode) {
    // Demo-Aggregate erzeugen
    aggregates = AnalysisRepository.generateDemoAggregates(days: 84);
    isDemo = true;
  }

  if (aggregates.isEmpty) {
    return _buildEmptyState(timeframe);
  }

  // Neuestes Aggregat für Form-Ampel
  final latest = aggregates.last;

  // Form-Ampel berechnen
  final formCalc = const FormCalculator();
  final historyCount = isDemo ? 56 : totalRecordedDays;
  final formTrafficLight = formCalc.calculate(
    ctl: latest.ctl,
    atl: latest.atl,
    daysOfHistory: historyCount,
    firstRecordedDate: now.subtract(Duration(days: historyCount)),
    orbitScore: latest.orbitScore,
  );

  // Slice für den aktiven Zeitraum
  final activeAggregates =
      aggregates.where((a) => a.localDate.compareTo(startStr) >= 0).toList();

  // Soll-Ist Belastung
  final weeklyLoad = AggregatesCalculator.calculateWeeklyLoad(
    aggregates: activeAggregates,
    plannedWorkouts: plannedWorkouts,
  );

  // Konsistenz
  final consistency = AggregatesCalculator.calculateConsistency(
    aggregates: activeAggregates,
    plannedWorkouts: plannedWorkouts,
    totalDays: days,
  );

  // Sportverteilung
  final sportDist =
      AggregatesCalculator.calculateSportDistribution(activeAggregates);

  // Zonenverteilung
  final zoneDist =
      AggregatesCalculator.calculateZoneDistribution(activeAggregates);

  // 8-Wochen-Trend
  final sortedDesc = List<DailyAggregate>.from(aggregates)
    ..sort((a, b) => b.localDate.compareTo(a.localDate));
  final trendPoints = AggregatesCalculator.calculate8WeekTrend(sortedDesc);
  final trendDesc = AggregatesCalculator.describeWeeklyTrend(trendPoints);

  // Fitness / Fatigue Zeitreihe
  final fitnessPoints =
      AggregatesCalculator.calculateFitnessFatiguePoints(aggregates);

  return AnalysisViewState(
    timeframe: timeframe,
    formTrafficLight: formTrafficLight,
    weeklyLoad: weeklyLoad,
    consistency: consistency,
    sportDistribution: sportDist,
    zoneDistribution: zoneDist,
    weeklyTrend: trendPoints,
    weeklyTrendDescription: trendDesc,
    fitnessFatiguePoints: fitnessPoints,
    isDemo: isDemo,
    hasData: true,
  );
});

String _formatDate(DateTime dt) {
  return '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

AnalysisViewState _buildEmptyState(AnalysisTimeframe timeframe) {
  return AnalysisViewState(
    timeframe: timeframe,
    formTrafficLight: const FormTrafficLight(
      status: FormStatus.insufficientData,
      ctl: 0,
      atl: 0,
      tsb: 0,
      ratio: 0,
      daysOfHistory: 0,
    ),
    weeklyLoad:
        const WeeklyLoadSummary(actualLoad: 0, plannedLoad: 0, hasPlan: false),
    consistency: const ConsistencySummary(
        activeDays: 0, totalDays: 7, plannedDays: 0, streakWeeks: 0),
    sportDistribution:
        const SportDistributionSummary(items: [], totalDurationSec: 0),
    zoneDistribution:
        const ZoneDistributionSummary(zones: [], totalDurationSec: 0),
    weeklyTrend: const [],
    weeklyTrendDescription: 'Noch keine Daten vorhanden.',
    fitnessFatiguePoints: const [],
    isDemo: false,
    hasData: false,
  );
}
