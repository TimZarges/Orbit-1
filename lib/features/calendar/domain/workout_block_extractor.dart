import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../workout_builder/domain/workout_calculator.dart';
import '../../workout_builder/domain/workout_parser.dart';
import '../../workout_builder/models/workout_builder_models.dart';
import '../models/planned_workout.dart';

/// Repräsentiert einen einzelnen visualisierbaren Trainingsblock für Profile und Detailansichten.
class ExtractedWorkoutStep {
  /// Index des Blocks (1-basiert).
  final int stepIndex;

  /// Fachliche Bezeichnung des Blocks (z. B. "Warmup", "Intervall 1/4", "Pause 1/4", "Ausrollen").
  final String label;

  /// Dauer in Sekunden.
  final int durationSec;

  /// Optionale Distanz in Metern.
  final int? distanceM;

  /// Trainingszone (1 bis 7).
  final int zone;

  /// Semantische Akzentfarbe der Zone.
  final Color color;

  /// Prozentbereich des Schwellenwerts (z. B. 95–105 % FTP).
  final String intensityPercentLabel;

  /// Konkreter Zielwert in Watt (für Radsport, z. B. "320–355 W").
  final String? targetWattsLabel;

  /// Konkreter Zielwert als Pace (für Laufsport, z. B. "4:15–4:30 min/km").
  final String? targetPaceLabel;

  /// Konkreter Zielwert als Herzfrequenz (z. B. "160–172 bpm").
  final String? targetHrLabel;

  const ExtractedWorkoutStep({
    required this.stepIndex,
    required this.label,
    required this.durationSec,
    this.distanceM,
    required this.zone,
    required this.color,
    required this.intensityPercentLabel,
    this.targetWattsLabel,
    this.targetPaceLabel,
    this.targetHrLabel,
  });

  /// Formatierte Dauer (z. B. "04:00 min" oder "10:00 min").
  String get formattedDuration {
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    final mStr = m.toString().padLeft(2, '0');
    final sStr = s.toString().padLeft(2, '0');
    return '$mStr:$sStr min';
  }
}

/// Extrahiert und berechnet strukturierte Workout-Blöcke aus beliebigen [PlannedWorkout]-Dokumenten (Phase 37.2).
///
/// Garantiert 1:1 Konsistenz zwischen Titel/Beschreibung und visueller Block-Darstellung
/// (z. B. "4x4min Intervalle" erzeugt exakt 10 Blöcke: Warmup + 4x [Belastung + Erholung] + Cooldown).
class WorkoutBlockExtractor {
  const WorkoutBlockExtractor._();

  /// Extrahiert die vollständige Liste sequenzieller Trainingsblöcke inkl. Schwellenwert-Umrechnung.
  static List<ExtractedWorkoutStep> extractSteps(
    PlannedWorkout workout, {
    AthleteThresholds thresholds = AthleteThresholds.empty,
    int? maxHr,
  }) {
    // 1. Auswertung vorhandener Firestore-Struktur
    if (workout.structure != null &&
        workout.structure!.containsKey('blocks') &&
        (workout.structure!['blocks'] as List).isNotEmpty) {
      final steps = _fromStructure(workout.structure!, thresholds, maxHr);
      if (steps.isNotEmpty) return steps;
    }

    // 2. Syntax-Parsing aus der Beschreibung falls vorhanden
    if (workout.description != null && workout.description!.trim().isNotEmpty) {
      try {
        final parser = WorkoutParser(sport: workout.sport);
        final parseRes = parser.parse(workout.description!.trim());
        if (parseRes.isSuccess && parseRes.structure != null) {
          final steps =
              _fromWorkoutStructure(parseRes.structure!, thresholds, maxHr);
          if (steps.isNotEmpty) return steps;
        }
      } catch (_) {}
    }

    // 3. Intelligente Erkennung von Wiederholungsmustern im Titel (z. B. "4x4min", "5x3 min", "30/30")
    final repeatSteps = _inferFromTitle(
        workout.title, workout.plannedDurationSec, thresholds, maxHr);
    if (repeatSteps != null && repeatSteps.isNotEmpty) {
      return repeatSteps;
    }

    // 4. Fallback auf dreiteiliges Standard-Profil (Warmup 15 %, GA1 70 %, Cooldown 15 %)
    return _buildDefaultThreePart(
        workout.plannedDurationSec, thresholds, maxHr);
  }

