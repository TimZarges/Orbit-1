/// Datei-Header: `test/phase45_web_responsive_and_coach_e2e_v1_test.dart`
/// Zweck: Testsuite für Phase 45 (Responsive Web-Layout ab `900px` mit
/// `NavigationRail` vs. mobile `BottomNavigationBar`, plattformübergreifender
/// Web-`.FIT`-Upload-/Download-Weiche, `activitiesProvider` Coach-Isolation und
/// `AthleteCoachTabScreen` im V1.0.0-Standardbetrieb).
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/config/release_config.dart';
import 'package:orbit/core/theme/orbit_professional_theme.dart';
import 'package:orbit/core/widgets/responsive_content_frame.dart';
import 'package:orbit/features/activities/models/activity.dart';
import 'package:orbit/features/activities/providers/activities_provider.dart';
import 'package:orbit/features/activities/providers/activity_upload_provider.dart';
import 'package:orbit/features/activities/services/fit_download_service.dart';
import 'package:orbit/features/auth/providers/user_provider.dart';
import 'package:orbit/features/coach_link/models/v1_coach_athlete_link.dart';
import 'package:orbit/features/coach_link/providers/athlete_context_provider.dart';
import 'package:orbit/features/coach_link/providers/v1_coach_connection_provider.dart';
import 'package:orbit/features/coach_link/screens/athlete_coach_tab_screen.dart';
import 'package:orbit/features/dashboard/screens/dashboard_screen.dart';
import 'package:orbit/features/home/models/home_dashboard_data.dart';
import 'package:orbit/features/home/providers/home_dashboard_provider.dart';
import 'package:orbit/features/integrations/models/garmin_status.dart';
import 'package:orbit/features/integrations/providers/garmin_provider.dart';
import 'package:orbit/features/profile/widgets/v1_athlete_coach_connection_card.dart';
import 'package:orbit/features/settings/models/app_settings.dart';
import 'package:orbit/features/settings/providers/settings_provider.dart';

/// Deterministischer Test-Controller für Sprache und Wohnland.
class _Phase45SettingsController extends SettingsController {
  final String lang;

  _Phase45SettingsController({this.lang = 'de'});

  @override
  AppSettings build() => AppSettings(
        languageCode: lang,
        countryCode: 'DE',
        themeMode: ThemeMode.light,
      );
}

