import 'dart:math';
import '../models/activity_stream.dart';

/// Berechnet den sekündlichen Füllstand der anaeroben Arbeitskapazität W'bal
/// nach dem Differentialmodell von Skiba et al. (2012, 2015).
class WBalCalculator {
  /// Berechnet W'bal für jeden Punkt der Zeitreihe und gibt aktualisierte [ActivityStreamPoint]s zurück.
  ///
  /// [points]: Rohdatenpunkte mit [power]
  /// [cpWatts]: Critical Power in Watt (z. B. 280 W)
  /// [wPrimeJoules]: W-Prime anaerobe Reserve in Joule (z. B. 20.000 J = 20 kJ)
  static List<ActivityStreamPoint> calculateWBalSeries({
    required List<ActivityStreamPoint> points,
    required double cpWatts,
    required double wPrimeJoules,
  }) {
    if (points.isEmpty || cpWatts <= 0 || wPrimeJoules <= 0) {
      return points;
    }

    final n = points.length;
    final updated = <ActivityStreamPoint>[];

    double currentWBal = wPrimeJoules;

    for (int i = 0; i < n; i++) {
      final p = points[i];
      final power = p.power != null ? max(0.0, p.power!) : 0.0;
      final dt = i == 0
          ? 1.0
          : max(1.0, (p.timeSec - points[i - 1].timeSec).toDouble());

      if (power > cpWatts) {
        // Entleerung bei supramaximaler Last: W'bal(t) = W'bal(t-1) - (P - CP) * dt
        final expenditure = (power - cpWatts) * dt;
        currentWBal -= expenditure;
        if (currentWBal < 0) currentWBal = 0.0;
      } else {
        // Dynamische exponentielle Erholung:
        // tau = 546 * exp(-0.01 * (CP - P_under)) + 316
        final dUnder = cpWatts - power;
        final tau = 546.0 * exp(-0.01 * dUnder) + 316.0;
        final recovery = (wPrimeJoules - currentWBal) * (1.0 - exp(-dt / tau));
        currentWBal += recovery;
        if (currentWBal > wPrimeJoules) currentWBal = wPrimeJoules;
      }

      final wBalPercent = (currentWBal / wPrimeJoules) * 100.0;

      updated.add(ActivityStreamPoint(
        timeSec: p.timeSec,
        hr: p.hr,
        power: p.power,
        cadence: p.cadence,
        speedMps: p.speedMps,
        altitudeM: p.altitudeM,
        lat: p.lat,
        lng: p.lng,
        tempC: p.tempC,
        coreTempC: p.coreTempC,
        distanceM: p.distanceM,
        wBalJoules: currentWBal,
        wBalPercent: wBalPercent,
      ));
    }

    return updated;
  }
}
