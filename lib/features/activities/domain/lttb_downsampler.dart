import 'dart:math';
import '../models/activity_stream.dart';

/// Implementierung des Largest-Triangle-Three-Buckets (LTTB) Algorithmus.
///
/// Reduziert hochauflösende Zeitreihen (z. B. 36.000 Punkte bei 10h-Aktivitäten)
/// unter Erhalt markanter Extrema (Leistungsspitzen, Bergkuppen, Antritte)
/// auf eine zielgenaue Anzahl an Anzeigepunkten (z. B. 300 bis 500).
class LttbDownsampler {
  /// Reduziert eine Liste von [ActivityStreamPoint] auf maximal [threshold] Punkte.
  static List<ActivityStreamPoint> downsample(
    List<ActivityStreamPoint> data,
    int threshold,
  ) {
    if (data.length <= threshold || threshold <= 2) {
      return data;
    }

    final sampled = <ActivityStreamPoint>[];

    // Bucket-Größe für die mittleren Punkte
    final every = (data.length - 2) / (threshold - 2);

    int a = 0; // Zuletzt ausgewählter Punkt
    sampled.add(data[a]);

    for (int i = 0; i < threshold - 2; i++) {
      // 1. Berechne den Mittelwert des nächsten Buckets (Bucket C)
      final avgRangeStart = ((i + 1) * every).floor() + 1;
      final avgRangeEnd = min(((i + 2) * every).floor() + 1, data.length);

      double avgX = 0.0;
      double avgY = 0.0;
      final avgCount = avgRangeEnd - avgRangeStart;

      if (avgCount > 0) {
        for (int j = avgRangeStart; j < avgRangeEnd; j++) {
          avgX += data[j].timeSec;
          avgY += _getRepresentativeValue(data[j]);
        }
        avgX /= avgCount;
        avgY /= avgCount;
      } else {
        avgX = data[min(avgRangeStart, data.length - 1)].timeSec.toDouble();
        avgY =
            _getRepresentativeValue(data[min(avgRangeStart, data.length - 1)]);
      }

      // 2. Finde den Punkt im aktuellen Bucket (Bucket B), der mit A und dem Durchschnitt von C das größte Dreieck aufspannt
      final rangeStart = (i * every).floor() + 1;
      final rangeEnd = min(((i + 1) * every).floor() + 1, data.length);

      final pointAX = data[a].timeSec.toDouble();
      final pointAY = _getRepresentativeValue(data[a]);

      double maxArea = -1.0;
      int maxAreaIndex = rangeStart;

      for (int j = rangeStart; j < rangeEnd; j++) {
        final pointX = data[j].timeSec.toDouble();
        final pointY = _getRepresentativeValue(data[j]);

        // Dreiecksfläche = 0.5 * |x_A*(y_B - y_C) + x_B*(y_C - y_A) + x_C*(y_A - y_B)|
        final area = ((pointAX - avgX) * (pointY - pointAY) -
                    (pointAX - pointX) * (avgY - pointAY))
                .abs() *
            0.5;

        if (area > maxArea) {
          maxArea = area;
          maxAreaIndex = j;
        }
      }

      sampled.add(data[maxAreaIndex]);
      a = maxAreaIndex; // Nächster Referenzpunkt
    }

    // Letzten Punkt exakt übernehmen
    sampled.add(data.last);

    return sampled;
  }

  /// Ermittelt einen repräsentativen Vergleichswert (Leistung vorrangig vor HF oder Speed).
  static double _getRepresentativeValue(ActivityStreamPoint p) {
    if (p.power != null) return p.power!;
    if (p.hr != null) return p.hr!;
    if (p.speedMps != null) return p.speedMps!;
    if (p.altitudeM != null) return p.altitudeM!;
    return 0.0;
  }
}
