import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../domain/aggregates_calculator.dart';

/// 8-Wochen-Belastungstrend als performantes Balkendiagramm.
class WeeklyLoadTrendChart extends StatelessWidget {
  final List<WeeklyLoadTrendPoint> points;
  final String trendDescription;

  const WeeklyLoadTrendChart({
    super.key,
    required this.points,
    required this.trendDescription,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxLoad = points.map((p) => p.totalLoad).fold(0.0, max);
    final avgLoad = points.fold(0.0, (sum, p) => sum + p.totalLoad) / points.length;

    return Semantics(
      container: true,
      label: '8-Wochen-Belastungstrend: $trendDescription. Durchschnittliche Wochenbelastung: ${avgLoad.round()} TSS.',
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
            // Kopfzeile
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, size: 20, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Text(
                      '8-Wochen-Trend',
                      style: AppTypography.title.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
                Text(
                  'Ø ${avgLoad.round()} TSS',
                  style: AppTypography.label.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Balkendiagramm
            SizedBox(
              height: 140,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, 140),
                    painter: _WeeklyTrendPainter(
                      points: points,
                      maxLoad: maxLoad > 0 ? maxLoad * 1.15 : 100.0,
                      avgLoad: avgLoad,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Zugängliche Textzusammenfassung
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.techGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trendDescription,
                      style: AppTypography.label.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTrendPainter extends CustomPainter {
  final List<WeeklyLoadTrendPoint> points;
  final double maxLoad;
  final double avgLoad;

  _WeeklyTrendPainter({
    required this.points,
    required this.maxLoad,
    required this.avgLoad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final n = points.length;
    final chartHeight = size.height - 24; // Platz für Beschriftung unten
    final barWidth = (size.width / n) * 0.55;
    final step = size.width / n;

    final barPaint = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.fill;

    final activeBarPaint = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.fill;

    // Durchschnittslinie zeichnen
    if (avgLoad > 0 && maxLoad > 0) {
      final avgY = chartHeight - (avgLoad / maxLoad) * chartHeight;
      final linePaint = Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Gestrichelte Linie
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, avgY), Offset(min(x + 4, size.width), avgY), linePaint);
        x += 8;
      }
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < n; i++) {
      final point = points[i];
      final isLast = i == n - 1;
      final xCenter = (i + 0.5) * step;
      final barHeight = maxLoad > 0 ? (point.totalLoad / maxLoad) * chartHeight : 0.0;
      final topY = chartHeight - barHeight;

      // Balken mit abgerundeter Oberkante
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(xCenter - (barWidth / 2), topY, barWidth, barHeight),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      canvas.drawRRect(rect, isLast ? activeBarPaint : barPaint);

      // Wert über dem Balken
      if (point.totalLoad > 0) {
        textPainter.text = TextSpan(
          text: point.totalLoad.round().toString(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
            color: isLast ? AppColors.navy : Colors.grey.shade700,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(xCenter - (textPainter.width / 2), topY - textPainter.height - 2),
        );
      }

      // Label unter dem Balken
      textPainter.text = TextSpan(
        text: isLast ? 'Aktuell' : 'W${point.weekNumber}',
        style: TextStyle(
          fontSize: 9,
          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
          color: isLast ? AppColors.navy : Colors.grey.shade600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xCenter - (textPainter.width / 2), chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxLoad != maxLoad ||
        oldDelegate.avgLoad != avgLoad;
  }
}
