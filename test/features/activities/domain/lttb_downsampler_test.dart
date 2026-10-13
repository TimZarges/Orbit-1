import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/activities/models/activity_stream.dart';
import 'package:orbit/features/activities/domain/lttb_downsampler.dart';

void main() {
  group('LttbDownsampler Tests', () {
    test('liefert identische Liste wenn Länge <= threshold', () {
      final input = List.generate(50, (i) {
        return ActivityStreamPoint(timeSec: i, power: 200.0 + i);
      });

      final result = LttbDownsampler.downsample(input, 100);
      expect(result.length, equals(50));
    });

    test('erhält Start- und Endpunkt exakt', () {
      final input = List.generate(1000, (i) {
        return ActivityStreamPoint(timeSec: i, power: 150.0 + (i % 50));
      });

      final result = LttbDownsampler.downsample(input, 100);
      expect(result.length, equals(100));
      expect(result.first.timeSec, equals(0));
      expect(result.last.timeSec, equals(999));
    });

    test('bewahrt signifikante Leistungsspitzen (Peak Preservation)', () {
      final input = List.generate(1000, (i) {
        // Normaler Grundwert 200 W, plötzlicher Sprint auf 850 W bei Sekunde 500
        final p = (i == 500) ? 850.0 : 200.0;
        return ActivityStreamPoint(timeSec: i, power: p);
      });

      final result = LttbDownsampler.downsample(input, 50);
      expect(result.length, equals(50));

      final maxPowerInSample = result.map((p) => p.power ?? 0.0).fold(0.0, (a, b) => a > b ? a : b);
      expect(maxPowerInSample, equals(850.0));
    });

    test('performant bei 36.000 Datenpunkten (10h Aktivität)', () {
      final input = List.generate(36000, (i) {
        return ActivityStreamPoint(timeSec: i, power: 220.0 + (i % 20), hr: 140.0);
      });

      final stopwatch = Stopwatch()..start();
      final result = LttbDownsampler.downsample(input, 400);
      stopwatch.stop();

      expect(result.length, equals(400));
      // Sollte in unter 100ms auf Mobilgeräten laufen
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });
  });
}
