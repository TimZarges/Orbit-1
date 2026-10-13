import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';

enum LoadComparisonStatus {
  onTrack,
  overPlan,
  underPlan,
  noPlan,
}

/// Zusammenfassung der Wochenbelastung im Vergleich zum Trainingsplan.
class WeeklyLoadSummary {
  /// Tatsächlich absolvierte Belastung (TSS / Belastungspunkte).
  final double actualLoad;

  /// Geplante Belastung laut Trainingsplan.
  final double plannedLoad;

  /// Gibt an, ob für diese Woche Einheiten geplant waren.
  final bool hasPlan;

  const WeeklyLoadSummary({
    required this.actualLoad,
    required this.plannedLoad,
    required this.hasPlan,
  });

  /// Abweichung in Prozent (z.B. +12.5 oder -20.0).
  double? get deviationPercent {
    if (!hasPlan || plannedLoad <= 0) return null;
    return ((actualLoad - plannedLoad) / plannedLoad) * 100;
  }

  /// Erfüllungsgrad in Prozent (z. B. 95 %).
  int get completionPercent {
    if (!hasPlan || plannedLoad <= 0) return 100;
    return ((actualLoad / plannedLoad) * 100).round();
  }

  /// Status der Wochenbelastung.
  LoadComparisonStatus get status {
    if (!hasPlan || plannedLoad <= 0) return LoadComparisonStatus.noPlan;
    final diff = deviationPercent!;
    if (diff > 15) return LoadComparisonStatus.overPlan;
    if (diff < -15) return LoadComparisonStatus.underPlan;
    return LoadComparisonStatus.onTrack;
  }

  /// Klartext-Meldung auf Deutsch.
  String get statusTextDe {
    switch (status) {
      case LoadComparisonStatus.onTrack:
        return 'Im Plan ($completionPercent %)';
      case LoadComparisonStatus.overPlan:
        final p = deviationPercent!.round();
        return 'Über Plan (+$p %)';
      case LoadComparisonStatus.underPlan:
        final p = deviationPercent!.round().abs();
        return 'Unter Plan (-$p %)';
      case LoadComparisonStatus.noPlan:
        return 'Kein Wochenplan hinterlegt';
    }
  }

  /// Klartext-Meldung auf Englisch.
  String get statusTextEn {
    switch (status) {
      case LoadComparisonStatus.onTrack:
        return 'On track ($completionPercent %)';
      case LoadComparisonStatus.overPlan:
        final p = deviationPercent!.round();
        return 'Above plan (+$p %)';
      case LoadComparisonStatus.underPlan:
        final p = deviationPercent!.round().abs();
        return 'Below plan (-$p %)';
      case LoadComparisonStatus.noPlan:
        return 'No weekly plan defined';
    }
  }

  /// Farbe für das Status-Badge.
  Color get statusColor {
    switch (status) {
      case LoadComparisonStatus.onTrack:
        return AppColors.accentVolt;
      case LoadComparisonStatus.overPlan:
        return const Color(0xFFDD6B20); // Warm Amber
      case LoadComparisonStatus.underPlan:
        return const Color(0xFF3182CE); // Blau / Erholung
      case LoadComparisonStatus.noPlan:
        return const Color(0xFF94A3B8);
    }
  }
}
