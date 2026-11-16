/// Datei-Header: `test/phase44_coach_view_connection_and_download_v1_test.dart`
/// Zweck: Umfassende Testsuite für Phase 44 (V1.0.0 Coach-3-Tab-Navigation,
/// Coach-Athleten-Verbindung mit DSGVO-Freigabe & 1-Klick-Trennen, Coach-Kalender
/// mit Athletenwechsel, `.FIT`-Download mit `athleteId` sowie Editierbarkeit von
/// „Profil Einfach“ für Athlet & Coach in DE/EN).
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/theme/orbit_professional_theme.dart';
import 'package:orbit/features/activities/models/activity.dart';
import 'package:orbit/features/activities/providers/activities_provider.dart';
import 'package:orbit/features/activities/services/fit_download_service.dart';
import 'package:orbit/features/auth/providers/user_provider.dart';
import 'package:orbit/features/calendar/providers/calendar_provider.dart';
import 'package:orbit/features/coach_link/models/v1_coach_athlete_link.dart';
import 'package:orbit/features/coach_link/providers/athlete_context_provider.dart';
import 'package:orbit/features/coach_link/providers/v1_coach_connection_provider.dart';
import 'package:orbit/features/coach_link/screens/v1_coach_athletes_tab.dart';
import 'package:orbit/features/coach_link/screens/v1_coach_calendar_tab.dart';
import 'package:orbit/features/dashboard/screens/dashboard_screen.dart';
import 'package:orbit/features/home/widgets/home_recent_activity_card.dart';
import 'package:orbit/features/integrations/models/garmin_status.dart';
import 'package:orbit/features/integrations/providers/garmin_provider.dart';
import 'package:orbit/features/onboarding/widgets/triathlon_combined_icon.dart';
import 'package:orbit/features/profile/widgets/v1_athlete_coach_connection_card.dart';
import 'package:orbit/features/profile/widgets/v1_simple_profile_view.dart';
import 'package:orbit/features/settings/models/app_settings.dart';
import 'package:orbit/features/settings/providers/settings_provider.dart';

/// Hilfs-Controller für deterministische Sprache/Wohnland-Einstellungen in Tests.
class _TestSettingsController extends SettingsController {
  final String languageCode;
  final String countryCode;

  _TestSettingsController({
    this.languageCode = 'de',
    this.countryCode = 'DE',
  });

  @override
  AppSettings build() => AppSettings(
        languageCode: languageCode,
        countryCode: countryCode,
        themeMode: ThemeMode.light,
      );
}

