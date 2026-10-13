import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/analysis_timeframe.dart';

/// Auswahlelement für den Analyse-Zeitraum (Woche / Monat / Saison).
class AnalysisTimeframeSelector extends StatelessWidget {
  final AnalysisTimeframe selected;
  final ValueChanged<AnalysisTimeframe> onSelected;

  const AnalysisTimeframeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBorder.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: AnalysisTimeframe.values.map((timeframe) {
          final isSelected = timeframe == selected;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: 'Zeitraum ${timeframe.labelDe}',
              child: InkWell(
                onTap: () => onSelected(timeframe),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    timeframe.labelDe,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.navy : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
