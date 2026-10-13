import 'dart:math' as math;
import '../models/workout_builder_models.dart';
import 'workout_parse_error.dart';

/// Ergebnis des Workout-Parsings mit entweder einer validen [WorkoutStructure]
/// oder einer Liste von [WorkoutParseError]s mit exakten Zeichenpositionen.
class WorkoutParseResult {
  /// Die geparste Struktur (nur vorhanden wenn fehlerfrei).
  final WorkoutStructure? structure;

  /// Liste gefundener Syntax- und Validierungsfehler.
  final List<WorkoutParseError> errors;

  const WorkoutParseResult._({this.structure, required this.errors});

  factory WorkoutParseResult.success(WorkoutStructure structure) =>
      WorkoutParseResult._(structure: structure, errors: const []);

  factory WorkoutParseResult.failure(List<WorkoutParseError> errors) =>
      WorkoutParseResult._(structure: null, errors: errors);

  /// Gibt an, ob das Parsen erfolgreich war.
  bool get isSuccess => structure != null && errors.isEmpty;
}

/// Parser für die Workout-Textkurzeingabe gemäß `WORKOUT_SYNTAX.md`.
class WorkoutParser {
  final String sport;

  const WorkoutParser({required this.sport});

  /// Parst den eingegebenen [input]-String für die konfigurierte Sportart.
  WorkoutParseResult parse(String input) {
    final errors = <WorkoutParseError>[];

    // 1. Längenprüfung
    if (input.trim().isEmpty) {
      return WorkoutParseResult.failure([
        const WorkoutParseError(
          startIndex: 0,
          endIndex: 0,
          code: 'EMPTY_INPUT',
          messageDe: 'Workout-Eingabe darf nicht leer sein.',
          messageEn: 'Workout input cannot be empty.',
        ),
      ]);
    }

    if (input.length > 500) {
      return WorkoutParseResult.failure([
        WorkoutParseError(
          startIndex: 500,
          endIndex: input.length,
          code: 'INPUT_TOO_LONG',
          messageDe: 'Eingabe überschreitet maximal 500 Zeichen.',
          messageEn: 'Input exceeds maximum of 500 characters.',
        ),
      ]);
    }

    // 2. Normalisierung typischer Anführungszeichen (z. B. auf Mobilgeräten)
    final normalized = _normalizeQuotes(input);

    // 3. Klammerprüfung
    _validateParentheses(normalized, errors);
    if (errors.isNotEmpty) {
      return WorkoutParseResult.failure(errors);
    }

    // 4. Tokenisierung / Blockteilung auf oberster Ebene
    final blocks = _parseBlockList(
      normalized,
      0,
      normalized.length,
      errors,
      currentDepth: 1,
      isTopLevel: true,
    );

    if (errors.isNotEmpty) {
      return WorkoutParseResult.failure(errors);
    }

    if (blocks.isEmpty) {
      return WorkoutParseResult.failure([
        WorkoutParseError(
          startIndex: 0,
          endIndex: input.length,
          code: 'NO_VALID_BLOCKS',
          messageDe: 'Keine gültigen Blöcke gefunden.',
          messageEn: 'No valid blocks found.',
        ),
      ]);
    }

    // 5. Automatische Rollenzuweisung (WU am Anfang, CD am Ende)
    final assignedBlocks = _inferTopLevelRoles(blocks);

    // 6. Erstellung der WorkoutStructure und finale Validierung
    final structure = WorkoutStructure(
      schemaVersion: 1,
      sport: sport.toUpperCase(),
      blocks: assignedBlocks,
    );

    final validationErrors = structure.validate();
    if (validationErrors.isNotEmpty) {
      for (final ve in validationErrors) {
        errors.add(
          WorkoutParseError(
            startIndex: 0,
            endIndex: input.length,
            code: 'VALIDATION_ERROR',
            messageDe: ve,
            messageEn: ve,
          ),
        );
      }
      return WorkoutParseResult.failure(errors);
    }

    return WorkoutParseResult.success(structure);
  }

  /// Normalisiert typografische Anführungszeichen in Standardzeichen.
  static String _normalizeQuotes(String s) {
    return s
        .replaceAll('’', '\'')
        .replaceAll('‘', '\'')
        .replaceAll('”', '"')
        .replaceAll('“', '"')
        .replaceAll('„', '"');
  }

