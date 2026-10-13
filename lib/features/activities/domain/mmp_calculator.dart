import 'dart:math';
import '../models/activity_stream.dart';
import '../models/power_duration_curve.dart';
import '../models/activity_bests.dart';

/// Berechnet die Mean-Maximal-Power (MMP) Kurve aus Watt-Zeitreihen.
class MmpCalculator {
  /// Standard-Dauern in Sekunden: 1s, 5s, 15s, 30s, 1m, 2m, 5m, 10m, 20m, 30m, 60m.
  static const List<int> defaultDurationsSec = [
    1, 5, 15, 30, 60, 120, 300, 600, 1200, 1800, 3600,
  ];

  /// Berechnet die besten Durchschnittsleistungen über die definierten Intervalle.
  static Map<int, double> calculateMmp(
    List<double> powerWatts, {
    List<int> durations = defaultDurationsSec,
  }) {
    final result = <int, double>{};
    final n = powerWatts.length;
    if (n == 0) return result;

    for (final duration in durations) {
      if (duration > n) break;

      // Sliding Window mit gleitender Summe: O(N)
      double currentSum = 0.0;
      for (int i = 0; i < duration; i++) {
        currentSum += powerWatts[i];
      }

      double maxAvg = currentSum / duration;

      for (int i = duration; i < n; i++) {
        currentSum += powerWatts[i] - powerWatts[i - duration];
        final avg = currentSum / duration;
        if (avg > maxAvg) {
          maxAvg = avg;
        }
      }

      result[duration] = maxAvg;
    }

    return result;
  }

  /// Erzeugt ein vollständiges [PowerDurationCurve] Modell inklusive Vergleich zu Bestwerten.
  static PowerDurationCurve buildCurve({
    required ActivityStream stream,
    ActivityBests? bests,
    List<int> durations = defaultDurationsSec,
  }) {
    final powerList = stream.points.map((p) => p.power ?? 0.0).toList();
    final mmpMap = calculateMmp(powerList, durations: durations);

    final points = <PowerDurationPoint>[];
    for (final duration in durations) {
      final actWatts = mmpMap[duration] ?? 0.0;
      if (actWatts <= 0 && duration > stream.lengthSec) continue;

      final seasonWatts = bests?.seasonMmp[duration];
      final allTimeWatts = bests?.allTimeMmp[duration];

      points.add(PowerDurationPoint(
        durationSec: duration,
        activityWatts: actWatts,
        seasonBestWatts: seasonWatts,
        allTimeBestWatts: allTimeWatts,
      ));
    }

    return PowerDurationCurve(points: points);
  }
}
