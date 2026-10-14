import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/zone_distribution.dart';

/// Karte für die Intensitätszonen-Verteilung (Z1 bis Z7).
class ZoneDistributionCard extends StatelessWidget {
  final ZoneDistributionSummary summary;

  const ZoneDistributionCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.zones.isEmpty || summary.totalDurationSec <= 0) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      label:
          'Zonenverteilung: ${summary.zones.map((z) => '${z.zoneLabel} ${z.nameDe}: ${z.percent.round()} %').join(', ')}',
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
                    Icon(Icons.bar_chart, size: 20, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Text(
                      'Zonenverteilung',
                      style:
                          AppTypography.title.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
                Text(
                  'Gesamt ${_formatTotal(summary.totalDurationSec)}',
                  style:
                      AppTypography.label.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Gestapelte Zonenübersicht oben
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: summary.zones.map((zone) {
                    if (zone.percent <= 0) return const SizedBox.shrink();
                    return Flexible(
                      flex: (zone.percent * 10).round().clamp(1, 1000),
                      child: Container(
                        color: zone.color,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detailzeilen je Zone
            Column(
              children: summary.zones.map((zone) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Zonenkürzel (Z1..Z7) mit Farbe
                      Container(
                        width: 32,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: zone.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: zone.color),
                        ),
                        child: Text(
                          zone.zoneLabel,
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Zonenname
                      SizedBox(
                        width: 90,
                        child: Text(
                          zone.nameDe,
                          style: AppTypography.label.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Prozent-Balken
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final barW =
                                (w * (zone.percent / 100)).clamp(0.0, w);
                            return Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBorder
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                if (barW > 0)
                                  Container(
                                    height: 8,
                                    width: barW,
                                    decoration: BoxDecoration(
                                      color: zone.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Dauer & Prozent
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${zone.formattedDuration} (${zone.percent.round()}%)',
                          textAlign: TextAlign.end,
                          style: AppTypography.label.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
