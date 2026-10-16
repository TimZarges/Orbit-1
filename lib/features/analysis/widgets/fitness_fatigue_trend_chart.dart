import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../domain/aggregates_calculator.dart';

/// Interaktiver Performance Management Chart (PMC) nach Banister.
///
/// Features:
/// - CTL (Fitness, Cyan #00D2FF)
/// - ATL (Ermüdung, Amber #FF6B00)
/// - TSB (Form, Emerald #10B981 mit schattierter Fläche zur Nulllinie)
/// - 7-Tage-Ramp-Rate-Anzeige inkl. Überlastungswarnung bei > 7 TSS/Woche
/// - 14-Tage-Zukunftsprojektion mit gestrichelten Linien
class FitnessFatigueTrendChart extends StatefulWidget {
  final List<FitnessFatiguePoint> points;

  const FitnessFatigueTrendChart({
    super.key,
    required this.points,
  });

  @override
  State<FitnessFatigueTrendChart> createState() =>
      _FitnessFatigueTrendChartState();
}

class _FitnessFatigueTrendChartState extends State<FitnessFatigueTrendChart> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SizedBox.shrink();
    }

    // Heutiger bzw. aktuellster historischer Punkt (vor der Projektion)
    final historicalPoints =
        widget.points.where((p) => !p.isProjection).toList();
    final latestHistorical = historicalPoints.isNotEmpty
        ? historicalPoints.last
        : widget.points.first;

    // 7-Tage-Ramp-Rate berechnen (CTL heute - CTL vor 7 Tagen)
    double rampRate = 0.0;
    if (historicalPoints.length >= 8) {
      final ctlToday = latestHistorical.ctl;
      final ctlWeekAgo = historicalPoints[historicalPoints.length - 8].ctl;
      rampRate = ctlToday - ctlWeekAgo;
    } else if (historicalPoints.length > 1) {
      rampRate = latestHistorical.ctl - historicalPoints.first.ctl;
    }

    final isOverload = rampRate > 7.0;

    // Aktiver Punkt für HUD (Hover oder neuester historischer Wert)
    final activeIndex = _hoverIndex ??
        (historicalPoints.isNotEmpty ? historicalPoints.length - 1 : 0);
    final activePoint =
        widget.points[activeIndex.clamp(0, widget.points.length - 1)];

    final maxVal = widget.points.map((p) => max(p.ctl, p.atl)).fold(0.0, max);
    final minTsb = widget.points.map((p) => p.tsb).fold(0.0, min);
    final maxTsb = widget.points.map((p) => p.tsb).fold(0.0, max);

    final semanticDesc =
        'PMC-Verlauf: Fitness (CTL) bei ${latestHistorical.ctl.round()}, '
        'Ermüdung (ATL) bei ${latestHistorical.atl.round()}, '
        'Form (TSB) bei ${latestHistorical.tsb.round()}, '
        '7-Tage-Ramp-Rate: ${rampRate >= 0 ? "+" : ""}${rampRate.toStringAsFixed(1)} TSS/Woche.';

    return Semantics(
      container: true,
      label: semanticDesc,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart,
                        size: 20, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Text(
                      'Performance Management (PMC)',
                      style:
                          AppTypography.title.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
                // Ramp-Rate Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOverload
                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                        : (rampRate > 5.0
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : const Color(0xFF10B981).withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOverload
                          ? const Color(0xFFEF4444)
                          : (rampRate > 5.0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981)),
                    ),
                  ),
                  child: Text(
                    'Ramp-Rate: ${rampRate >= 0 ? "+" : ""}${rampRate.toStringAsFixed(1)}/Wo',
                    style: TextStyle(
                      color: isOverload
                          ? const Color(0xFFEF4444)
                          : (rampRate > 5.0
                              ? const Color(0xFFB45309)
                              : const Color(0xFF047857)),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Überlastungswarnung bei Ramp-Rate > 7
            if (isOverload) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Überlastungswarnung: Wöchentlicher Fitness-Zuwachs > 7 TSS/Woche erhöht das Verletzungsrisiko.',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Legende & Hover-Werte
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(
                  color: const Color(0xFF00D2FF), // Cyan
                  label: 'Fitness (CTL) ${activePoint.ctl.round()}',
                ),
                _LegendItem(
                  color: const Color(0xFFFF6B00), // Amber
                  label: 'Ermüdung (ATL) ${activePoint.atl.round()}',
                ),
                _LegendItem(
                  color: const Color(0xFF10B981), // Emerald
                  label:
                      'Form (TSB) ${activePoint.tsb >= 0 ? "+" : ""}${activePoint.tsb.round()}',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chart mit Gesten-Erkennung
            SizedBox(
              height: 160,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onHorizontalDragUpdate: (d) {
                      final frac = (d.localPosition.dx / constraints.maxWidth)
                          .clamp(0.0, 1.0);
                      final idx = (frac * (widget.points.length - 1)).round();
                      setState(() => _hoverIndex = idx);
                    },
                    onHorizontalDragEnd: (_) =>
                        setState(() => _hoverIndex = null),
                    onTapDown: (d) {
                      final frac = (d.localPosition.dx / constraints.maxWidth)
                          .clamp(0.0, 1.0);
                      final idx = (frac * (widget.points.length - 1)).round();
                      setState(() => _hoverIndex = idx);
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 160),
                      painter: _FitnessFatiguePainter(
                        points: widget.points,
                        maxVal: maxVal > 0 ? maxVal * 1.15 : 100.0,
                        minTsb: minTsb,
                        maxTsb: maxTsb,
                        hoverIndex: _hoverIndex,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Projektions-Hinweis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestrichelte Linie = 14-Tage-Projektion aus geplanten Workouts',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (_hoverIndex != null)
                  Text(
                    '${activePoint.date}${activePoint.isProjection ? " (Prognose)" : ""}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FitnessFatiguePainter extends CustomPainter {
  final List<FitnessFatiguePoint> points;
  final double maxVal;
  final double minTsb;
  final double maxTsb;
  final int? hoverIndex;

  _FitnessFatiguePainter({
    required this.points,
    required this.maxVal,
    required this.minTsb,
    required this.maxTsb,
    this.hoverIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final n = points.length;
    final w = size.width;
    final h = size.height;

    final zeroY = h * 0.72;
    final zeroPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, zeroY), Offset(w, zeroY), zeroPaint);

    final stepX = w / (n - 1);

    // 1. TSB Fläche zur Nulllinie (Grün über 0, Rötlich unter 0)
    for (int i = 0; i < n - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final x1 = i * stepX;
      final x2 = (i + 1) * stepX;
      final y1 = zeroY - (p1.tsb / (maxVal * 0.5)) * 28;
      final y2 = zeroY - (p2.tsb / (maxVal * 0.5)) * 28;

      final tsbAreaPath = Path()
        ..moveTo(x1, zeroY)
        ..lineTo(x1, y1.clamp(0.0, h))
        ..lineTo(x2, y2.clamp(0.0, h))
        ..lineTo(x2, zeroY)
        ..close();

      final avgTsb = (p1.tsb + p2.tsb) / 2.0;
      final areaPaint = Paint()
        ..color = avgTsb >= 0
            ? const Color(0xFF10B981)
                .withValues(alpha: p1.isProjection ? 0.08 : 0.20)
            : const Color(0xFFEF4444)
                .withValues(alpha: p1.isProjection ? 0.06 : 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawPath(tsbAreaPath, areaPaint);
    }

    // 2. Linienpfade für historisch vs. projiziert trennen
    _drawMetricLine(
      canvas: canvas,
      stepX: stepX,
      zeroY: zeroY,
      h: h,
      color: const Color(0xFF10B981), // Emerald TSB
      strokeWidth: 2.0,
      scaleY: (p) => zeroY - (p.tsb / (maxVal * 0.5)) * 28,
    );

    _drawMetricLine(
      canvas: canvas,
      stepX: stepX,
      zeroY: zeroY,
      h: h,
      color: const Color(0xFFFF6B00), // Amber ATL
      strokeWidth: 2.0,
      scaleY: (p) => zeroY - (p.atl / maxVal) * (zeroY - 10),
    );

    _drawMetricLine(
      canvas: canvas,
      stepX: stepX,
      zeroY: zeroY,
      h: h,
      color: const Color(0xFF00D2FF), // Cyan CTL
      strokeWidth: 2.5,
      scaleY: (p) => zeroY - (p.ctl / maxVal) * (zeroY - 10),
    );

    // 3. Markierung "Heute" (Übergang zu Projektion)
    final projectionIndex = points.indexWhere((p) => p.isProjection);
    if (projectionIndex > 0) {
      final projX = projectionIndex * stepX;
      final todayPaint = Paint()
        ..color = AppColors.navy.withValues(alpha: 0.4)
        ..strokeWidth = 1.0;
      _drawDashedLine(canvas, Offset(projX, 0), Offset(projX, h), todayPaint);
    }

    // 4. Hover Indikator
    if (hoverIndex != null && hoverIndex! < n) {
      final hx = hoverIndex! * stepX;
      final hoverPaint = Paint()
        ..color = AppColors.navy
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(hx, 0), Offset(hx, h), hoverPaint);
    }
  }

  void _drawMetricLine({
    required Canvas canvas,
    required double stepX,
    required double zeroY,
    required double h,
    required Color color,
    required double strokeWidth,
    required double Function(FitnessFatiguePoint) scaleY,
  }) {
    final solidPath = Path();
    final dashedPath = Path();

    bool solidStarted = false;
    bool dashedStarted = false;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = i * stepX;
      final y = scaleY(p).clamp(0.0, h);

      if (!p.isProjection) {
        if (!solidStarted) {
          solidPath.moveTo(x, y);
          solidStarted = true;
        } else {
          solidPath.lineTo(x, y);
        }
      } else {
        // Verbinde letzten historischen Punkt mit dem ersten projizierten
        if (!dashedStarted) {
          final prevX = (i - 1) * stepX;
          final prevY = scaleY(points[i - 1]).clamp(0.0, h);
          dashedPath.moveTo(prevX, prevY);
          dashedPath.lineTo(x, y);
          dashedStarted = true;
        } else {
          dashedPath.lineTo(x, y);
        }
      }
    }

    // Durchgezogene historische Linie
    final solidPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(solidPath, solidPaint);

    // Gestrichelte Zukunftsprojektion
    if (dashedStarted) {
      final dashPaint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      _drawDashedPath(canvas, dashedPath, dashPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLength = 4.0;
    const spaceLength = 3.0;
    final totalDistance = (p2 - p1).distance;
    final unitVector = (p2 - p1) / totalDistance;

    double current = 0.0;
    while (current < totalDistance) {
      final start = p1 + unitVector * current;
      final end = p1 + unitVector * min(current + dashLength, totalDistance);
      canvas.drawLine(start, end, paint);
      current += dashLength + spaceLength;
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    const dashLength = 5.0;
    const spaceLength = 3.5;

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final extractLength = min(dashLength, metric.length - distance);
        final extracted =
            metric.extractPath(distance, distance + extractLength);
        canvas.drawPath(extracted, paint);
        distance += dashLength + spaceLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FitnessFatiguePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.maxVal != maxVal;
  }
}
