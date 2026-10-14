import '../models/workout_builder_models.dart';

/// Hinterlegte Schwellenwerte des Athleten für Einheitenberechnungen und Umrechnungen.
class AthleteThresholds {
  /// Functional Threshold Power in Watt (Rad).
  final double? ftp;

  /// Laktatschwellen-Herzfrequenz in Schlägen/min (Rad/Lauf).
  final int? lthr;

  /// Schwellen-Pace beim Laufen in Sekunden pro Kilometer (z. B. 270 s = 4:30/km).
  final int? runThresholdPaceSecPerKm;

  /// Critical Swim Speed in Sekunden pro 100 Meter (z. B. 105 s = 1:45/100m).
  final int? cssSecPer100m;

  const AthleteThresholds({
    this.ftp,
    this.lthr,
    this.runThresholdPaceSecPerKm,
    this.cssSecPer100m,
  });

  static const AthleteThresholds empty = AthleteThresholds();
}

/// Ergebnis der Workout-Berechnung mit Dauer, Distanz, Zonenverteilung und Belastung.
class WorkoutCalculationResult {
  /// Berechnete Gesamtdauer in Sekunden.
  final int totalDurationSec;

  /// Berechnete Gesamtdistanz in Metern.
  final int totalDistanceM;

  /// Zeitaufteilung je Zone (1..7) in Sekunden.
  final Map<int, int> timeInZonesSec;

  /// Geschätzte Belastung (ORBIT Score / TSS Vorschau).
  final double? estimatedLoad;

  /// Dokumentierte Annahmen bei Schätzungen (z. B. Distanzumrechnung mit CSS).
  final List<String> assumptions;

  /// Warnhinweise bei fehlenden Schwellenwerten.
  final List<String> missingThresholdWarnings;

  const WorkoutCalculationResult({
    required this.totalDurationSec,
    required this.totalDistanceM,
    required this.timeInZonesSec,
    this.estimatedLoad,
    required this.assumptions,
    required this.missingThresholdWarnings,
  });

  /// Formatierte Gesamtdauer (z. B. "1h 15min" oder "45 min").
  String get formattedDuration {
    if (totalDurationSec == 0) return '0 min';
    final h = totalDurationSec ~/ 3600;
    final m = (totalDurationSec % 3600) ~/ 60;
    if (h > 0) {
      return m == 0 ? '${h}h' : '${h}h ${m}min';
    }
    return '$m min';
  }

  /// Formatierte Gesamtdistanz (z. B. "2.4 km" oder "800 m").
  String get formattedDistance {
    if (totalDistanceM == 0) return '--';
    if (totalDistanceM >= 1000) {
      final km = totalDistanceM / 1000.0;
      return km % 1 == 0 ? '${km.toInt()} km' : '${km.toStringAsFixed(1)} km';
    }
    return '$totalDistanceM m';
  }

  /// Formatierte Belastung (z. B. "65 Score").
  String get formattedLoad {
    if (estimatedLoad == null || estimatedLoad! <= 0) return '--';
    return '${estimatedLoad!.round()} Score';
  }
}

/// Berechnet Kennzahlen aus einer [WorkoutStructure].
class WorkoutCalculator {
  const WorkoutCalculator._();

