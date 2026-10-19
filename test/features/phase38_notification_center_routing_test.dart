import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/design/app_colors.dart';
import 'package:orbit/features/notifications/models/app_notification.dart';
import 'package:orbit/features/notifications/providers/notifications_provider.dart';
import 'package:orbit/features/notifications/widgets/notification_center_sheet.dart';

class _MockNotificationsController extends StateNotifier<AsyncValue<void>>
    implements NotificationsController {
  _MockNotificationsController() : super(const AsyncValue.data(null));

  final List<String> markedReadIds = [];

  @override
  Future<void> markAsRead(String id) async {
    markedReadIds.add(id);
  }

  @override
  Future<void> markAllAsRead() async {}

  Future<void> deleteNotification(String id) async {}

  @override
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? route,
  }) async {}
}

void main() {
  testWidgets(
      'Mitteilungszentrale rendert Volt-Rahmen für ungelesen und markiert bei Klick',
      (tester) async {
    final mockController = _MockNotificationsController();

    final testNotifications = [
      AppNotification(
        id: 'notif_1',
        title: 'Neuer FTP-Schwellenwert',
        body: 'Deine FTP wurde auf 285 W aktualisiert.',
        type: NotificationType.thresholdFound,
        route: '/profile/thresholds',
        read: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AppNotification(
        id: 'notif_2',
        title: 'Garmin-Sync erfolgreich',
        body: '3 Aktivitäten wurden importiert.',
        type: NotificationType.garminSynced,
        route: null,
        read: true,
        createdAt: DateTime(2026, 10, 15, 10, 30),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsStreamProvider
              .overrideWith((ref) => Stream.value(testNotifications)),
          notificationsControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationCenterSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Titel und Texte sichtbar
    expect(find.text('Neuer FTP-Schwellenwert'), findsOneWidget);
    expect(find.text('Garmin-Sync erfolgreich'), findsOneWidget);
    expect(find.text('vor 15 Min.'), findsOneWidget);
    expect(find.text('15.10.2026'), findsOneWidget);

    // 2. Umrandungen prüfen (Volt für unread, white24 für read)
    final unreadCardFinder = find.byKey(const Key('notification_item_notif_1'));
    expect(unreadCardFinder, findsOneWidget);

    final readCardFinder = find.byKey(const Key('notification_item_notif_2'));
    expect(readCardFinder, findsOneWidget);

    final unreadContainer = tester.firstWidget<Container>(find.descendant(
      of: unreadCardFinder,
      matching: find.byType(Container),
    ));
    final unreadBox = unreadContainer.decoration as BoxDecoration;
    expect((unreadBox.border as Border).top.color, AppColors.volt);
    expect((unreadBox.border as Border).top.width, 1.5);

    final readContainer = tester.firstWidget<Container>(find.descendant(
      of: readCardFinder,
      matching: find.byType(Container),
    ));
    final readBox = readContainer.decoration as BoxDecoration;
    expect((readBox.border as Border).top.color, Colors.white38);
    expect((readBox.border as Border).top.width, 1.2);

    // 3. Klick löst markAsRead aus
    await tester.tap(unreadCardFinder);
    await tester.pumpAndSettle();

    expect(mockController.markedReadIds, contains('notif_1'));
  });
}
