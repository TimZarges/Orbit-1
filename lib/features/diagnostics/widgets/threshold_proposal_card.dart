import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/threshold_proposal.dart';
import 'threshold_explanation_sheet.dart';

/// Karte zur Darstellung eines Schwellenwert-Vorschlags mit Aktionen (Übernehmen, Ignorieren, Warum?).
class ThresholdProposalCard extends StatelessWidget {
  final ThresholdProposal proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isCoachView;

  const ThresholdProposalCard({
    super.key,
    required this.proposal,
    required this.onAccept,
    required this.onReject,
    this.isCoachView = false,
  });

  @override
  Widget build(BuildContext context) {
    final deltaIsPositive = proposal.delta >= 0;
    final deltaColor =
        deltaIsPositive ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF003875)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kopfzeile: Sportart & Konfidenz-Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001F47),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF003875)),
                    ),
                    child: Icon(_getSportIcon(proposal.sport),
                        size: 16, color: AppColors.volt),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    proposal.typeLabelDe,
                    style: AppTypography.title.copyWith(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: proposal.confidenceColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: proposal.confidenceColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: proposal.confidenceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      proposal.confidenceLabelDe,
                      style: AppTypography.label.copyWith(
                        color: proposal.confidenceColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Wert & Delta
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                proposal.formattedProposedValue,
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 26,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  proposal.formattedDelta,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: deltaColor,
                  ),
                ),
              ),
              const Spacer(),
              if (proposal.currentValue != null)
                Text(
                  'Bisher: ${_formatValue(proposal.type, proposal.currentValue!)}',
                  style: AppTypography.label.copyWith(color: Colors.white54),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Erklärungstext
          Text(
            proposal.explanationDe,
            style: AppTypography.body.copyWith(
              fontSize: 13,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Aktionen
          if (isCoachView) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF001F47),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF003875)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: Colors.white54),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nur der Athlet selbst kann Vorschläge übernehmen oder verwerfen.',
                      style:
                          AppTypography.label.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                // Warum? Button
                TextButton.icon(
                  onPressed: () =>
                      ThresholdExplanationSheet.show(context, proposal),
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Warum?'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.volt,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const Spacer(),

                // Ignorieren Button
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF003875)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Ignorieren'),
                ),
                const SizedBox(width: 8),

                // Übernehmen Button (Volt-Hintergrund, Navy-Text)
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.volt,
                    foregroundColor: AppColors.navy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Übernehmen',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  String _formatValue(ThresholdType type, double val) {
    switch (type) {
      case ThresholdType.ftp:
        return '${val.round()} W';
      case ThresholdType.lthr:
        return '${val.round()} bpm';
      case ThresholdType.thresholdPace:
      case ThresholdType.css:
        final m = val.toInt() ~/ 60;
        final s = (val % 60).round();
        return '$m:${s.toString().padLeft(2, '0')} ${type == ThresholdType.thresholdPace ? '/km' : '/100m'}';
    }
  }
}
