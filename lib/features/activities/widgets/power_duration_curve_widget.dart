import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/power_duration_curve.dart';

/// Interaktives Power-Duration-Kurven-Widget im Dark Cockpit.
///
/// Stellt die beste Wattleistung über logarithmisch skalierte Intervalle dar
/// (1s bis 60m) und vergleicht sie mit Saison- und Allzeit-Bestwerten.
class PowerDurationCurveWidget extends StatelessWidget {
  final PowerDurationCurve curve;

  const PowerDurationCurveWidget({
    super.key,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    if (curve.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxWatt = curve.points
        .map((p) =>
            [p.activityWatts, p.seasonBestWatts ?? 0, p.allTimeBestWatts ?? 0])
        .expand((e) => e)
        .fold(0.0, max);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit PR-Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart,
                      color: Color(0xFFF6C453), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Power-Duration-Kurve (MMP)',
                    style: AppTypography.title.copyWith(color: Colors.white),
                  ),
                ],
              ),
              if (curve.hasPR)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors
                        .accentVolt, // Volt-Regel: Volt-Fläche mit Navy-Text
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events,
                          size: 14, color: AppColors.navy),
                      const SizedBox(width: 4),
                      Text(
                        '${curve.prCount}x PR',
                        style: AppTypography.label.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Legende
          Row(
            children: [
              _buildLegend(const Color(0xFFF6C453), 'Diese Aktivität'),
              const SizedBox(width: 16),
              _buildLegend(const Color(0xFF22D3EE), 'Saison-Best'),
              const SizedBox(width: 16),
              _buildLegend(const Color(0xFF94A3B8), 'Allzeit-Best'),
            ],
          ),
          const SizedBox(height: 16),

          // Logarithmischer Kurven-Painter
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 160),
                  painter: _PowerDurationPainter(
                    curve: curve,
                    maxWatt: maxWatt > 0 ? maxWatt * 1.15 : 500.0,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Tabelle der Schlüsselwerte (5s, 1m, 5m, 20m)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: curve.points
                .where((p) => [5, 60, 300, 1200].contains(p.durationSec))
                .map((p) {
              return Column(
                children: [
                  Text(
                    p.formattedDuration,
                    style: AppTypography.label
                        .copyWith(color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.activityWatts.round()} W',
                    style: AppTypography.title.copyWith(
                      color: const Color(0xFFF6C453),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (p.isAllTimePR)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accentVolt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PR',
                        style: AppTypography.label.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
      ],
    );
  }
}

class _PowerDurationPainter extends CustomPainter {
  final PowerDurationCurve curve;
  final double maxWatt;

  _PowerDurationPainter({required this.curve, required this.maxWatt});

  @override
  void paint(Canvas canvas, Size size) {
    final points = curve.points;
    if (points.isEmpty) return;

    final w = size.width;
    final h = size.height - 20;

    // Logarithmische X-Skalierung
    final minLog = log(1.0);
    final maxLog = log(3600.0);

    double toX(int sec) {
      final l = log(max(1.0, sec.toDouble()));
      return ((l - minLog) / (maxLog - minLog)) * w;
    }

    double toY(double watt) {
      return h - (watt / maxWatt) * h;
    }

    // 1. Allzeit-Linie
    _drawPath(canvas, points, toX, toY, (p) => p.allTimeBestWatts,
        const Color(0xFF94A3B8), 1.0,
        isDashed: true);

    // 2. Saison-Linie
    _drawPath(canvas, points, toX, toY, (p) => p.seasonBestWatts,
        const Color(0xFF22D3EE), 1.5);

    // 3. Aktivitäts-Linie
    _drawPath(canvas, points, toX, toY, (p) => p.activityWatts,
        const Color(0xFFF6C453), 2.5);

    // X-Achsen-Labels
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelSecs = [1, 5, 30, 300, 1200, 3600];

    for (final sec in labelSecs) {
      final x = toX(sec);
      labelPainter.text = TextSpan(
        text: _formatShortSec(sec),
        style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(x - (labelPainter.width / 2), h + 4));
    }
  }

  void _drawPath(
    Canvas canvas,
    List<PowerDurationPoint> points,
    double Function(int) toX,
    double Function(double) toY,
    double? Function(PowerDurationPoint) getter,
    Color color,
    double strokeWidth, {
    bool isDashed = false,
  }) {
    final path = Path();
    bool started = false;

    for (final p in points) {
      final watt = getter(p);
      if (watt != null && watt > 0) {
        final x = toX(p.durationSec);
        final y = toY(watt);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  String _formatShortSec(int sec) {
    if (sec < 60) return '${sec}s';
    if (sec < 3600) return '${sec ~/ 60}m';
    return '${sec ~/ 3600}h';
  }

  @override
  bool shouldRepaint(covariant _PowerDurationPainter oldDelegate) {
    return oldDelegate.curve != curve || oldDelegate.maxWatt != maxWatt;
  }
}
