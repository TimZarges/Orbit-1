import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/daily_metrics.dart';

/// Kompakte Wochen- und Monatsbericht-Karte für die Health- & Recovery-Entwicklung.
class HealthReportCard extends StatelessWidget {
  final List<DailyMetrics> metrics;
  final String title;

  const HealthReportCard({
    super.key,
    required this.metrics,
    this.title = 'Wochenbericht (Letzte 7 Tage)',
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgRecovery =
        _avg(metrics.map((m) => m.effectiveRecoveryScore)).round();
    final avgStrain = _avg(metrics.map((m) => m.effectiveStrainScore)).round();
    final avgSleepScore =
        _avg(metrics.map((m) => m.effectiveSleepScore)).round();
    final totalSleepDebtMin = metrics
        .map((m) => m.sleepScoreData?.debtMinutes ?? 0)
        .fold<int>(0, (int a, int b) => a + b);

    final greenDays =
        metrics.where((m) => m.recoveryTrafficLight == 'GREEN').length;
    final yellowDays =
        metrics.where((m) => m.recoveryTrafficLight == 'YELLOW').length;
    final redDays =
        metrics.where((m) => m.recoveryTrafficLight == 'RED').length;

    final avgRhr =
        _avg(metrics.map((m) => m.restingHrBpm).whereType<int>()).round();
    final avgHrv = _avg(metrics.map((m) => m.hrvMs).whereType<int>()).round();

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
              Text(
                title,
                style: AppTypography.title.copyWith(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${metrics.length} Tage',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.techGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Kern-Durchschnitte
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Ø Erholung',
                  value: '$avgRecovery %',
                  valueColor: avgRecovery >= 66
                      ? AppColors.emerald
                      : (avgRecovery >= 34 ? AppColors.amber : AppColors.coral),
                  icon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Ø Belastung',
                  value: '$avgStrain',
                  valueColor: AppColors.amber,
                  icon: Icons.bolt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Ø Schlaf',
                  value: '$avgSleepScore %',
                  valueColor: const Color(0xFF38BDF8),
                  icon: Icons.bedtime_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ampeltage-Verteilung
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrafficLightCounter(
                  label: 'Grün',
                  count: greenDays,
                  color: AppColors.emerald,
                ),
                Container(width: 1, height: 28, color: const Color(0xFF334155)),
                _buildTrafficLightCounter(
                  label: 'Gelb',
                  count: yellowDays,
                  color: AppColors.amber,
                ),
                Container(width: 1, height: 28, color: const Color(0xFF334155)),
                _buildTrafficLightCounter(
                  label: 'Rot',
                  count: redDays,
                  color: AppColors.coral,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Vitalwerte & Schlafschuld
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ø Ruhepuls: ${avgRhr > 0 ? "$avgRhr bpm" : "–"} · Ø HRV: ${avgHrv > 0 ? "$avgHrv ms" : "–"}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              if (totalSleepDebtMin > 0)
                Text(
                  'Schlafschuld: ${totalSleepDebtMin ~/ 60}h ${totalSleepDebtMin % 60}m',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: valueColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficLightCounter({
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _avg(Iterable<num> values) {
    if (values.isEmpty) return 0;
    double sum = 0;
    int count = 0;
    for (final v in values) {
      sum += v;
      count++;
    }
    return count > 0 ? sum / count : 0;
  }
}
