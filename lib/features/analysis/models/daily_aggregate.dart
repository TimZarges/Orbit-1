import 'package:cloud_firestore/cloud_firestore.dart';

/// Repräsentiert ein aggregiertes Tagesergebnis unter `users/{uid}/aggregates/{localDate}`.
///
/// Wird serverseitig von Cloud Functions gepflegt, um zeitaufwändige
/// Mehrfach-Aggregationen auf dem Mobilgerät zu vermeiden.
class DailyAggregate {
  /// Lokales Datum im ISO-Format `yyyy-MM-dd`.
  final String localDate;

  /// Tägliche Gesamtbelastung (TSS / Belastungswert).
  final double dailyLoad;

  /// Chronic Training Load (Fitness, 42-Tage EMA).
  final double ctl;

  /// Acute Training Load (Ermüdung, 7-Tage EMA).
  final double atl;

  /// Training Stress Balance (Frische = CTL - ATL).
  final double tsb;

  /// Optionaler experimenteller Belastungsindex (0–100).
  final double? orbitScore;

  /// Version des Metrik-Schemas (z. B. '1').
  final String? metricsVersion;

  /// Verteilung der Dauer in Sekunden je Sportart (`SWIM`, `BIKE`, `RUN`, `STRENGTH`, `OTHER`).
  final Map<String, double> sportsBreakdownSec;

  /// Zeit in Sekunden je Intensitätszone (Z1 bis Z7).
  final List<double> zoneBreakdownSec;

  /// Anzahl absolvierter Einheiten an diesem Tag.
  final int activityCount;

  const DailyAggregate({
    required this.localDate,
    required this.dailyLoad,
    required this.ctl,
    required this.atl,
    required this.tsb,
    this.orbitScore,
    this.metricsVersion,
    this.sportsBreakdownSec = const {},
    this.zoneBreakdownSec = const [],
    this.activityCount = 0,
  });

  factory DailyAggregate.fromMap(String date, Map<String, dynamic> map) {
    final sportsMap = <String, double>{};
    if (map['sportsBreakdown'] is Map) {
      (map['sportsBreakdown'] as Map).forEach((k, v) {
        if (v is num) {
          sportsMap[k.toString()] = v.toDouble();
        }
      });
    }

    final zonesList = <double>[];
    if (map['zoneBreakdown'] is List) {
      for (final item in (map['zoneBreakdown'] as List)) {
        if (item is num) {
          zonesList.add(item.toDouble());
        }
      }
    }

    return DailyAggregate(
      localDate: date,
      dailyLoad: (map['dailyLoad'] as num?)?.toDouble() ?? 0.0,
      ctl: (map['ctl'] as num?)?.toDouble() ?? 0.0,
      atl: (map['atl'] as num?)?.toDouble() ?? 0.0,
      tsb: (map['tsb'] as num?)?.toDouble() ?? 0.0,
      orbitScore: (map['orbitScore'] as num?)?.toDouble(),
      metricsVersion: map['metricsVersion'] as String?,
      sportsBreakdownSec: sportsMap,
      zoneBreakdownSec: zonesList,
      activityCount: (map['activityCount'] as num?)?.toInt() ??
          (map['dailyLoad'] != null && (map['dailyLoad'] as num) > 0 ? 1 : 0),
    );
  }

  factory DailyAggregate.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DailyAggregate.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyLoad': dailyLoad,
      'ctl': ctl,
      'atl': atl,
      'tsb': tsb,
      if (orbitScore != null) 'orbitScore': orbitScore,
      if (metricsVersion != null) 'metricsVersion': metricsVersion,
      'sportsBreakdown': sportsBreakdownSec,
      'zoneBreakdown': zoneBreakdownSec,
      'activityCount': activityCount,
    };
  }
}
