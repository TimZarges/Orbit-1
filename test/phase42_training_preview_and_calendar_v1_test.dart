/// Datei-Header: `test/phase42_training_preview_and_calendar_v1_test.dart`
/// Zweck: Automatisierte Unit- und Widget-Tests für Phase 42 (`v0.42.0`):
/// 1. Einheitliche COROS-Vorschaukarte (`TrainingPreviewCard`): Hauptmetrik,
///    Sekundärmetriken, `dd.mm.yy • 24h` Datum, `.FIT`-Button rechts und strikt
///    nicht-klickbarer Kartenkörper bei `ReleaseConfig.isV2Enabled == false`.
/// 2. Speicherschonender `.FIT`-Download-Service (`FitDownloadService`): Erfolg,
///    Fallback-Pfad-Auflösung und `notFound`-Handling.
/// 3. Strikte V1.0.0 Heute-Ansicht (`TodayTabScreen`): Filterung auf heute
///    absolvierte Trainings + Empty-State mit Garmin Sync & Datei-Upload.
/// 4. V1.0.0 Kalender (`CalendarScreen`): Woche, Monat und Liste ohne V2-Planungs-
///    elemente und mit einheitlicher `TrainingPreviewCard`.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/config/release_config.dart';
import 'package:orbit/core/design/app_theme.dart';
import 'package:orbit/features/activities/models/activity.dart';
import 'package:orbit/features/activities/providers/activities_provider.dart';
import 'package:orbit/features/activities/screens/today_tab_screen.dart';
import 'package:orbit/features/activities/services/fit_download_service.dart';
import 'package:orbit/features/calendar/providers/calendar_provider.dart';
import 'package:orbit/features/calendar/screens/calendar_screen.dart';
import 'package:orbit/features/coach_link/providers/athlete_context_provider.dart';
import 'package:orbit/features/home/models/home_dashboard_data.dart';
import 'package:orbit/features/home/providers/home_dashboard_provider.dart';
import 'package:orbit/features/home/widgets/home_recent_activity_card.dart';

