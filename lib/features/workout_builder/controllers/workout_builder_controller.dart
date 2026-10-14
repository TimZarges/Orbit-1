import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/workout_calculator.dart';
import '../domain/workout_formatter.dart';
import '../domain/workout_parse_error.dart';
import '../domain/workout_parser.dart';
import '../models/workout_builder_models.dart';

/// Zustand des interaktiven Workout Builders.
class WorkoutBuilderState {
  final String sport;
  final String text;
  final WorkoutStructure? structure;
  final List<WorkoutParseError> errors;
  final WorkoutCalculationResult calculation;
  final bool canUndo;
  final bool canRedo;
  final int? selectedBlockIndex;

  const WorkoutBuilderState({
    required this.sport,
    required this.text,
    this.structure,
    this.errors = const [],
    required this.calculation,
    this.canUndo = false,
    this.canRedo = false,
    this.selectedBlockIndex,
  });

  bool get isValid => errors.isEmpty && structure != null;

  WorkoutBuilderState copyWith({
    String? sport,
    String? text,
    WorkoutStructure? structure,
    List<WorkoutParseError>? errors,
    WorkoutCalculationResult? calculation,
    bool? canUndo,
    bool? canRedo,
    int? selectedBlockIndex,
  }) {
    return WorkoutBuilderState(
      sport: sport ?? this.sport,
      text: text ?? this.text,
      structure: structure ?? this.structure,
      errors: errors ?? this.errors,
      calculation: calculation ?? this.calculation,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      selectedBlockIndex: selectedBlockIndex ?? this.selectedBlockIndex,
    );
  }
}

/// Controller zur Verwaltung von Texteingabe, grafischer Struktur und Undo/Redo.
class WorkoutBuilderNotifier extends StateNotifier<WorkoutBuilderState> {
  final AthleteThresholds thresholds;
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  WorkoutBuilderNotifier({
    String initialSport = 'BIKE',
    String? initialText,
    WorkoutStructure? initialStructure,
    this.thresholds = AthleteThresholds.empty,
  }) : super(
          _createInitialState(
            sport: initialSport,
            initialText: initialText,
            initialStructure: initialStructure,
            thresholds: thresholds,
          ),
        );

  static WorkoutBuilderState _createInitialState({
    required String sport,
    String? initialText,
    WorkoutStructure? initialStructure,
    required AthleteThresholds thresholds,
  }) {
    String text = initialText ?? '';
    WorkoutStructure? structure = initialStructure;

    if (structure != null && text.isEmpty) {
      text = WorkoutFormatter.format(structure);
    } else if (text.isNotEmpty && structure == null) {
      final parser = WorkoutParser(sport: sport);
      final parseResult = parser.parse(text);
      structure = parseResult.structure;
    } else if (text.isEmpty && structure == null) {
      // Sinnvoller Standard für neue Einheit
      text = "10' Z1, 4x(4' Z4 / 2' Z1), 10' Z1";
      final parser = WorkoutParser(sport: sport);
      structure = parser.parse(text).structure;
    }

    final calc = structure != null
        ? WorkoutCalculator.calculate(structure, thresholds: thresholds)
        : const WorkoutCalculationResult(
            totalDurationSec: 0,
            totalDistanceM: 0,
            timeInZonesSec: {},
            assumptions: [],
            missingThresholdWarnings: [],
          );

    return WorkoutBuilderState(
      sport: sport,
      text: text,
      structure: structure,
      calculation: calc,
    );
  }

  /// Aktualisiert den Zustand ausgehend von einer Texteingabe.
  void updateText(String newText) {
    if (newText == state.text) return;

    _pushUndo(state.text);

    final parser = WorkoutParser(sport: state.sport);
    final parseResult = parser.parse(newText);

    if (parseResult.isSuccess && parseResult.structure != null) {
      final calc = WorkoutCalculator.calculate(
        parseResult.structure!,
        thresholds: thresholds,
      );
      state = state.copyWith(
        text: newText,
        structure: parseResult.structure,
        errors: const [],
        calculation: calc,
        canUndo: _undoStack.isNotEmpty,
        canRedo: false,
      );
    } else {
      state = state.copyWith(
        text: newText,
        errors: parseResult.errors,
        canUndo: _undoStack.isNotEmpty,
        canRedo: false,
      );
    }
  }

