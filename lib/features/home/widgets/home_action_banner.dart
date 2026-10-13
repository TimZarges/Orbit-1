import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// Banner für ausstehende Aktionen (z. B. neue Schwellenwerte, ungelesene Nachrichten, Zuordnung).
class HomeActionBanner extends StatelessWidget {
  final int pendingThresholdsCount;
  final int unreadChatMessagesCount;
  final int unmatchedActivitiesCount;
  final VoidCallback? onThresholdsTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onMatchTap;

  const HomeActionBanner({
    super.key,
    this.pendingThresholdsCount = 0,
    this.unreadChatMessagesCount = 0,
    this.unmatchedActivitiesCount = 0,
    this.onThresholdsTap,
    this.onChatTap,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (pendingThresholdsCount > 0) {
      items.add(_buildBannerTile(
        icon: Icons.auto_awesome,
        iconColor: AppColors.navy,
        badgeText: '$pendingThresholdsCount NEU',
        title: '$pendingThresholdsCount neuer Schwellenwert-Vorschlag verfügbar',
        actionLabel: 'Prüfen',
        onTap: onThresholdsTap,
      ));
    }

    if (unreadChatMessagesCount > 0) {
      items.add(_buildBannerTile(
        icon: Icons.chat_bubble_outline,
        iconColor: AppColors.navy,
        badgeText: '$unreadChatMessagesCount',
        title: unreadChatMessagesCount == 1
            ? '1 neue Nachricht von deinem Trainer'
            : '$unreadChatMessagesCount neue Nachrichten von deinem Trainer',
        actionLabel: 'Chat',
        onTap: onChatTap,
      ));
    }

    if (unmatchedActivitiesCount > 0) {
      items.add(_buildBannerTile(
        icon: Icons.link,
        iconColor: AppColors.navy,
        badgeText: '$unmatchedActivitiesCount',
        title: 'Einheit noch keinem geplanten Workout zugeordnet',
        actionLabel: 'Zuordnen',
        onTap: onMatchTap,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)).toList(),
    );
  }

  Widget _buildBannerTile({
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required String title,
    required String actionLabel,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.volt.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.volt),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              actionLabel,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
