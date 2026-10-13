import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/consistency_summary.dart';

/// Karte für Trainingskonsistenz und Regelmäßigkeit.
class ConsistencyCard extends StatelessWidget {
  final ConsistencySummary consistency;

  const ConsistencyCard({
    super.key,
    required this.consistency,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Konsistenz: ${consistency.statusTextDe}. Serie: ${consistency.streakWeeks} Wochen.',
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
                    Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Text(
                      'Konsistenz',
                      style: AppTypography.title.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
                if (consistency.streakWeeks > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentVolt.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentVolt),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 14, color: AppColors.navy),
                        const SizedBox(width: 4),
                        Text(
                          '${consistency.streakWeeks} Wochen Serie',
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

            // Große Kennzahl
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${consistency.activeDays}',
                  style: AppTypography.display.copyWith(
                    fontSize: 32,
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / ${consistency.totalDays} Tage',
                  style: AppTypography.title.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${consistency.activePercent} % aktiv)',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Visuelle Punkte-Reihe (für 7-Tage-Woche oder 4-Wochen-Muster)
            Row(
              children: List.generate(consistency.totalDays <= 7 ? 7 : 14, (index) {
                final isActive = index < consistency.activeDays;
                return Expanded(
                  child: Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.navy : AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // Statustext
            Text(
              consistency.statusTextDe,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
