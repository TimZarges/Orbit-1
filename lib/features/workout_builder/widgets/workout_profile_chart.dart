import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../domain/workout_calculator.dart';
import '../models/workout_builder_models.dart';

/// Flaches Segment für die grafische Profil-Darstellung.
class _VisualSegment {
  final int durationSec;
  final int zone;
  final String label;
  final WorkoutRole role;
  final int? repeatCount;
  final int? repeatGroupId;

  const _VisualSegment({
    required this.durationSec,
    required this.zone,
    required this.label,
    required this.role,
    this.repeatCount,
    this.repeatGroupId,
  });
}

/// Grafische Live-Profilansicht eines strukturierten Workouts (Balken in Zonenfarben).
class WorkoutProfileChart extends StatelessWidget {
  final WorkoutStructure? structure;
  final AthleteThresholds thresholds;
  final double height;
  final EdgeInsetsGeometry padding;

  const WorkoutProfileChart({
    super.key,
    required this.structure,
    this.thresholds = AthleteThresholds.empty,
    this.height = 130.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    if (structure == null || structure!.blocks.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cockpit.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'Keine Trainingsblöcke vorhanden',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    final segments = _buildVisualSegments(structure!);
    final totalDuration = segments.fold<int>(0, (sum, s) => sum + s.durationSec);

    return Semantics(
      label: 'Workout-Profil: ${structure!.sport}, $totalDuration Sekunden Gesamtdauer, ${segments.length} Intervalle',
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark cockpit background for high contrast
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.2)),
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: _WorkoutProfilePainter(
            segments: segments,
            totalDuration: math.max(1, totalDuration),
          ),
        ),
      ),
    );
  }

  List<_VisualSegment> _buildVisualSegments(WorkoutStructure s) {
    final list = <_VisualSegment>[];
    int groupCounter = 0;

    void expand(WorkoutBlock b, int? repeatCount, int? groupId) {
      if (b is StepBlock) {
        int duration = b.target.durationSec ?? 0;
        if (duration <= 0 && b.target.isDistance) {
          // Annahme für Distanz
          duration = ((b.target.distanceM ?? 100) / 100.0 * 90).round();
        }
        if (duration <= 0) duration = 60;

        final zone = _resolveZone(b.intensity);
        final label = _resolveLabel(b.intensity);

        list.add(
          _VisualSegment(
            durationSec: duration,
            zone: zone,
            label: label,
            role: b.role,
            repeatCount: repeatCount,
            repeatGroupId: groupId,
          ),
        );
      } else if (b is RepeatBlock) {
        final currentGroup = ++groupCounter;
        for (int i = 0; i < b.count; i++) {
          for (final child in b.blocks) {
            expand(child, b.count, currentGroup);
          }
        }
      }
    }

    for (final block in s.blocks) {
      expand(block, null, null);
    }

    return list;
  }

  int _resolveZone(WorkoutIntensity intensity) {
    switch (intensity) {
      case final ZoneIntensity z:
        return z.low.clamp(1, 7);
      case final PctFtpIntensity f:
        final avg = (f.low + f.high) / 2.0;
        if (avg < 55) return 1;
        if (avg <= 75) return 2;
        if (avg <= 90) return 3;
        if (avg <= 105) return 4;
        if (avg <= 120) return 5;
        if (avg <= 150) return 6;
        return 7;
      case final PctLthrIntensity l:
        final avg = (l.low + l.high) / 2.0;
        if (avg < 68) return 1;
        if (avg <= 83) return 2;
        if (avg <= 94) return 3;
        if (avg <= 105) return 4;
        return 5;
      case final CssOffsetIntensity c:
        if (c.offsetSecPer100m > 5) return 2;
        if (c.offsetSecPer100m > 0) return 3;
        if (c.offsetSecPer100m == 0) return 4;
        if (c.offsetSecPer100m >= -3) return 5;
        return 6;
      case final PaceIntensity _:
      case final SwimPaceIntensity _:
        return 4;
      case final FreeIntensity _:
        return 1;
    }
  }

  String _resolveLabel(WorkoutIntensity intensity) {
    switch (intensity) {
      case final ZoneIntensity z:
        return 'Z${z.low}';
      case final PctFtpIntensity f:
        return '${f.low}%';
      case final PctLthrIntensity l:
        return '${l.low}%';
      case final CssOffsetIntensity c:
        return c.offsetSecPer100m == 0 ? 'CSS' : '${c.offsetSecPer100m}s';
      case final PaceIntensity p:
        return '${p.secPerKm ~/ 60}:${(p.secPerKm % 60).toString().padLeft(2, '0')}';
      case final SwimPaceIntensity s:
        return '${s.secPer100m}s';
      case final FreeIntensity _:
        return 'Frei';
    }
  }
}

class _WorkoutProfilePainter extends CustomPainter {
  final List<_VisualSegment> segments;
  final int totalDuration;

  _WorkoutProfilePainter({
    required this.segments,
    required this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || size.width <= 0 || size.height <= 0) return;

    final basePaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.15);

    final baselineY = size.height - 4.0;
    final availableHeight = size.height - 18.0;

    // Horizontale Hilfslinien für Zonen
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;
    for (int z = 1; z <= 6; z++) {
      final y = baselineY - (z / 7.0 * availableHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Minimum sichtbare Breite für ultrakurze Intervalle (z. B. 15s)
    const minBarWidth = 4.0;
    double currentX = 0.0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final rawWidth = (seg.durationSec / totalDuration) * size.width;
      final barWidth = math.max(minBarWidth, rawWidth);

      // Höhe proportional zur Zone 1..7 (Z1 = 20%, Z7 = 100%)
      final zoneFraction = (seg.zone / 7.0).clamp(0.2, 1.0);
      final barHeight = zoneFraction * availableHeight;
      final topY = baselineY - barHeight;

      // Zonenfarbe
      basePaint.color = AppColors.zoneColor(seg.zone);

      final rect = Rect.fromLTWH(currentX, topY, barWidth - 1.0, barHeight);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );

      canvas.drawRRect(rrect, basePaint);
      canvas.drawRRect(rrect, strokePaint);

      // Textbeschriftung wenn ausreichend breit
      if (barWidth >= 22.0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: seg.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 2),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: barWidth);

        final textX = currentX + (barWidth - textPainter.width) / 2.0;
        final textY = topY + 4.0;
        if (textY + textPainter.height < baselineY) {
          textPainter.paint(canvas, Offset(textX, textY));
        }
      }

      currentX += barWidth;
      if (currentX >= size.width) break;
    }
  }

  @override
  bool shouldRepaint(covariant _WorkoutProfilePainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.totalDuration != totalDuration;
  }
}
