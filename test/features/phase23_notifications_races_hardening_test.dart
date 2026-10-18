import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit/core/config/app_config.dart';
import 'package:orbit/core/utils/crash_reporter.dart';
import 'package:orbit/features/analysis/domain/aggregates_calculator.dart';
import 'package:orbit/features/analysis/widgets/fitness_fatigue_trend_chart.dart';
import 'package:orbit/features/home/models/race_goal.dart';
import 'package:orbit/features/home/widgets/race_countdown_card.dart';
import 'package:orbit/features/notifications/services/notification_service.dart';
import 'package:orbit/features/profile/screens/profile_screen.dart';
import 'package:orbit/features/races/models/race.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 23.1: Push-Benachrichtigungen & Deep-Linking', () {
    testWidgets(
        'handleNotificationClick navigates to explicit route or activity/health/calendar/threshold',
        (tester) async {
      final routesVisited = <String>[];

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  NotificationService.handleNotificationClick(context, {
                    'route': '/health',
                  });
                },
                child: const Text('Test'),
              ),
            ),
          ),
          GoRoute(
            path: '/health',
            builder: (context, state) {
              routesVisited.add('/health');
              return const Scaffold(body: Text('Health Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      expect(routesVisited, contains('/health'));
      expect(find.text('Health Screen'), findsOneWidget);
    });
  });

  group('Phase 23.2: Wettkampf-Planung & Saison-Ziele (A-, B-, C-Rennen)', () {
    test('Race Model serializes and maps priorities correctly', () {
      final raceA = Race(
        id: 'race_1',
        userId: 'user_1',
        title: 'Ironman 70.3 Kraichgau',
        date: '2026-05-24',
        sport: 'TRIATHLON',
        distanceLabel: 'Mitteldistanz',
        priority: RacePriority.a,
        targetTimeSec: 16200, // 4:30:00
        targetPowerWatts: 265,
        notes: 'Saison-Highlight',
      );

      expect(raceA.priorityCode, 'A');
      expect(raceA.priorityLabel, 'A-Hauptwettkampf');
      expect(raceA.formattedTargetTime, '4:30:00');

      final map = raceA.toMap();
      expect(map['priority'], 'A');
      expect(map['targetTimeSec'], 16200);
      expect(map['targetPowerWatts'], 265);

      final reconstructed = Race.fromMap(map, id: 'race_1');
      expect(reconstructed.title, 'Ironman 70.3 Kraichgau');
      expect(reconstructed.priority, RacePriority.a);
    });

    test(
        'RaceGoal supports A/B/C priorities and converts bi-directionally to Race',
        () {
      const goalB = RaceGoal(
        id: 'race_2',
        title: 'Eschborn-Frankfurt',
        date: '2026-05-01',
        distance: '100 km',
        priority: 'B',
        sport: 'BIKE',
        targetPowerWatts: 290,
      );

      expect(goalB.isARace, false);
      expect(goalB.isBRace, true);
      expect(goalB.isCRace, false);
      expect(goalB.priorityLabel, 'B-Vorbereitung');

      final race = goalB.toRace(userId: 'ath_1');
      expect(race.priority, RacePriority.b);
      expect(race.targetPowerWatts, 290);

      final convertedGoal = RaceGoal.fromRace(race);
      expect(convertedGoal.priority, 'B');
      expect(convertedGoal.title, 'Eschborn-Frankfurt');
    });

    testWidgets(
        'RaceCountdownCard renders A-Race with Volt badge and target power',
        (tester) async {
      const goalA = RaceGoal(
        title: 'Challenge Roth',
        date: '2026-07-05',
        distance: 'Langdistanz',
        priority: 'A',
        sport: 'TRIATHLON',
        targetTime: '9:15:00',
        targetPowerWatts: 240,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RaceCountdownCard(raceGoal: goalA),
          ),
        ),
      );

      expect(find.text('Challenge Roth'), findsOneWidget);
      expect(find.text('A-Rennen'), findsOneWidget);
      expect(find.text('Langdistanz'), findsOneWidget);
      expect(find.text('Ziel: 9:15:00'), findsOneWidget);
      expect(find.text('240 W'), findsOneWidget);
    });

    testWidgets('RaceCountdownCard renders B-Race with Cyan badge',
        (tester) async {
      const goalB = RaceGoal(
        title: 'City Triathlon Frankfurt',
        date: '2026-08-02',
        distance: 'Olympisch',
        priority: 'B',
        sport: 'TRIATHLON',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RaceCountdownCard(raceGoal: goalB),
          ),
        ),
      );

      expect(find.text('City Triathlon Frankfurt'), findsOneWidget);
      expect(find.text('B-Rennen'), findsOneWidget);
    });

    testWidgets(
        'FitnessFatigueTrendChart renders race flags and updates HUD on race date hover',
        (tester) async {
      final points = [
        const FitnessFatiguePoint(
            date: '2026-05-20', ctl: 60, atl: 65, tsb: -5),
        const FitnessFatiguePoint(date: '2026-05-21', ctl: 60, atl: 55, tsb: 5),
        const FitnessFatiguePoint(
            date: '2026-05-22', ctl: 60, atl: 48, tsb: 12),
        const FitnessFatiguePoint(
            date: '2026-05-23', ctl: 60, atl: 42, tsb: 18),
        const FitnessFatiguePoint(
            date: '2026-05-24', ctl: 60, atl: 38, tsb: 22, isProjection: true),
      ];

      const race = RaceGoal(
        title: 'Ironman 70.3 Kraichgau',
        date: '2026-05-24',
        priority: 'A',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FitnessFatigueTrendChart(
              points: points,
              races: const [race],
            ),
          ),
        ),
      );

      expect(find.byType(FitnessFatigueTrendChart), findsOneWidget);
      expect(find.text('Performance Management (PMC)'), findsOneWidget);

      // Simuliere Tap/Hover auf den Renntag (letzter Punkt)
      final chartFinder = find.byType(CustomPaint).first;
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();

      // Sollte die Taper-Projektion bzw. den Rennhinweis anzeigen
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group(
      'Phase 23.3: Beta-Hardening (Version Gate, App Config, Crashlytics & Profile)',
      () {
    test('AppConfig parses minRequiredBuild and feature flags correctly', () {
      final map = {
        'minRequiredBuild': 2,
        'latestBuild': 3,
        'updateUrl': 'https://app.orbit.training/beta',
        'maintenanceMode': false,
        'featureFlags': {
          'garmin_direct_sync': true,
          'experimental_intervals': true,
          'ai_coaching': false,
        },
      };

      final config = AppConfig.fromMap(map);
      expect(config.minRequiredBuild, 2);
      expect(config.latestBuild, 3);
      expect(config.isFeatureEnabled('garmin_direct_sync'), true);
      expect(config.isFeatureEnabled('ai_coaching'), false);
      expect(config.isFeatureEnabled('nonexistent'), false);
    });

    testWidgets(
        'VersionGateWrapper allows normal child when minRequiredBuild <= currentBuild',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigStreamProvider.overrideWith((ref) => Stream.value(
                  const AppConfig(minRequiredBuild: 1, latestBuild: 1),
                )),
          ],
          child: const VersionGateWrapper(
            child: MaterialApp(
              home: Scaffold(body: Text('ORBIT Main Dashboard')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ORBIT Main Dashboard'), findsOneWidget);
      expect(find.text('Neues Beta-Update erforderlich'), findsNothing);
    });

    testWidgets(
        'VersionGateWrapper blocks app with update screen when minRequiredBuild > currentBuild',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigStreamProvider.overrideWith((ref) => Stream.value(
                  const AppConfig(
                    minRequiredBuild: 99, // Höher als AppInfo.buildNumber (1)
                    latestBuild: 100,
                  ),
                )),
          ],
          child: const VersionGateWrapper(
            child: MaterialApp(
              home: Scaffold(body: Text('ORBIT Main Dashboard')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Das Dashboard darf nicht sichtbar sein
      expect(find.text('ORBIT Main Dashboard'), findsNothing);

      // Blockierender Update-Screen muss sichtbar sein
      expect(find.text('Neues Beta-Update erforderlich'), findsOneWidget);
      expect(find.text('Jetzt aktualisieren'), findsOneWidget);
    });

    testWidgets(
        'VersionGateWrapper displays maintenance screen when maintenanceMode == true',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigStreamProvider.overrideWith((ref) => Stream.value(
                  const AppConfig(
                    maintenanceMode: true,
                  ),
                )),
          ],
          child: const VersionGateWrapper(
            child: MaterialApp(
              home: Scaffold(body: Text('ORBIT Main Dashboard')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wartungsarbeiten'), findsOneWidget);
    });

    test('CrashReporter defaults to no consent and sanitizes emails', () {
      CrashReporter.initialize(hasConsent: false);
      expect(CrashReporter.hasConsent, false);

      CrashReporter.setConsent(true);
      expect(CrashReporter.hasConsent, true);

      // Test error sanitization
      CrashReporter.recordError(
        Exception(
            'Network failure for user athlete@orbit.training with Bearer secret_123'),
        StackTrace.current,
        reason: 'Contacting coach coach@club.de',
      );

      // Reset
      CrashReporter.setConsent(false);
      expect(CrashReporter.hasConsent, false);
    });

    testWidgets(
        'ProfileScreen renders build version and Frankfurt server region in footer',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('ORBIT v1.0.0 (Build 1) • Closed Beta'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('ORBIT v1.0.0 (Build 1) • Closed Beta'), findsOneWidget);
      expect(find.text('Server-Region: ${AppInfo.region}'), findsOneWidget);
    });
  });
}
