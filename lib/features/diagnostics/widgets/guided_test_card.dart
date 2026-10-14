import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/guided_test_info.dart';

/// Karte für geführte Feldtests (z. B. 20-Min-FTP, 30-Min-Lauf, 400m/200m CSS).
class GuidedTestCard extends StatefulWidget {
  final GuidedTestInfo testInfo;
  final VoidCallback onSchedule;

  const GuidedTestCard({
    super.key,
    required this.testInfo,
    required this.onSchedule,
  });

  @override
  State<GuidedTestCard> createState() => _GuidedTestCardState();
}

class _GuidedTestCardState extends State<GuidedTestCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.testInfo;

    return Container(
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
          // Header mit Titel und Dauer
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.techGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getSportIcon(info.sport),
                    color: AppColors.navy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.titleDe,
                      style: AppTypography.title
                          .copyWith(fontSize: 15, color: AppColors.navy),
                    ),
                    Text(
                      'Dauer: ca. ${info.durationMinutes} Min.',
                      style: AppTypography.label
                          .copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.navy,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            info.subtitleDe,
            style: AppTypography.body
                .copyWith(fontSize: 13, color: Colors.grey.shade700),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            // Protokoll
            Text(
              'Ablauf & Protokoll',
              style: AppTypography.title
                  .copyWith(fontSize: 14, color: AppColors.navy),
            ),
            const SizedBox(height: 6),
            Text(
              info.protocolDe,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                color: AppColors.navy,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Sicherheitshinweis
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // Amber 100
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.safetyNoteDe,
                      style: AppTypography.label.copyWith(
                        color: const Color(0xFF92400E),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onSchedule,
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text('Test in Kalender einplanen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: BorderSide(color: AppColors.navy.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
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
}
