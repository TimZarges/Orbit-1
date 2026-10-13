import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';

/// Einzelne Intensitätszone Z1 bis Z7.
class ZoneItem {
  final int zoneIndex; // 1 bis 7
  final double durationSec;
  final double percent;

  const ZoneItem({
    required this.zoneIndex,
    required this.durationSec,
    required this.percent,
  });

  String get zoneLabel => 'Z$zoneIndex';

  String get nameDe {
    switch (zoneIndex) {
      case 1:
        return 'Aktive Erholung';
      case 2:
        return 'Grundlage';
      case 3:
        return 'Tempo';
      case 4:
        return 'Schwelle';
      case 5:
        return 'VO₂max';
      case 6:
        return 'Anaerob';
      case 7:
        return 'Neuromuskulär';
      default:
        return 'Zone $zoneIndex';
    }
  }

  String get nameEn {
    switch (zoneIndex) {
      case 1:
        return 'Active Recovery';
      case 2:
        return 'Endurance';
      case 3:
        return 'Tempo';
      case 4:
        return 'Threshold';
      case 5:
        return 'VO₂max';
      case 6:
        return 'Anaerobic';
      case 7:
        return 'Neuromuscular';
      default:
        return 'Zone $zoneIndex';
    }
  }

  Color get color {
    switch (zoneIndex) {
      case 1:
        return AppColors.zone1;
      case 2:
        return AppColors.zone2;
      case 3:
        return AppColors.zone3;
      case 4:
        return AppColors.zone4;
      case 5:
        return AppColors.zone5;
      case 6:
        return AppColors.zone6;
      case 7:
        return AppColors.zone7;
      default:
        return Colors.grey;
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

/// Aggregierte Zonenverteilung.
class ZoneDistributionSummary {
  final List<ZoneItem> zones;
  final double totalDurationSec;

  const ZoneDistributionSummary({
    required this.zones,
    required this.totalDurationSec,
  });

  factory ZoneDistributionSummary.fromSeconds(List<double> zoneSeconds) {
    final total = zoneSeconds.fold(0.0, (sum, sec) => sum + sec);
    final list = <ZoneItem>[];

    for (int i = 0; i < zoneSeconds.length; i++) {
      final sec = zoneSeconds[i];
      final pct = total > 0 ? (sec / total) * 100 : 0.0;
      list.add(ZoneItem(
        zoneIndex: i + 1,
        durationSec: sec,
        percent: pct,
      ));
    }

    return ZoneDistributionSummary(
      zones: list,
      totalDurationSec: total,
    );
  }
}
