import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/sport_distribution.dart';

/// Karte für die Sportarten-Verteilung (horizontaler Balken statt Torte).
class SportDistributionCard extends StatelessWidget {
  final SportDistributionSummary summary;

  const SportDistributionCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      label: 'Sportarten-Verteilung: ${summary.items.map((i) => '${i.labelDe}: ${i.formattedDuration} (${i.percent.round()} %)').join(', ')}',
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
              children: [
                Icon(Icons.pie_chart_outline, size: 20, color: AppColors.navy),
                const SizedBox(width: 8),
                Text(
                  'Sportverteilung',
                  style: AppTypography.title.copyWith(color: AppColors.navy),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Horizontaler Stapelbalken
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: summary.items.map((item) {
                    return Flexible(
                      flex: (item.percent * 10).round().clamp(1, 1000),
                      child: Container(
                        color: item.color,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legende und Detail-Zeilen
            Column(
              children: summary.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Icon mit Farbkreis
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 16, color: item.color),
                      ),
                      const SizedBox(width: 10),

                      // Sportart-Name
                      Expanded(
                        child: Text(
                          item.labelDe,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),

                      // Dauer
                      Text(
                        item.formattedDuration,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Prozent
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${item.percent.round()} %',
                          textAlign: TextAlign.end,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
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
}
