import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/threshold_proposal.dart';

/// Dialog zur Bestätigung der Schwellenwert-Übernahme mit optionaler Neuberechnung der Historie.
class RecomputeConfirmationDialog extends StatefulWidget {
  final ThresholdProposal proposal;
  final VoidCallback onCancel;
  final ValueChanged<bool> onConfirm;

  const RecomputeConfirmationDialog({
    super.key,
    required this.proposal,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<RecomputeConfirmationDialog> createState() => _RecomputeConfirmationDialogState();
}

class _RecomputeConfirmationDialogState extends State<RecomputeConfirmationDialog> {
  bool _recomputePastWorkouts = false;

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.techGrey,
              shape: BoxShape.circle,
            ],
            child: Icon(Icons.check_circle_outline, color: AppColors.navy, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Schwellenwert übernehmen',
              style: AppTypography.title.copyWith(color: AppColors.navy),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchtest du den vorgeschlagenen Wert von ${proposal.formattedProposedValue} für ${proposal.typeLabelDe} übernehmen?',
              style: AppTypography.body.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gültig ab heute. Bestehende Vergangenheitsdaten bleiben standardmäßig unangetastet.',
                      style: AppTypography.label.copyWith(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Vergangene Einheiten neu berechnen?',
              style: AppTypography.title.copyWith(fontSize: 15, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              'Berechnet TSS, Intensitätsfaktor und deine Formkurve für die letzten 60 Tage mit dem neuen Schwellenwert nach. (Dauer ca. 15–30 Sekunden)',
              style: AppTypography.label.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _recomputePastWorkouts,
              onChanged: (val) {
                setState(() {
                  _recomputePastWorkouts = val ?? false;
                });
              },
              title: Text(
                'Ja, vergangene Einheiten neu berechnen',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              subtitle: Text(
                'Standardmäßig deaktiviert, um historische Verläufe stabil zu halten.',
                style: AppTypography.label.copyWith(color: Colors.grey.shade500),
              ),
              activeColor: AppColors.navy,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(
            'Abbrechen',
            style: AppTypography.body.copyWith(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: () => widget.onConfirm(_recomputePastWorkouts),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.volt,
            foregroundColor: AppColors.navy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
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
    );
  }
}
