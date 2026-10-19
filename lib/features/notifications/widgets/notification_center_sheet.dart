import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/orbit_date_formatter.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../models/app_notification.dart';
import '../providers/notifications_provider.dart';

/// Zentrales Bottom-Sheet für alle System- und Coaching-Mitteilungen.
///
/// Bündelt PRs, Garmin-Sync-Status, Schwellenwerterkennungen und Trainingshinweise
/// an einem Ort, getrennt vom 1:1-Coach-Chat im unteren Tab.
class NotificationCenterSheet extends ConsumerWidget {
  /// Erstellt das NotificationCenterSheet.
  const NotificationCenterSheet({super.key});

  /// Zeigt das Bottom-Sheet im modalen Kontext an.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationCenterSheet(),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.thresholdFound:
        return Icons.speed;
      case NotificationType.prAchieved:
        return Icons.emoji_events;
      case NotificationType.garminSynced:
        return Icons.sync;
      case NotificationType.workoutAssigned:
        return Icons.fitness_center;
      case NotificationType.coachComment:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
        return Icons.notifications_none;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.thresholdFound:
      case NotificationType.prAchieved:
        return AppColors.volt;
      case NotificationType.garminSynced:
        return const Color(0xFF38BDF8); // Sky blue
      case NotificationType.workoutAssigned:
        return const Color(0xFFFB923C); // Orange
      case NotificationType.coachComment:
        return AppColors.volt;
      case NotificationType.system:
        return Colors.white70;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min.';
    } else if (diff.inHours < 24) {
      return 'vor ${diff.inHours} Std.';
    } else {
      return OrbitDateFormatter.formatDate(dt);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag-Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        color: AppColors.volt, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Mitteilungen',
                      style: AppTypography.headline.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const BetaBugReportIconButton(),
                    const SizedBox(width: 4),
                    TextButton(
                      key: const Key('mark_all_notifications_read_button'),
                      onPressed: () {
                        ref
                            .read(notificationsControllerProvider)
                            .markAllAsRead();
                      },
                      child: Text(
                        'Alle gelesen',
                        style:
                            AppTypography.label.copyWith(color: AppColors.volt),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF003875), height: 1),

          // Inhalt
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.volt),
              ),
              error: (err, _) =>
                  _buildList(context, ref, defaultSeedNotifications),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_off_outlined,
                            size: 48, color: Colors.white38),
                        const SizedBox(height: 12),
                        Text(
                          'Keine neuen Mitteilungen',
                          style: AppTypography.body
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }

                return _buildList(context, ref, list);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<AppNotification> list) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        final iconColor = _getColorForType(item.type);

        return InkWell(
          key: Key('notification_item_${item.id}'),
          onTap: () {
            ref.read(notificationsControllerProvider).markAsRead(item.id);
            final targetRoute = item.route;
            Navigator.of(context).pop();
            if (targetRoute != null && targetRoute.isNotEmpty) {
              final rootCtx = rootNavigatorKey.currentContext;
              if (rootCtx != null) {
                rootCtx.push(targetRoute);
              }
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF002A5C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.read ? Colors.white38 : AppColors.volt,
                width: item.read ? 1.2 : 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon-Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(item.type),
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTypography.body.copyWith(
                                color: Colors.white,
                                fontWeight: item.read
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _formatTimeAgo(item.createdAt),
                            style: AppTypography.label.copyWith(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ungelesen-Indikator
                if (!item.read) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.volt,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
