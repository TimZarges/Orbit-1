import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/error/orbit_error_handler.dart';
import 'package:orbit/features/activities/models/activity_stream.dart';
import 'package:orbit/features/activities/widgets/telemetry_map_widget.dart';
import 'package:orbit/features/beta_feedback/models/beta_feedback_report.dart';
import 'package:orbit/features/beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import 'package:orbit/features/onboarding/screens/onboarding_screen.dart';

void main() {
  group('Phase 19.1 - Guided Mobile-First Onboarding Assistent', () {
    testWidgets('4-Schritte Flow von Rolle bis DSGVO-Abschluss',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      OnboardingSubmissionData? submittedData;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(
              onCompleteOverride: (data) async {
                submittedData = data;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Schritt 1: Rolle & Profil
      expect(find.text('Willkommen bei ORBIT'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_role_athlete')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_role_trainer')), findsOneWidget);

      // Name eingeben
      await tester.enterText(
        find.byKey(const Key('onboarding_name_field')),
        'Alex Tester',
      );
      await tester.pumpAndSettle();

      // Sportart wählen (zusätzlich Schwimmen)
      await tester.tap(find.byKey(const Key('onboarding_sport_SWIM')));
      await tester.pumpAndSettle();

      // Weiter zu Schritt 2
      final nextBtn1 = find.byKey(const Key('onboarding_next_button'));
      expect(tester.widget<ElevatedButton>(nextBtn1).enabled, isTrue);
      await tester.tap(nextBtn1);
      await tester.pumpAndSettle();

      // Schritt 2: Schwellen & Zonen
      expect(find.text('Physiologische Basiswerte & Zonen'), findsOneWidget);
      expect(
        find.byKey(const Key('onboarding_auto_estimate_button')),
        findsOneWidget,
      );

      // Option wählen: Automatisch aus ersten Trainings berechnen
      await tester
          .tap(find.byKey(const Key('onboarding_auto_estimate_button')));
      await tester.pumpAndSettle();

      // Weiter zu Schritt 3
      final nextBtn2 = find.byKey(const Key('onboarding_next_button'));
      expect(tester.widget<ElevatedButton>(nextBtn2).enabled, isTrue);
      await tester.tap(nextBtn2);
      await tester.pumpAndSettle();

      // Schritt 3: Datenquelle
      expect(find.byKey(const Key('onboarding_source_garmin')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_source_later')), findsOneWidget);

      // "Später verbinden" auswählen
      await tester.tap(find.byKey(const Key('onboarding_source_later')));
      await tester.pumpAndSettle();

      // Weiter zu Schritt 4
      final nextBtn3 = find.byKey(const Key('onboarding_next_button'));
      expect(tester.widget<ElevatedButton>(nextBtn3).enabled, isTrue);
      await tester.tap(nextBtn3);
      await tester.pumpAndSettle();

      // Schritt 4: Coach-Link & DSGVO
      expect(find.text('Trainer-Kopplung & Datenschutz'), findsOneWidget);
      expect(
        find.byKey(const Key('onboarding_invite_code_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_gdpr_consent_checkbox')),
        findsOneWidget,
      );

      // Einladungscode eingeben
      await tester.enterText(
        find.byKey(const Key('onboarding_invite_code_field')),
        'TRN123',
      );
      await tester.pumpAndSettle();

      // Finish Button vor DSGVO-Zustimmung tippen -> Warnung wird angezeigt
      final finishBtn = find.byKey(const Key('onboarding_finish_button'));
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('Bitte willige'), findsOneWidget);

      // DSGVO Checkbox anhaken
      await tester
          .tap(find.byKey(const Key('onboarding_gdpr_consent_checkbox')));
      await tester.pumpAndSettle();

      // Jetzt wird das Onboarding erfolgreich abgeschlossen
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Verifikation des eingereichten Payloads
      expect(submittedData, isNotNull);
      expect(submittedData!.role, equals('ATHLETE'));
      expect(submittedData!.displayName, equals('Alex Tester'));
      expect(submittedData!.sports, containsAll(['BIKE', 'RUN', 'SWIM']));
      expect(submittedData!.autoEstimateThresholds, isTrue);
      expect(submittedData!.selectedDataSource, equals('LATER'));
      expect(submittedData!.inviteCode, equals('TRN123'));
      expect(submittedData!.healthConsentAccepted, isTrue);
    });
  });

  group('Phase 19.2 - Central Error Handling (OrbitErrorHandler)', () {
    setUp(() {
      OrbitErrorHandler.clearLogs();
    });

    test('Bilingual Error Translation & Actionability', () {
      final deMsg = OrbitErrorHandler.resolve(
        Exception('permission-denied: insufficient privileges'),
        languageCode: 'de',
      );
      expect(deMsg.title, equals('Zugriff nicht erlaubt'));
      expect(deMsg.canRetry, isFalse);

      final enMsg = OrbitErrorHandler.resolve(
        Exception('permission-denied: insufficient privileges'),
        languageCode: 'en',
      );
      expect(enMsg.title, equals('Access denied'));
      expect(enMsg.canRetry, isFalse);

      final garminMsg = OrbitErrorHandler.resolve(
        Exception('Garmin API request deadline-exceeded'),
        languageCode: 'de',
        contextHint: 'garmin-sync',
      );
      expect(garminMsg.title, contains('Garmin'));
      expect(garminMsg.canRetry, isTrue);
    });

    test('PII Sanitization masks emails and tokens', () {
      const rawLog =
          'User user.test+beta@orbit.training failed with oauth_token=secret_xyz123!';
      final sanitized = OrbitErrorHandler.sanitizeLogText(rawLog);

      expect(sanitized, isNot(contains('user.test+beta@orbit.training')));
      expect(sanitized, contains('<redacted-email>'));
      expect(sanitized, isNot(contains('secret_xyz123')));
      expect(sanitized, contains('oauth_token=<redacted>'));
    });

    test('Recent Logs Ring Buffer caps at maxLogEntries (20)', () {
      for (int i = 0; i < 35; i++) {
        OrbitErrorHandler.recordLog('Log message #$i');
      }

      final logs = OrbitErrorHandler.recentLogs;
      expect(logs.length, equals(OrbitErrorHandler.maxLogEntries));
      expect(logs.first, contains('Log message #15'));
      expect(logs.last, contains('Log message #34'));
    });

    testWidgets('OrbitErrorBanner displays message, retry and report buttons',
        (WidgetTester tester) async {
      bool retryPressed = false;
      bool reportPressed = false;

      const error = FormatException('Failed to parse telemetry');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrbitErrorBanner(
              error: error,
              languageCode: 'de',
              onRetry: () => retryPressed = true,
              onReportIssue: () => reportPressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrbitErrorBanner), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(find.text('Problem melden'), findsOneWidget);

      await tester.tap(find.text('Erneut versuchen'));
      expect(retryPressed, isTrue);

      await tester.tap(find.text('Problem melden'));
      expect(reportPressed, isTrue);
    });

    testWidgets('BetaBugReporterSheet validation and report submission',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      BetaFeedbackReport? capturedReport;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                BetaBugReportIconButton(
                  onSubmitOverride: (report, bytes) async {
                    capturedReport = report;
                  },
                ),
              ],
            ),
            body: const Center(child: Text('Dashboard')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bug Icon antippen
      await tester.tap(find.byKey(const Key('beta_bug_report_icon_button')));
      await tester.pumpAndSettle();

      expect(find.text('Beta Bug- & Feedback-Reporter'), findsOneWidget);
      expect(
        find.byKey(const Key('beta_feedback_description_field')),
        findsOneWidget,
      );

      // Klick auf Absenden ohne Beschreibung zeigt Validierungsfehler
      await tester.tap(find.byKey(const Key('beta_feedback_submit_button')));
      await tester.pumpAndSettle();
      expect(
        find.text('Bitte beschreibe kurz, was passiert ist.'),
        findsOneWidget,
      );

      // Kategorie ändern auf "Falsche Berechnung"
      await tester
          .tap(find.byKey(const Key('beta_category_WRONG_CALCULATION')));
      await tester.pumpAndSettle();

      // Gültige Beschreibung eingeben
      await tester.enterText(
        find.byKey(const Key('beta_feedback_description_field')),
        'Normalized Power zeigt 0 Watt trotz 250 Watt Durchschnitt.',
      );
      await tester.pumpAndSettle();

      // Absenden
      await tester.tap(find.byKey(const Key('beta_feedback_submit_button')));
      await tester.pumpAndSettle();

      expect(capturedReport, isNotNull);
      expect(
        capturedReport!.category,
        equals(BetaFeedbackCategory.wrongCalculation),
      );
      expect(
        capturedReport!.description,
        contains('Normalized Power zeigt 0 Watt'),
      );
      expect(capturedReport!.includeDiagnostics, isTrue);
      expect(capturedReport!.diagnostics, isNotNull);
    });
  });

  group('Phase 19.3 - Real Map Tiles (TelemetryMapWidget) & GDPR Opt-In', () {
    final samplePoints = [
      ActivityStreamPoint(
        timeSec: 0,
        lat: 50.1109,
        lng: 8.6821,
        power: 180,
        hr: 135,
        speedMps: 7.5,
      ),
      ActivityStreamPoint(
        timeSec: 60,
        lat: 50.1120,
        lng: 8.6840,
        power: 240,
        hr: 155,
        speedMps: 8.2,
      ),
      ActivityStreamPoint(
        timeSec: 120,
        lat: 50.1135,
        lng: 8.6865,
        power: 290,
        hr: 172,
        speedMps: 9.0,
      ),
    ];

    testWidgets(
        'DSGVO-Default ohne Kacheln rendert Vektor-Track vor Navy #001F47 und Opt-In Button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelemetryMapWidget(
              points: samplePoints,
              initialTilesEnabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Karte und Start/Ziel-Marker sind gerendert
      expect(
        find.byKey(const Key('telemetry_map_container')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('telemetry_map_start_marker')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('telemetry_map_finish_marker')),
        findsOneWidget,
      );

      // Opt-in Button ist sichtbar
      expect(
        find.byKey(const Key('telemetry_map_optin_button')),
        findsOneWidget,
      );
      expect(find.textContaining('Kartenkacheln aktivieren'), findsOneWidget);

      // Klick auf Opt-in Button öffnet DSGVO-Dialog
      await tester.tap(find.byKey(const Key('telemetry_map_optin_button')));
      await tester.pumpAndSettle();

      expect(find.text('Externe Kartenkacheln aktivieren?'), findsOneWidget);
      expect(
        find.byKey(const Key('telemetry_map_confirm_optin_button')),
        findsOneWidget,
      );

      // Dialog bestätigen
      await tester
          .tap(find.byKey(const Key('telemetry_map_confirm_optin_button')));
      await tester.pumpAndSettle();

      // Nach Bestätigung ist Kachel-Status aktiv ("Kartenkacheln aktiv")
      expect(find.textContaining('Kartenkacheln aktiv'), findsOneWidget);
    });

    testWidgets('Farbcodierungs-Umschaltung nach HF-Zone, Watt-Zone und Pace',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelemetryMapWidget(
              points: samplePoints,
              initialTilesEnabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('telemetry_map_mode_powerZone')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('telemetry_map_mode_heartRateZone')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('telemetry_map_mode_paceSpeed')),
        findsOneWidget,
      );

      // Umschalten auf HF-Zone
      await tester
          .tap(find.byKey(const Key('telemetry_map_mode_heartRateZone')));
      await tester.pumpAndSettle();

      // Umschalten auf Pace/Speed
      await tester.tap(find.byKey(const Key('telemetry_map_mode_paceSpeed')));
      await tester.pumpAndSettle();
    });

    testWidgets('Live Scrubbing synchronisiert Marker auf der Karte',
        (WidgetTester tester) async {
      final scrubPt = samplePoints[1];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelemetryMapWidget(
              points: samplePoints,
              scrubPoint: scrubPt,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('telemetry_map_scrub_marker')),
        findsOneWidget,
      );
    });
  });
}