void main() {
  group('Phase 45: Responsive Web-Layout & plattformübergreifendes .FIT-Handling',
      () {
    testWidgets(
        '1. Coach-Layout ab width >= 900px rendert vertikale NavigationRail ohne BottomNav',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewedAthleteIdProvider.overrideWith((ref) => 'ath_1'),
            activitiesProvider.overrideWith((ref) => Stream.value(const [])),
            userDocumentProvider.overrideWith(
              (ref) => Stream.value({
                'role': 'TRAINER',
                'profile': {'firstName': 'Tim', 'lastName': 'Coach'},
              }),
            ),
            v1CoachAthletesStreamProvider.overrideWith(
              (ref) => Stream.value(const <V1CoachAthleteLink>[]),
            ),
            settingsControllerProvider.overrideWith(
              () => _Phase45SettingsController(lang: 'de'),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final railFinder =
          find.byKey(const Key('dashboard_web_navigation_rail'));
      expect(railFinder, findsOneWidget);
      expect(
        find.byKey(const Key('dashboard_mobile_bottom_nav')),
        findsNothing,
      );

      final rail = tester.widget<NavigationRail>(railFinder);
      expect(rail.extended, isTrue);
      expect(rail.destinations.length, equals(3));
      expect(find.text('Athleten'), findsWidgets);
      expect(find.text('Kalender'), findsWidgets);
      expect(find.text('Profil'), findsWidgets);
      expect(find.byType(ResponsiveContentFrame), findsWidgets);
    });

    testWidgets(
        '2. Athleten-Layout bei width >= 900px zeigt NavigationRail (Heute, Kalender, Coach, Profil)',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewedAthleteIdProvider.overrideWith((ref) => 'ath_1'),
            activitiesProvider.overrideWith((ref) => Stream.value(const [])),
            homeDashboardProvider('ath_1').overrideWith(
              (ref) => Future.value(
                const HomeDashboardData(todayLocalDate: '2026-11-17'),
              ),
            ),
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(
                const GarminStatus(state: GarminConnectionState.disconnected),
              ),
            ),
            userDocumentProvider.overrideWith(
              (ref) => Stream.value({
                'role': 'ATHLETE',
                'profile': {'firstName': 'Elena', 'lastName': 'Tri'},
              }),
            ),
            settingsControllerProvider.overrideWith(
              () => _Phase45SettingsController(lang: 'de'),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildDarkTheme(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final railFinder =
          find.byKey(const Key('dashboard_web_navigation_rail'));
      expect(railFinder, findsOneWidget);
      expect(
        find.byKey(const Key('dashboard_mobile_bottom_nav')),
        findsNothing,
      );

      final rail = tester.widget<NavigationRail>(railFinder);
      // 1024px liegt zwischen 900px und 1160px -> kompakte Rail
      expect(rail.extended, isFalse);
      expect(rail.destinations.length, equals(4));
      expect(find.text('Heute'), findsWidgets);
      expect(find.text('Kalender'), findsWidgets);
      expect(find.text('Coach'), findsWidgets);
      expect(find.text('Profil'), findsWidgets);
    });

    testWidgets(
        '3. Mobiles Layout (< 900px) nutzt BottomNavigationBar statt NavigationRail',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewedAthleteIdProvider.overrideWith((ref) => 'ath_1'),
            activitiesProvider.overrideWith((ref) => Stream.value(const [])),
            userDocumentProvider.overrideWith(
              (ref) => Stream.value({
                'role': 'TRAINER',
                'profile': {'firstName': 'Tim', 'lastName': 'Coach'},
              }),
            ),
            v1CoachAthletesStreamProvider.overrideWith(
              (ref) => Stream.value(const <V1CoachAthleteLink>[]),
            ),
            settingsControllerProvider.overrideWith(
              () => _Phase45SettingsController(lang: 'en'),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard_mobile_bottom_nav')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dashboard_web_navigation_rail')),
        findsNothing,
      );
      expect(find.text('Athletes'), findsWidgets);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    test(
        '4. ActivityUploadNotifier.validateBytesForUpload prüft .FIT-Bytes plattformunabhängig (ohne dart:isolate)',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activityUploadProvider.notifier);

      // Gültiger 14-Byte-FIT-Header (".FIT" bei Offset 8..12)
      final validFitBytes = Uint8List.fromList([
        0x0E, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x2E, 0x46, 0x49, 0x54, // ".FIT"
        0x00, 0x00,
      ]);
      final okResult = await notifier.validateBytesForUpload(
        validFitBytes,
        'morning_ride.fit',
      );
      expect(okResult.isValid, isTrue);
      expect(okResult.extension, equals('fit'));

      // Leere Datei wird sicher abgelehnt
      final emptyResult = await notifier.validateBytesForUpload(
        Uint8List(0),
        'empty.fit',
      );
      expect(emptyResult.isValid, isFalse);
    });

    test(
        '5. FitDownloadService löst Storage-Pfad für Coach-Athleten auf und exportiert benannte .FIT-Datei',
        () async {
      String? loadedPath;
      String? savedName;
      Uint8List? savedBytes;

      final service = FitDownloadService(
        loadBytes: (path) async {
          loadedPath = path;
          return Uint8List.fromList([0x0E, 0x10, 0x2E, 0x46, 0x49, 0x54]);
        },
        saveFile: ({
          required String fileName,
          required Uint8List bytes,
          required String dialogTitle,
        }) async {
          savedName = fileName;
          savedBytes = bytes;
          return Uri(scheme: 'web-download', path: fileName);
        },
      );

      final activity = Activity(
        id: 'act_web_99',
        athleteId: 'ath_e2e_1',
        startTimeUtc: DateTime(2026, 11, 17, 9, 30),
        localDate: '2026-11-17',
        sport: 'BIKE',
        title: 'Web Garmin Ride',
        durationSec: 3600,
        distanceM: 35000,
      );

      final result = await service.downloadFitFile(activity, lang: 'de');
      expect(result.status, equals(FitDownloadStatus.success));
      expect(
        loadedPath,
        equals('users/ath_e2e_1/rawActivities/act_web_99.fit'),
      );
      expect(savedName, equals('20261117_Web_Garmin_Ride.fit'));
      expect(savedBytes, isNotEmpty);
    });

    test(
        '6. FitDownloadService bevorzugt rawFilePath und bietet kanonischen .fit/.fit.gz Fallback',
        () {
      final activity = Activity(
        id: 'act_77',
        athleteId: 'ath_e2e_1',
        startTimeUtc: DateTime(2026, 11, 17),
        localDate: '2026-11-17',
        sport: 'RUN',
        title: 'Tempo Run',
        durationSec: 2400,
        distanceM: 10000,
        rawFilePath: 'users/ath_e2e_1/rawActivities/custom_garmin.fit',
      );

      final candidates = FitDownloadService.resolveCandidatePaths(activity);
      expect(
        candidates,
        equals([
          'users/ath_e2e_1/rawActivities/custom_garmin.fit',
          'users/ath_e2e_1/rawActivities/act_77.fit',
          'users/ath_e2e_1/rawActivities/act_77.fit.gz',
        ]),
      );
    });

    test(
        '7. Coach-Kontext: v1SelectedCoachAthleteIdProvider & viewedAthleteIdProvider bleiben getrennt von Coach-UID',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(v1SelectedCoachAthleteIdProvider), isNull);

      container.read(v1SelectedCoachAthleteIdProvider.notifier).state =
          'ath_e2e_1';
      container.read(viewedAthleteIdProvider.notifier).state = 'ath_e2e_1';

      expect(
        container.read(v1SelectedCoachAthleteIdProvider),
        equals('ath_e2e_1'),
      );
      expect(container.read(viewedAthleteIdProvider), equals('ath_e2e_1'));

      // Wechsel auf zweiten Athleten
      container.read(v1SelectedCoachAthleteIdProvider.notifier).state =
          'ath_e2e_2';
      container.read(viewedAthleteIdProvider.notifier).state = 'ath_e2e_2';

      expect(
        container.read(v1SelectedCoachAthleteIdProvider),
        equals('ath_e2e_2'),
      );
      expect(container.read(viewedAthleteIdProvider), equals('ath_e2e_2'));
    });

    testWidgets(
        '8. AthleteCoachTabScreen im V1.0.0-Standardbetrieb zeigt V1AthleteCoachConnectionCard in ResponsiveContentFrame',
        (tester) async {
      ReleaseConfig.resetTestingOverrides();
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            v1AthleteCoachLinksStreamProvider.overrideWith(
              (ref) => Stream.value(const <V1CoachAthleteLink>[]),
            ),
            settingsControllerProvider.overrideWith(
              () => _Phase45SettingsController(lang: 'de'),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: const AthleteCoachTabScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResponsiveContentFrame), findsOneWidget);
      expect(find.byType(V1AthleteCoachConnectionCard), findsOneWidget);
      expect(find.text('Mein Coach / Verbindung mit Coach'), findsOneWidget);
    });
  });
}