  /// Wandelt eine rohe Firestore-Map-Struktur in [ExtractedWorkoutStep]s um.
  static List<ExtractedWorkoutStep> _fromStructure(
    Map<String, dynamic> raw,
    AthleteThresholds thresholds,
    int? maxHr,
  ) {
    final rawBlocks = raw['blocks'] as List<dynamic>? ?? [];
    final steps = <ExtractedWorkoutStep>[];
    int stepCounter = 1;

    for (final b in rawBlocks) {
      if (b is! Map<String, dynamic>) continue;
      final type = b['type']?.toString().toUpperCase();

      if (type == 'STEP' || type == null) {
        int dur = (b['durationSec'] as num?)?.toInt() ?? 300;
        if (b['target'] is Map<String, dynamic>) {
          dur = (b['target']['durationSec'] as num?)?.toInt() ?? dur;
        }

        int zone = (b['zone'] as num?)?.toInt() ?? 2;
        if (b['intensity'] is Map<String, dynamic>) {
          final intensityMap = b['intensity'] as Map<String, dynamic>;
          final kind = intensityMap['kind']?.toString().toUpperCase();
          if (kind == 'ZONE') {
            zone = (intensityMap['low'] as num?)?.toInt() ?? zone;
          } else if (kind == 'PCT_FTP') {
            final pct = (intensityMap['low'] as num?)?.toInt() ?? 100;
            if (pct < 55) {
              zone = 1;
            } else if (pct < 75) {
              zone = 2;
            } else if (pct < 90) {
              zone = 3;
            } else if (pct < 105) {
              zone = 4;
            } else if (pct < 120) {
              zone = 5;
            } else {
              zone = 6;
            }
          }
        }

        final role = b['role']?.toString().toLowerCase();

        String label = 'Belastung';
        if (role == 'warmup') label = 'Aufwärmen';
        if (role == 'cooldown') label = 'Ausrollen';
        if (role == 'rest') label = 'Erholung';

        steps.add(_buildStep(
          stepIndex: stepCounter++,
          label: label,
          durationSec: dur,
          zone: zone,
          thresholds: thresholds,
          maxHr: maxHr,
        ));
      } else if (type == 'REPEAT') {
        final count = (b['count'] as num?)?.toInt() ?? 3;
        final inner = b['blocks'] as List<dynamic>? ?? [];

        for (int i = 0; i < count; i++) {
          for (final sub in inner) {
            if (sub is! Map<String, dynamic>) continue;
            int dur = (sub['durationSec'] as num?)?.toInt() ?? 180;
            if (sub['target'] is Map<String, dynamic>) {
              dur = (sub['target']['durationSec'] as num?)?.toInt() ?? dur;
            }

            int zone = (sub['zone'] as num?)?.toInt() ?? 4;
            if (sub['intensity'] is Map<String, dynamic>) {
              final intensityMap = sub['intensity'] as Map<String, dynamic>;
              final kind = intensityMap['kind']?.toString().toUpperCase();
              if (kind == 'ZONE') {
                zone = (intensityMap['low'] as num?)?.toInt() ?? zone;
              } else if (kind == 'PCT_FTP') {
                final pct = (intensityMap['low'] as num?)?.toInt() ?? 100;
                if (pct < 55) {
                  zone = 1;
                } else if (pct < 75) {
                  zone = 2;
                } else if (pct < 90) {
                  zone = 3;
                } else if (pct < 105) {
                  zone = 4;
                } else if (pct < 120) {
                  zone = 5;
                } else {
                  zone = 6;
                }
              }
            }

            final isRest =
                (sub['role']?.toString().toLowerCase() == 'rest') || zone <= 2;

            steps.add(_buildStep(
              stepIndex: stepCounter++,
              label: isRest
                  ? 'Erholung ${i + 1}/$count'
                  : 'Intervall ${i + 1}/$count',
              durationSec: dur,
              zone: zone,
              thresholds: thresholds,
              maxHr: maxHr,
            ));
          }
        }
      }
    }

    return steps;
  }

