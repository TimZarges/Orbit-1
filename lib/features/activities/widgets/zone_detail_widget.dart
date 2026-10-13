import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../analysis/models/zone_distribution.dart';

/// Detaillierte Zonenverteilung für das Analyse-Cockpit.
class ZoneDetailWidget extends StatelessWidget {
  final String title;
  final ZoneDistributionSummary summary;

  const ZoneDetailWidget({
    super.key,
    required this.title,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.zones.isEmpty || summary.totalDurationSec <= 0) {
      return const SizedBox.shrink();
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.title.copyWith(color: Colors.white, fontSize: 16)),
              Text(
                'Gesamt ${_formatTotal(summary.totalDurationSec)}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Gestapelter Balken
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: summary.zones.map((z) {
                  if (z.percent <= 0) return const SizedBox.shrink();
                  return Flexible(
                    flex: (z.percent * 10).round().clamp(1, 1000),
                    child: Container(color: z.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Zeilen je Zone
          Column(
            children: summary.zones.map((zone) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: zone.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        zone.zoneLabel,
                        style: TextStyle(color: zone.color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        zone.nameDe,
                        style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                      ),
                    ),
                    Text(
                      '${zone.formattedDuration} (${zone.percent.round()}%)',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTotal(double sec) {
    final h = (sec / 3600).floor();
    final m = ((sec % 3600) / 60).round();
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
