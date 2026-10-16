import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// Datenpunkt für ein Vitalwert-Trendchart
class VitalDataPoint {
  final DateTime date;
  final double value;
  final bool isMissing;

  const VitalDataPoint({
    required this.date,
    required this.value,
    this.isMissing = false,
  });
}

/// Karte mit Trendchart und 30-Tage-Normband (\mu \pm 1\sigma).
///
/// Kennzeichnet Werte außerhalb des statistischen 30-Tage-Bandes mit dem
/// neutralen sportwissenschaftlichen Hinweis „Außerhalb deines 30-Tage-Normbereichs“.
class VitalTrendChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final List<VitalDataPoint> points;
  final double baselineMean;
  final double baselineStd;
  final Color primaryColor;
  final bool lowerIsBetter; // z.B. für Ruhepuls
  final String? infoTooltip;

  const VitalTrendChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.points,
    required this.baselineMean,
    required this.baselineStd,
    this.primaryColor = AppColors.volt,
    this.lowerIsBetter = false,
    this.infoTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final validPoints =
        points.where((p) => !p.isMissing && p.value > 0).toList();
    final latestPoint = validPoints.isNotEmpty ? validPoints.last : null;
    final latestValue = latestPoint?.value;

    final bandMin = baselineMean - baselineStd;
    final bandMax = baselineMean + baselineStd;

    final isOutsideNorm = latestValue != null &&
        baselineStd > 0 &&
        (latestValue < bandMin || latestValue > bandMax);

    final statusText = isOutsideNorm
        ? 'Außerhalb deines 30-Tage-Normbereichs'
        : (latestValue != null ? 'Im 30-Tage-Normbereich' : 'Keine Daten');

    final statusColor = isOutsideNorm
        ? (lowerIsBetter && latestValue < bandMin
            ? AppColors.emerald
            : AppColors.amber)
        : AppColors.emerald;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.title.copyWith(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (infoTooltip != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: infoTooltip!,
                        child: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.techGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (latestValue != null)
                Text(
                  '${latestValue.toStringAsFixed(latestValue >= 10 ? 0 : 1)} $unit',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Normbereich & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  baselineStd > 0
                      ? 'Norm: ${bandMin.toStringAsFixed(1)} – ${bandMax.toStringAsFixed(1)} $unit (μ=${baselineMean.toStringAsFixed(1)})'
                      : 'Baseline wird aufgebaut...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Graph mit Normband
          SizedBox(
            height: 140,
            width: double.infinity,
            child: validPoints.length >= 2
                ? CustomPaint(
                    painter: _VitalNormBandChartPainter(
                      points: validPoints,
                      baselineMean: baselineMean,
                      bandMin: bandMin,
                      bandMax: bandMax,
                      lineColor: primaryColor,
                    ),
                  )
                : const Center(
                    child: Text(
                      'Nicht genügend Messpunkte für Trendchart',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VitalNormBandChartPainter extends CustomPainter {
  final List<VitalDataPoint> points;
  final double baselineMean;
  final double bandMin;
  final double bandMax;
  final Color lineColor;

  _VitalNormBandChartPainter({
    required this.points,
    required this.baselineMean,
    required this.bandMin,
    required this.bandMax,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    double minVal = points.map((p) => p.value).reduce(math.min);
    double maxVal = points.map((p) => p.value).reduce(math.max);

    if (bandMin > 0) minVal = math.min(minVal, bandMin);
    if (bandMax > 0) maxVal = math.max(maxVal, bandMax);

    // Padding oben/unten
    final valRange = (maxVal - minVal) <= 0 ? 1.0 : (maxVal - minVal);
    final yPad = valRange * 0.15;
    final yMin = math.max(0.0, minVal - yPad);
    final yMax = maxVal + yPad;

    double toY(double v) {
      final norm = (v - yMin) / (yMax - yMin);
      return size.height - (norm.clamp(0.0, 1.0) * size.height);
    }

    double toX(int index) {
      if (points.length <= 1) return size.width / 2;
      return (index / (points.length - 1)) * size.width;
    }

    // 1. 30-Tage Normband schattieren (\mu \pm 1\sigma)
    if (bandMin > 0 && bandMax > 0 && bandMax > bandMin) {
      final bandTopY = toY(bandMax);
      final bandBottomY = toY(bandMin);
      final bandPaint = Paint()
        ..color = const Color(0xFF334155).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(0, bandTopY, size.width, bandBottomY),
        bandPaint,
      );

      // Gestrichelte Mittellinie bei Mean \mu
      final meanY = toY(baselineMean);
      final meanLinePaint = Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, meanY),
          Offset(math.min(startX + 4, size.width), meanY),
          meanLinePaint,
        );
        startX += 8;
      }
    }

    // 2. Trendlinie
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = toX(i);
      final y = toY(points[i].value);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // 3. Datenpunkte zeichnen (Ausreißer farblich markieren)
    for (int i = 0; i < points.length; i++) {
      final val = points[i].value;
      final x = toX(i);
      final y = toY(val);

      final isOutside =
          (bandMin > 0 && bandMax > 0) && (val < bandMin || val > bandMax);

      final pointPaint = Paint()
        ..color = isOutside ? AppColors.coral : lineColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), isOutside ? 4.5 : 3.0, pointPaint);

      // Heller Kern für Lesbarkeit
      final innerPaint = Paint()
        ..color = AppColors.navy
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 1.5, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VitalNormBandChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.baselineMean != baselineMean ||
        oldDelegate.bandMin != bandMin ||
        oldDelegate.bandMax != bandMax ||
        oldDelegate.lineColor != lineColor;
  }
}