  /// Wandelt eine typisierte [WorkoutStructure] in [ExtractedWorkoutStep]s um.
  static List<ExtractedWorkoutStep> _fromWorkoutStructure(
    WorkoutStructure structure,
    AthleteThresholds thresholds,
    int? maxHr,
  ) {
    final steps = <ExtractedWorkoutStep>[];
    int stepCounter = 1;

    for (final b in structure.blocks) {
      if (b is StepBlock) {
        final dur = b.target.durationSec ?? 300;
        int zone = 2;
        if (b.intensity is ZoneIntensity) {
          zone = (b.intensity as ZoneIntensity).low;
        }

        String label = 'Belastung';
        if (b.role == WorkoutRole.warmup) label = 'Aufwärmen';
        if (b.role == WorkoutRole.cooldown) label = 'Ausrollen';
        if (b.role == WorkoutRole.rest) label = 'Erholung';

        steps.add(_buildStep(
          stepIndex: stepCounter++,
          label: label,
          durationSec: dur,
          zone: zone,
          thresholds: thresholds,
          maxHr: maxHr,
        ));
      } else if (b is RepeatBlock) {
        for (int i = 0; i < b.count; i++) {
          for (final sub in b.blocks) {
            if (sub is StepBlock) {
              final dur = sub.target.durationSec ?? 180;
              int zone = 4;
              if (sub.intensity is ZoneIntensity) {
                zone = (sub.intensity as ZoneIntensity).low;
              }
              final isRest = sub.role == WorkoutRole.rest || zone <= 2;

              steps.add(_buildStep(
                stepIndex: stepCounter++,
                label: isRest
                    ? 'Erholung ${i + 1}/${b.count}'
                    : 'Intervall ${i + 1}/${b.count}',
                durationSec: dur,
                zone: zone,
                thresholds: thresholds,
                maxHr: maxHr,
              ));
            }
          }
        }
      }
    }

    return steps;
  }

  /// Erkennt Wiederholungsmuster im Titel wie "4x4min", "5x1000m", "6x3min".
  static List<ExtractedWorkoutStep>? _inferFromTitle(
    String title,
    int totalPlannedSec,
    AthleteThresholds thresholds,
    int? maxHr,
  ) {
    final clean = title.toLowerCase();
    final match =
        RegExp(r'(\d+)\s*[x*]\s*(\d+)\s*(min|m|s|sek)?').firstMatch(clean);
    if (match == null) return null;

    final count = int.tryParse(match.group(1) ?? '');
    final amount = int.tryParse(match.group(2) ?? '');
    if (count == null || amount == null || count < 2 || count > 30) return null;

    // Ermittle Intervall-Dauer in Sekunden
    final unit = match.group(3) ?? 'min';
    int intervalSec = 240; // Default 4 min
    if (unit.startsWith('s')) {
      intervalSec = amount;
    } else if (unit.startsWith('m') &&
        !unit.startsWith('min') &&
        amount >= 100) {
      // Distanzangabe in Metern (z. B. 5x1000m) -> Pace-basierte Schätzung
      final paceSec = thresholds.runThresholdPaceSecPerKm ?? 300;
      intervalSec = ((amount / 1000.0) * paceSec).round();
    } else {
      intervalSec = amount * 60;
    }

    // Passende Erholungsdauer
    final restSec = intervalSec >= 180 ? 120 : (intervalSec ~/ 2).clamp(30, 90);

    // Warmup & Cooldown ermitteln
    final warmupSec = 600; // 10 min
    final cooldownSec = 600; // 10 min

    final steps = <ExtractedWorkoutStep>[];
    int counter = 1;

    // 1. Warmup
    steps.add(_buildStep(
      stepIndex: counter++,
      label: 'Aufwärmen',
      durationSec: warmupSec,
      zone: 2,
      thresholds: thresholds,
      maxHr: maxHr,
    ));

    // 2. Wiederholungsschleife
    for (int i = 0; i < count; i++) {
      steps.add(_buildStep(
        stepIndex: counter++,
        label: 'Intervall ${i + 1}/$count',
        durationSec: intervalSec,
        zone: 5,
        thresholds: thresholds,
        maxHr: maxHr,
      ));
      steps.add(_buildStep(
        stepIndex: counter++,
        label: 'Erholung ${i + 1}/$count',
        durationSec: restSec,
        zone: 1,
        thresholds: thresholds,
        maxHr: maxHr,
      ));
    }

    // 3. Cooldown
    steps.add(_buildStep(
      stepIndex: counter++,
      label: 'Ausrollen / Auslaufen',
      durationSec: cooldownSec,
      zone: 1,
      thresholds: thresholds,
      maxHr: maxHr,
    ));

    return steps;
  }

  /// Dreiteiliges Standardprofil (Warmup, Hauptteil, Cooldown).
  static List<ExtractedWorkoutStep> _buildDefaultThreePart(
    int totalPlannedSec,
    AthleteThresholds thresholds,
    int? maxHr,
  ) {
    final dur = totalPlannedSec > 0 ? totalPlannedSec : 3600;
    final warmup = (dur * 0.15).round().clamp(300, 900);
    final cooldown = (dur * 0.15).round().clamp(300, 900);
    final main = (dur - warmup - cooldown).clamp(300, 24 * 3600);

    return [
      _buildStep(
        stepIndex: 1,
        label: 'Aufwärmen',
        durationSec: warmup,
        zone: 2,
        thresholds: thresholds,
        maxHr: maxHr,
      ),
      _buildStep(
        stepIndex: 2,
        label: 'Grundlagenausdauer (GA1)',
        durationSec: main,
        zone: 2,
        thresholds: thresholds,
        maxHr: maxHr,
      ),
      _buildStep(
        stepIndex: 3,
        label: 'Ausrollen / Nachbereitung',
        durationSec: cooldown,
        zone: 1,
        thresholds: thresholds,
        maxHr: maxHr,
      ),
    ];
  }

