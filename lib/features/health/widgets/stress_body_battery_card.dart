import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/daily_metrics.dart';

/// Karte für den Stress- und Body-Battery-Verlauf.
class StressBodyBatteryCard extends StatelessWidget {
  final DailyMetrics? todayMetrics;
  final List<DailyMetrics> history;

  const StressBodyBatteryCard({
    super.key,
    this.todayMetrics,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final bodyBattery = todayMetrics?.bodyBattery ?? 78;
    final stress = todayMetrics?.stress ?? 24;

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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.volt.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.battery_charging_full_rounded,
                        color: AppColors.volt,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Body Battery & Alltagsstress',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title.copyWith(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Autonomes Nervensystem & Energiereserven',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label.copyWith(
                              color: AppColors.techGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$bodyBattery %',
                        style: const TextStyle(
                          color: AppColors.volt,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Energie',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$stress / 100',
                        style: TextStyle(
                          color: stress > 50
                              ? AppColors.coral
                              : (stress > 30
                                  ? AppColors.amber
                                  : AppColors.emerald),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Stress',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Graph der letzten Tage
          SizedBox(
            height: 110,
            width: double.infinity,
            child: history.isNotEmpty
                ? CustomPaint(
                    painter: _StressBatteryPainter(history: history),
                  )
                : const Center(
                    child: Text(
                      'Keine Daten verfügbar',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Legende
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.volt,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Body Battery',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Stresslevel',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StressBatteryPainter extends CustomPainter {
  final List<DailyMetrics> history;

  _StressBatteryPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final count = history.length;
    double toX(int index) {
      if (count <= 1) return size.width / 2;
      return (index / (count - 1)) * size.width;
    }

    double toY(double val) {
      final norm = val.clamp(0.0, 100.0) / 100.0;
      return size.height - (norm * size.height);
    }

    // Grid Linien bei 25, 50, 75
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;
    for (final level in [25.0, 50.0, 75.0]) {
      final y = toY(level);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 1. Body Battery Pfad
    final bbPaint = Paint()
      ..color = AppColors.volt
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bbPath = Path();
    bool bbStarted = false;
    for (int i = 0; i < count; i++) {
      final bb = history[i].bodyBattery?.toDouble() ?? 75.0;
      final x = toX(i);
      final y = toY(bb);
      if (!bbStarted) {
        bbPath.moveTo(x, y);
        bbStarted = true;
      } else {
        bbPath.lineTo(x, y);
      }
    }
    canvas.drawPath(bbPath, bbPaint);

    // 2. Stress Pfad
    final stressPaint = Paint()
      ..color = AppColors.coral.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stressPath = Path();
    bool stressStarted = false;
    for (int i = 0; i < count; i++) {
      final st = history[i].stress?.toDouble() ?? 25.0;
      final x = toX(i);
      final y = toY(st);
      if (!stressStarted) {
        stressPath.moveTo(x, y);
        stressStarted = true;
      } else {
        stressPath.lineTo(x, y);
      }
    }
    canvas.drawPath(stressPath, stressPaint);
  }

  @override
  bool shouldRepaint(covariant _StressBatteryPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
