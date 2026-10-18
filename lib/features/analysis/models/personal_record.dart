import '../../../core/utils/orbit_date_formatter.dart';

/// Filter-Zeitraum für persönliche Bestleistungen.
enum PRTimeframe {
  allTime('Allzeit'),
  year2026('2026'),
  last90Days('Letzte 90 Tage');

  final String label;
  const PRTimeframe(this.label);
}

/// Sportart für persönliche Bestleistungen.
enum PRSport {
  bike('Rad'),
  run('Lauf'),
  swim('Schwimmen');

  final String label;
  const PRSport(this.label);
}

/// Rad-Bestleistung über ein bestimmtes Zeitintervall.
class BikePR {
  final int durationSec;
  final String durationLabel;
  final double watts;
  final double wattsPerKg;
  final DateTime date;
  final String activityTitle;

  const BikePR({
    required this.durationSec,
    required this.durationLabel,
    required this.watts,
    required this.wattsPerKg,
    required this.date,
    required this.activityTitle,
  });

  String get formattedDate => OrbitDateFormatter.formatDate(date);
}

/// Lauf-Bestleistung über eine Standard-Distanz.
class RunPR {
  final int distanceM;
  final String distanceLabel;
  final int timeSec;
  final double paceSecPerKm;
  final DateTime date;
  final String activityTitle;

  const RunPR({
    required this.distanceM,
    required this.distanceLabel,
    required this.timeSec,
    required this.paceSecPerKm,
    required this.date,
    required this.activityTitle,
  });

