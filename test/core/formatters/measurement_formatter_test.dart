import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/formatters/measurement_formatter.dart';
import 'package:orbit/features/settings/models/app_settings.dart';

void main() {
  group('MeasurementFormatter Metric', () {
    const formatter = MeasurementFormatter(MeasurementSystem.metric);

    test('Distance', () {
      expect(formatter.formatDistance(1500), '1.5 km');
    });

    test('Pace (Laufen)', () {
      // 5 min/km = 1000m / 300s = 3.333 m/s
      expect(formatter.formatPace(3.3333333), '5:00 min/km');
    });

    test('Pace (Schwimmen)', () {
      // 1:30 min/100m = 100m / 90s = 1.111 m/s
      expect(formatter.formatSwimPace(1.1111111), '1:30 /100m');
    });

    test('Weight & Elevation', () {
      expect(formatter.formatWeight(75), '75.0 kg');
      expect(formatter.formatElevation(100), '100 m');
    });
  });

  group('MeasurementFormatter Imperial', () {
    const formatter = MeasurementFormatter(MeasurementSystem.imperial);

    test('Distance', () {
      expect(formatter.formatDistance(1609.34), '1.0 mi');
    });

    test('Weight', () {
      // 1 kg = 2.20462 lbs
      expect(formatter.formatWeight(10), '22.0 lbs');
    });
  });
}
