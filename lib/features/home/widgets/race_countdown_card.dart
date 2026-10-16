import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/race_goal.dart';

/// Karte mit Countdown zum persönlichen Hauptwettkampf (A-, B- oder C-Priorität).
class RaceCountdownCard extends StatelessWidget {
  final RaceGoal raceGoal;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const RaceCountdownCard({
    super.key,
    required this.raceGoal,
    this.onEdit,
    this.onTap,
  });

  Color _getPriorityBgColor() {
    switch (raceGoal.priority.toUpperCase()) {
      case 'A':
        return AppColors.volt;
      case 'B':
        return const Color(0xFF00D2FF); // Cyan
      case 'C':
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  Color _getPriorityTextColor() {
    switch (raceGoal.priority.toUpperCase()) {
      case 'A':
      case 'B':
        return AppColors.navy;
      case 'C':
      default:
        return const Color(0xFF475569);
    }
  }

  IconData _getSportIcon() {
    switch (raceGoal.sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      case 'TRIATHLON':
      default:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = raceGoal.daysRemaining;
    final isUpcoming = days >= 0;

    return Semantics(
      container: true,
      label:
          'Wettkampf ${raceGoal.title}, Priorität ${raceGoal.priority}, am ${raceGoal.date}. ${raceGoal.formattedCountdown}',
      child: InkWell(
        onTap: onTap ?? onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
              // Kopfzeile: Saisonziel & Prioritäts-Badge
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
                        child: Icon(_getSportIcon(),
                            size: 18, color: AppColors.navy),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saisonziel',
                        style: AppTypography.label
                            .copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 8),
                      // Prioritäts-Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityBgColor(),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${raceGoal.priority}-Rennen',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityTextColor(),
                          ),
                        ),
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
                      tooltip: 'Wettkampf bearbeiten',
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
              const SizedBox(height: 6),

              // Details: Distanz, Zielzeit oder Ziel-Watt
              if (raceGoal.distance != null ||
                  raceGoal.targetTime != null ||
                  raceGoal.targetPowerWatts != null) ...[
                Row(
                  children: [
                    if (raceGoal.distance != null) ...[
                      Text(
                        raceGoal.distance!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (raceGoal.targetTime != null ||
                          raceGoal.targetPowerWatts != null)
                        Text(' • ',
                            style: TextStyle(color: Colors.grey.shade400)),
                    ],
                    if (raceGoal.targetTime != null) ...[
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.navy),
                      const SizedBox(width: 4),
                      Text(
                        'Ziel: ${raceGoal.targetTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (raceGoal.targetPowerWatts != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.bolt_outlined,
                          size: 14, color: AppColors.navy),
                      const SizedBox(width: 4),
                      Text(
                        '${raceGoal.targetPowerWatts} W',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Countdown-Hervorhebung
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? _getPriorityBgColor().withValues(alpha: 0.25)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      raceGoal.formattedCountdown,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isUpcoming ? AppColors.navy : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    raceGoal.date,
                    style: AppTypography.label
                        .copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
