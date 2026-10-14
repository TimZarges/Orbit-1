import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/workout_builder/domain/workout_calculator.dart';
import 'package:orbit/features/workout_builder/domain/workout_parser.dart';

void main() {
  group('WorkoutCalculator', () {
    test('Berechnet Gesamtdauer und Belastung für Standard-Radintervalle', () {
      const parser = WorkoutParser(sport: 'BIKE');
      final result = parser.parse("10' Z1, 4x(4' Z4 / 2' Z1), 10' Z1");
      expect(result.isSuccess, isTrue);

      final calc = WorkoutCalculator.calculate(result.structure!);

      // Gesamtdauer: 10' + 4 * (4' + 2') + 10' = 10 + 24 + 10 = 44 min = 2640 s
      expect(calc.totalDurationSec, 2640);
      expect(calc.formattedDuration, '44 min');

      // Zonenverteilung:
      // Z1: 10' (WU) + 4 * 2' (Rest) + 10' (CD) = 28 min = 1680 s
      // Z4: 4 * 4' = 16 min = 960 s
      expect(calc.timeInZonesSec[1], 1680);
      expect(calc.timeInZonesSec[4], 960);

      // Belastung: Positiver TSS Wert
      expect(calc.estimatedLoad, isNotNull);
      expect(calc.estimatedLoad!, greaterThan(20.0));
      expect(calc.estimatedLoad!, lessThan(60.0));
    });

    test('Rechnet Schwimm-Distanz mit hinterlegter CSS in Dauer um', () {
      const parser = WorkoutParser(sport: 'SWIM');
      final result = parser.parse('400m Z1, 8x(100m CSS / 20"), 200m Z1');
      expect(result.isSuccess, isTrue);

      const thresholds = AthleteThresholds(cssSecPer100m: 105); // 1:45/100m
      final calc = WorkoutCalculator.calculate(result.structure!,
          thresholds: thresholds);

      // Gesamtdistanz: 400 + (8 * 100) + 200 = 1400 m
      expect(calc.totalDistanceM, 1400);
      expect(calc.formattedDistance, '1.4 km');

      // Dauer: CSS 1:45/100m für 8x100m = 8 * 105s = 840s + 8 * 20s Pause = 160s.
      expect(calc.assumptions, isNotEmpty);
      expect(calc.assumptions.first, contains('CSS'));
      expect(calc.missingThresholdWarnings, isEmpty);
    });

    test('Warnt wenn keine CSS hinterlegt ist für Schwimm-Distanzziel', () {
      const parser = WorkoutParser(sport: 'SWIM');
      final result = parser.parse('8x100m CSS / 20"');
      expect(result.isSuccess, isTrue);

      final calc = WorkoutCalculator.calculate(result.structure!,
          thresholds: AthleteThresholds.empty);
      expect(calc.missingThresholdWarnings, isNotEmpty);
      expect(calc.missingThresholdWarnings.first,
          contains('Keine CSS hinterlegt'));
    });
  });
}
