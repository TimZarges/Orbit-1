import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../domain/aggregates_calculator.dart';

/// Linienchart für CTL, ATL und TSB (Experten-Ansicht).
class FitnessFatigueTrendChart extends StatelessWidget {
  final List<FitnessFatiguePoint> points;

  const FitnessFatigueTrendChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest = points.last;
    final maxVal = points.map((p) => max(p.ctl, p.atl)).fold(0.0, max);
    final minTsb = points.map((p) => p.tsb).fold(0.0, min);
    final maxTsb = points.map((p) => p.tsb).fold(0.0, max);

    final semanticDesc = 'Verlauf: Fitness (CTL) bei ${latest.ctl.round()}, '
        'Ermüdung (ATL) bei ${latest.atl.round()}, '
        'Frische (TSB) bei ${latest.tsb.round()}.';

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
            // Kopfzeile mit Legende
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline, size: 20, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Text(
                      'CTL / ATL / TSB Verlauf',
                      style:
                          AppTypography.title.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Legende mit aktuellen Werten
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(
                  color: AppColors.navy,
                  label: 'CTL ${latest.ctl.round()}',
                ),
                _LegendItem(
                  color: const Color(0xFFDD6B20), // Amber
                  label: 'ATL ${latest.atl.round()}',
                ),
                _LegendItem(
                  color: const Color(0xFF0EA5E9), // Cyan / Frische
                  label:
                      'TSB ${(latest.tsb >= 0 ? "+${latest.tsb.round()}" : latest.tsb.round().toString())}',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Linienchart
            SizedBox(
              height: 150,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, 150),
                    painter: _FitnessFatiguePainter(
                      points: points,
                      maxVal: maxVal > 0 ? maxVal * 1.15 : 100.0,
                      minTsb: minTsb,
                      maxTsb: maxTsb,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Barrierefreier Text
            Text(
              semanticDesc,
              style: AppTypography.label.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
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

  _FitnessFatiguePainter({
    required this.points,
    required this.maxVal,
    required this.minTsb,
    required this.maxTsb,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final n = points.length;
    final w = size.width;
    final h = size.height;

    // Horizontale Null-Linie für TSB (in der Mitte / im unteren Drittel)
    final zeroY = h * 0.75;
    final zeroPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, zeroY), Offset(w, zeroY), zeroPaint);

    final ctlPath = Path();
    final atlPath = Path();
    final tsbPath = Path();

    final stepX = w / (n - 1);

    for (int i = 0; i < n; i++) {
      final p = points[i];
      final x = i * stepX;

      // CTL Skalierung: 0 bis maxVal über obere 75%
      final ctlY = zeroY - (p.ctl / maxVal) * (zeroY - 10);
      // ATL Skalierung
      final atlY = zeroY - (p.atl / maxVal) * (zeroY - 10);
      // TSB Skalierung: um die Null-Linie
      final tsbY = zeroY - (p.tsb / (maxVal * 0.5)) * 30;

      if (i == 0) {
        ctlPath.moveTo(x, ctlY.clamp(0.0, h));
        atlPath.moveTo(x, atlY.clamp(0.0, h));
        tsbPath.moveTo(x, tsbY.clamp(0.0, h));
      } else {
        ctlPath.lineTo(x, ctlY.clamp(0.0, h));
        atlPath.lineTo(x, atlY.clamp(0.0, h));
        tsbPath.lineTo(x, tsbY.clamp(0.0, h));
      }
    }

    // TSB Linie (Cyan)
    final tsbPaint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(tsbPath, tsbPaint);

    // ATL Linie (Orange)
    final atlPaint = Paint()
      ..color = const Color(0xFFDD6B20)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(atlPath, atlPaint);

    // CTL Linie (Deep Navy)
    final ctlPaint = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(ctlPath, ctlPaint);
  }

  @override
  bool shouldRepaint(covariant _FitnessFatiguePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.maxVal != maxVal;
  }
}
