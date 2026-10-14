import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';

/// Einzelner Eintrag in der Sportarten-Verteilung.
class SportDistributionItem {
  final String sport;
  final double durationSec;
  final double percent;

  const SportDistributionItem({
    required this.sport,
    required this.durationSec,
    required this.percent,
  });

  Color get color {
    switch (sport.toUpperCase()) {
      case 'SWIM':
        return AppColors.sportSwim;
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'STRENGTH':
        return AppColors.sportStrength;
      case 'MULTISPORT':
        return AppColors.sportMulti;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData get icon {
    switch (sport.toUpperCase()) {
      case 'SWIM':
        return Icons.pool;
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'STRENGTH':
        return Icons.fitness_center;
      default:
        return Icons.timer_outlined;
    }
  }

  String get labelDe {
    switch (sport.toUpperCase()) {
      case 'SWIM':
        return 'Schwimmen';
      case 'BIKE':
        return 'Rad';
      case 'RUN':
        return 'Lauf';
      case 'STRENGTH':
        return 'Kraft';
      case 'MULTISPORT':
        return 'Koppel';
      default:
        return 'Sonstiges';
    }
  }

  String get formattedDuration {
    final totalMin = (durationSec / 60).round();
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }
}

/// Aggregierte Sportartenverteilung über einen Zeitraum.
class SportDistributionSummary {
  final List<SportDistributionItem> items;
  final double totalDurationSec;

  const SportDistributionSummary({
    required this.items,
    required this.totalDurationSec,
  });

  factory SportDistributionSummary.fromDurations(
      Map<String, double> durations) {
    final total = durations.values.fold(0.0, (sum, d) => sum + d);
    if (total <= 0) {
      return const SportDistributionSummary(items: [], totalDurationSec: 0);
    }

    final list = <SportDistributionItem>[];
    // Sortiert nach Dauer absteigend
    final sortedEntries = durations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
      if (entry.value > 0) {
        list.add(SportDistributionItem(
          sport: entry.key,
          durationSec: entry.value,
          percent: (entry.value / total) * 100,
        ));
      }
    }

    return SportDistributionSummary(
      items: list,
      totalDurationSec: total,
    );
  }
}
