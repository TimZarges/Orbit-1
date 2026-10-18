import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit/features/notifications/models/app_notification.dart';
import 'package:orbit/features/notifications/providers/notifications_provider.dart';
import 'package:orbit/features/notifications/widgets/notification_bell_icon_button.dart';
import 'package:orbit/features/notifications/widgets/notification_center_sheet.dart';
import 'package:orbit/features/coach_link/models/coach_global_mode.dart';
import 'package:orbit/features/coach_link/providers/coach_global_mode_provider.dart';
import 'package:orbit/features/coach_link/models/coach_dashboard_athlete.dart';
import 'package:orbit/features/coach_link/widgets/coach_athletes_table.dart';

void main() {
  group('Phase 32.1: AppNotification & Notification Center Tests', () {
    test('AppNotification serialisiert korrekt mit NotificationType', () {
      final notif = AppNotification(
        id: 'notif_1',
        title: 'Neuer PR erzielt!',
        body: '325 W über 5 Minuten',
        type: NotificationType.prAchieved,
        route: '/diagnostics',
        read: false,
        createdAt: DateTime(2026, 10, 18, 12, 0),
      );

      final map = notif.toMap();
      expect(map['title'], 'Neuer PR erzielt!');
      expect(map['type'], 'PR_ACHIEVED');
      expect(map['route'], '/diagnostics');
      expect(map['read'], false);

      final recreated = AppNotification.fromMap('notif_1', {
        'title': 'Neuer PR erzielt!',
        'body': '325 W über 5 Minuten',
        'type': 'PR_ACHIEVED',
        'route': '/diagnostics',
        'read': false,
        'createdAt': '2026-10-18T12:00:00.000',
      });

      expect(recreated.type, NotificationType.prAchieved);
      expect(recreated.read, false);
      expect(recreated.route, '/diagnostics');
    });

    testWidgets(
        'NotificationBellIconButton zeigt Volt-Badge bei ungelesenen Mitteilungen',
        (tester) async {
      final mockNotifications = [
        AppNotification(
          id: 'n1',
          title: 'PR',
          body: 'Test Body',
          type: NotificationType.prAchieved,
          read: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: 'n2',
          title: 'Garmin',
          body: 'Sync OK',
          type: NotificationType.garminSynced,
          read: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsStreamProvider
                .overrideWith((ref) => Stream.value(mockNotifications)),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [NotificationBellIconButton()],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      // Badge mit Ziffer '1' sichtbar
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('NotificationCenterSheet listet Mitteilungen und Typen-Icons',
        (tester) async {
      final mockNotifications = [
        AppNotification(
          id: 'n1',
          title: 'Schwellenwert erkannt',
          body: 'FTP auf 290 W gestiegen',
          type: NotificationType.thresholdFound,
          read: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: 'n2',
          title: 'Garmin Sync',
          body: 'Aktivität geladen',
          type: NotificationType.garminSynced,
          read: true,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsStreamProvider
                .overrideWith((ref) => Stream.value(mockNotifications)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenterSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mitteilungen'), findsOneWidget);
      expect(find.text('Schwellenwert erkannt'), findsOneWidget);
      expect(find.text('Garmin Sync'), findsOneWidget);
      expect(find.text('Alle gelesen'), findsOneWidget);
    });
  });

  group('Phase 32.3: Globale Coach-Modi (Einfach & Download vs. Vollanalyse)',
      () {
    test('CoachGlobalMode Enum besitzt korrekte Display-Strings', () {
      expect(CoachGlobalMode.simpleDownload.displayName, 'Einfach & Download');
      expect(CoachGlobalMode.fullAnalysis.displayName, 'Vollanalyse');
    });

    testWidgets(
        'CoachAthletesTable in Modus 1 (Einfach & Download) rendert .FIT Download Button',
        (tester) async {
      const demoAthlete = CoachDashboardAthlete(
        athleteId: 'ath_1',
        coachId: 'coach_1',
        name: 'Max Mustermann',
        sport: 'BIKE',
        formStatus: CoachAthleteFormStatus.optimal,
        ctl: 65,
        atl: 55,
        tsb: 10,
        compliance7d: 95,
        actualLoad7d: 380,
        plannedLoad7d: 400,
        latestActivity: {
          'title': 'Grundlagenfahrt Z2',
          'durationSec': 3600,
          'distanceM': 32000.0,
          'avgHr': 142,
          'avgPowerW': 215,
          'rawFilePath': 'users/ath_1/rawActivities/act_1.fit',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coachGlobalModeProvider
                .overrideWith((ref) => CoachGlobalMode.simpleDownload),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CoachAthletesTable(
                athletes: const [demoAthlete],
                onAthleteOpen: (_, __) {},
                onCreateProposal: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Prüfe Modus 1 Spalten und Buttons
      expect(find.text('Letzte Einheit'), findsOneWidget);
      expect(find.text('Originaldatei (.FIT / .TCX)'), findsOneWidget);
      expect(find.text('.FIT Download'), findsOneWidget);
      expect(find.text('Grundlagenfahrt Z2'), findsOneWidget);
    });

    testWidgets(
        'CoachAthletesTable in Modus 2 (Vollanalyse) rendert volles Cockpit mit Form & Erholung',
        (tester) async {
      const demoAthlete = CoachDashboardAthlete(
        athleteId: 'ath_1',
        coachId: 'coach_1',
        name: 'Max Mustermann',
        sport: 'BIKE',
        formStatus: CoachAthleteFormStatus.optimal,
        ctl: 65,
        atl: 55,
        tsb: 10,
        compliance7d: 95,
        actualLoad7d: 380,
        plannedLoad7d: 400,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coachGlobalModeProvider
                .overrideWith((ref) => CoachGlobalMode.fullAnalysis),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CoachAthletesTable(
                athletes: const [demoAthlete],
                onAthleteOpen: (_, __) {},
                onCreateProposal: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Prüfe Modus 2 Spalten
      expect(find.text('Form'), findsOneWidget);
      expect(find.text('Erholung'), findsOneWidget);
      expect(find.text('Soll/Ist (7T)'), findsOneWidget);
      expect(find.text('Last 7T'), findsOneWidget);
      expect(find.text('Saisonziel'), findsOneWidget);
    });
  });
}
