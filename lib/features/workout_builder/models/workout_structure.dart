import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;
import 'workout_block.dart';
import 'workout_intensity.dart';

/// Repräsentiert die vollständige Struktur einer Trainingseinheit (Schema v1).
/// Siehe `docs/specs/WORKOUT_SYNTAX.md`.
class WorkoutStructure {
  /// Schema-Version (aktuell 1).
  final int schemaVersion;

  /// Sportart ('BIKE', 'RUN', 'SWIM', 'STRENGTH').
  final String sport;

  /// Die oberste Liste von Blöcken (Steps oder Repeats).
  final List<WorkoutBlock> blocks;

  const WorkoutStructure({
    this.schemaVersion = 1,
    required this.sport,
    required this.blocks,
  });

  /// Maximale Verschachtelungstiefe der Blöcke (max. 3 erlaubt).
  int get maxDepth => blocks.isEmpty
      ? 0
      : blocks.map((b) => b.depth).fold(0, math.max);

  /// Gesamtzahl der Einzelschritte nach Multiplikation aller Wiederholungen (max. 200).
  int get totalStepsCount => blocks.isEmpty
      ? 0
      : blocks.map((b) => b.totalStepsCount).fold(0, (a, b) => a + b);

  /// Validiert die Struktur nach allen Vorgaben aus der Spezifikation.
  /// Gibt eine leere Liste zurück, wenn alles valide ist, andernfalls die Fehlerbeschreibungen.
  List<String> validate() {
    final errors = <String>[];

    if (schemaVersion != 1) {
      errors.add('Ungültige schemaVersion: $schemaVersion (erwartet: 1)');
    }

    final normalizedSport = sport.toUpperCase();
    if (!const {'BIKE', 'RUN', 'SWIM', 'STRENGTH'}.contains(normalizedSport)) {
      errors.add('Unbekannte Sportart: $sport');
    }

    if (blocks.isEmpty) {
      errors.add('Workout-Struktur darf keine leere Blockliste enthalten.');
      return errors;
    }

    if (maxDepth > 3) {
      errors.add('Maximale Verschachtelungstiefe überschritten ($maxDepth > 3).');
    }

    if (totalStepsCount > 200) {
      errors.add(
        'Maximale Schrittanzahl nach Expansion überschritten ($totalStepsCount > 200).',
      );
    }

    // Rekursive Blockprüfung
    _validateBlocks(blocks, normalizedSport, errors, currentDepth: 1);

    return errors;
  }

  /// Gibt an, ob die Struktur alle Validierungsregeln erfüllt.
  bool get isValid => validate().isEmpty;

  void _validateBlocks(
    List<WorkoutBlock> list,
    String normalizedSport,
    List<String> errors, {
    required int currentDepth,
  }) {
    for (final block in list) {
      if (block is RepeatBlock) {
        if (block.count < 2 || block.count > 99) {
          errors.add('Wiederholungsanzahl muss zwischen 2 und 99 liegen (ist: ${block.count}).');
        }
        if (block.blocks.isEmpty) {
          errors.add('Wiederholungsblock darf nicht leer sein.');
        } else {
          _validateBlocks(
            block.blocks,
            normalizedSport,
            errors,
            currentDepth: currentDepth + 1,
          );
        }
      } else if (block is StepBlock) {
        _validateStep(block, normalizedSport, errors);
      }
    }
  }

  void _validateStep(
    StepBlock step,
    String normalizedSport,
    List<String> errors,
  ) {
    // Zielvorgabe
    if (step.target.isDuration) {
      final sec = step.target.durationSec ?? 0;
      if (sec <= 0) {
        errors.add('Schritt-Dauer muss > 0 Sekunden sein.');
      }
    } else if (step.target.isDistance) {
      final m = step.target.distanceM ?? 0;
      if (m <= 0) {
        errors.add('Schritt-Distanz muss > 0 Meter sein.');
      }
    } else {
      errors.add('Schritt besitzt weder gültige Dauer noch Distanz.');
    }

    // Sportartenkompatibilität der Intensität
    if (!step.intensity.isAllowedForSport(normalizedSport)) {
      errors.add(
        'Intensität "${step.intensity.formattedDisplay}" (${step.intensity.kind}) ist für $normalizedSport nicht zulässig.',
      );
    }

    // Intensitätswerte
    switch (step.intensity) {
      case final ZoneIntensity z:
        if (z.low < 1 || z.low > 7 || z.high < 1 || z.high > 7 || z.low > z.high) {
          errors.add('Ungültiger Zonenbereich: Z${z.low}-Z${z.high}.');
        }
      case final PctFtpIntensity f:
        if (f.low <= 0 || f.high < f.low) {
          errors.add('Ungültiger FTP-Bereich: ${f.low}-${f.high}%.');
        }
      case final PctLthrIntensity l:
        if (l.low <= 0 || l.high < l.low) {
          errors.add('Ungültiger LTHR-Bereich: ${l.low}-${l.high}%.');
        }
      case final PaceIntensity p:
        if (p.secPerKm <= 0) {
          errors.add('Lauf-Pace muss > 0 s/km sein.');
        }
      case final SwimPaceIntensity s:
        if (s.secPer100m <= 0) {
          errors.add('Schwimm-Pace muss > 0 s/100m sein.');
        }
      case CssOffsetIntensity _:
      case FreeIntensity _:
        break;
    }

    // Cadence
    if (step.cadence != null) {
      if (step.cadence!.low <= 0 || step.cadence!.high < step.cadence!.low) {
        errors.add('Ungültiger Trittfrequenzbereich: ${step.cadence}.');
      }
    }
  }

  /// Migriert eine Roh-Map auf das aktuelle Strukturschema.
  /// Unbekannte oder zukünftige Schema-Versionen werden mit `FormatException` abgewiesen.
  static WorkoutStructure migrateStructure(Map<String, dynamic> raw) {
    final version = raw['schemaVersion'];
    if (version == null) {
      throw const FormatException('Fehlendes Feld "schemaVersion" im Workout-Dokument.');
    }
    if (version is! num || version.toInt() != 1) {
      throw FormatException(
        'Nicht unterstützte schemaVersion: $version (unterstützt wird nur v1).',
      );
    }
    return WorkoutStructure.fromJson(raw);
  }

  WorkoutStructure copyWith({
    int? schemaVersion,
    String? sport,
    List<WorkoutBlock>? blocks,
  }) {
    return WorkoutStructure(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      sport: sport ?? this.sport,
      blocks: blocks ?? this.blocks,
    );
  }

  /// Konvertiert in das Schema-JSON (Schema v1).
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'sport': sport.toUpperCase(),
    'blocks': blocks.map((b) => b.toJson()).toList(),
  };

  /// Deserialisiert eine [WorkoutStructure] aus Schema-JSON.
  factory WorkoutStructure.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'] as List<dynamic>? ?? [];
    return WorkoutStructure(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      sport: (json['sport'] as String? ?? 'BIKE').toUpperCase(),
      blocks: rawBlocks
          .map((b) => WorkoutBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutStructure &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          sport == other.sport &&
          listEquals(blocks, other.blocks);

  @override
  int get hashCode =>
      schemaVersion.hashCode ^ sport.hashCode ^ Object.hashAll(blocks);

  @override
  String toString() =>
      'WorkoutStructure(sport: $sport, blocks: ${blocks.length}, maxDepth: $maxDepth)';
}
