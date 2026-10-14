import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/activities/models/activity_stream.dart';
import 'package:orbit/features/activities/models/activity_bests.dart';
import 'package:orbit/features/activities/domain/mmp_calculator.dart';

void main() {
  group('MmpCalculator Tests', () {
    test('berechnet konstante Wattleistung korrekt über alle Dauern', () {
      final powerList = List<double>.filled(120, 250.0);
      final mmp =
          MmpCalculator.calculateMmp(powerList, durations: [1, 5, 15, 30, 60]);

      expect(mmp[1], equals(250.0));
      expect(mmp[5], equals(250.0));
      expect(mmp[15], equals(250.0));
      expect(mmp[30], equals(250.0));
      expect(mmp[60], equals(250.0));
    });

    test('erkennt maximale Sprintspitze über 5 Sekunden', () {
      // 100 Sekunden mit 200 W, aber 5 Sekunden mit 600 W (von Sekunde 40 bis 44)
      final powerList = List<double>.generate(
          100, (i) => (i >= 40 && i < 45) ? 600.0 : 200.0);
      final mmp = MmpCalculator.calculateMmp(powerList, durations: [1, 5, 10]);

      expect(mmp[1], equals(600.0));
      expect(mmp[5], equals(600.0));
      // 10s Fenster: 5s * 600 + 5s * 200 = 3000 + 1000 = 4000 / 10 = 400 W
      expect(mmp[10], equals(400.0));
    });

    test('erkennt neue persönliche Rekorde (PRs) im Vergleich zu Bestwerten',
        () {
      final streamPoints = List.generate(
          60, (i) => ActivityStreamPoint(timeSec: i, power: 450.0));
      final stream = ActivityStream(lengthSec: 60, points: streamPoints);

      const bests = ActivityBests(
        sport: 'BIKE',
        allTimeMmp: {5: 400.0, 30: 380.0},
        seasonMmp: {5: 390.0, 30: 370.0},
      );

      final curve = MmpCalculator.buildCurve(
        stream: stream,
        bests: bests,
        durations: [5, 30],
      );

      expect(curve.hasPR, isTrue);
      expect(curve.prCount, equals(2));
      expect(curve.points.first.isAllTimePR, isTrue);
    });
  });
}
