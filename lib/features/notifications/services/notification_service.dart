import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/notification_repository.dart';

/// Service zur Verwaltung von Push-Berechtigungen im Kontext, Notification Channels und Deep Linking.
class NotificationService {
  final NotificationRepository _repository;

  NotificationService({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  /// Zugriff auf das zugrundeliegende NotificationRepository.
  NotificationRepository get repository => _repository;

  /// Fragt die Push-Berechtigung im Kontext an (z. B. nach Trainer-Verknüpfung oder beim ersten Chat).
  /// Zeigt vorher eine verständliche Erklärung gemäß DESIGN.md §8.
  static Future<bool> requestPermissionInContext(
    BuildContext context, {
    required String contextReason,
  }) async {
    final granted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                color: Color(0xFF0F172A), size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Benachrichtigungen',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contextReason,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bedtime_outlined, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pushes beachten deine Ruhezeiten und enthalten keine sensiblen Gesundheitsdaten.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Nicht jetzt', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCDFB17), // Volt
              foregroundColor: const Color(0xFF0F172A), // Navy
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Aktivieren',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );

    return granted ?? false;
  }

  /// Verarbeitet eingehende Deep Links aus Notification Clicks.
  static void handleNotificationClick(
      BuildContext context, Map<String, dynamic> data) {
    // 1. Explizite Route prüfen (z. B. '/activities/act_123', '/health', '/thresholds')
    final explicitRoute = data['route'] as String?;
    if (explicitRoute != null && explicitRoute.isNotEmpty) {
      context.push(explicitRoute);
      return;
    }

    final type = (data['type'] as String?)?.toUpperCase();
    switch (type) {
      case 'ACTIVITY':
      case 'ACTIVITY_ANALYSIS':
        final activityId = data['activityId'] as String?;
        if (activityId != null && activityId.isNotEmpty) {
          context.push('/activities/$activityId');
        } else {
          context.push('/');
        }
        break;
      case 'HEALTH':
      case 'RECOVERY_BRIEFING':
        context.push('/health');
        break;
      case 'THRESHOLD':
        context.push('/thresholds');
        break;
      case 'CHAT':
        final chatId = data['chatId'] as String?;
        if (chatId != null && chatId.isNotEmpty) {
          context.push('/chat/$chatId');
        } else {
          context.push('/chats');
        }
        break;
      case 'WORKOUT':
      case 'CALENDAR':
        context.push('/calendar');
        break;
      case 'DIAGNOSTICS':
        context.push('/diagnostics');
        break;
      case 'SUMMARY':
        context.push('/analysis');
        break;
      default:
        context.push('/');
        break;
    }
  }
}
