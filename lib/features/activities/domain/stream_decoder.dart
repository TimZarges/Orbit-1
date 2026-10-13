import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/activity_stream.dart';

/// Hilfsklasse zum Dekodieren, Entpacken und Bereitstellen von Telemetrie-Streams.
class StreamDecoder {
  /// Dekodiert ein komprimiertes GZIP- oder rohes JSON-Bytearray in einem Hintergrund-Isolate.
  static Future<ActivityStream> decodeBytes(List<int> bytes) async {
    return compute(_decodeBytesIsolate, bytes);
  }

  /// Erzeugt einen realistischen synthetischen Telemetrie-Stream für Tests, Benchmarks und Demo-Modus.
  ///
  /// [durationSec] Dauer der Aktivität (z. B. 7200 für 2h oder 36000 für 10h)
  /// [sport] 'BIKE', 'RUN' oder 'SWIM'
  static ActivityStream generateSyntheticStream({
    int durationSec = 7200,
    String sport = 'BIKE',
    bool hasPower = true,
    bool hasHr = true,
    bool hasGps = true,
  }) {
    final points = <ActivityStreamPoint>[];
    final random = Random(1337);

    // Start-Koordinaten (Frankfurt / Feldberg)
    double lat = 50.1109;
    double lng = 8.6821;
    double alt = 120.0;
    double cumulativeDist = 0.0;

    double basePower = sport == 'BIKE' ? 220.0 : 0.0;
    double baseHr = 135.0;
    double baseCadence = sport == 'BIKE' ? 88.0 : 172.0;
    double baseSpeed = sport == 'BIKE' ? 8.5 : 3.3; // m/s (ca. 30 km/h Rad, 5:00/km Lauf)

    for (int t = 0; t < durationSec; t++) {
      // Welliges Höhenprofil (Perioden von ca. 15-20 min)
      final hillFactor = sin((t / 900.0) * pi);
      alt = 120.0 + (hillFactor * 250.0).clamp(-50.0, 600.0) + (random.nextDouble() * 2 - 1);

      // Leistung steigt am Berg
      double currentPower = 0.0;
      if (hasPower && sport == 'BIKE') {
        currentPower = (basePower + (hillFactor * 70.0) + (random.nextDouble() * 40 - 20)).clamp(0.0, 850.0);
        // Gelegentliche Antritte / Sprints
        if (t % 600 < 15) {
          currentPower += 250.0;
        }
      }

      // Herzfrequenz folgt der Leistung mit leichter Verzögerung
      double currentHr = 0.0;
      if (hasHr) {
        currentHr = (baseHr + (hillFactor * 25.0) + (random.nextDouble() * 6 - 3)).clamp(85.0, 192.0);
      }

      // Geschwindigkeit (am Berg langsamer, bergab schneller)
      double currentSpeed = (baseSpeed - (hillFactor * 2.5) + (random.nextDouble() * 0.4 - 0.2)).clamp(1.5, 18.0);
      cumulativeDist += currentSpeed;

      // Trittfrequenz
      double currentCadence = (baseCadence + (random.nextDouble() * 6 - 3)).clamp(60.0, 115.0);

      // GPS Drift (Rundkurs)
      if (hasGps) {
        final angle = (t / durationSec) * 2 * pi;
        lat = 50.1109 + sin(angle) * 0.08 + (random.nextDouble() * 0.0001);
        lng = 8.6821 + cos(angle) * 0.12 + (random.nextDouble() * 0.0001);
      }

      points.add(ActivityStreamPoint(
        timeSec: t,
        power: hasPower ? currentPower : null,
        hr: hasHr ? currentHr : null,
        cadence: currentCadence,
        speedMps: currentSpeed,
        altitudeM: alt,
        lat: hasGps ? lat : null,
        lng: hasGps ? lng : null,
        tempC: 18.5 + (sin(t / 3600.0) * 3.0),
        distanceM: cumulativeDist,
      ));
    }

    return ActivityStream(
      version: 1,
      sampleRateSec: 1,
      lengthSec: durationSec,
      points: points,
    );
  }
}

/// Isolate-Funktion zur Dekodierung von JSON / GZIP
ActivityStream _decodeBytesIsolate(List<int> bytes) {
  try {
    List<int> uncompressed = bytes;
    // GZIP Magic Bytes prüfen (0x1F, 0x8B)
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      uncompressed = gzip.decode(bytes);
    }

    final jsonString = utf8.decode(uncompressed);
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return ActivityStream.fromJsonMap(map);
  } catch (e) {
    // Fallback: leerer Stream
    return const ActivityStream(lengthSec: 0, points: []);
  }
}