void main() {
  tearDown(() {
    ReleaseConfig.resetTestingOverrides();
  });

  group('1. TrainingPreviewCard (COROS-Stil & V1.0.0 Klick-Verhalten)', () {
    testWidgets(
        'zeigt Hauptmetrik (km), Sekundärmetriken (Dauer, W, bpm, kcal), dd.mm.yy • 24h und .FIT-Button; Körper ignoriert Tap bei isV2Enabled=false',
        (tester) async {
      ReleaseConfig.resetTestingOverrides();
      bool cockpitTapped = false;
      bool fitDownloadTapped = false;

      final bikeActivity = Activity(
        id: 'act_bike_42',
        athleteId: 'athlete_1',
        sport: 'BIKE',
        title: 'Lage Rennradfahren',
        startTimeUtc: DateTime(2026, 11, 14, 11, 39),
        localDate: '2026-11-14',
        durationSec: 3180,
        distanceM: 23600,
        summary: ActivitySummary(
          avgPowerW: 183,
          avgHr: 131,
          calories: 640,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: TrainingPreviewCard(
                activity: bikeActivity,
                onOpenCockpit: () => cockpitTapped = true,
                onDownloadFit: () => fitDownloadTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zeile 1: Hauptmetrik in km
      expect(find.text('23.6 km'), findsOneWidget);
      // Zeile 2: Sekundärmetriken (Dauer, W, bpm, kcal)
      expect(
        find.byKey(const Key('activity_secondary_metrics_act_bike_42')),
        findsOneWidget,
      );
      expect(find.textContaining('53 min'), findsOneWidget);
      expect(find.textContaining('183 W'), findsOneWidget);
      expect(find.textContaining('131 bpm'), findsOneWidget);
      expect(find.textContaining('640 kcal'), findsOneWidget);

      // Zeile 3: Titel + dd.mm.yy • 24h
      expect(find.text('Lage Rennradfahren'), findsOneWidget);
      expect(find.text('14.11.26 • 11:39'), findsOneWidget);

      // Kein Cockpit-CTA sichtbar im V1.0.0-Modus
      expect(find.text('Im Analyse-Cockpit öffnen'), findsNothing);

      // Tap auf den Kartenkörper (Titel / Hauptmetrik) darf NICHTS triggern
      await tester.tap(find.text('23.6 km'));
      await tester.pumpAndSettle();
      expect(cockpitTapped, isFalse);
      expect(fitDownloadTapped, isFalse);

      // Tap auf den .FIT-Download-Button rechts triggert den Download-Callback
      await tester
          .tap(find.byKey(const Key('fit_download_button_act_bike_42')));
      await tester.pumpAndSettle();
      expect(fitDownloadTapped, isTrue);
      expect(cockpitTapped, isFalse);
    });

    testWidgets(
        'zeigt bei Kraft-/Indoor-Einheit ohne Distanz hh:mm:ss als Hauptmetrik',
        (tester) async {
      final strengthActivity = Activity(
        id: 'act_strength_42',
        athleteId: 'athlete_1',
        sport: 'STRENGTH',
        title: 'Athletik & Core',
        startTimeUtc: DateTime(2026, 11, 15, 18, 0),
        localDate: '2026-11-15',
        durationSec: 4380,
        distanceM: 0,
        summary: ActivitySummary(avgHr: 118, calories: 380),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: TrainingPreviewCard(activity: strengthActivity),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('01:13:00'), findsOneWidget);
      expect(find.text('Athletik & Core'), findsOneWidget);
      expect(find.text('15.11.26 • 18:00'), findsOneWidget);
    });
  });

  group('2. FitDownloadService (Cloud Storage Streaming & Export)', () {
    test('lädt Original-.FIT-Datei und exportiert sie über FileSaver',
        () async {
      String? requestedPath;
      String? savedFileName;
      Uint8List? savedBytes;

      final service = FitDownloadService(
        loadBytes: (path) async {
          requestedPath = path;
          return Uint8List.fromList([14, 16, 46, 70, 73, 84]);
        },
        saveFile: ({
          required String fileName,
          required Uint8List bytes,
          required String dialogTitle,
        }) async {
          savedFileName = fileName;
          savedBytes = bytes;
          return Uri.parse('file:///tmp/$fileName');
        },
      );

      final activity = Activity(
        id: 'garmin_123',
        athleteId: 'athlete_1',
        sport: 'BIKE',
        title: 'Bonn Ausfahrt',
        startTimeUtc: DateTime(2026, 11, 14, 11, 39),
        localDate: '2026-11-14',
        durationSec: 3600,
        distanceM: 30000,
        rawFilePath: 'users/athlete_1/rawActivities/garmin_123.fit',
      );

      final result = await service.downloadFitFile(activity, lang: 'de');
      expect(result.status, equals(FitDownloadStatus.success));
      expect(
        requestedPath,
        equals('users/athlete_1/rawActivities/garmin_123.fit'),
      );
      expect(savedFileName, equals('20261114_Bonn_Ausfahrt.fit'));
      expect(savedBytes, isNotNull);
      expect(savedBytes!.length, equals(6));
    });

    test('liefert FitDownloadStatus.notFound wenn keine Rohdatei existiert',
        () async {
      final service = FitDownloadService(
        loadBytes: (_) async => null,
        saveFile: ({
          required String fileName,
          required Uint8List bytes,
          required String dialogTitle,
        }) async =>
            null,
      );

      final activity = Activity(
        id: 'legacy_act',
        athleteId: 'athlete_1',
        sport: 'RUN',
        title: 'Alt-Einheit',
        startTimeUtc: DateTime(2026, 10, 1, 9, 0),
        localDate: '2026-10-01',
        durationSec: 1800,
        distanceM: 5000,
      );

      final result = await service.downloadFitFile(activity, lang: 'de');
      expect(result.status, equals(FitDownloadStatus.notFound));
    });
  });

  group('3. TodayTabScreen V1.0.0 (Strikt nur heute absolviertes Training)',
      () {
    testWidgets(
        'zeigt heute absolvierte Einheit und filtert gestrige Einheiten aus',
        (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      String iso(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final todayAct = Activity(
        id: 'act_today',
        athleteId: 'athlete_1',
        sport: 'RUN',
        title: 'Heutiger Morgenlauf',
        startTimeUtc: DateTime(now.year, now.month, now.day, 7, 30),
        localDate: iso(now),
        durationSec: 2400,
        distanceM: 8500,
      );
      final yesterdayAct = Activity(
        id: 'act_yesterday',
        athleteId: 'athlete_1',
        sport: 'BIKE',
        title: 'Gestrige Ausfahrt',
        startTimeUtc:
            DateTime(yesterday.year, yesterday.month, yesterday.day, 17, 0),
        localDate: iso(yesterday),
        durationSec: 3600,
        distanceM: 32000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAthleteIdProvider.overrideWithValue('athlete_1'),
            viewedAthleteIdProvider.overrideWith((ref) => 'athlete_1'),
            homeDashboardProvider('athlete_1').overrideWith(
              (ref) => Future.value(
                HomeDashboardData(todayLocalDate: iso(now)),
              ),
            ),
            activitiesProvider.overrideWith(
              (ref) => Stream.value([todayAct, yesterdayAct]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TodayTabScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heutiger Morgenlauf'), findsOneWidget);
      expect(find.text('Gestrige Ausfahrt'), findsNothing);
    });

    testWidgets(
        'zeigt ruhigen Empty-State ohne Garmin Sync oder .FIT-Upload wenn heute noch keine Einheit existiert',
        (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      String iso(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final yesterdayAct = Activity(
        id: 'act_yesterday_only',
        athleteId: 'athlete_1',
        sport: 'BIKE',
        title: 'Gestrige Einheit',
        startTimeUtc:
            DateTime(yesterday.year, yesterday.month, yesterday.day, 17, 0),
        localDate: iso(yesterday),
        durationSec: 3600,
        distanceM: 30000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAthleteIdProvider.overrideWithValue('athlete_1'),
            viewedAthleteIdProvider.overrideWith((ref) => 'athlete_1'),
            homeDashboardProvider('athlete_1').overrideWith(
              (ref) => Future.value(
                HomeDashboardData(todayLocalDate: iso(now)),
              ),
            ),
            activitiesProvider
                .overrideWith((ref) => Stream.value([yesterdayAct])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const TodayTabScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Heute noch kein absolviertes Training'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Sobald heute ein Training synchronisiert wird, erscheint es hier.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('v1_today_empty_garmin_button')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('v1_today_empty_upload_button')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('today_fab_upload_button')),
        findsNothing,
      );
      expect(find.text('Gestrige Einheit'), findsNothing);
    });
  });

  group('4. CalendarScreen V1.0.0 (Woche, Monat, Liste ohne V2-Planung)', () {
    testWidgets(
        'rendert Woche, Monat und Liste mit absolvierten Trainings ohne V2-Planungs-Elemente',
        (tester) async {
      final now = DateTime.now();
      String iso(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final act = Activity(
        id: 'act_cal_1',
        athleteId: 'athlete_1',
        sport: 'BIKE',
        title: 'Kalender Radfahrt',
        startTimeUtc: DateTime(now.year, now.month, now.day, 10, 15),
        localDate: iso(now),
        durationSec: 4500,
        distanceM: 42000,
        summary: ActivitySummary(avgPowerW: 210, avgHr: 140),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAthleteIdProvider.overrideWithValue('athlete_1'),
            viewedAthleteIdProvider.overrideWith((ref) => 'athlete_1'),
            calendarViewModeProvider
                .overrideWith((ref) => CalendarViewMode.week),
            selectedCalendarDateProvider.overrideWith((ref) => now),
            activitiesProvider.overrideWith((ref) => Stream.value([act])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CalendarScreen(athleteId: 'athlete_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // V2-Planungs-Elemente dürfen in V1.0.0 nicht existieren
      expect(find.byKey(const Key('calendar_plan_workout_fab')), findsNothing);
      expect(find.text('Training planen'), findsNothing);
      expect(find.text('+ Ruhetag / Einheit planen'), findsNothing);

      // 1. Wochenansicht zeigt TrainingPreviewCard mit .FIT-Button
      expect(find.byType(TrainingPreviewCard), findsOneWidget);
      expect(find.text('Kalender Radfahrt'), findsOneWidget);
      expect(find.text('42.0 km'), findsOneWidget);
      expect(
        find.byKey(const Key('fit_download_button_act_cal_1')),
        findsOneWidget,
      );

      // 2. Umschalten auf Monatsansicht
      await tester.tap(find.text('Monat'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendar_month_grid')), findsOneWidget);
      expect(find.byType(TrainingPreviewCard), findsOneWidget);

      // 3. Umschalten auf Listenansicht
      await tester.tap(find.text('Liste'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('calendar_chronological_list')),
        findsOneWidget,
      );
      expect(find.byType(TrainingPreviewCard), findsOneWidget);
    });
  });
}
