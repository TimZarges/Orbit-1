import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../activities/models/activity.dart';

/// Karte für die zuletzt absolvierte Trainingseinheit mit Direktzugriff auf das Analyse-Cockpit.
class HomeRecentActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onOpenCockpit;

  const HomeRecentActivityCard({
    super.key,
    required this.activity,
    required this.onOpenCockpit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.techGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getSportIcon(activity.sport), size: 18, color: AppColors.navy),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Letzte Trainingseinheit',
                    style: AppTypography.label.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
              Text(
                activity.localDate,
                style: AppTypography.label.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Titel
          Text(
            activity.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title.copyWith(fontSize: 16, color: AppColors.navy),
          ),
          const SizedBox(height: 12),

          // Metrik-Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Dauer', value: _formatDuration(activity.durationSec)),
              if (activity.distanceM > 0)
                _StatItem(label: 'Distanz', value: _formatDistance(activity.sport, activity.distanceM)),
              if (activity.summary?.avgPowerW != null && activity.summary!.avgPowerW! > 0)
                _StatItem(label: 'Ø Leistung', value: '${activity.summary!.avgPowerW!.round()} W'),
              if (activity.summary?.avgHr != null && activity.summary!.avgHr! > 0)
                _StatItem(label: 'Ø Puls', value: '${activity.summary!.avgHr!.round()} bpm'),
            ],
          ),
          const SizedBox(height: 14),

          // Cockpit CTA-Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenCockpit,
              icon: const Icon(Icons.analytics_outlined, size: 16),
              label: const Text('Im Analyse-Cockpit öffnen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: BorderSide(color: AppColors.navy.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatDuration(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m min';
  }

  String _formatDistance(String sport, double distanceM) {
    if (sport.toUpperCase() == 'SWIM') return '${distanceM.round()} m';
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.label.copyWith(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy)),
      ],
    );
  }
}
