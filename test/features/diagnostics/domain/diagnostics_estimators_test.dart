import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/diagnostics/domain/ftp_estimator.dart';
import 'package:orbit/features/diagnostics/domain/lthr_estimator.dart';
import 'package:orbit/features/diagnostics/domain/css_estimator.dart';
import 'package:orbit/features/diagnostics/models/threshold_proposal.dart';

void main() {
  group('FtpEstimator', () {
    const estimator = FtpEstimator();
    final testDate = DateTime(2026, 10, 13);

    test('erzeugt validen FTP-Vorschlag bei sauberem Pacing', () {
      final result = estimator.estimateFrom20MinMmp(
        twentyMinMmp: 300.0,
        normalizedPower: 306.0, // VI = 1.02 -> HIGH
        currentFtp: 270.0,
        athleteId: 'ath1',
        activityDate: testDate,
      );

      expect(result.hasProposal, isTrue);
      final p = result.proposal!;
      expect(p.proposedValue, 285.0); // 300 * 0.95 = 285
      expect(p.delta, 15.0);
      expect(p.confidence, ConfidenceLevel.high);
      expect(p.type, ThresholdType.ftp);
      expect(p.sport, 'BIKE');
    });

    test('erzeugt mittleren Konfidenz-Vorschlag bei leichtem Pacing-Drift', () {
      final result = estimator.estimateFrom20MinMmp(
        twentyMinMmp: 300.0,
        normalizedPower: 324.0, // VI = 1.08 -> MEDIUM
        currentFtp: 270.0,
        athleteId: 'ath1',
        activityDate: testDate,
      );

      expect(result.hasProposal, isTrue);
      expect(result.proposal!.confidence, ConfidenceLevel.medium);
    });

    test('verwirft Vorschlag bei ungleichmäßigem Pacing (VI > 1.15)', () {
      final result = estimator.estimateFrom20MinMmp(
        twentyMinMmp: 300.0,
        normalizedPower: 360.0, // VI = 1.20
        currentFtp: 270.0,
        athleteId: 'ath1',
        activityDate: testDate,
      );

      expect(result.hasProposal, isFalse);
      expect(result.reasonForNoProposal, contains('Variabilitätsindex > 1.15'));
    });

    test('verwirft Vorschlag bei irrelevanter Minimaldifferenz (< 3 W und < 1.5 %)', () {
      final result = estimator.estimateFrom20MinMmp(
        twentyMinMmp: 285.0, // 285 * 0.95 = 270.75 -> round 271 W
        normalizedPower: 290.0,
        currentFtp: 270.0, // Delta = +1 W (< 3 W und < 1.5 %)
        athleteId: 'ath1',
        activityDate: testDate,
      );

      expect(result.hasProposal, isFalse);
      expect(result.reasonForNoProposal, contains('Relevanzschwelle'));
    });

    test('verwirft unplausible physiologische Leistungswerte', () {
      final low = estimator.estimateFrom20MinMmp(
        twentyMinMmp: 35.0,
        normalizedPower: 35.0,
        athleteId: 'ath1',
        activityDate: testDate,
      );
      expect(low.hasProposal, isFalse);

      final high = estimator.estimateFrom20MinMmp(
        twentyMinMmp: 650.0,
        normalizedPower: 650.0,
        athleteId: 'ath1',
        activityDate: testDate,
      );
      expect(high.hasProposal, isFalse);
    });
  });

  group('LthrEstimator', () {
    const estimator = LthrEstimator();
    final testDate = DateTime(2026, 10, 13);

    test('erzeugt LTHR- und Pace-Vorschläge bei konstantem 30-Minuten-Test', () {
      final result = estimator.estimateFrom30MinRun(
        last20MinAvgHr: 174.0,
        thirtyMinAvgPaceSec: 270.0, // 4:30 min/km
        hrStdDev: 2.5,
        currentLthr: 168.0,
        currentPaceSec: 285.0,
        athleteId: 'ath1',
        activityDate: testDate,
      );

      expect(result.hasLthrProposal, isTrue);
      expect(result.lthrProposal!.proposedValue, 174.0);
      expect(result.lthrProposal!.delta, 6.0);
      expect(result.lthrProposal!.confidence, ConfidenceLevel.high);

      expect(result.hasPaceProposal, isTrue);
      expect(result.paceProposal!.proposedValue, 270.0);
      expect(result.paceProposal!.delta, -15.0); // schneller
    });

    test('verwirft Vorschläge bei instabilem Herzfrequenzplateau (StdDev > 8 bpm)', () {
      final result = estimator.estimateFrom30MinRun(
        last20MinAvgHr: 174.0,
        thirtyMinAvgPaceSec: 270.0,
        hrStdDev: 9.2,
        currentLthr: 168.0,
        athleteId: 'ath1',
        activityDate: testDate,
      );

      expect(result.hasLthrProposal, isFalse);
      expect(result.hasPaceProposal, isFalse);
      expect(result.reasonForNoProposal, contains('kein stabiles Plateau'));
    });
  });

  group('CssEstimator', () {
    const estimator = CssEstimator();
    final testDate = DateTime(2026, 10, 13);

    test('berechnet CSS exakt aus 400m- und 200m-Zeiten', () {
      // 400m in 6:00 (360s), 200m in 2:40 (160s)
      // CSS pace = (360 - 160) / 2 = 100 s / 100m (1:40 min/100m)
      final result = estimator.estimateFrom400mAnd200m(
        t400Seconds: 360.0,
        t200Seconds: 160.0,
        currentCssPaceSec: 105.0, // Bisher 1:45
        athleteId: 'ath1',
        testDate: testDate,
      );

      expect(result.hasProposal, isTrue);
      final p = result.proposal!;
      expect(p.proposedValue, 100.0);
      expect(p.delta, -5.0); // 5 Sekunden schneller
      expect(p.confidence, ConfidenceLevel.high);
      expect(p.type, ThresholdType.css);
      expect(p.sport, 'SWIM');
    });

    test('verwirft ungültigen Test wenn 400m schneller als 200m geschwommen wurde', () {
      final result = estimator.estimateFrom400mAnd200m(
        t400Seconds: 200.0,
        t200Seconds: 220.0,
        athleteId: 'ath1',
        testDate: testDate,
      );

      expect(result.hasProposal, isFalse);
    });

    test('verwirft Minimaländerung (< 1.0 s/100m)', () {
      final result = estimator.estimateFrom400mAnd200m(
        t400Seconds: 360.0,
        t200Seconds: 160.0,
        currentCssPaceSec: 100.4, // Delta = 0.4s < 1.0s
        athleteId: 'ath1',
        testDate: testDate,
      );

      expect(result.hasProposal, isFalse);
      expect(result.reasonForNoProposal, contains('Relevanzschwelle'));
    });
  });
}
