import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/metrics/term_resolver.dart';
import '../models/form_traffic_light.dart';
import 'analysis_info_sheet.dart';

/// Visuelle Karte für die physiologische Form-Ampel.
class FormTrafficLightCard extends StatelessWidget {
  final FormTrafficLight form;
  final ExperienceLevel experienceLevel;

  const FormTrafficLightCard({
    super.key,
    required this.form,
    this.experienceLevel = ExperienceLevel.beginner,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Form-Ampel: Zustand ${form.titleDe}. ${form.descriptionDe}. ${form.dataBasisTextDe}.',
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
            // Kopfzeile: Titel und Info-Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed_outlined, size: 20, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Text(
                      'Form-Ampel',
                      style: AppTypography.title.copyWith(color: AppColors.navy),
                    ),
                  ],
                ),
                Semantics(
                  button: true,
                  label: 'Information zur Form-Ampel anzeigen',
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => AnalysisInfoSheet.showFormTrafficLight(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status-Badge mit Leitfarbe
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: form.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: form.statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(form.icon, size: 16, color: form.statusColor),
                      const SizedBox(width: 6),
                      Text(
                        form.titleDe,
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

            // Physiologische Erläuterung
            Text(
              form.descriptionDe,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.navy.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Kennzahlen-Zeile (Fitness, Ermüdung, Frische) bei ausreichender Datenlage
            if (form.status != FormStatus.insufficientData) ...[
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricColumn(
                    label: TermResolver.resolve(MetricTerm.ctl, experienceLevel),
                    value: form.ctl.round().toString(),
                    term: MetricTerm.ctl,
                    level: experienceLevel,
                  ),
                  Container(width: 1, height: 32, color: AppColors.cardBorder),
                  _MetricColumn(
                    label: TermResolver.resolve(MetricTerm.atl, experienceLevel),
                    value: form.atl.round().toString(),
                    term: MetricTerm.atl,
                    level: experienceLevel,
                  ),
                  Container(width: 1, height: 32, color: AppColors.cardBorder),
                  _MetricColumn(
                    label: TermResolver.resolve(MetricTerm.tsb, experienceLevel),
                    value: (form.tsb >= 0 ? '+${form.tsb.round()}' : '${form.tsb.round()}'),
                    term: MetricTerm.tsb,
                    level: experienceLevel,
                    highlightColor: form.statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Fußnote: Datenbasis
            Row(
              children: [
                Icon(Icons.history_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    form.dataBasisTextDe,
                    style: AppTypography.label.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final MetricTerm term;
  final ExperienceLevel level;
  final Color? highlightColor;

  const _MetricColumn({
    required this.label,
    required this.value,
    required this.term,
    required this.level,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => AnalysisInfoSheet.showTerm(context, term: term, level: level),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.bold,
                color: highlightColor ?? AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
