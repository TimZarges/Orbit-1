import '../models/daily_metrics.dart';
import '../models/health_baseline.dart';

/// Die sportwissenschaftliche Einordnung der Tagesform im Verhältnis zur persönlichen 28-Tage-Basislinie.
enum ReadinessStatus {
  /// Keine Gesundheitsdaten vorhanden.
  noData,

  /// Weniger als 14 Tage Datenpunkte vorhanden: Die Basislinie wird aktuell aufgebaut.
  buildingBaseline,

  /// Unauffällig: Ruhepuls und HRV bewegen sich im gewohnten Normalbereich.
  normal,

  /// Leichte Abweichung: Werte weichen moderat von der Basislinie ab.
  slightDeviation,

  /// Deutliche Abweichung: Merklicher Anstieg des Ruhepulses oder markanter Abfall der HRV.
  noticeableDeviation,
}

/// Ergebnis der Tagesform-Bewertung mit Abweichungen und Status.
class ReadinessEvaluation {
  /// Der ermittelte Status der Tagesform.
  final ReadinessStatus status;

  /// Die zugrunde liegende 28-Tage-Basislinie.
  final HealthBaseline baseline;

  /// Die Messwerte des aktuellen Tages (falls vorhanden).
  final DailyMetrics? todayMetrics;

  /// Absolute Abweichung des Ruhepulses heute vs. Basislinien-Median in bpm (positiv = erhöht).
  final double? restingHrDelta;

  /// Absolute Abweichung der HRV heute vs. Basislinien-Median in ms (negativ = verringert).
  final double? hrvDelta;

  /// Abweichung der Schlafdauer heute vs. Durchschnitt in Stunden.
  final double? sleepDurationDeltaHours;

  const ReadinessEvaluation({
    required this.status,
    required this.baseline,
    this.todayMetrics,
    this.restingHrDelta,
    this.hrvDelta,
    this.sleepDurationDeltaHours,
  });

  /// Berechnet die sportwissenschaftliche Einordnung der Tagesform.
  ///
  /// Schwellenwerte:
  /// - Basislinie benötigt mind. 14 valide Tage.
  /// - Ruhepuls:
  ///   - Delta <= +3 bpm -> Unauffällig
  ///   - +3 bpm < Delta <= +5 bpm -> Leichte Abweichung
  ///   - Delta > +5 bpm -> Deutliche Abweichung
  /// - HRV (rMSSD):
  ///   - Delta >= -(0.75 * stdDev oder -10% vom Median) -> Unauffällig
  ///   - Abfall um 10% bis 25% -> Leichte Abweichung
  ///   - Abfall um mehr als 25% (bzw. > 1.5 * stdDev) -> Deutliche Abweichung
  factory ReadinessEvaluation.evaluate({
    required HealthBaseline baseline,
    DailyMetrics? today,
  }) {
    if (today == null) {
      return ReadinessEvaluation(
        status: ReadinessStatus.noData,
        baseline: baseline,
      );
    }

    if (!baseline.hasSufficientData) {
      return ReadinessEvaluation(
        status: baseline.dataPointsCount == 0 ? ReadinessStatus.noData : ReadinessStatus.buildingBaseline,
        baseline: baseline,
        todayMetrics: today,
      );
    }

    // Delta-Berechnungen
    double? rhrDelta;
    if (today.restingHrBpm != null && baseline.medianRestingHr != null) {
      rhrDelta = today.restingHrBpm!.toDouble() - baseline.medianRestingHr!;
    }

    double? hrvDelta;
    if (today.hrvMs != null && baseline.medianHrv != null) {
      hrvDelta = today.hrvMs!.toDouble() - baseline.medianHrv!;
    }

    double? sleepDeltaHours;
    if (today.sleepSeconds != null && baseline.meanSleepSeconds != null) {
      sleepDeltaHours = (today.sleepSeconds! - baseline.meanSleepSeconds!) / 3600.0;
    }

    // Klassifikation anhand von Ruhepuls und HRV
    var isNoticeable = false;
    var isSlight = false;

    // 1. Ruhepuls-Bewertung (erhöhter Puls = Stress / unvollständige Erholung)
    if (rhrDelta != null) {
      if (rhrDelta >= 6.0) {
        isNoticeable = true;
      } else if (rhrDelta >= 3.5) {
        isSlight = true;
      }
    }

    // 2. HRV-Bewertung (abgefallene HRV = vegetative Belastung)
    if (hrvDelta != null && baseline.medianHrv != null && baseline.medianHrv! > 0) {
      final hrvDropRatio = -hrvDelta / baseline.medianHrv!;
      final hrvStd = baseline.stdHrv ?? (baseline.medianHrv! * 0.15);

      if (hrvDelta < -1.5 * hrvStd || hrvDropRatio >= 0.25) {
        isNoticeable = true;
      } else if (hrvDelta < -0.75 * hrvStd || hrvDropRatio >= 0.12) {
        isSlight = true;
      }
    }

    ReadinessStatus calculatedStatus;
    if (isNoticeable) {
      calculatedStatus = ReadinessStatus.noticeableDeviation;
    } else if (isSlight) {
      calculatedStatus = ReadinessStatus.slightDeviation;
    } else {
      calculatedStatus = ReadinessStatus.normal;
    }

    return ReadinessEvaluation(
      status: calculatedStatus,
      baseline: baseline,
      todayMetrics: today,
      restingHrDelta: rhrDelta,
      hrvDelta: hrvDelta,
      sleepDurationDeltaHours: sleepDeltaHours,
    );
  }
}
