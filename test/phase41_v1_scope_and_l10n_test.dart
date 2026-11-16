/// Datei-Header: `test/phase41_v1_scope_and_l10n_test.dart`
/// Zweck: Automatisierte Unit- und Widget-Tests für Phase 41 (`v0.41.0`):
/// 1. `ReleaseConfig` Feature-Steuerung (Standard V1.0.0: `isV2Enabled = false`,
///    `isV3Enabled = false`, Ausblendung der 3 Daily Health Ringe, Readiness-Score,
///    Workout-Builder/Analyse-Tabs im V1.0.0-Standardbetrieb sowie Test-Override).
/// 2. Clean Professional Design System (`OrbitProfessionalTheme`: Dark `#0D0F12` /
///    `#16181D` / `0x14FFFFFF` vs. Light `#F4F6F9` / `#FFFFFF` / `#E2E8F0` / `#0F172A`).
/// 3. Vollständige Zweisprachigkeit (`DE` & `EN`) und `CountryDateTimeFormatter`
///    (`dd.mm.yy` & `24h`-Format nach Wohnland).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/config/release_config.dart';
import 'package:orbit/core/design/app_theme.dart';
import 'package:orbit/core/theme/orbit_professional_theme.dart';
import 'package:orbit/core/utils/country_date_time_formatter.dart';
import 'package:orbit/features/activities/models/activity.dart';
import 'package:orbit/features/activities/providers/activities_provider.dart';
import 'package:orbit/features/activities/screens/today_tab_screen.dart';
import 'package:orbit/features/auth/providers/user_provider.dart';
import 'package:orbit/features/calendar/providers/calendar_provider.dart';
import 'package:orbit/features/coach_link/providers/athlete_context_provider.dart';
import 'package:orbit/features/dashboard/screens/dashboard_screen.dart';
import 'package:orbit/features/health/widgets/readiness_card.dart';
import 'package:orbit/features/home/models/home_dashboard_data.dart';
import 'package:orbit/features/home/providers/home_dashboard_provider.dart';
import 'package:orbit/features/home/widgets/daily_ring_widget.dart';
import 'package:orbit/features/home/widgets/home_hero_card.dart';
import 'package:orbit/features/settings/providers/settings_provider.dart';
import 'package:orbit/features/settings/screens/settings_screen.dart';