  /// Hilfsmethode zur Erzeugung eines einzelnen visualisierbaren Blocks mit berechneten Zielwerten.
  static ExtractedWorkoutStep _buildStep({
    required int stepIndex,
    required String label,
    required int durationSec,
    required int zone,
    required AthleteThresholds thresholds,
    int? maxHr,
  }) {
    final color = AppColors.zoneColor(zone);
    String percentLabel;
    String? wattsLabel;
    String? paceLabel;
    String? hrLabel;

    // Prozentbereiche je Zone
    switch (zone) {
      case 1:
        percentLabel = '< 55 %';
        break;
      case 2:
        percentLabel = '55–75 %';
        break;
      case 3:
        percentLabel = '76–90 %';
        break;
      case 4:
        percentLabel = '91–105 %';
        break;
      case 5:
        percentLabel = '106–120 %';
        break;
      case 6:
      case 7:
        percentLabel = '> 120 %';
        break;
      default:
        percentLabel = '65–75 %';
    }

    // Wattwerte (Rad)
    if (thresholds.ftp != null && thresholds.ftp! > 0) {
      final ftp = thresholds.ftp!;
      switch (zone) {
        case 1:
          wattsLabel = '< ${(ftp * 0.55).round()} W';
          break;
        case 2:
          wattsLabel = '${(ftp * 0.55).round()}–${(ftp * 0.75).round()} W';
          break;
        case 3:
          wattsLabel = '${(ftp * 0.76).round()}–${(ftp * 0.90).round()} W';
          break;
        case 4:
          wattsLabel = '${(ftp * 0.91).round()}–${(ftp * 1.05).round()} W';
          break;
        case 5:
          wattsLabel = '${(ftp * 1.06).round()}–${(ftp * 1.20).round()} W';
          break;
        case 6:
        case 7:
          wattsLabel = '> ${(ftp * 1.20).round()} W';
          break;
      }
    }

    // Pace (Lauf)
    if (thresholds.runThresholdPaceSecPerKm != null &&
        thresholds.runThresholdPaceSecPerKm! > 0) {
      final tPace = thresholds.runThresholdPaceSecPerKm!;
      // Je höher die Zone, desto schneller (weniger Sekunden)
      int lowPace;
      int highPace;
      switch (zone) {
        case 1:
          lowPace = (tPace * 1.25).round();
          highPace = (tPace * 1.40).round();
          break;
        case 2:
          lowPace = (tPace * 1.15).round();
          highPace = (tPace * 1.24).round();
          break;
        case 3:
          lowPace = (tPace * 1.05).round();
          highPace = (tPace * 1.14).round();
          break;
        case 4:
          lowPace = (tPace * 0.98).round();
          highPace = (tPace * 1.04).round();
          break;
        case 5:
        case 6:
        case 7:
          lowPace = (tPace * 0.88).round();
          highPace = (tPace * 0.97).round();
          break;
        default:
          lowPace = tPace;
          highPace = (tPace * 1.1).round();
      }
      paceLabel = '${_formatPace(lowPace)}–${_formatPace(highPace)} min/km';
    }

    // HF (Herzfrequenz)
    if (maxHr != null && maxHr > 100) {
      switch (zone) {
        case 1:
          hrLabel = '< ${(maxHr * 0.68).round()} bpm';
          break;
        case 2:
          hrLabel = '${(maxHr * 0.68).round()}–${(maxHr * 0.83).round()} bpm';
          break;
        case 3:
          hrLabel = '${(maxHr * 0.84).round()}–${(maxHr * 0.94).round()} bpm';
          break;
        case 4:
          hrLabel = '${(maxHr * 0.95).round()}–${(maxHr * 1.02).round()} bpm';
          break;
        case 5:
        case 6:
        case 7:
          hrLabel = '> ${(maxHr * 1.03).round()} bpm';
          break;
      }
    }

    return ExtractedWorkoutStep(
      stepIndex: stepIndex,
      label: label,
      durationSec: durationSec,
      zone: zone,
      color: color,
      intensityPercentLabel: percentLabel,
      targetWattsLabel: wattsLabel,
      targetPaceLabel: paceLabel,
      targetHrLabel: hrLabel,
    );
  }

  static String _formatPace(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
