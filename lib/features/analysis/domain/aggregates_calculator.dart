import 'dart:math';
import '../models/daily_aggregate.dart';
import '../models/weekly_load_summary.dart';
import '../models/consistency_summary.dart';
import '../models/sport_distribution.dart';
import '../models/zone_distribution.dart';
import '../../calendar/models/planned_workout.dart';

/// Datenpunkt für einen 8-Wochen-Belastungstrend.
class WeeklyLoadTrendPoint {
  final int weekNumber;
  final String weekLabel;
  final double totalLoad;

  const WeeklyLoadTrendPoint({
    required this.weekNumber,
    required this.weekLabel,
    required this.totalLoad,
  });
}

/// Datenpunkt für den CTL/ATL/TSB-Verlauf.
class FitnessFatiguePoint {
  final String date;
  final double ctl;
  final double atl;
  final double tsb;
  final bool isProjection;
  final double dailyLoad;

  const FitnessFatiguePoint({
    required this.date,
    required this.ctl,
    required this.atl,
    required this.tsb,
    this.isProjection = false,
    this.dailyLoad = 0.0,
  });
}

/// Rechner für rollierende Auswertungen über mehrere Aggregate.
class AggregatesCalculator {
  /// Berechnet den Soll-Ist-Vergleich für die Belastung.
  static WeeklyLoadSummary calculateWeeklyLoad({
    required List<DailyAggregate> aggregates,
    required List<PlannedWorkout> plannedWorkouts,
  }) {
    final actual = aggregates.fold(0.0, (sum, a) => sum + a.dailyLoad);
    final hasPlan = plannedWorkouts.isNotEmpty;
    final planned = plannedWorkouts.fold(0.0, (sum, p) {
      if (p.plannedLoad != null && p.plannedLoad! > 0) {
        return sum + p.plannedLoad!;
      }
      if (p.plannedDurationSec > 0) {
        // Schätzung: ca. 50 TSS pro Stunde Grundlagentraining
        return sum + (p.plannedDurationSec / 3600.0) * 50.0;
      }
      return sum;
    });

    return WeeklyLoadSummary(
      actualLoad: actual,
      plannedLoad: planned,
      hasPlan: hasPlan,
    );
  }

  /// Berechnet die Trainingskonsistenz.
  static ConsistencySummary calculateConsistency({
    required List<DailyAggregate> aggregates,
    required List<PlannedWorkout> plannedWorkouts,
    required int totalDays,
  }) {
    final activeDays =
        aggregates.where((a) => a.activityCount > 0 || a.dailyLoad > 0).length;
    final plannedDaySet = plannedWorkouts.map((p) => p.localDate).toSet();

    // Streak-Berechnung: Wir prüfen rückwirkend 7-Tage-Blöcke
    int streakWeeks = 0;
    if (aggregates.length >= 7) {
      final sorted = List<DailyAggregate>.from(aggregates)
        ..sort((a, b) => b.localDate.compareTo(a.localDate)); // Neueste zuerst

      for (int w = 0; w < (sorted.length / 7).floor(); w++) {
        final weekSlice =
            sorted.sublist(w * 7, min((w + 1) * 7, sorted.length));
        final activeInWeek = weekSlice
            .where((a) => a.activityCount > 0 || a.dailyLoad > 0)
            .length;
        if (activeInWeek >= 3) {
          streakWeeks++;
        } else {
          break;
        }
      }
    }

    return ConsistencySummary(
      activeDays: activeDays,
      totalDays: totalDays,
      plannedDays: plannedDaySet.length,
      streakWeeks: streakWeeks,
    );
  }

  /// Berechnet die kumulierte Sportarten-Verteilung.
  static SportDistributionSummary calculateSportDistribution(
      List<DailyAggregate> aggregates) {
    final map = <String, double>{};
    for (final agg in aggregates) {
      agg.sportsBreakdownSec.forEach((sport, sec) {
        map[sport] = (map[sport] ?? 0.0) + sec;
      });
    }
    return SportDistributionSummary.fromDurations(map);
  }

  /// Berechnet die kumulierte Zonenverteilung.
  static ZoneDistributionSummary calculateZoneDistribution(
      List<DailyAggregate> aggregates) {
    final zones = List<double>.filled(7, 0.0);
    for (final agg in aggregates) {
      for (int i = 0; i < min(7, agg.zoneBreakdownSec.length); i++) {
        zones[i] += agg.zoneBreakdownSec[i];
      }
    }
    return ZoneDistributionSummary.fromSeconds(zones);
  }