void main() {
  group('Phase 44: V1.0.0 Coach-Ansicht, Verbindung & .FIT-Download', () {
    testWidgets(
        '1. Coach-3-Tab-Navigation (Athleten, Kalender, Profil) ohne V2-Analyse/Bibliothek (DE)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewedAthleteIdProvider.overrideWith((ref) => 'coach_1'),
            activitiesProvider.overrideWith((ref) => Stream.value(const [])),
            userDocumentProvider.overrideWith(
              (ref) => Stream.value({
                'role': 'TRAINER',
                'profile': {'firstName': 'Max', 'lastName': 'Trainer'},
              }),
            ),
            v1CoachAthletesStreamProvider.overrideWith(
              (ref) => Stream.value(const <V1CoachAthleteLink>[]),
            ),
            settingsControllerProvider.overrideWith(
              () => _TestSettingsController(languageCode: 'de'),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exakt 3 Tabs in der BottomNavigationBar
      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.items.length, equals(3));
      expect(navBar.items[0].label, equals('Athleten'));
      expect(navBar.items[1].label, equals('Kalender'));
      expect(navBar.items[2].label, equals('Profil'));

      // Keine V2/V3-Tabs sichtbar
      expect(find.text('Analyse'), findsNothing);
      expect(find.text('Bibliothek'), findsNothing);
    });

    testWidgets(
        '2. Coach-3-Tab-Navigation ist auf Englisch lokalisiert und rendert im Dark Mode',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewedAthleteIdProvider.overrideWith((ref) => 'coach_1'),
            activitiesProvider.overrideWith((ref) => Stream.value(const [])),
            userDocumentProvider.overrideWith(
              (ref) => Stream.value({
                'role': 'TRAINER',
                'profile': {'firstName': 'Max', 'lastName': 'Trainer'},
              }),
            ),
            v1CoachAthletesStreamProvider.overrideWith(
              (ref) => Stream.value(const <V1CoachAthleteLink>[]),
            ),
            settingsControllerProvider.overrideWith(
              () => _TestSettingsController(languageCode: 'en'),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildDarkTheme(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.items.length, equals(3));
      expect(navBar.items[0].label, equals('Athletes'));
      expect(navBar.items[1].label, equals('Calendar'));
      expect(navBar.items[2].label, equals('Profile'));
    });

    testWidgets(
        '3. Coach erzeugt Einladungscode und Athlet verbindet sich erst nach DSGVO-Opt-In',
        (tester) async {
      String? invokedFn;
      Map<String, dynamic>? invokedPayload;
      final fakeService = V1CoachConnectionService(
        invoke: (name, payload) async {
          invokedFn = name;
          invokedPayload = payload;
          if (name == 'createInvite') return {'code': 'ORB44X'};
          if (name == 'redeemInvite') return {'coachId': 'coach_1'};
          return const {};
        },
      );

      // A) Coach erzeugt Einladungscode
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            v1CoachConnectionServiceProvider.overrideWithValue(fakeService),
            settingsControllerProvider.overrideWith(
              () => _TestSettingsController(languageCode: 'de'),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: const V1CoachAthletesTab(athletesOverride: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('coach_generate_invite_btn')));
      await tester.pumpAndSettle();
      expect(invokedFn, equals('createInvite'));
      expect(find.text('ORB44X'), findsOneWidget);

      // B) Athlet gibt Code ein -> Button bleibt ohne DSGVO-Haken deaktiviert
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            v1CoachConnectionServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: V1AthleteCoachConnectionCard(
                  lang: 'de',
                  linksOverride: [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('athlete_invite_code_input')),
        'ORB44X',
      );
      await tester.pumpAndSettle();

      // Ohne DSGVO-Bestätigung gesperrt
      final connectBtnBefore = tester.widget<FilledButton>(
        find.byKey(const Key('athlete_connect_code_btn')),
      );
      expect(connectBtnBefore.onPressed, isNull);

      // DSGVO-Checkbox setzen & verbinden
      await tester.tap(find.byKey(const Key('athlete_code_gdpr_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('athlete_connect_code_btn')));
      await tester.pumpAndSettle();

      expect(invokedFn, equals('redeemInvite'));
      expect(invokedPayload?['code'], equals('ORB44X'));
    });

    testWidgets(
        '4. Eingehende Coach-Anfrage erfordert DSGVO-Freigabe vor Bestätigung',
        (tester) async {
      String? invokedFn;
      Map<String, dynamic>? invokedPayload;
      final fakeService = V1CoachConnectionService(
        invoke: (name, payload) async {
          invokedFn = name;
          invokedPayload = payload;
          return {'success': true};
        },
      );

      const pendingLink = V1CoachAthleteLink(
        linkId: 'ath1_coach1',
        athleteId: 'ath1',
        coachId: 'coach1',
        status: 'PENDING',
        coachName: 'Coach Laura',
        coachEmail: 'laura@orbit.training',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            v1CoachConnectionServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: V1AthleteCoachConnectionCard(
                  lang: 'de',
                  linksOverride: [pendingLink],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Eingehende Coach-Anfrage'), findsOneWidget);
      expect(
        find.text('Coach Laura (laura@orbit.training)'),
        findsOneWidget,
      );

      // Bestätigen-Button vor DSGVO-Haken deaktiviert
      final acceptBtnBefore = tester.widget<FilledButton>(
        find.byKey(const Key('accept_coach_btn_ath1_coach1')),
      );
      expect(acceptBtnBefore.onPressed, isNull);

      // DSGVO-Haken setzen und bestätigen
      await tester.tap(
        find.byKey(const Key('pending_gdpr_checkbox_ath1_coach1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accept_coach_btn_ath1_coach1')));
      await tester.pumpAndSettle();

      expect(invokedFn, equals('respondToCoachLinkRequest'));
      expect(invokedPayload?['linkId'], equals('ath1_coach1'));
      expect(invokedPayload?['accept'], isTrue);
      expect(invokedPayload?['gdprConsent'], isTrue);
    });

    testWidgets(
        '5. Aktive Coach-Verbindung lässt sich vom Athleten mit 1 Klick trennen',
        (tester) async {
      String? revokedLinkId;
      final fakeService = V1CoachConnectionService(
        invoke: (name, payload) async {
          if (name == 'revokeLink') {
            revokedLinkId = payload['linkId'] as String?;
          }
          return {'success': true};
        },
      );

      const activeLink = V1CoachAthleteLink(
        linkId: 'ath1_coach1',
        athleteId: 'ath1',
        coachId: 'coach1',
        status: 'ACTIVE',
        coachName: 'Coach Tim',
        coachEmail: 'tim@orbit.training',
        shareActivities: true,
        shareCalendar: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            v1CoachConnectionServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildDarkTheme(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: V1AthleteCoachConnectionCard(
                  lang: 'de',
                  linksOverride: [activeLink],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coach Tim'), findsOneWidget);
      expect(find.text('Verbunden'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('disconnect_coach_btn_ath1_coach1')),
      );
      await tester.pumpAndSettle();

      expect(revokedLinkId, equals('ath1_coach1'));
    });

    testWidgets(
        '6. Coach-Athleten-Übersicht zeigt Triathlon-Icon, Wohnland-Datum & wechselt in Kalender',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsControllerProvider.overrideWith(
            () => _TestSettingsController(
              languageCode: 'de',
              countryCode: 'DE',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final athlete = V1CoachAthleteLink(
        linkId: 'ath_tri_coach1',
        athleteId: 'ath_tri',
        coachId: 'coach1',
        status: 'ACTIVE',
        athleteName: 'Elena Tri',
        athleteEmail: 'elena@orbit.training',
        athleteSports: const ['TRIATHLON', 'BIKE'],
        lastActivityAt: DateTime(2026, 10, 21, 19, 54),
        shareActivities: true,
        shareCalendar: true,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: V1CoachAthletesTab(athletesOverride: [athlete]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Elena Tri'), findsOneWidget);
      expect(find.byType(TriathlonCombinedIcon), findsOneWidget);
      expect(
        find.textContaining('Letztes Training: 21.10.26 • 19:54'),
        findsOneWidget,
      );

      // Tippen auf Athlet wählt athleteId aus und wechselt auf Tab 1 (Kalender)
      await tester.tap(find.byKey(const Key('coach_athlete_card_ath_tri')));
      await tester.pumpAndSettle();

      expect(
        container.read(v1SelectedCoachAthleteIdProvider),
        equals('ath_tri'),
      );
      expect(container.read(v1CoachTabIndexProvider), equals(1));
    });

    testWidgets(
        '7. Coach-Kalender wechselt Athleten und übergibt athleteId an FitDownloadService',
        (tester) async {
      String? requestedStoragePath;
      final mockFitService = FitDownloadService(
        loadBytes: (path) async {
          requestedStoragePath = path;
          return Uint8List.fromList([0x0E, 0x10, 0x46, 0x49, 0x54]);
        },
        saveFile: ({
          required String fileName,
          required Uint8List bytes,
          required String dialogTitle,
        }) async =>
            Uri.file('/tmp/$fileName'),
      );

      final now = DateTime.now();
      final localDateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final athlete1Activity = Activity(
        id: 'act_42',
        athleteId: 'athlete_tri_1',
        title: 'Koppeltraining Bonn',
        sport: 'BIKE',
        startTimeUtc: now,
        localDate: localDateStr,
        durationSec: 3600,
        distanceM: 42500,
      );

      final athletes = [
        const V1CoachAthleteLink(
          linkId: 'athlete_tri_1_c1',
          athleteId: 'athlete_tri_1',
          coachId: 'c1',
          status: 'ACTIVE',
          athleteName: 'Elena Tri',
          shareActivities: true,
        ),
        const V1CoachAthleteLink(
          linkId: 'athlete_run_2_c1',
          athleteId: 'athlete_run_2',
          coachId: 'c1',
          status: 'ACTIVE',
          athleteName: 'Lukas Run',
          shareActivities: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsControllerProvider.overrideWith(
              () => _TestSettingsController(languageCode: 'de'),
            ),
            selectedCalendarDateProvider.overrideWith((ref) => now),
            calendarViewModeProvider
                .overrideWith((ref) => CalendarViewMode.list),
            fitDownloadServiceProvider.overrideWithValue(mockFitService),
            activitiesProvider.overrideWith(
              (ref) => Stream.value([athlete1Activity]),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: Scaffold(
              body: V1CoachCalendarTab(athletesOverride: athletes),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Athleten-Auswahlleiste oben und COROS-Vorschaukarte sichtbar
      expect(
        find.byKey(const Key('coach_calendar_athlete_selector')),
        findsOneWidget,
      );
      expect(find.text('Elena Tri'), findsOneWidget);
      expect(find.text('Lukas Run'), findsOneWidget);
      expect(find.byType(HomeRecentActivityCard), findsOneWidget);
      expect(find.text('Koppeltraining Bonn'), findsOneWidget);

      // Klick auf .FIT-Download-Button lädt exakt users/athlete_tri_1/rawActivities/act_42.fit
      await tester.tap(find.byKey(const Key('fit_download_button_act_42')));
      await tester.pumpAndSettle();

      expect(
        requestedStoragePath,
        equals('users/athlete_tri_1/rawActivities/act_42.fit'),
      );
    });

    testWidgets(
        '8. Profil Einfach ist für Coach & Athlet editierbar und speichert Stammdaten (DE & EN)',
        (tester) async {
      Map<String, dynamic>? savedCoachPayload;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(
                const GarminStatus(state: GarminConnectionState.disconnected),
              ),
            ),
            settingsControllerProvider.overrideWith(
              () => _TestSettingsController(
                languageCode: 'en',
                countryCode: 'DE',
              ),
            ),
          ],
          child: MaterialApp(
            theme: OrbitProfessionalTheme.buildLightTheme(),
            home: V1SimpleProfileView(
              initialUserDocOverride: const {
                'role': 'TRAINER',
                'profile': {
                  'firstName': 'Jonas',
                  'lastName': 'Coach',
                  'countryCode': 'DE',
                  'coachBio': 'Triathlon',
                },
              },
              onSaveOverride: (payload) async {
                savedCoachPayload = payload;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Simple Profile'), findsOneWidget);
      expect(find.text('Coaching Focus / Bio'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('v1_profile_first_name_field')),
        'Jonas-Updated',
      );
      await tester.enterText(
        find.byKey(const Key('v1_profile_coach_bio_field')),
        'Ironman & Cycling',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('v1_profile_save_button')),
      );
      await tester.tap(find.byKey(const Key('v1_profile_save_button')));
      await tester.pumpAndSettle();

      expect(savedCoachPayload, isNotNull);
      final profile = savedCoachPayload!['profile'] as Map<String, dynamic>;
      expect(profile['firstName'], equals('Jonas-Updated'));
      expect(profile['coachBio'], equals('Ironman & Cycling'));
    });
  });
}
