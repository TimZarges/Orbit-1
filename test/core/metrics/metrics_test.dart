import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/metrics/estimations.dart';
import 'package:orbit/core/metrics/training_zones_model.dart';

void main() {
  group('Estimations', () {
    test('Max HR estimation (Tanaka)', () {
      expect(Estimations.estimateMaxHr(30), 187); // 208 - 21
      expect(Estimations.estimateMaxHr(40), 180); // 208 - 28
    });

    test('FTP estimation from 20min', () {
      expect(Estimations.estimateFtpFrom20MinTest(300), 285);
      expect(Estimations.estimateFtpFrom20MinTest(200), 190);
    });

    test('CSS estimation from 400m and 200m', () {
      // 400m in 6 min (360s), 200m in 2.5 min (150s)
      // Diff = 210s. 200m / 210s = 0.952 m/s
      final css = Estimations.estimateCssFrom400And200Test(360, 150);
      expect(css, closeTo(0.952, 0.001));
    });
  });

  group('Training Zones', () {
    test('Power Zones have 7 zones', () {
      expect(powerZones.length, 7);
      expect(powerZones[0].shortName, 'Z1');
      expect(powerZones[6].shortName, 'Z7');
    });

    test('Zone bounds are correct (contains)', () {
      final z2 = powerZones.firstWhere((z) => z.shortName == 'Z2');
      expect(z2.contains(0.54), isFalse);
      expect(z2.contains(0.55), isTrue);
      expect(z2.contains(0.70), isTrue);
      expect(z2.contains(0.75), isFalse); // Max is exclusive
    });
  });
}