  /// Erzeugt Datenpunkte für die letzten 8 Wochen.
  static List<WeeklyLoadTrendPoint> calculate8WeekTrend(
      List<DailyAggregate> sortedAggregatesDesc) {
    final points = <WeeklyLoadTrendPoint>[];
    if (sortedAggregatesDesc.isEmpty) return points;

    // Wir teilen in bis zu 8 7-Tage-Blöcke ein
    for (int w = 0; w < 8; w++) {
      final start = w * 7;
      if (start >= sortedAggregatesDesc.length) break;
      final end = min((w + 1) * 7, sortedAggregatesDesc.length);
      final slice = sortedAggregatesDesc.sublist(start, end);
      final load = slice.fold(0.0, (sum, a) => sum + a.dailyLoad);

      final label = w == 0 ? 'Aktuell' : 'KW -${w}';
      points.add(WeeklyLoadTrendPoint(
        weekNumber: 8 - w,
        weekLabel: label,
        totalLoad: load,
      ));
    }

    return points.reversed.toList();
  }

  /// Erzeugt eine barrierefreie Textzusammenfassung für den 8-Wochen-Trend.
  static String describeWeeklyTrend(List<WeeklyLoadTrendPoint> points) {
    if (points.isEmpty) return 'Noch keine Trenddaten verfügbar.';
    if (points.length < 2)
      return 'Belastung der letzten Woche: ${points.first.totalLoad.round()} TSS.';

    final first = points.first.totalLoad;
    final last = points.last.totalLoad;
    if (first == 0) {
      return 'Aktuelle Wochenbelastung liegt bei ${last.round()} TSS.';
    }

    final diffPct = ((last - first) / first) * 100;
    if (diffPct > 15) {
      return 'Belastung in den letzten 8 Wochen deutlich gestiegen (+${diffPct.round()} %).';
    } else if (diffPct > 5) {
      return 'Belastung in den letzten 8 Wochen moderat gestiegen (+${diffPct.round()} %).';
    } else if (diffPct < -15) {
      return 'Belastung in den letzten 8 Wochen planmäßig reduziert (${diffPct.round()} %).';
    } else if (diffPct < -5) {
      return 'Belastung in den letzten 8 Wochen leicht gesunken (${diffPct.round()} %).';
    }
    return 'Belastung in den letzten 8 Wochen weitgehend stabil.';
  }

  /// Erzeugt Zeitreihenpunkte für das CTL/ATL/TSB-Diagramm.
  static List<FitnessFatiguePoint> calculateFitnessFatiguePoints(
      List<DailyAggregate> aggregatesAsc) {
    return aggregatesAsc.map((a) {
      return FitnessFatiguePoint(
        date: a.localDate,
        ctl: a.ctl,
        atl: a.atl,
        tsb: a.tsb,
        dailyLoad: a.dailyLoad,
        isProjection: false,
      );
    }).toList();
  }

  /// Erzeugt Zeitreihenpunkte für das PMC-Diagramm inkl. 14-Tage-Zukunftsprojektion
  /// basierend auf geplanten Workouts und dem Banister Impulse-Response Modell.
  static List<FitnessFatiguePoint> calculatePmcWithProjection({
    required List<DailyAggregate> aggregatesAsc,
    List<PlannedWorkout> plannedWorkouts = const [],
    int projectionDays = 14,
  }) {
    final points = <FitnessFatiguePoint>[];
    for (final a in aggregatesAsc) {
      points.add(FitnessFatiguePoint(
        date: a.localDate,
        ctl: a.ctl,
        atl: a.atl,
        tsb: a.tsb,
        dailyLoad: a.dailyLoad,
        isProjection: false,
      ));
    }

    if (points.isEmpty) return points;

    // 14-Tage-Zukunftsprojektion
    double lastCtl = points.last.ctl;
    double lastAtl = points.last.atl;
    final lastDateStr = points.last.date;
    final lastDate = DateTime.tryParse(lastDateStr) ?? DateTime.now();

    final plannedMap = <String, double>{};
    for (final p in plannedWorkouts) {
      final plannedTss = p.plannedLoad ??
          (p.plannedDurationSec > 0
              ? (p.plannedDurationSec / 3600.0) * 50.0
              : 0.0);
      plannedMap[p.localDate] = (plannedMap[p.localDate] ?? 0.0) + plannedTss;
    }

    for (int day = 1; day <= projectionDays; day++) {
      final nextDate = lastDate.add(Duration(days: day));
      final nextDateStr =
          "${nextDate.year.toString().padLeft(4, '0')}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}";
      final dayTss = plannedMap[nextDateStr] ?? 0.0;

      // Banister EMA: lambda = 1 - exp(-1 / tau)
      final ctlLambda = 1.0 - exp(-1.0 / 42.0);
      final atlLambda = 1.0 - exp(-1.0 / 7.0);

      final nextCtl = lastCtl + (dayTss - lastCtl) * ctlLambda;
      final nextAtl = lastAtl + (dayTss - lastAtl) * atlLambda;
      final nextTsb = lastCtl - lastAtl;

      points.add(FitnessFatiguePoint(
        date: nextDateStr,
        ctl: nextCtl,
        atl: nextAtl,
        tsb: nextTsb,
        dailyLoad: dayTss,
        isProjection: true,
      ));

      lastCtl = nextCtl;
      lastAtl = nextAtl;
    }

    return points;
  }
}