  /// Prüft auf ungeschlossene oder falsche Klammern.
  void _validateParentheses(String s, List<WorkoutParseError> errors) {
    final stack = <int>[];
    for (int i = 0; i < s.length; i++) {
      final char = s[i];
      if (char == '(') {
        stack.add(i);
      } else if (char == ')') {
        if (stack.isEmpty) {
          errors.add(
            WorkoutParseError(
              startIndex: i,
              endIndex: i + 1,
              code: 'UNEXPECTED_CLOSING_PAREN',
              messageDe: 'Unerwartete schließende Klammer ")"',
              messageEn: 'Unexpected closing parenthesis ")"',
            ),
          );
        } else {
          stack.removeLast();
        }
      }
    }
    for (final openIndex in stack) {
      errors.add(
        WorkoutParseError(
          startIndex: openIndex,
          endIndex: openIndex + 1,
          code: 'UNCLOSED_PAREN',
          messageDe: 'Nicht geschlossene Klammer "("',
          messageEn: 'Unclosed parenthesis "("',
        ),
      );
    }
  }

  /// Parst eine Liste von Blöcken (getrennt durch Komma oder Slash).
  List<WorkoutBlock> _parseBlockList(
    String s,
    int startOffset,
    int endOffset,
    List<WorkoutParseError> errors, {
    required int currentDepth,
    required bool isTopLevel,
  }) {
    if (currentDepth > 3) {
      errors.add(
        WorkoutParseError(
          startIndex: startOffset,
          endIndex: endOffset,
          code: 'MAX_DEPTH_EXCEEDED',
          messageDe: 'Maximale Verschachtelungstiefe von 3 überschritten.',
          messageEn: 'Maximum nesting depth of 3 exceeded.',
        ),
      );
      return [];
    }

    final rawSegments = _splitByTopLevelDelimiter(s, startOffset, endOffset, const {',', '/'});
    final blocks = <WorkoutBlock>[];

    for (final seg in rawSegments) {
      final trimmedStart = _skipWhitespace(s, seg.start, seg.end);
      final trimmedEnd = _trimTrailingWhitespace(s, trimmedStart, seg.end);
      if (trimmedStart >= trimmedEnd) continue;

      final block = _parseSingleBlock(
        s,
        trimmedStart,
        trimmedEnd,
        errors,
        currentDepth: currentDepth,
        isInsideSlashPair: seg.delimiterBefore == '/',
      );
      if (block != null) {
        blocks.add(block);
      }
    }

    return blocks;
  }

  /// Parst einen einzelnen Block (entweder Wiederholung oder Einzelschritt).
  WorkoutBlock? _parseSingleBlock(
    String s,
    int start,
    int end,
    List<WorkoutParseError> errors, {
    required int currentDepth,
    required bool isInsideSlashPair,
  }) {
    final text = s.substring(start, end).trim();

    // 1. Prüfung auf Gruppen-Wiederholung: z. B. `4x(...)`
    final repeatMatch = RegExp(r'^(\d+)\s*x\s*\((.*)\)$', caseSensitive: false).firstMatch(text);
    if (repeatMatch != null) {
      final count = int.parse(repeatMatch.group(1)!);
      if (count < 2 || count > 99) {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: start + repeatMatch.group(1)!.length + 1,
            code: 'INVALID_REPEAT_COUNT',
            messageDe: 'Wiederholungsanzahl muss zwischen 2 und 99 liegen (war: $count).',
            messageEn: 'Repeat count must be between 2 and 99 (was: $count).',
          ),
        );
      }

      // Inhalt der Klammer
      final parenContentStart = start + text.indexOf('(') + 1;
      final parenContentEnd = start + text.lastIndexOf(')');

      final innerBlocks = _parseBlockList(
        s,
        parenContentStart,
        parenContentEnd,
        errors,
        currentDepth: currentDepth + 1,
        isTopLevel: false,
      );

