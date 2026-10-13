import 'package:cloud_firestore/cloud_firestore.dart';

/// Repräsentiert die aggregierten Gesundheits- und Wellnessdaten eines Tages (Tageswerte).
/// Gespeichert unter `users/{uid}/dailyMetrics/{localDate}`.
class DailyMetrics {
  /// Datum im Format YYYY-MM-DD am Ort des Athleten.
  final String localDate;

  /// Netto-Schlafdauer in Sekunden.
  final int? sleepSeconds;

  /// Schlaf-Score (0 bis 100), sofern von der Uhr / Garmin bereitgestellt.
  final int? sleepScore;

  /// Nächtlicher bzw. Ruhe-Puls in Schlägen pro Minute.
  final int? restingHrBpm;

  /// Herzfrequenzvariabilität (HRV rMSSD) der letzten Nacht in Millisekunden.
  final int? hrvMs;

  /// Durchschnittliches Stress-Level des Tages (0 bis 100).
  final int? stress;

  /// Schrittanzahl des Tages.
  final int? steps;

  /// Garmin Body Battery Wert zum Tagesende / Ladezustand (0 bis 100).
  final int? bodyBattery;

  /// Quelle der Daten, z. B. 'GARMIN' oder 'DEMO'.
  final String source;

  /// Letzter Aktualisierungszeitpunkt.
  final DateTime? updatedAt;

  const DailyMetrics({
    required this.localDate,
    this.sleepSeconds,
    this.sleepScore,
    this.restingHrBpm,
    this.hrvMs,
    this.stress,
    this.steps,
    this.bodyBattery,
    this.source = 'GARMIN',
    this.updatedAt,
  });

  /// Schlafdauer in Stunden als Dezimalwert.
  double? get sleepHours => sleepSeconds != null ? sleepSeconds! / 3600.0 : null;

  /// Formatierte Schlafdauer (z. B. "7h 45m").
  String get formattedSleepDuration {
    if (sleepSeconds == null) return '--';
    final hours = sleepSeconds! ~/ 3600;
    final minutes = (sleepSeconds! % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  /// Erstellt ein [DailyMetrics]-Objekt aus einem Firestore-Dokument.
  factory DailyMetrics.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DailyMetrics.fromMap(doc.id, data);
  }

  /// Erstellt ein [DailyMetrics]-Objekt aus einer Map mit gegebener [dateId].
  factory DailyMetrics.fromMap(String dateId, Map<String, dynamic> map) {
    DateTime? updated;
    final rawUpdated = map['updatedAt'];
    if (rawUpdated is Timestamp) {
      updated = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      updated = DateTime.tryParse(rawUpdated);
    }

    return DailyMetrics(
      localDate: dateId,
      sleepSeconds: (map['sleepSeconds'] as num?)?.toInt(),
      sleepScore: (map['sleepScore'] as num?)?.toInt(),
      restingHrBpm: (map['restingHrBpm'] as num?)?.toInt(),
      hrvMs: (map['hrvMs'] as num?)?.toInt(),
      stress: (map['stress'] as num?)?.toInt(),
      steps: (map['steps'] as num?)?.toInt(),
      bodyBattery: (map['bodyBattery'] as num?)?.toInt(),
      source: (map['source'] as String?) ?? 'GARMIN',
      updatedAt: updated,
    );
  }

  /// Konvertiert das Objekt in eine speicherbare Map für Firestore.
  Map<String, dynamic> toMap() {
    return {
      'sleepSeconds': sleepSeconds,
      'sleepScore': sleepScore,
      'restingHrBpm': restingHrBpm,
      'hrvMs': hrvMs,
      'stress': stress,
      'steps': steps,
      'bodyBattery': bodyBattery,
      'source': source,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
