import 'dart:math' as math;
import 'daily_metrics.dart';

/// Statistische Auswertung der persönlichen Basislinie über einen Beobachtungszeitraum (standardmäßig 28 Tage).
class HealthBaseline {
  /// Anzahl der Tage mit verfügbaren Gesundheitsdaten im Auswertefenster.
  final int dataPointsCount;

  /// Gibt an, ob genügend Datenpunkte für eine verlässliche Basislinie vorliegen (Mindestanforderung: 14 Tage).
  final bool hasSufficientData;

  /// Robuster Median des Ruhepulses in bpm.
  final double? medianRestingHr;

  /// Standardabweichung des Ruhepulses.
  final double? stdRestingHr;

  /// Robuster Median der HRV (rMSSD) in ms.
  final double? medianHrv;

  /// Standardabweichung der HRV.
  final double? stdHrv;

  /// Durchschnittliche Schlafdauer in Sekunden über den Zeitraum.
  final double? meanSleepSeconds;

  /// Durchschnittlicher Schlaf-Score.
  final double? meanSleepScore;

  const HealthBaseline({
    required this.dataPointsCount,
    required this.hasSufficientData,
    this.medianRestingHr,
    this.stdRestingHr,
    this.medianHrv,
    this.stdHrv,
    this.meanSleepSeconds,
    this.meanSleepScore,
  });

  /// Durchschnittliche Schlafdauer in Stunden.
  double? get meanSleepHours =>
      meanSleepSeconds != null ? meanSleepSeconds! / 3600.0 : null;

  /// Erzeugt eine leere Basislinie (keine Daten vorhanden).
  factory HealthBaseline.empty() {
    return const HealthBaseline(
      dataPointsCount: 0,
      hasSufficientData: false,
    );
  }

  /// Berechnet die robuste Basislinie aus einer Liste von [DailyMetrics] (typischerweise der letzten 28 Tage).
  ///
  /// Mindestdatenlage: Mindestens 14 Tage müssen valide Werte aufweisen.
  factory HealthBaseline.fromMetrics(List<DailyMetrics> history) {
    if (history.isEmpty) {
      return HealthBaseline.empty();
    }

    final restingHrList = history
        .map((m) => m.restingHrBpm)
        .whereType<int>()
        .map((e) => e.toDouble())
        .toList();

    final hrvList = history
        .map((m) => m.hrvMs)
        .whereType<int>()
        .map((e) => e.toDouble())
        .toList();

    final sleepSecList = history
        .map((m) => m.sleepSeconds)
        .whereType<int>()
        .map((e) => e.toDouble())
        .toList();

    final sleepScoreList = history
        .map((m) => m.sleepScore)
        .whereType<int>()
        .map((e) => e.toDouble())
        .toList();

    // Anzahl der Tage mit mindestens einem relevanten Vitalwert
    final validDaysCount =
        history.where((m) => m.restingHrBpm != null || m.hrvMs != null).length;
    final sufficient = validDaysCount >= 14;

    return HealthBaseline(
      dataPointsCount: validDaysCount,
      hasSufficientData: sufficient,
      medianRestingHr: _calculateMedian(restingHrList),
      stdRestingHr: _calculateStdDev(restingHrList),
      medianHrv: _calculateMedian(hrvList),
      stdHrv: _calculateStdDev(hrvList),
      meanSleepSeconds: _calculateMean(sleepSecList),
      meanSleepScore: _calculateMean(sleepScoreList),
    );
  }

  /// Berechnet den Median einer Zahlenliste (robuster Mittelwert).
  static double? _calculateMedian(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  /// Berechnet den arithmetischen Mittelwert.
  static double? _calculateMean(List<double> values) {
    if (values.isEmpty) return null;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  /// Berechnet die Stichproben-Standardabweichung.
  static double? _calculateStdDev(List<double> values) {
    if (values.length < 2) return null;
    final mean = _calculateMean(values)!;
    final sumSquaredDiff =
        values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b);
    return math.sqrt(sumSquaredDiff / (values.length - 1));
  }
}