  /// Aktualisiert den Zustand ausgehend vom grafischen Block-Editor (synchronisiert Text).
  void updateStructure(WorkoutStructure newStructure) {
    _pushUndo(state.text);

    final newText = WorkoutFormatter.format(newStructure);
    final calc =
        WorkoutCalculator.calculate(newStructure, thresholds: thresholds);

    state = state.copyWith(
      text: newText,
      structure: newStructure,
      errors: const [],
      calculation: calc,
      canUndo: _undoStack.isNotEmpty,
      canRedo: false,
    );
  }

  /// Aktueller Zustand des Workout Builders.
  WorkoutBuilderState get currentState => state;

  /// Ersetzt einen Block an Position [index] durch [newBlock].
  void replaceBlock(int index, WorkoutBlock newBlock) {
    final currentBlocks = state.structure?.blocks ?? [];
    if (index < 0 || index >= currentBlocks.length) return;

    final updated = List<WorkoutBlock>.from(currentBlocks)..[index] = newBlock;
    updateStructure(
      WorkoutStructure(
        schemaVersion: 1,
        sport: state.sport,
        blocks: updated,
      ),
    );
  }

  /// Ändert die Sportart der Einheit.
  void setSport(String newSport) {
    if (newSport.toUpperCase() == state.sport.toUpperCase()) return;

    _pushUndo(state.text);

    final parser = WorkoutParser(sport: newSport);
    final parseResult = parser.parse(state.text);

    if (parseResult.isSuccess && parseResult.structure != null) {
      final updatedStructure = parseResult.structure!.copyWith(sport: newSport);
      final calc =
          WorkoutCalculator.calculate(updatedStructure, thresholds: thresholds);
      state = state.copyWith(
        sport: newSport,
        structure: updatedStructure,
        errors: const [],
        calculation: calc,
        canUndo: _undoStack.isNotEmpty,
      );
    } else {
      state = state.copyWith(
        sport: newSport,
        errors: parseResult.errors,
        canUndo: _undoStack.isNotEmpty,
      );
    }
  }

  /// Fügt einen neuen Block am Ende hinzu.
  void addBlock(WorkoutBlock block) {
    final currentBlocks = state.structure?.blocks ?? [];
    final updatedBlocks = [...currentBlocks, block];
    final updated = WorkoutStructure(
      schemaVersion: 1,
      sport: state.sport,
      blocks: updatedBlocks,
    );
    updateStructure(updated);
  }

  /// Dupliziert einen Block am angegebenen Index.
  void duplicateBlock(int index) {
    final currentBlocks = state.structure?.blocks ?? [];
    if (index < 0 || index >= currentBlocks.length) return;

    final updatedBlocks = List<WorkoutBlock>.from(currentBlocks);
    updatedBlocks.insert(index + 1, currentBlocks[index]);

    final updated = WorkoutStructure(
      schemaVersion: 1,
      sport: state.sport,
      blocks: updatedBlocks,
    );
    updateStructure(updated);
  }

  /// Löscht den Block am angegebenen Index.
  void deleteBlock(int index) {
    final currentBlocks = state.structure?.blocks ?? [];
    if (index < 0 || index >= currentBlocks.length) return;
    if (currentBlocks.length <= 1) return; // Mindestens ein Block muss bleiben

    final updatedBlocks = List<WorkoutBlock>.from(currentBlocks)
      ..removeAt(index);
    final updated = WorkoutStructure(
      schemaVersion: 1,
      sport: state.sport,
      blocks: updatedBlocks,
    );
    updateStructure(updated);
  }

  /// Verschiebt einen Block (z. B. per Drag & Drop oder Auf/Ab-Tasten).
  void moveBlock(int oldIndex, int newIndex) {
    final currentBlocks = state.structure?.blocks ?? [];
    if (oldIndex < 0 || oldIndex >= currentBlocks.length) return;
    if (newIndex < 0 || newIndex >= currentBlocks.length) return;

    final updatedBlocks = List<WorkoutBlock>.from(currentBlocks);
    final item = updatedBlocks.removeAt(oldIndex);
    updatedBlocks.insert(newIndex, item);

    final updated = WorkoutStructure(
      schemaVersion: 1,
      sport: state.sport,
      blocks: updatedBlocks,
    );
    updateStructure(updated);
  }

