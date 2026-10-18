import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/threshold_entry.dart';
import '../models/threshold_proposal.dart';

/// Diagramm zur Darstellung des Schwellenwert-Verlaufs über die Zeit.
class ThresholdHistoryChart extends StatelessWidget {
  final List<ThresholdEntry> entries;
  final ThresholdType type;

  const ThresholdHistoryChart({
    super.key,
    required this.entries,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // Filtere relevante Datenpunkte
    final validPoints = <_HistoryPoint>[];
    for (final entry in entries) {
      double? val;
      switch (type) {
        case ThresholdType.ftp:
          val = entry.ftpW;
          break;
        case ThresholdType.lthr:
          val = entry.thresholdHrBpm;
          break;
        case ThresholdType.thresholdPace:
          val = entry.runThresholdPaceSecPerKm;
          break;
        case ThresholdType.css:
          val = entry.swimCssSecPer100m;
          break;
      }

      if (val != null && val > 0) {
        validPoints.add(_HistoryPoint(date: entry.effectiveFrom, value: val));
      }
    }

    if (validPoints.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF003875)),
        ),
        child: Text(
          'Noch keine historischen Daten für diesen Schwellenwert erfasst.',
          style: AppTypography.label.copyWith(color: Colors.white60),
        ),
      );
    }

    // Min und Max berechnen
    double minY = validPoints.first.value;
    double maxY = validPoints.first.value;
    for (final p in validPoints) {
      if (p.value < minY) minY = p.value;
      if (p.value > maxY) maxY = p.value;
    }

    // Puffer oben und unten
    final yRange = (maxY - minY).abs();
    final paddingY = yRange == 0 ? 10.0 : yRange * 0.2;
    minY -= paddingY;
    maxY += paddingY;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF003875)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entwicklung',
                style: AppTypography.title.copyWith(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '${validPoints.length} Einträge',
                style: AppTypography.label.copyWith(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _HistoryChartPainter(
                points: validPoints,
                minY: minY,
                maxY: maxY,
                type: type,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Datumsanzeige (Start und Ende)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                validPoints.first.date,
                style: AppTypography.label
                    .copyWith(fontSize: 11, color: Colors.white60),
              ),
              Text(
                validPoints.last.date,
                style: AppTypography.label
                    .copyWith(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryPoint {
  final String date;
  final double value;

  _HistoryPoint({required this.date, required this.value});
}

class _HistoryChartPainter extends CustomPainter {
  final List<_HistoryPoint> points;
  final double minY;
  final double maxY;
  final ThresholdType type;

  _HistoryChartPainter({
    required this.points,
    required this.minY,
    required this.maxY,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = AppColors.volt
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = const Color(0xFF003875)
      ..strokeWidth = 1.0;

    final pointPaint = Paint()
      ..color = AppColors.volt
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Horizontale Hilfslinien
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double xStep =
        points.length > 1 ? size.width / (points.length - 1) : 0;
    final path = Path();
    final pointOffsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width / 2 : i * xStep;
      final normalizedY =
          (points[i].value - minY) / (maxY - minY == 0 ? 1 : (maxY - minY));
      final y = size.height - (normalizedY * size.height);
      final offset = Offset(x, y.clamp(8, size.height - 8));
      pointOffsets.add(offset);

      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    // Punkte zeichnen
    for (final offset in pointOffsets) {
      canvas.drawCircle(offset, 5, pointPaint);
      canvas.drawCircle(offset, 5, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY;
  }
}
