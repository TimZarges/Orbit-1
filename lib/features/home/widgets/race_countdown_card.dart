import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/race_goal.dart';

/// Karte mit Countdown zum persönlichen Hauptwettkampf.
class RaceCountdownCard extends StatelessWidget {
  final RaceGoal raceGoal;
  final VoidCallback? onEdit;

  const RaceCountdownCard({
    super.key,
    required this.raceGoal,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.techGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.emoji_events_outlined,
                        size: 18, color: AppColors.navy),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saisonziel',
                    style: AppTypography.label
                        .copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Colors.grey),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Ziel bearbeiten',
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Wettkampf-Titel
          Text(
            raceGoal.title,
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),

          // Countdown-Hervorhebung
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  raceGoal.formattedCountdown,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                raceGoal.date,
                style:
                    AppTypography.label.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
