import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/analysis/models/form_traffic_light.dart';
import 'package:orbit/features/analysis/domain/form_calculator.dart';

void main() {
  group('FormCalculator - Grenz- und Mindestdatenfälle', () {
    const calculator = FormCalculator();

    test('liefert insufficientData wenn weniger als 21 Tage vorliegen', () {
      final result = calculator.calculate(
        ctl: 50.0,
        atl: 45.0,
        daysOfHistory: 20,
      );

      expect(result.status, equals(FormStatus.insufficientData));
      expect(result.dataBasisTextDe, contains('20 von 21 Tagen erfasst'));
      expect(result.titleDe, equals('Noch zu wenig Daten'));
      expect(result.titleEn, equals('Insufficient data'));
    });

    test('liefert lowBaseline wenn CTL unter Mindestschwelle 10 liegt', () {
      final result = calculator.calculate(
        ctl: 8.0,
        atl: 6.0,
        daysOfHistory: 28,
      );

      expect(result.status, equals(FormStatus.lowBaseline));
      expect(result.titleDe, equals('Geringe Grundbelastung'));
      expect(result.titleEn, equals('Low baseline load'));
      expect(result.dataBasisTextDe, contains('4 Wochen Training'));
    });

    test('berechnet veryTired wenn TSB/CTL unter -0.30 liegt', () {
      // CTL = 50, ATL = 70 => TSB = -20 => Ratio = -20 / 50 = -0.40 (< -0.30)
      final result = calculator.calculate(
        ctl: 50.0,
        atl: 70.0,
        daysOfHistory: 42,
      );

      expect(result.status, equals(FormStatus.veryTired));
      expect(result.titleDe, equals('Sehr müde'));
      expect(result.titleEn, equals('High fatigue'));
      expect(result.ratio, closeTo(-0.40, 0.001));
    });

    test('berechnet wellLoaded wenn TSB/CTL zwischen -0.30 und -0.10 liegt', () {
      // CTL = 50, ATL = 60 => TSB = -10 => Ratio = -10 / 50 = -0.20
      final result = calculator.calculate(
        ctl: 50.0,
        atl: 60.0,
        daysOfHistory: 42,
      );

      expect(result.status, equals(FormStatus.wellLoaded));
      expect(result.titleDe, equals('Gut belastet'));
      expect(result.titleEn, equals('Productive'));
      expect(result.ratio, closeTo(-0.20, 0.001));
    });

    test('berechnet balanced wenn TSB/CTL zwischen -0.10 und +0.15 liegt', () {
      // CTL = 50, ATL = 50 => TSB = 0 => Ratio = 0.0
      final result = calculator.calculate(
        ctl: 50.0,
        atl: 50.0,
        daysOfHistory: 42,
      );

      expect(result.status, equals(FormStatus.balanced));
      expect(result.titleDe, equals('Ausgeglichen'));
      expect(result.titleEn, equals('Balanced'));
      expect(result.ratio, closeTo(0.0, 0.001));
    });

    test('berechnet fresh wenn TSB/CTL ueber +0.15 liegt', () {
      // CTL = 50, ATL = 40 => TSB = 10 => Ratio = 10 / 50 = 0.20 (> 0.15)
      final result = calculator.calculate(
        ctl: 50.0,
        atl: 40.0,
        daysOfHistory: 42,
      );

      expect(result.status, equals(FormStatus.fresh));
      expect(result.titleDe, equals('Frisch'));
      expect(result.titleEn, equals('Fresh'));
      expect(result.ratio, closeTo(0.20, 0.001));
    });

    test('Grenzwert-Genauigkeit an den Schwellen', () {
      // Exakt -0.30 -> wellLoaded (da < -0.30 veryTired ist)
      final edgeTired = calculator.calculate(
        ctl: 100.0,
        atl: 130.0,
        daysOfHistory: 30,
      );
      expect(edgeTired.status, equals(FormStatus.wellLoaded));

      // Exakt -0.10 -> balanced (da < -0.10 wellLoaded ist)
      final edgeLoaded = calculator.calculate(
        ctl: 100.0,
        atl: 110.0,
        daysOfHistory: 30,
      );
      expect(edgeLoaded.status, equals(FormStatus.balanced));

      // Exakt 0.15 -> balanced (da <= 0.15 balanced ist)
      final edgeBalanced = calculator.calculate(
        ctl: 100.0,
        atl: 85.0,
        daysOfHistory: 30,
      );
      expect(edgeBalanced.status, equals(FormStatus.balanced));

      // 0.1501 -> fresh
      final edgeFresh = calculator.calculate(
        ctl: 100.0,
        atl: 84.9,
        daysOfHistory: 30,
      );
      expect(edgeFresh.status, equals(FormStatus.fresh));
    });
  });
}
