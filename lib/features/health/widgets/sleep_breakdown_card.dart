import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/daily_metrics.dart';

/// Karte zur Visualisierung von Schlaf-Score, Schlafphasen, Schlafbedarf und Schlafschuld.
class SleepBreakdownCard extends StatelessWidget {
  final DailyMetrics? todayMetrics;

  const SleepBreakdownCard({
    super.key,
    this.todayMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final sleepSec = todayMetrics?.effectiveSleepSeconds ?? 27000;
    final totalHours = sleepSec / 3600;
    final sleepScore = todayMetrics?.effectiveSleepScore ?? 82;

    final scoreData = todayMetrics?.sleepScoreData;
    final deepSec = todayMetrics?.deepSleepSeconds ?? (sleepSec * 0.22).round();
    final remSec = todayMetrics?.remSleepSeconds ?? (sleepSec * 0.24).round();
    final awakeSec =
        todayMetrics?.awakeSleepSeconds ?? (sleepSec * 0.06).round();
    final lightSec = (sleepSec - deepSec - remSec).clamp(0, sleepSec);

    final debtMin = scoreData?.debtMinutes ?? 20;
    final neededSec = scoreData?.neededSeconds ?? (8.0 * 3600).round();

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bedtime_outlined,
                      color: Color(0xFF38BDF8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schlaf & Phasenanalyse',
                        style: AppTypography.title.copyWith(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qualität, Tiefschlafanteil & Erholungsphasen',
                        style: AppTypography.label.copyWith(
                          color: AppColors.techGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sleepScore %',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${totalHours.toStringAsFixed(1)} Std.',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Phasen-Balken
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: deepSec,
                    child:
                        Container(color: const Color(0xFF1E3A8A)), // Deep Blue
                  ),
                  Expanded(
                    flex: remSec,
                    child: Container(
                        color: const Color(0xFF6366F1)), // Indigo / REM
                  ),
                  Expanded(
                    flex: lightSec,
                    child:
                        Container(color: const Color(0xFF38BDF8)), // Light Blue
                  ),
                  Expanded(
                    flex: awakeSec,
                    child: Container(
                        color: const Color(0xFFEF4444)), // Red / Awake
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Phasen-Legende
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPhaseItem('Tiefschlaf', deepSec, const Color(0xFF1E3A8A)),
              _buildPhaseItem('REM', remSec, const Color(0xFF6366F1)),
              _buildPhaseItem('Leicht', lightSec, const Color(0xFF38BDF8)),
              _buildPhaseItem('Wach', awakeSec, const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 14),

          // Schlafbedarf & Schuld
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Schlafbedarf',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(neededSec / 3600).toStringAsFixed(1)} Std.',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Aktuelle Schlafschuld',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    debtMin > 0 ? '$debtMin min' : '0 min (Ausgeglichen)',
                    style: TextStyle(
                      color: debtMin > 45
                          ? AppColors.coral
                          : (debtMin > 20
                              ? AppColors.amber
                              : AppColors.emerald),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseItem(String label, int seconds, Color color) {
    final m = seconds ~/ 60;
    final h = m ~/ 60;
    final remM = m % 60;
    final timeStr = h > 0 ? '${h}h ${remM}m' : '${remM}m';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
            Text(
              timeStr,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
