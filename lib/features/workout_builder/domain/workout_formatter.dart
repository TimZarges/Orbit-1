import '../models/workout_builder_models.dart';

/// Formatter für [WorkoutStructure] in kanonischen Kurztext gemäß `WORKOUT_SYNTAX.md`.
class WorkoutFormatter {
  const WorkoutFormatter._();

  /// Formatiert eine gesamte [WorkoutStructure] in kanonischen Text.
  static String format(WorkoutStructure structure) {
    if (structure.blocks.isEmpty) return '';
    return structure.blocks
        .map((b) => _formatBlock(b, structure.sport))
        .join(', ');
  }

  /// Formatiert einen einzelnen Block (Step oder Repeat).
  static String _formatBlock(WorkoutBlock block, String sport) {
    if (block is StepBlock) {
      return _formatStep(block, sport);
    } else if (block is RepeatBlock) {
      return _formatRepeat(block, sport);
    }
    return '';
  }

  /// Formatiert einen Wiederholungsblock (z. B. `4x(4' Z4 / 2' Z1)`).
  static String _formatRepeat(RepeatBlock repeat, String sport) {
    if (repeat.blocks.isEmpty) {
      return '${repeat.count}x()';
    }

    final buffer = StringBuffer('${repeat.count}x(');
    for (int i = 0; i < repeat.blocks.length; i++) {
      final block = repeat.blocks[i];
      if (i > 0) {
        final isRest = block is StepBlock && block.role == WorkoutRole.rest;
        if (isRest) {
          buffer.write(' / ');
        } else {
          buffer.write(', ');
        }
      }
      buffer.write(_formatBlock(block, sport));
    }
    buffer.write(')');
    return buffer.toString();
  }

  /// Formatiert einen Einzelschritt.
  static String _formatStep(StepBlock step, String sport) {
    final buffer = StringBuffer();

    // 1. Ziel (Dauer oder Distanz)
    buffer.write(_formatTarget(step.target));

    // 2. Intensität
    final intensityStr = _formatIntensity(step.intensity);
    if (intensityStr.isNotEmpty) {
      buffer.write(' ');
      buffer.write(intensityStr);
    }

    // 3. Cadence (optional)
    if (step.cadence != null) {
      final unit = sport.toUpperCase() == 'RUN' ? 'spm' : 'rpm';
      buffer.write(' @');
      if (step.cadence!.low == step.cadence!.high) {
        buffer.write('${step.cadence!.low}$unit');
      } else {
        buffer.write('${step.cadence!.low}-${step.cadence!.high}$unit');
      }
    }

    // 4. Notiz (optional)
    if (step.note != null && step.note!.trim().isNotEmpty) {
      buffer.write(' [${step.note!.trim()}]');
    }

    return buffer.toString();
  }

  /// Formatiert das Ziel in Kurzschreibweise (`10'`, `30"`, `1h30'`, `400m`, `2km`).
  static String _formatTarget(WorkoutTarget target) {
    if (target.isDuration) {
      final sec = target.durationSec ?? 0;
      if (sec < 60) {
        return '$sec"';
      } else if (sec >= 3600) {
        final hours = sec ~/ 3600;
        final remainderMin = (sec % 3600) ~/ 60;
        if (remainderMin == 0) {
          return '${hours}h';
        }
        return '${hours}h${remainderMin}\'';
      } else if (sec % 60 == 0) {
        final min = sec ~/ 60;
        return '$min\'';
      } else {
        final min = sec ~/ 60;
        final remSec = sec % 60;
        return '$min\'$remSec"';
      }
    } else if (target.isDistance) {
      final m = target.distanceM ?? 0;
      if (m >= 1000 && m % 100 == 0) {
        final km = m / 1000.0;
        return km % 1 == 0 ? '${km.toInt()}km' : '${km.toStringAsFixed(1)}km';
      }
      return '${m}m';
    }
    return '';
  }

  /// Formatiert die Intensität in Kurzschreibweise.
  static String _formatIntensity(WorkoutIntensity intensity) {
    switch (intensity) {
      case final ZoneIntensity z:
        return z.low == z.high ? 'Z${z.low}' : 'Z${z.low}-Z${z.high}';
      case final PctFtpIntensity f:
        return f.low == f.high ? '${f.low}% FTP' : '${f.low}-${f.high}% FTP';
      case final PctLthrIntensity l:
        return l.low == l.high ? '${l.low}% LTHR' : '${l.low}-${l.high}% LTHR';
      case final PaceIntensity p:
        final min = p.secPerKm ~/ 60;
        final sec = p.secPerKm % 60;
        return '@$min:${sec.toString().padLeft(2, '0')}/km';
      case final SwimPaceIntensity s:
        final min = s.secPer100m ~/ 60;
        final sec = s.secPer100m % 60;
        return '@$min:${sec.toString().padLeft(2, '0')}/100m';
      case final CssOffsetIntensity c:
        if (c.offsetSecPer100m == 0) return 'CSS';
        if (c.offsetSecPer100m > 0) return 'CSS+${c.offsetSecPer100m}"';
        return 'CSS${c.offsetSecPer100m}"';
      case FreeIntensity _:
        return 'frei';
    }
  }
}