  String get formattedTime {
    final h = timeSec ~/ 3600;
    final m = (timeSec % 3600) ~/ 60;
    final s = timeSec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedPace {
    final m = paceSecPerKm ~/ 60;
    final s = (paceSecPerKm % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  String get formattedDate => OrbitDateFormatter.formatDate(date);
}

/// Schwimm-Bestleistung über eine Standard-Distanz.
class SwimPR {
  final int distanceM;
  final String distanceLabel;
  final int timeSec;
  final double paceSecPer100m;
  final DateTime date;
  final String activityTitle;

  const SwimPR({
    required this.distanceM,
    required this.distanceLabel,
    required this.timeSec,
    required this.paceSecPer100m,
    required this.date,
    required this.activityTitle,
  });

  String get formattedTime {
    final m = timeSec ~/ 60;
    final s = timeSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedPace {
    final m = paceSecPer100m ~/ 60;
    final s = (paceSecPer100m % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /100m';
  }

  String get formattedDate => OrbitDateFormatter.formatDate(date);
}

/// Gesamtzusammenfassung der persönlichen Bestleistungen nach Sportart und Zeitraum.
class PersonalRecordsSummary {
  final Map<PRTimeframe, List<BikePR>> bikePRs;
  final Map<PRTimeframe, List<RunPR>> runPRs;
  final Map<PRTimeframe, List<SwimPR>> swimPRs;

  const PersonalRecordsSummary({
    required this.bikePRs,
    required this.runPRs,
    required this.swimPRs,
  });

  List<BikePR> getBike(PRTimeframe timeframe) => bikePRs[timeframe] ?? const [];
  List<RunPR> getRun(PRTimeframe timeframe) => runPRs[timeframe] ?? const [];
  List<SwimPR> getSwim(PRTimeframe timeframe) => swimPRs[timeframe] ?? const [];

  /// Realistische Demo-Daten generieren basierend auf Schwellenwerten (FTP / Gewicht).
  factory PersonalRecordsSummary.demo({
    double ftp = 280.0,
    double weightKg = 72.0,
  }) {
    final now = DateTime.now();

    List<BikePR> generateBike(double factor, DateTime baseDate) {
      final baseWatts = ftp * factor;
      final durations = [
        (5, '5s', baseWatts * 3.0),
        (15, '15s', baseWatts * 2.5),
        (30, '30s', baseWatts * 2.05),
        (60, '1m', baseWatts * 1.55),
        (180, '3m', baseWatts * 1.28),
        (300, '5m', baseWatts * 1.18),
        (600, '10m', baseWatts * 1.08),
        (1200, '20m', baseWatts * 1.03),
        (3600, '60m', baseWatts * 0.98),
        (5400, '90m', baseWatts * 0.91),
        (10800, '180m', baseWatts * 0.82),
      ];

      return durations.map((d) {
        final w = (d.$3).roundToDouble();
        final wpk = double.parse((w / weightKg).toStringAsFixed(2));
        return BikePR(
          durationSec: d.$1,
          durationLabel: d.$2,
          watts: w,
          wattsPerKg: wpk,
          date: baseDate.subtract(Duration(days: (d.$1 % 30) + 2)),
          activityTitle: 'Intervallfahrt & Berg-Segment',
        );
      }).toList();
    }

    List<RunPR> generateRun(double factor, DateTime baseDate) {
      final dists = [
        (400, '400m', (74 * factor).round(), 185.0 * factor),
        (1000, '1 km', (205 * factor).round(), 205.0 * factor),
        (3000, '3 km', (655 * factor).round(), 218.0 * factor),
        (5000, '5 km', (1130 * factor).round(), 226.0 * factor),
        (10000, '10 km', (2380 * factor).round(), 238.0 * factor),
        (21097, 'Halbmarathon', (5380 * factor).round(), 255.0 * factor),
        (42195, 'Marathon', (11650 * factor).round(), 276.0 * factor),
      ];

      return dists.map((d) {
        return RunPR(
          distanceM: d.$1,
          distanceLabel: d.$2,
          timeSec: d.$3,
          paceSecPerKm: d.$4,
          date: baseDate.subtract(Duration(days: (d.$1 % 45) + 5)),
          activityTitle: 'Tempodauerlauf / Wettkampf',
        );
      }).toList();
    }

    List<SwimPR> generateSwim(double factor, DateTime baseDate) {
      final dists = [
        (100, '100m', (75 * factor).round(), 75.0 * factor),
        (200, '200m', (162 * factor).round(), 81.0 * factor),
        (400, '400m', (344 * factor).round(), 86.0 * factor),
        (800, '800m', (712 * factor).round(), 89.0 * factor),
        (1500, '1500m', (1395 * factor).round(), 93.0 * factor),
      ];

      return dists.map((d) {
        return SwimPR(
          distanceM: d.$1,
          distanceLabel: d.$2,
          timeSec: d.$3,
          paceSecPer100m: d.$4,
          date: baseDate.subtract(Duration(days: (d.$1 % 20) + 1)),
          activityTitle: 'Bahnen-Training & CSS Test',
        );
      }).toList();
    }

    return PersonalRecordsSummary(
      bikePRs: {
        PRTimeframe.allTime:
            generateBike(1.0, now.subtract(const Duration(days: 40))),
        PRTimeframe.year2026:
            generateBike(0.97, now.subtract(const Duration(days: 15))),
        PRTimeframe.last90Days:
            generateBike(0.94, now.subtract(const Duration(days: 5))),
      },
      runPRs: {
        PRTimeframe.allTime:
            generateRun(1.0, now.subtract(const Duration(days: 60))),
        PRTimeframe.year2026:
            generateRun(1.03, now.subtract(const Duration(days: 20))),
        PRTimeframe.last90Days:
            generateRun(1.06, now.subtract(const Duration(days: 8))),
      },
      swimPRs: {
        PRTimeframe.allTime:
            generateSwim(1.0, now.subtract(const Duration(days: 35))),
        PRTimeframe.year2026:
            generateSwim(1.02, now.subtract(const Duration(days: 12))),
        PRTimeframe.last90Days:
            generateSwim(1.05, now.subtract(const Duration(days: 4))),
      },
    );
  }
}