      if (innerBlocks.isEmpty && errors.isEmpty) {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: end,
            code: 'EMPTY_REPEAT_BLOCK',
            messageDe: 'Wiederholungsblock darf nicht leer sein.',
            messageEn: 'Repeat block cannot be empty.',
          ),
        );
        return null;
      }

      return RepeatBlock(count: count.clamp(2, 99), blocks: innerBlocks);
    }

    // 2. Prüfung auf Kurzform-Wiederholung: z. B. `8x100m CSS / 20"` oder `5x1000m @4:30/km / 90"`
    final shortRepeatMatch = RegExp(r'^(\d+)\s*x\s*([^/]+)\s*/\s*(.+)$', caseSensitive: false).firstMatch(text);
    if (shortRepeatMatch != null) {
      final count = int.parse(shortRepeatMatch.group(1)!);
      if (count < 2 || count > 99) {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: start + shortRepeatMatch.group(1)!.length + 1,
            code: 'INVALID_REPEAT_COUNT',
            messageDe: 'Wiederholungsanzahl muss zwischen 2 und 99 liegen.',
            messageEn: 'Repeat count must be between 2 and 99.',
          ),
        );
      }

      final workStr = shortRepeatMatch.group(2)!.trim();
      final restStr = shortRepeatMatch.group(3)!.trim();

      final workStep = _parseStep(
        workStr,
        start,
        start + workStr.length,
        errors,
        defaultRole: WorkoutRole.work,
      );
      final restStep = _parseStep(
        restStr,
        end - restStr.length,
        end,
        errors,
        defaultRole: WorkoutRole.rest,
      );

      if (workStep != null && restStep != null) {
        return RepeatBlock(
          count: count.clamp(2, 99),
          blocks: [workStep, restStep],
        );
      }
      return null;
    }

    // 3. Einzelschritt parsen
    final defaultRole = isInsideSlashPair ? WorkoutRole.rest : WorkoutRole.work;
    return _parseStep(text, start, end, errors, defaultRole: defaultRole);
  }

  /// Parst einen einzelnen Schritt (z. B. `10' Z1 [Locker]`, `400m CSS`, `8' 90-95%FTP @90rpm`).
  StepBlock? _parseStep(
    String raw,
    int startIndex,
    int endIndex,
    List<WorkoutParseError> errors, {
    required WorkoutRole defaultRole,
  }) {
    var text = raw.trim();
    if (text.isEmpty) return null;

    // 1. Notiz extrahieren: `[...]`
    String? note;
    final noteMatch = RegExp(r'\[(.*?)\]').firstMatch(text);
    if (noteMatch != null) {
      note = noteMatch.group(1)!.trim();
      text = text.replaceRange(noteMatch.start, noteMatch.end, '').trim();
    }

    // 2. Explizite Rolle extrahieren (falls vorhanden, z. B. `WU: 10' Z1` oder `Pause: 2'`)
    var role = defaultRole;
    final roleMatch = RegExp(r'^(WU|CD|WARMUP|COOLDOWN|WORK|REST|PAUSE|MAIN)\s*:\s*', caseSensitive: false).firstMatch(text);
    if (roleMatch != null) {
      final rolePrefix = roleMatch.group(1)!;
      role = WorkoutRole.fromSchemaString(rolePrefix);
      text = text.substring(roleMatch.end).trim();
    }

    // 3. Cadence extrahieren: `@90rpm`, `@90-95rpm`, `@180spm`
    WorkoutCadence? cadence;
    final cadenceMatch = RegExp(r'@(\d+)(?:-(\d+))?\s*(rpm|spm)', caseSensitive: false).firstMatch(text);
    if (cadenceMatch != null) {
      final low = int.parse(cadenceMatch.group(1)!);
      final high = cadenceMatch.group(2) != null ? int.parse(cadenceMatch.group(2)!) : low;
      cadence = WorkoutCadence(low: low, high: high);
      text = text.replaceRange(cadenceMatch.start, cadenceMatch.end, '').trim();
    }

    // 4. Zielvorgabe (Dauer oder Distanz) extrahieren
    WorkoutTarget? target;
    final targetMatch = RegExp(
      r'''^(\d+h(?:\d+['’])?|\d+['’](?:\d+["”])?|\d+["”]?|\d+min|\d+s|\d+(?:\.\d+)?km|\d+m)(?:\s+|$)''',
      caseSensitive: false,
    ).firstMatch(text);

    if (targetMatch != null) {
      final targetStr = targetMatch.group(1)!.trim();
      target = _parseTarget(targetStr, startIndex, startIndex + targetStr.length, errors);
      text = text.substring(targetMatch.end).trim();
    } else {
      errors.add(
        WorkoutParseError(
          startIndex: startIndex,
          endIndex: endIndex,
          code: 'MISSING_OR_INVALID_TARGET',
          messageDe: 'Zielvorgabe (Dauer wie 10\' oder Distanz wie 400m) fehlt oder ist ungültig.',
          messageEn: 'Target (duration like 10\' or distance like 400m) is missing or invalid.',
        ),
      );
      return null;
    }

    if (target == null) return null;

    // 5. Intensität parsen
    final intensity = _parseIntensity(
      text,
      startIndex,
      endIndex,
      errors,
    );

    return StepBlock(
      role: role,
      target: target,
      intensity: intensity,
      cadence: cadence,
      note: note,
    );
  }

  /// Parst eine Zielvorgabe (Dauer oder Distanz).
  WorkoutTarget? _parseTarget(String s, int start, int end, List<WorkoutParseError> errors) {
    final lower = s.toLowerCase();

    // 1. Distanz in km
    if (lower.endsWith('km')) {
      final valStr = lower.substring(0, lower.length - 2);
      final km = double.tryParse(valStr);
      if (km != null && km > 0) {
        return WorkoutTarget.distance((km * 1000).round());
      }
    }

    // 2. Distanz in m
    if (lower.endsWith('m') && !lower.endsWith('min')) {
      final valStr = lower.substring(0, lower.length - 1);
      final m = int.tryParse(valStr);
      if (m != null && m > 0) {
        return WorkoutTarget.distance(m);
      }
    }

    // 3. Dauer in Stunden: `1h` oder `1h30'`
    if (lower.contains('h')) {
      final parts = lower.split('h');
      final h = int.tryParse(parts[0]) ?? 0;
      var min = 0;
      if (parts.length > 1 && parts[1].isNotEmpty) {
        final minStr = parts[1].replaceAll("'", '').replaceAll('min', '');
        min = int.tryParse(minStr) ?? 0;
      }
      final totalSec = (h * 3600) + (min * 60);
      if (totalSec > 0) {
        return WorkoutTarget.duration(totalSec);
      }
    }

    // 4. Dauer mit Minuten und Sekunden: `1'30"`
    if (lower.contains('\'') && lower.contains('"')) {
      final parts = lower.split('\'');
      final min = int.tryParse(parts[0]) ?? 0;
      final sec = int.tryParse(parts[1].replaceAll('"', '')) ?? 0;
      final totalSec = (min * 60) + sec;
      if (totalSec > 0) {
        return WorkoutTarget.duration(totalSec);
      }
    }

    // 5. Dauer in Minuten: `10'`, `10min`
    if (lower.endsWith('\'') || lower.endsWith('min')) {
      final valStr = lower.replaceAll('\'', '').replaceAll('min', '');
      final min = int.tryParse(valStr);
      if (min != null && min > 0) {
        return WorkoutTarget.duration(min * 60);
      }
    }

    // 6. Dauer in Sekunden: `30"`, `30s`
    if (lower.endsWith('"') || lower.endsWith('s')) {
      final valStr = lower.replaceAll('"', '').replaceAll('s', '');
      final sec = int.tryParse(valStr);
      if (sec != null && sec > 0) {
        return WorkoutTarget.duration(sec);
      }
    }

    // 7. Nur Zahl ohne Einheit (Fallstrick): als Minuten interpretieren wenn >= 1
    final fallbackMin = int.tryParse(lower);
    if (fallbackMin != null && fallbackMin > 0) {
      return WorkoutTarget.duration(fallbackMin * 60);
    }

    errors.add(
      WorkoutParseError(
        startIndex: start,
        endIndex: end,
        code: 'INVALID_TARGET_FORMAT',
        messageDe: 'Ungültiges Format für Dauer oder Distanz: "$s".',
        messageEn: 'Invalid format for duration or distance: "$s".',
      ),
    );
    return null;
  }

  /// Parst eine Intensitätsangabe aus dem verbliebenen Text.
  WorkoutIntensity _parseIntensity(
    String s,
    int start,
    int end,
    List<WorkoutParseError> errors,
  ) {
    final t = s.trim();
    if (t.isEmpty) {
      // Leere Intensität: Fallback auf Z1 oder Free
      return sport.toUpperCase() == 'STRENGTH' ? const FreeIntensity() : const ZoneIntensity.single(1);
    }

    final upper = t.toUpperCase();

    // 1. Frei / Locker
    if (upper == 'FREI' || upper == 'FREE') {
      return const FreeIntensity();
    }
    if (upper == 'LOCKER' || upper == 'EASY') {
      return const ZoneIntensity.single(1);
    }

    // 2. Zonen: `Z1`..`Z7` oder Bereiche `Z2-Z3`
    final zoneMatch = RegExp(r'^Z([1-7])(?:-Z?([1-7]))?$', caseSensitive: false).firstMatch(upper);
    if (zoneMatch != null) {
      final low = int.parse(zoneMatch.group(1)!);
      final high = zoneMatch.group(2) != null ? int.parse(zoneMatch.group(2)!) : low;
      if (low > high) {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: end,
            code: 'INVALID_ZONE_RANGE',
            messageDe: 'Zonenbereich ungültig: Z$low-Z$high (erste Zone muss kleiner/gleich sein).',
            messageEn: 'Invalid zone range: Z$low-Z$high.',
          ),
        );
        return const ZoneIntensity.single(1);
      }
      return ZoneIntensity(low: low, high: high);
    }

    // 3. % FTP: `85%FTP`, `90-95%FTP`, `85% FTP`
    final ftpMatch = RegExp(r'^(\d+)(?:-(\d+))?%\s*FTP$', caseSensitive: false).firstMatch(upper);
    if (ftpMatch != null) {
      if (sport.toUpperCase() != 'BIKE') {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: end,
            code: 'FTP_NOT_ALLOWED',
            messageDe: '% FTP ist nur beim Radfahren zulässig.',
            messageEn: '% FTP is only allowed for cycling.',
          ),
        );
      }
      final low = int.parse(ftpMatch.group(1)!);
      final high = ftpMatch.group(2) != null ? int.parse(ftpMatch.group(2)!) : low;
      return PctFtpIntensity(low: low, high: high);
    }

    // 4. % LTHR: `88%LTHR`, `85-90%LTHR`
    final lthrMatch = RegExp(r'^(\d+)(?:-(\d+))?%\s*LTHR$', caseSensitive: false).firstMatch(upper);
    if (lthrMatch != null) {
      if (sport.toUpperCase() != 'BIKE' && sport.toUpperCase() != 'RUN') {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: end,
            code: 'LTHR_NOT_ALLOWED',
            messageDe: '% LTHR ist nur für Rad und Lauf zulässig.',
            messageEn: '% LTHR is only allowed for cycling and running.',
          ),
        );
      }
      final low = int.parse(lthrMatch.group(1)!);
      final high = lthrMatch.group(2) != null ? int.parse(lthrMatch.group(2)!) : low;
      return PctLthrIntensity(low: low, high: high);
    }

    // 5. CSS / CSS Offset: `CSS`, `CSS+5"`, `CSS-3"`
    if (upper.startsWith('CSS')) {
      if (sport.toUpperCase() != 'SWIM') {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: end,
            code: 'CSS_NOT_ALLOWED',
            messageDe: 'CSS ist nur beim Schwimmen zulässig.',
            messageEn: 'CSS is only allowed for swimming.',
          ),
        );
      }
      if (upper == 'CSS') {
        return const CssOffsetIntensity(offsetSecPer100m: 0);
      }
      final offsetMatch = RegExp(r'^CSS([+-]\d+)["”]?$', caseSensitive: false).firstMatch(upper);
      if (offsetMatch != null) {
        final offset = int.parse(offsetMatch.group(1)!);
        return CssOffsetIntensity(offsetSecPer100m: offset);
      }
    }

    // 6. Lauf-Pace: `@4:30/km` oder `4:30/km`
    final runPaceMatch = RegExp(r'^@?(\d+):(\d{2})/KM$', caseSensitive: false).firstMatch(upper);
    if (runPaceMatch != null) {
      if (sport.toUpperCase() != 'RUN') {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: end,
            code: 'RUN_PACE_NOT_ALLOWED',
            messageDe: 'Lauf-Pace (/km) ist nur beim Laufen zulässig.',
            messageEn: 'Run pace (/km) is only allowed for running.',
          ),
        );
      }
      final min = int.parse(runPaceMatch.group(1)!);
      final sec = int.parse(runPaceMatch.group(2)!);
      return PaceIntensity(secPerKm: (min * 60) + sec);
    }

    // 7. Schwimm-Pace: `@1:45/100m` oder `1:45/100m`
    final swimPaceMatch = RegExp(r'^@?(\d+):(\d{2})/100M$', caseSensitive: false).firstMatch(upper);
    if (swimPaceMatch != null) {
      if (sport.toUpperCase() != 'SWIM') {
        errors.add(
          WorkoutParseError(
            startIndex: start,
            endIndex: end,
            code: 'SWIM_PACE_NOT_ALLOWED',
            messageDe: 'Schwimm-Pace (/100m) ist nur beim Schwimmen zulässig.',
            messageEn: 'Swim pace (/100m) is only allowed for swimming.',
          ),
        );
      }
      final min = int.parse(swimPaceMatch.group(1)!);
      final sec = int.parse(swimPaceMatch.group(2)!);
      return SwimPaceIntensity(secPer100m: (min * 60) + sec);
    }

    // Nicht erkannt
    errors.add(
      WorkoutParseError(
        startIndex: start,
        endIndex: end,
        code: 'UNKNOWN_INTENSITY',
        messageDe: 'Unbekannte Intensitätsangabe: "$t".',
        messageEn: 'Unknown intensity: "$t".',
      ),
    );
    return const ZoneIntensity.single(1);
  }

  /// Weist automatisch WARMUP für den ersten und COOLDOWN für den letzten Einzelschritt zu,
  /// sofern nicht explizit anders deklariert.
  List<WorkoutBlock> _inferTopLevelRoles(List<WorkoutBlock> blocks) {
    if (blocks.length <= 1) return blocks;

    final result = List<WorkoutBlock>.from(blocks);

    // Erster Block
    final first = result.first;
    if (first is StepBlock && first.role == WorkoutRole.work) {
      result[0] = first.copyWith(role: WorkoutRole.warmup);
    }

    // Letzter Block
    final last = result.last;
    if (last is StepBlock && (last.role == WorkoutRole.work || last.role == WorkoutRole.rest)) {
      result[result.length - 1] = last.copyWith(role: WorkoutRole.cooldown);
    }

    return result;
  }

  /// Teilt einen String an Trennzeichen (z. B. `,` oder `/`), ignoriert aber Delimiter innerhalb von Klammern.
  List<_Segment> _splitByTopLevelDelimiter(
    String s,
    int startOffset,
    int endOffset,
    Set<String> delimiters,
  ) {
    final segments = <_Segment>[];
    int currentStart = startOffset;
    int parenDepth = 0;
    String? lastDelim;

    for (int i = startOffset; i < endOffset; i++) {
      final char = s[i];
      if (char == '(') {
        parenDepth++;
      } else if (char == ')') {
        parenDepth = math.max(0, parenDepth - 1);
      } else if (parenDepth == 0 && delimiters.contains(char)) {
        segments.add(
          _Segment(
            start: currentStart,
            end: i,
            delimiterBefore: lastDelim,
          ),
        );
        currentStart = i + 1;
        lastDelim = char;
      }
    }

    if (currentStart < endOffset) {
      segments.add(
        _Segment(
          start: currentStart,
          end: endOffset,
          delimiterBefore: lastDelim,
        ),
      );
    }

    return segments;
  }

  int _skipWhitespace(String s, int start, int end) {
    while (start < end && s[start].trim().isEmpty) {
      start++;
    }
    return start;
  }

  int _trimTrailingWhitespace(String s, int start, int end) {
    while (end > start && s[end - 1].trim().isEmpty) {
      end--;
    }
    return end;
  }
}

class _Segment {
  final int start;
  final int end;
  final String? delimiterBefore;

  const _Segment({
    required this.start,
    required this.end,
    this.delimiterBefore,
  });
}
