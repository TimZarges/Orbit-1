import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/analysis/models/daily_aggregate.dart';
import 'package:orbit/features/analysis/domain/aggregates_calculator.dart';
import 'package:orbit/features/calendar/models/planned_workout.dart';

void main() {
  group('AggregatesCalculator Tests', () {
    test('calculateWeeklyLoad mit und ohne Plan', () {
      final aggregates = [
        const DailyAggregate(
          localDate: '2026-10-10',
          dailyLoad: 60.0,
          ctl: 40,
          atl: 40,
          tsb: 0,
        ),
        const DailyAggregate(
          localDate: '2026-10-11',
          dailyLoad: 80.0,
          ctl: 41,
          atl: 45,
          tsb: -4,
        ),
      ];

      final planned = [
        PlannedWorkout(
          id: 'p1',
          athleteId: 'a1',
          createdBy: 'a1',
          localDate: '2026-10-10',
          sport: 'RUN',
          title: 'Lauf',
          plannedDurationSec: 3600,
          plannedLoad: 70.0,
        ),
        PlannedWorkout(
          id: 'p2',
          athleteId: 'a1',
          createdBy: 'a1',
          localDate: '2026-10-11',
          sport: 'BIKE',
          title: 'Rad',
          plannedDurationSec: 3600,
          plannedLoad: 70.0,
        ),
      ];

      final summary = AggregatesCalculator.calculateWeeklyLoad(
        aggregates: aggregates,
        plannedWorkouts: planned,
      );

      expect(summary.actualLoad, equals(140.0));
      expect(summary.plannedLoad, equals(140.0));
      expect(summary.hasPlan, isTrue);
      expect(summary.completionPercent, equals(100));
      expect(summary.statusTextDe, contains('Im Plan (100 %)'));
    });

    test('calculateConsistency zählt aktive Tage und Streaks', () {
      final aggregates = List.generate(14, (i) {
        return DailyAggregate(
          localDate: '2026-10-${(i + 1).toString().padLeft(2, '0')}',
          dailyLoad: (i % 2 == 0) ? 50.0 : 0.0,
          ctl: 30,
          atl: 30,
          tsb: 0,
          activityCount: (i % 2 == 0) ? 1 : 0,
        );
      });

      final consistency = AggregatesCalculator.calculateConsistency(
        aggregates: aggregates,
        plannedWorkouts: const [],
        totalDays: 14,
      );

      expect(consistency.activeDays, equals(7));
      expect(consistency.totalDays, equals(14));
      expect(consistency.streakWeeks, equals(2));
    });

    test('calculateSportDistribution summiert Sportarten korrekt', () {
      final aggregates = [
        const DailyAggregate(
          localDate: '2026-10-01',
          dailyLoad: 50,
          ctl: 20,
          atl: 20,
          tsb: 0,
          sportsBreakdownSec: {'BIKE': 3600, 'RUN': 1800},
        ),
        const DailyAggregate(
          localDate: '2026-10-02',
          dailyLoad: 50,
          ctl: 20,
          atl: 20,
          tsb: 0,
          sportsBreakdownSec: {'SWIM': 1800, 'BIKE': 1800},
        ),
      ];

      final dist = AggregatesCalculator.calculateSportDistribution(aggregates);
      expect(dist.totalDurationSec, equals(9000));
      expect(dist.items.length, equals(3));
      expect(dist.items.first.sport, equals('BIKE'));
      expect(dist.items.first.durationSec, equals(5400));
      expect(dist.items.first.percent, equals(60.0));
    });

    test('calculate8WeekTrend und describeWeeklyTrend', () {
      final points = [
        const WeeklyLoadTrendPoint(weekNumber: 1, weekLabel: 'W1', totalLoad: 200),
        const WeeklyLoadTrendPoint(weekNumber: 2, weekLabel: 'W2', totalLoad: 250),
        const WeeklyLoadTrendPoint(weekNumber: 3, weekLabel: 'W3', totalLoad: 280),
      ];

      final desc = AggregatesCalculator.describeWeeklyTrend(points);
      expect(desc, contains('gestiegen'));
    });
  });
}
