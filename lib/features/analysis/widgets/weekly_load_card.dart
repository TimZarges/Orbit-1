import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/metrics/term_resolver.dart';
import '../models/weekly_load_summary.dart';
import 'analysis_info_sheet.dart';

/// Karte für den Soll-Ist-Abgleich der Wochenbelastung.
class WeeklyLoadCard extends StatelessWidget {
  final WeeklyLoadSummary summary;
  final ExperienceLevel experienceLevel;

  const WeeklyLoadCard({
    super.key,
    required this.summary,
    this.experienceLevel = ExperienceLevel.beginner,
  });

  @override
  Widget build(BuildContext context) {
    final termTitle = TermResolver.resolve(MetricTerm.tss, experienceLevel);

    return Semantics(
      container: true,
      label:
          'Wochenbelastung: ${summary.actualLoad.round()} von ${summary.hasPlan ? summary.plannedLoad.round() : 'kein Plan'} Punkten. ${summary.statusTextDe}.',
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
                    Icon(Icons.assessment_outlined,
                        size: 20, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Text(
                      'Wochenbelastung',
                      style:
                          AppTypography.title.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
                Semantics(
                  button: true,
                  label: 'Information zur Trainingsbelastung',
                  child: IconButton(
                    icon: const Icon(Icons.info_outline,
                        size: 20, color: Colors.grey),
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => AnalysisInfoSheet.showTerm(
                      context,
                      term: MetricTerm.tss,
                      level: experienceLevel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Werte-Zeile mit Status-Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          summary.actualLoad.round().toString(),
                          style: AppTypography.display.copyWith(
                            fontSize: 32,
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (summary.hasPlan) ...[
                          Text(
                            ' / ${summary.plannedLoad.round()}',
                            style: AppTypography.title.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        Text(
                          experienceLevel == ExperienceLevel.expert
                              ? 'Load'
                              : 'Punkte',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: summary.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: summary.statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    summary.statusTextDe,
                    style: AppTypography.label.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Fortschrittsbalken
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                return Stack(
                  children: [
                    // Hintergrund
                    Container(
                      height: 12,
                      width: maxWidth,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    // Ist-Balken
                    Container(
                      height: 12,
                      width: (summary.hasPlan
                              ? (maxWidth *
                                  (summary.actualLoad /
                                          (summary.plannedLoad * 1.3))
                                      .clamp(0.0, 1.0))
                              : maxWidth)
                          .clamp(4.0, maxWidth),
                      decoration: BoxDecoration(
                        color: summary.statusColor == AppColors.accentVolt
                            ? AppColors.navy
                            : summary.statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    // Soll-Markierungslinie (bei 100%) wenn Plan existiert
                    if (summary.hasPlan)
                      Positioned(
                        left: (maxWidth * (1.0 / 1.3)) - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            // Erläuterungstext
            Text(
              summary.hasPlan
                  ? 'Ziel: ${summary.plannedLoad.round()} $termTitle (${summary.completionPercent} % erreicht).'
                  : 'Trage geplante Workouts ein, um einen automatischen Soll-Ist-Vergleich zu sehen.',
              style: AppTypography.label.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