  /// Umschließt einen Block in eine Wiederholung (z. B. `4x(...)`).
  void wrapBlockInRepeat(int index, {int repeatCount = 4}) {
    final currentBlocks = state.structure?.blocks ?? [];
    if (index < 0 || index >= currentBlocks.length) return;

    final target = currentBlocks[index];
    final repeat = RepeatBlock(count: repeatCount, blocks: [target]);

    final updatedBlocks = List<WorkoutBlock>.from(currentBlocks)
      ..[index] = repeat;
    final updated = WorkoutStructure(
      schemaVersion: 1,
      sport: state.sport,
      blocks: updatedBlocks,
    );
    updateStructure(updated);
  }

  /// Löst eine Wiederholung auf und setzt die inneren Blöcke ein.
  void unwrapRepeat(int index) {
    final currentBlocks = state.structure?.blocks ?? [];
    if (index < 0 || index >= currentBlocks.length) return;

    final target = currentBlocks[index];
    if (target is! RepeatBlock) return;

    final updatedBlocks = List<WorkoutBlock>.from(currentBlocks)
      ..removeAt(index);
    updatedBlocks.insertAll(index, target.blocks);

    final updated = WorkoutStructure(
      schemaVersion: 1,
      sport: state.sport,
      blocks: updatedBlocks,
    );
    updateStructure(updated);
  }

  /// Macht die letzte Textänderung rückgängig.
  void undo() {
    if (_undoStack.isEmpty) return;
    final previousText = _undoStack.removeLast();
    _redoStack.add(state.text);

    final parser = WorkoutParser(sport: state.sport);
    final parseResult = parser.parse(previousText);

    final calc = parseResult.structure != null
        ? WorkoutCalculator.calculate(parseResult.structure!,
            thresholds: thresholds)
        : state.calculation;

    state = state.copyWith(
      text: previousText,
      structure: parseResult.structure,
      errors: parseResult.errors,
      calculation: calc,
      canUndo: _undoStack.isNotEmpty,
      canRedo: true,
    );
  }

  /// Stellt die letzte rückgängig gemachte Änderung wieder her.
  void redo() {
    if (_redoStack.isEmpty) return;
    final nextText = _redoStack.removeLast();
    _undoStack.add(state.text);

    final parser = WorkoutParser(sport: state.sport);
    final parseResult = parser.parse(nextText);

    final calc = parseResult.structure != null
        ? WorkoutCalculator.calculate(parseResult.structure!,
            thresholds: thresholds)
        : state.calculation;

    state = state.copyWith(
      text: nextText,
      structure: parseResult.structure,
      errors: parseResult.errors,
      calculation: calc,
      canUndo: true,
      canRedo: _redoStack.isNotEmpty,
    );
  }

  void _pushUndo(String currentText) {
    if (_undoStack.length >= 30) {
      _undoStack.removeAt(0);
    }
    _undoStack.add(currentText);
    _redoStack.clear();
  }
}

/// Parameter-Klasse für den WorkoutBuilderNotifierProvider.
class WorkoutBuilderParams {
  final String sport;
  final String? initialText;
  final WorkoutStructure? initialStructure;

  const WorkoutBuilderParams({
    this.sport = 'BIKE',
    this.initialText,
    this.initialStructure,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutBuilderParams &&
          runtimeType == other.runtimeType &&
          sport == other.sport &&
          initialText == other.initialText &&
          initialStructure == other.initialStructure;

  @override
  int get hashCode => Object.hash(sport, initialText, initialStructure);
}

/// Provider für den interaktiven Workout Builder.
final workoutBuilderProvider = StateNotifierProvider.autoDispose
    .family<WorkoutBuilderNotifier, WorkoutBuilderState, WorkoutBuilderParams>(
  (ref, params) {
    return WorkoutBuilderNotifier(
      initialSport: params.sport,
      initialText: params.initialText,
      initialStructure: params.initialStructure,
    );
  },
);