  /// Berechnet Gesamtdauer, Gesamtdistanz, Zeit in Zonen und geschätzte Belastung.
  static WorkoutCalculationResult calculate(
    WorkoutStructure structure, {
    AthleteThresholds thresholds = AthleteThresholds.empty,
  }) {
    int totalDuration = 0;
    int totalDistance = 0;
    final zonesMap = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    double totalTss = 0.0;
    final assumptions = <String>[];
    final warnings = <String>[];

    void processStep(StepBlock step, int multiplier) {
      int stepDuration = 0;
      int stepDistance = 0;

      // 1. Dauer und Distanz ermitteln
      if (step.target.isDuration) {
        stepDuration = (step.target.durationSec ?? 0) * multiplier;
        totalDuration += stepDuration;

        // Falls Pace bekannt, Distanz ausrechnen
        if (step.intensity is PaceIntensity) {
          final pace = (step.intensity as PaceIntensity).secPerKm;
          if (pace > 0) {
            stepDistance = ((stepDuration / pace) * 1000).round();
            totalDistance += stepDistance;
          }
        } else if (step.intensity is SwimPaceIntensity) {
          final pace = (step.intensity as SwimPaceIntensity).secPer100m;
          if (pace > 0) {
            stepDistance = ((stepDuration / pace) * 100).round();
            totalDistance += stepDistance;
          }
        }
      } else if (step.target.isDistance) {
        stepDistance = (step.target.distanceM ?? 0) * multiplier;
        totalDistance += stepDistance;

        // Distanz → Dauer umrechnen
        final singleDistanceM = step.target.distanceM ?? 0;
        int? singleDurationSec;

        if (step.intensity is PaceIntensity) {
          final pace = (step.intensity as PaceIntensity).secPerKm;
          singleDurationSec = ((singleDistanceM / 1000.0) * pace).round();
        } else if (step.intensity is SwimPaceIntensity) {
          final pace = (step.intensity as SwimPaceIntensity).secPer100m;
          singleDurationSec = ((singleDistanceM / 100.0) * pace).round();
        } else if (step.intensity is CssOffsetIntensity) {
          final offset =
              (step.intensity as CssOffsetIntensity).offsetSecPer100m;
          if (thresholds.cssSecPer100m != null) {
            final effectivePace = thresholds.cssSecPer100m! + offset;
            singleDurationSec =
                ((singleDistanceM / 100.0) * effectivePace).round();
            final paceMin = thresholds.cssSecPer100m! ~/ 60;
            final paceSec = thresholds.cssSecPer100m! % 60;
            assumptions.add(
              'Schwimmdauer für ${singleDistanceM}m geschätzt mit deiner CSS von $paceMin:${paceSec.toString().padLeft(2, '0')}/100m.',
            );
          } else {
            warnings.add(
              'Keine CSS hinterlegt: Dauer für ${singleDistanceM}m Schwimmen konnte nicht exakt berechnet werden.',
            );
            // Konservativer Standardwert (2:00/100m) für Layout-Zwecke
            singleDurationSec = ((singleDistanceM / 100.0) * 120).round();
          }
        } else if (structure.sport.toUpperCase() == 'RUN') {
          // Laufen mit Distanzziel ohne explizite Pace
          if (thresholds.runThresholdPaceSecPerKm != null) {
            final pace = thresholds.runThresholdPaceSecPerKm!;
            singleDurationSec = ((singleDistanceM / 1000.0) * pace).round();
            final paceMin = pace ~/ 60;
            final paceSec = pace % 60;
            assumptions.add(
              'Laufdauer für ${singleDistanceM}m geschätzt mit deiner Schwellenpace von $paceMin:${paceSec.toString().padLeft(2, '0')}/km.',
            );
          } else {
            warnings.add(
              'Keine Lauf-Schwellenpace hinterlegt: Dauer für ${singleDistanceM}m Lauf geschätzt mit 5:00/km.',
            );
            singleDurationSec =
                ((singleDistanceM / 100.0) * 30).round(); // 5:00/km = 300s/km
          }
        } else {
          // Fallback
          singleDurationSec = 60;
        }

        stepDuration = singleDurationSec * multiplier;
        totalDuration += stepDuration;
      }

      // 2. Zonenzuordnung
      final targetZone =
          _resolveIntensityToZone(step.intensity, structure.sport);
      zonesMap[targetZone] = (zonesMap[targetZone] ?? 0) + stepDuration;

      // 3. Geschätzter TSS / ORBIT Score
      final intensityFactor = _resolveIntensityFactor(step.intensity);
      if (stepDuration > 0 && intensityFactor > 0) {
        final stepTss =
            (stepDuration * intensityFactor * intensityFactor) / 3600.0 * 100.0;
        totalTss += stepTss;
      }
    }

    void processBlock(WorkoutBlock block, int currentMultiplier) {
      if (block is StepBlock) {
        processStep(block, currentMultiplier);
      } else if (block is RepeatBlock) {
        for (final child in block.blocks) {
          processBlock(child, currentMultiplier * block.count);
        }
      }
    }

    for (final block in structure.blocks) {
      processBlock(block, 1);
    }

    return WorkoutCalculationResult(
      totalDurationSec: totalDuration,
      totalDistanceM: totalDistance,
      timeInZonesSec: zonesMap,
      estimatedLoad: totalTss > 0 ? (totalTss * 10).round() / 10.0 : null,
      assumptions: assumptions.toSet().toList(), // Duplikate entfernen
      missingThresholdWarnings: warnings.toSet().toList(),
    );
  }

  /// Mappt eine beliebige [WorkoutIntensity] auf eine Hauptzone (1..7).
  static int _resolveIntensityToZone(WorkoutIntensity intensity, String sport) {
    switch (intensity) {
      case final ZoneIntensity z:
        return z.low;
      case final PctFtpIntensity f:
        final avgPct = (f.low + f.high) / 2.0;
        if (avgPct < 55) return 1;
        if (avgPct <= 75) return 2;
        if (avgPct <= 90) return 3;
        if (avgPct <= 105) return 4;
        if (avgPct <= 120) return 5;
        if (avgPct <= 150) return 6;
        return 7;
      case final PctLthrIntensity l:
        final avgPct = (l.low + l.high) / 2.0;
        if (avgPct < 68) return 1;
        if (avgPct <= 83) return 2;
        if (avgPct <= 94) return 3;
        if (avgPct <= 105) return 4;
        return 5;
      case final CssOffsetIntensity c:
        if (c.offsetSecPer100m > 5) return 2;
        if (c.offsetSecPer100m > 0) return 3;
        if (c.offsetSecPer100m == 0) return 4;
        if (c.offsetSecPer100m >= -3) return 5;
        return 6;
      case final PaceIntensity _:
      case final SwimPaceIntensity _:
        return 4; // Schwellenbereich als Standard
      case final FreeIntensity _:
        return 1;
    }
  }

  /// Ermittelt den Intensitätsfaktor (IF) für die Belastungsschätzung.
  static double _resolveIntensityFactor(WorkoutIntensity intensity) {
    switch (intensity) {
      case final ZoneIntensity z:
        switch (z.low) {
          case 1:
            return 0.55;
          case 2:
            return 0.70;
          case 3:
            return 0.82;
          case 4:
            return 0.95;
          case 5:
            return 1.08;
          case 6:
            return 1.25;
          case 7:
            return 1.50;
          default:
            return 0.70;
        }
      case final PctFtpIntensity f:
        return ((f.low + f.high) / 2.0) / 100.0;
      case final PctLthrIntensity l:
        return ((l.low + l.high) / 2.0) / 100.0;
      case final CssOffsetIntensity c:
        // CSS = Schwellenbelastung (IF = 1.00)
        return 1.0 - (c.offsetSecPer100m * 0.03);
      case final PaceIntensity _:
      case final SwimPaceIntensity _:
        return 0.95;
      case final FreeIntensity _:
        return 0.60;
    }
  }
}
