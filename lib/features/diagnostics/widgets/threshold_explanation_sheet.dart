import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/threshold_proposal.dart';

/// Modal-Sheet zur transparenten Erklärung eines Schwellenwert-Vorschlags („Warum?").
class ThresholdExplanationSheet extends StatelessWidget {
  final ThresholdProposal proposal;

  const ThresholdExplanationSheet({
    super.key,
    required this.proposal,
  });

  static void show(BuildContext context, ThresholdProposal proposal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ThresholdExplanationSheet(proposal: proposal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.techGrey,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.help_outline, color: AppColors.navy, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wie entsteht dieser Vorschlag?',
                        style:
                            AppTypography.title.copyWith(color: AppColors.navy),
                      ),
                      Text(
                        '${proposal.typeLabelDe} – Transparente Datenbasis',
                        style: AppTypography.label
                            .copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Konfidenz-Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: proposal.confidenceColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: proposal.confidenceColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: proposal.confidenceColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proposal.confidenceLabelDe,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          _getConfidenceDescription(proposal.confidence),
                          style: AppTypography.label
                              .copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Datenbasis
            Text(
              'Verwendete Datenpunkte',
              style: AppTypography.title
                  .copyWith(fontSize: 15, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            ...proposal.basis.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child:
                            Icon(Icons.circle, size: 6, color: AppColors.navy),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: AppTypography.body
                              .copyWith(fontSize: 14, color: AppColors.navy),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),

            // Grenzen & Transparenzhinweis
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ORBIT gibt keine physiologischen Garantien. Schwellenwerte können durch Tagesform, Temperatur, Hydration oder Ermüdung schwanken. Du kennst dein Körpergefühl am besten.',
                      style: AppTypography.label
                          .copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Schließen Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.techGrey,
                  foregroundColor: AppColors.navy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Verstanden',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getConfidenceDescription(ConfidenceLevel conf) {
    switch (conf) {
      case ConfidenceLevel.high:
        return 'Gleichmäßige Belastung ohne Pacing-Brüche oder Ausreißer über die volle Testdauer.';
      case ConfidenceLevel.medium:
        return 'Solide Belastungsdauer mit leichten Pacing-Schwankungen oder kurzen Pausen.';
      case ConfidenceLevel.low:
        return 'Starke Schwankungen oder unvollständige Telemetrie. Bitte mit Vorsicht prüfen.';
    }
  }
}
