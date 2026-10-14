import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;
import 'workout_cadence.dart';
import 'workout_enums.dart';
import 'workout_intensity.dart';
import 'workout_target.dart';

/// Basisklasse für Blöcke innerhalb einer Trainingsstruktur (entweder STEP oder REPEAT).
sealed class WorkoutBlock {
  const WorkoutBlock();

  /// Blocktyp ('STEP' oder 'REPEAT').
  String get type;

  /// Verschachtelungstiefe des Blocks (Einzelschritt = 1, Wiederholung = 1 + Tiefe der Kindelemente).
  int get depth;

  /// Anzahl der effektiven Einzelschritte nach Multiplikation aller Wiederholungen.
  int get totalStepsCount;

  /// Konvertiert in das Schema-JSON.
  Map<String, dynamic> toJson();

  /// Erstellt einen [WorkoutBlock] aus dem Schema-JSON.
  factory WorkoutBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'STEP':
        return StepBlock.fromJson(json);
      case 'REPEAT':
        return RepeatBlock.fromJson(json);
      default:
        throw FormatException('Unbekannter WorkoutBlock-Typ: $type ($json)');
    }
  }
}

/// Ein einzelner Trainingsschritt mit Rolle, Zielvorgabe und Intensität.
class StepBlock extends WorkoutBlock {
  /// Rolle des Schritts (WARMUP, WORK, REST, COOLDOWN, MAIN).
  final WorkoutRole role;

  /// Zielvorgabe (Dauer oder Distanz).
  final WorkoutTarget target;

  /// Intensitätsvorgabe.
  final WorkoutIntensity intensity;

  /// Optionale Tritt- oder Schrittfrequenz.
  final WorkoutCadence? cadence;

  /// Optionale Textnotiz oder Anweisung.
  final String? note;

  const StepBlock({
    required this.role,
    required this.target,
    required this.intensity,
    this.cadence,
    this.note,
  });

  @override
  String get type => 'STEP';

  @override
  int get depth => 1;

  @override
  int get totalStepsCount => 1;

  StepBlock copyWith({
    WorkoutRole? role,
    WorkoutTarget? target,
    WorkoutIntensity? intensity,
    WorkoutCadence? cadence,
    String? note,
  }) {
    return StepBlock(
      role: role ?? this.role,
      target: target ?? this.target,
      intensity: intensity ?? this.intensity,
      cadence: cadence ?? this.cadence,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type,
      'role': role.toSchemaString(),
      'target': target.toJson(),
      'intensity': intensity.toJson(),
    };
    if (cadence != null) {
      map['cadence'] = cadence!.toJson();
    }
    if (note != null && note!.isNotEmpty) {
      map['note'] = note;
    }
    return map;
  }

  factory StepBlock.fromJson(Map<String, dynamic> json) {
    return StepBlock(
      role: WorkoutRole.fromSchemaString(json['role'] as String),
      target: WorkoutTarget.fromJson(json['target'] as Map<String, dynamic>),
      intensity:
          WorkoutIntensity.fromJson(json['intensity'] as Map<String, dynamic>),
      cadence: json['cadence'] != null
          ? WorkoutCadence.fromJson(json['cadence'] as Map<String, dynamic>)
          : null,
      note: json['note'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepBlock &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          target == other.target &&
          intensity == other.intensity &&
          cadence == other.cadence &&
          note == other.note;

  @override
  int get hashCode =>
      role.hashCode ^
      target.hashCode ^
      intensity.hashCode ^
      cadence.hashCode ^
      note.hashCode;

  @override
  String toString() =>
      'StepBlock(role: ${role.name}, target: $target, intensity: $intensity, cadence: $cadence, note: $note)';
}

/// Ein Wiederholungsblock (z. B. 4x(4' Z4 / 2' Z1)), der Kindblöcke n-mal wiederholt.
class RepeatBlock extends WorkoutBlock {
  /// Anzahl der Wiederholungen (2 bis 99).
  final int count;

  /// Unterblöcke, die wiederholt werden.
  final List<WorkoutBlock> blocks;

  const RepeatBlock({
    required this.count,
    required this.blocks,
  }) : assert(count >= 2 && count <= 99, 'count muss zwischen 2 und 99 liegen');

  @override
  String get type => 'REPEAT';

  @override
  int get depth =>
      blocks.isEmpty ? 1 : 1 + blocks.map((b) => b.depth).fold(0, math.max);

  @override
  int get totalStepsCount => blocks.isEmpty
      ? 0
      : count * blocks.map((b) => b.totalStepsCount).fold(0, (a, b) => a + b);

  RepeatBlock copyWith({
    int? count,
    List<WorkoutBlock>? blocks,
  }) {
    return RepeatBlock(
      count: count ?? this.count,
      blocks: blocks ?? this.blocks,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'count': count,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  factory RepeatBlock.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'] as List<dynamic>? ?? [];
    return RepeatBlock(
      count: (json['count'] as num).toInt(),
      blocks: rawBlocks
          .map((b) => WorkoutBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatBlock &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          listEquals(blocks, other.blocks);

  @override
  int get hashCode => count.hashCode ^ Object.hashAll(blocks);

  @override
  String toString() => 'RepeatBlock(count: $count, blocks: $blocks)';
}