void main() {
  tearDown(() {
    // Stellt nach jedem Test den strikten V1.0.0-Standardzustand wieder her
    ReleaseConfig.resetTestingOverrides();
  });

  group('1. ReleaseConfig & V1.0.0 Scope-Steuerung', () {
    test('Standardwerte im App-Betrieb sind strikt V1.0.0 (v2=false, v3=false)',
        () {
      ReleaseConfig.resetTestingOverrides();
      expect(ReleaseConfig.isV2Enabled, isFalse);
      expect(ReleaseConfig.isV3Enabled, isFalse);
      expect(ReleaseConfig.currentState.isStrictV1, isTrue);
    });

    test('overrideForTesting aktiviert V2/V3 gezielt für Bestands-Tests', () {
      ReleaseConfig.overrideForTesting(v2: true, v3: true);
      expect(ReleaseConfig.isV2Enabled, isTrue);
      expect(ReleaseConfig.isV3Enabled, isTrue);
      expect(ReleaseConfig.currentState.isStrictV1, isFalse);

      ReleaseConfig.resetTestingOverrides();
      expect(ReleaseConfig.isV2Enabled, isFalse);
      expect(ReleaseConfig.isV3Enabled, isFalse);
    });

    testWidgets(
        'V1.0.0-Standardmodus blendet 3 Daily Health Ringe, ReadinessCard und Analyse-Tab aus und zeigt COROS-Karte mit .FIT-Download',
        (tester) async {
      final sampleActivity = Activity(
        id: 'act_v1_test',
        athleteId: 'athlete_1',
        sport: 'BIKE',
        title: 'Bonn Ausfahrt',
        startTimeUtc: DateTime(2026, 10, 21, 19, 54),
        localDate: '2026-10-21',
        durationSec: 3600,
        distanceM: 32500,
        summary: ActivitySummary(avgPowerW: 215, avgHr: 142),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAthleteIdProvider.overrideWithValue('athlete_1'),
            viewedAthleteIdProvider.overrideWith((ref) => 'athlete_1'),
            userDocumentProvider
                .overrideWith((ref) => Stream.value({'role': 'ATHLETE'})),
            homeDashboardProvider('athlete_1').overrideWith(
              (ref) => Future.value(
                HomeDashboardData(
                  todayLocalDate: '2026-10-21',
                  latestActivity: sampleActivity,
                ),
              ),
            ),
            activitiesProvider
                .overrideWith((ref) => Stream.value([sampleActivity])),
            athleteCurrentWeekWorkoutsProvider('athlete_1')
                .overrideWith((ref) => Stream.value([])),
            athleteCurrentMonthWorkoutsProvider('athlete_1')
                .overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Keine V3 Health-Ringe oder ReadinessCard im V1.0.0-Standardmodus
      expect(find.byType(HomeHeroCard), findsNothing);
      expect(find.byType(DailyRingWidget), findsNothing);
      expect(find.byType(ReadinessCard), findsNothing);

      // 2. Kein Analyse-Tab in der V1.0.0 BottomNavigationBar
      expect(find.text('Analyse'), findsNothing);
      expect(find.text('Heute'), findsWidgets);
      expect(find.text('Kalender'), findsOneWidget);
      expect(find.text('Coach'), findsOneWidget);

      // 3. Heute-Ansicht zeigt Schnellzugriff (Garmin Sync & Datei-Upload) + absolviertes Training
      expect(
        find.byKey(const Key('v1_today_quick_actions_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('v1_today_garmin_sync_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('v1_today_file_upload_button')),
        findsOneWidget,
      );
      expect(find.text('Bonn Ausfahrt'), findsOneWidget);

      // 4. COROS-Karte zeigt .FIT-Download-Button rechts und Datum als dd.mm.yy • 24h (21.10.26 • 19:54)
      expect(
        find.byKey(const Key('fit_download_button_act_v1_test')),
        findsOneWidget,
      );
      expect(find.text('21.10.26 • 19:54'), findsOneWidget);
      // Kein "Im Analyse-Cockpit öffnen" Button in V1.0.0
      expect(find.text('Im Analyse-Cockpit öffnen'), findsNothing);
    });

    testWidgets(
        'Mit ReleaseConfig.overrideForTesting(v2: true, v3: true) werden 3 Ringe und Cockpit-Button wieder gerendert',
        (tester) async {
      ReleaseConfig.overrideForTesting(v2: true, v3: true);

      final sampleActivity = Activity(
        id: 'act_v3_test',
        athleteId: 'athlete_1',
        sport: 'RUN',
        title: 'Tempolauf',
        startTimeUtc: DateTime(2026, 10, 21, 18, 30),
        localDate: '2026-10-21',
        durationSec: 2700,
        distanceM: 10000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAthleteIdProvider.overrideWithValue('athlete_1'),
            viewedAthleteIdProvider.overrideWith((ref) => 'athlete_1'),
            homeDashboardProvider('athlete_1').overrideWith(
              (ref) => Future.value(
                HomeDashboardData(
                  todayLocalDate: '2026-10-21',
                  latestActivity: sampleActivity,
                ),
              ),
            ),
            activitiesProvider
                .overrideWith((ref) => Stream.value([sampleActivity])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const TodayTabScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeHeroCard), findsOneWidget);
      expect(find.text('Im Analyse-Cockpit öffnen'), findsOneWidget);
    });
  });

  group('2. Clean Professional Design System (Hell & Dunkel)', () {
    test('Dark Mode nutzt #0D0F12 Carbon, #16181D Karten und 8% Weiß-Rahmen',
        () {
      final dark = AppTheme.darkTheme;
      expect(dark.brightness, equals(Brightness.dark));
      expect(
        dark.scaffoldBackgroundColor,
        equals(const Color(0xFF0D0F12)),
      );
      expect(
        dark.cardTheme.color,
        equals(const Color(0xFF16181D)),
      );
      final shape = dark.cardTheme.shape as RoundedRectangleBorder;
      expect(
        shape.side.color,
        equals(OrbitProfessionalTheme.darkSubtleBorder),
      );
      expect(shape.side.width, equals(1.0));
    });

    test(
        'Light Mode nutzt #F4F6F9 Alabaster, #FFFFFF Karten, #E2E8F0 Rahmen und #0F172A Typografie',
        () {
      final light = AppTheme.lightTheme;
      expect(light.brightness, equals(Brightness.light));
      expect(
        light.scaffoldBackgroundColor,
        equals(const Color(0xFFF4F6F9)),
      );
      expect(
        light.cardTheme.color,
        equals(const Color(0xFFFFFFFF)),
      );
      final shape = light.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, equals(const Color(0xFFE2E8F0)));
      expect(
        light.colorScheme.onSurface,
        equals(const Color(0xFF0F172A)),
      );
    });
  });

  group('3. CountryDateTimeFormatter (dd.mm.yy & 24h nach Wohnland)', () {
    test('formatiert Datum strikt als dd.mm.yy und Zeit als 24h HH:mm', () {
      final sample = DateTime(2026, 10, 21, 19, 54);
      for (final country in ['DE', 'AT', 'CH', 'NL', 'FR', 'IT', 'ES']) {
        expect(
          CountryDateTimeFormatter.formatDate(sample, countryCode: country),
          equals('21.10.26'),
        );
        expect(
          CountryDateTimeFormatter.formatTime24h(sample, countryCode: country),
          equals('19:54'),
        );
        expect(
          CountryDateTimeFormatter.formatDateTime(sample, countryCode: country),
          equals('21.10.26 • 19:54'),
        );
        expect(
          CountryDateTimeFormatter.uses24HourFormat(countryCode: country),
          isTrue,
        );
      }
    });

    test('formatiert einstellige Tage, Monate und Morgenstunden mit führender Null',
        () {
      final morning = DateTime(2026, 3, 5, 7, 4);
      expect(
        CountryDateTimeFormatter.formatDate(morning, countryCode: 'DE'),
        equals('05.03.26'),
      );
      expect(
        CountryDateTimeFormatter.formatTime24h(morning, countryCode: 'DE'),
        equals('07:04'),
      );
      expect(
        CountryDateTimeFormatter.formatDateString('2026-10-21',
            countryCode: 'AT',),
        equals('21.10.26'),
      );
    });
  });

  group('4. Zweisprachigkeit (DE & EN) und Theme-Umschaltung in SettingsScreen',
      () {
    testWidgets(
        'Umschalten zwischen DE und EN sowie Light/Dark Mode aktualisiert UI sofort',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Standard: Deutsch (DE)
      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('Sprache'), findsOneWidget);
      expect(find.text('Darstellung'), findsOneWidget);
      expect(
        find.text('Wohnland (Datum dd.mm.yy & 24h)'),
        findsOneWidget,
      );

      // Sprache auf Englisch ('en') umschalten
      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN').last);
      await tester.pumpAndSettle();

      // UI sofort auf Englisch aktualisiert
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(
        find.text('Country of Residence (dd.mm.yy & 24h)'),
        findsOneWidget,
      );

      // Darstellung auf Dark Mode umschalten
      await tester.tap(find.byKey(const Key('settings_theme_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(
        container.read(settingsControllerProvider).themeMode,
        equals(ThemeMode.dark),
      );
      expect(
        container.read(settingsControllerProvider).languageCode,
        equals('en'),
      );
    });
  });
}
