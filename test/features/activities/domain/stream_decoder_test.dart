import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/activities/domain/stream_decoder.dart';

void main() {
  group('StreamDecoder & Synthetic Streams Tests', () {
    test('generiert 2-Stunden-Stream mit validen Multichannel-Daten', () {
      final stream = StreamDecoder.generateSyntheticStream(
        durationSec: 7200,
        sport: 'BIKE',
      );

      expect(stream.lengthSec, equals(7200));
      expect(stream.points.length, equals(7200));
      expect(stream.hasPower, isTrue);
      expect(stream.hasHr, isTrue);
      expect(stream.hasGps, isTrue);
      expect(stream.hasAltitude, isTrue);
      expect(stream.maxPower, greaterThan(200.0));
      expect(stream.maxHr, greaterThan(130.0));
    });

    test('respektiert fehlende Kanäle (z. B. Lauf ohne Powermeter)', () {
      final stream = StreamDecoder.generateSyntheticStream(
        durationSec: 3600,
        sport: 'RUN',
        hasPower: false,
      );

      expect(stream.lengthSec, equals(3600));
      expect(stream.hasPower, isFalse);
      expect(stream.hasHr, isTrue);
      expect(stream.hasGps, isTrue);
    });
  });
}
