/// Datei-Header: `test/phase46_legal_gdpr_deletion_and_release_v1_test.dart`
/// Zweck: Automatisierte Unit- und Widget-Tests für Phase 46 (`v1.0.0`):
/// 1. Release-Konfiguration & Betreiber-Stammdaten (`AppInfo` ohne „Closed Beta“,
///    `ContactConfig` mit `ORBIT Performance / ORBIT Training`, `Tim Zarges`,
///    `support@orbit-training.app`, `privacy@orbit-training.app`).
/// 2. Rechtliche 1-Klick-Dokumente (`LegalDocumentsSheet` DE & EN, Light & Dark,
///    Reiterwechsel zwischen Datenschutz & Impressum).
/// 3. LoginScreen (DE/EN-Toggle & 1-Klick-Links für Datenschutz, Impressum, Webseite).
/// 4. V1.0.0 Onboarding Schritt 3 (1-Klick-Zugang zu Datenschutz & Impressum).
/// 5. V1.0.0 Profil Einfach (`V1SimpleProfileView`: Rechtliches, 2-Stufen-Löschdialog
///    & sauberer Release-Footer `ORBIT v1.0.0 (Build 1)`).
/// 6. Zweistufiger Kontolösch-Dialog (`TwoStepAccountDeletionDialog` DE & EN,
///    Schritt 1 -> Schritt 2 -> Checkbox-Sperre -> Lösch-Callback) sowie
///    [AccountDeletionService] (`deleteAccountAndSignOut()`).
/// 7. Einstellungen (`SettingsScreen`: 1-Klick Impressum/Datenschutz & Kontolöschung).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/config/app_config.dart';
import 'package:orbit/core/config/contact_config.dart';
import 'package:orbit/core/config/release_config.dart';
import 'package:orbit/core/design/app_theme.dart';
import 'package:orbit/features/activities/providers/activities_provider.dart';
import 'package:orbit/features/auth/providers/auth_provider.dart';
import 'package:orbit/features/auth/providers/user_provider.dart';
import 'package:orbit/features/auth/screens/login_screen.dart';
import 'package:orbit/features/auth/services/account_deletion_service.dart';
import 'package:orbit/features/auth/widgets/email_verification_banner.dart';
import 'package:orbit/features/auth/widgets/two_step_account_deletion_dialog.dart';
import 'package:orbit/features/beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import 'package:orbit/features/beta_feedback/widgets/global_floating_bug_beetle.dart';
import 'package:orbit/features/coach_link/models/v1_coach_athlete_link.dart';
import 'package:orbit/features/coach_link/providers/athlete_context_provider.dart';
import 'package:orbit/features/coach_link/providers/v1_coach_connection_provider.dart';
import 'package:orbit/features/dashboard/screens/dashboard_screen.dart';
import 'package:orbit/features/integrations/models/garmin_status.dart';
import 'package:orbit/features/integrations/providers/garmin_provider.dart';
import 'package:orbit/features/legal/widgets/legal_documents_sheet.dart';
import 'package:orbit/features/onboarding/widgets/v1_simple_onboarding_wizard.dart';
import 'package:orbit/features/profile/widgets/user_avatar_circle.dart';
import 'package:orbit/features/profile/widgets/v1_simple_profile_view.dart';
import 'package:orbit/features/settings/screens/settings_screen.dart';

/// Test-Mock für [AuthService] zur Verifikation von Sign-out nach Kontolöschung.
class _MockAuthService implements AuthService {
  bool signOutCalled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

/// Minimaler Mock für einen Firebase-[User] zur Prüfung des Verifikations-Banners.
class _FakeVerifyUser implements User {
  @override
  final bool emailVerified;

  @override
  final String? email;

  _FakeVerifyUser({required this.emailVerified, this.email});

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  tearDown(() {
    ReleaseConfig.resetTestingOverrides();
  });

  group('1. Release-Konfiguration & Betreiberdaten (V1.0.0)', () {
    test('AppInfo trägt Version v1.0.0 (Build 1) ohne Closed-Beta-Banner', () {
      expect(AppInfo.version, equals('1.0.0'));
      expect(AppInfo.buildNumber, equals(1));
      expect(AppInfo.environment, equals('Release'));
      expect(AppInfo.fullVersionString, equals('v1.0.0 (Build 1)'));
      expect(AppInfo.fullVersionString.contains('Closed Beta'), isFalse);
    });

    test('ContactConfig enthält verbindliche ORBIT-Marken- und Betreiberdaten',
        () {
      expect(
        ContactConfig.brandName,
        equals('ORBIT Performance / ORBIT Training'),
      );
      expect(
        ContactConfig.operatorName,
        equals('ORBIT Endurance Technologies'),
      );
      expect(ContactConfig.representativeName, equals('Tim Zarges'));
      expect(ContactConfig.supportEmail, equals('support@orbit-training.app'));
      expect(ContactConfig.privacyEmail, equals('privacy@orbit-training.app'));
      expect(
        ContactConfig.serverRegion,
        equals('Frankfurt am Main (europe-west3, EU)'),
      );
    });
  });

  group('2. LegalDocumentsSheet (DE & EN, Light & Dark Mode)', () {
    testWidgets('rendert Datenschutz und wechselt auf Impressum in DE & EN',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: LegalDocumentsSheet(
              initialTab: LegalDocumentTab.privacy,
              lang: 'de',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('legal_documents_sheet')), findsOneWidget);
      expect(
        find.textContaining('Datenschutzerklärung (DSGVO Art. 9, 13, 14 & 17)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Art. 9 Abs. 2 lit. a DSGVO'),
        findsOneWidget,
      );
      final listView = tester.widget<ListView>(find.byType(ListView).first);
      listView.controller?.jumpTo(280);
      await tester.pumpAndSettle();
      expect(find.textContaining('Frankfurt am Main'), findsWidgets);

      // Auf Impressum-Reiter wechseln
      await tester.tap(find.text('Impressum'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tim Zarges'), findsWidgets);
      expect(find.textContaining('support@orbit-training.app'), findsWidgets);

      // Englische Darstellung im Dark Mode prüfen
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: LegalDocumentsSheet(
              initialTab: LegalDocumentTab.privacy,
              lang: 'en',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Legal Notice'), findsOneWidget);
    });
  });

  group('3. 1-Klick-Zugang im Login, Onboarding, Profil & Einstellungen', () {
    testWidgets('LoginScreen bietet DE/EN-Toggle und 1-Klick-Rechtslinks',
        (tester) async {
      final mockAuth = _MockAuthService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(mockAuth)],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_lang_toggle_button')), findsOneWidget);
      expect(find.byKey(const Key('login_privacy_button')), findsOneWidget);
      expect(find.byKey(const Key('login_imprint_button')), findsOneWidget);
      expect(find.byKey(const Key('login_website_button')), findsOneWidget);

      // Datenschutz-Sheet direkt per 1 Klick öffnen
      await tester.ensureVisible(find.byKey(const Key('login_privacy_button')));
      await tester.tap(find.byKey(const Key('login_privacy_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('legal_documents_sheet')), findsOneWidget);

      await tester.tap(find.byKey(const Key('legal_close_btn')));
      await tester.pumpAndSettle();

      // Auf Englisch umschalten
      await tester.tap(find.byKey(const Key('login_lang_toggle_button')));
      await tester.pumpAndSettle();
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Legal Notice'), findsOneWidget);
    });

    testWidgets(
        'V1SimpleOnboardingWizard bietet in Schritt 3 1-Klick-Zugang zu Datenschutz & Impressum',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const V1SimpleOnboardingWizard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Schritt 1 -> Schritt 2
      await tester.tap(find.byKey(const Key('v1_onboarding_next_button')));
      await tester.pumpAndSettle();

      // Pflichtfelder Vorname & Nachname füllen -> Schritt 3
      await tester.enterText(
        find.byKey(const Key('v1_onboarding_first_name_field')),
        'Tim',
      );
      await tester.enterText(
        find.byKey(const Key('v1_onboarding_last_name_field')),
        'Zarges',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('v1_onboarding_next_button')),
      );
      await tester.tap(find.byKey(const Key('v1_onboarding_next_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('v1_onboarding_privacy_link')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('v1_onboarding_imprint_link')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('v1_onboarding_imprint_link')),
      );
      await tester.tap(find.byKey(const Key('v1_onboarding_imprint_link')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('legal_documents_sheet')), findsOneWidget);
      expect(find.textContaining('Tim Zarges'), findsWidgets);
    });

    testWidgets(
        'V1SimpleProfileView zeigt Rechtliches, Löschen-Button und V1.0.0-Footer ohne Closed Beta',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(
                const GarminStatus(state: GarminConnectionState.disconnected),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const V1SimpleProfileView(
              initialUserDocOverride: {
                'role': 'ATHLETE',
                'profile': {
                  'firstName': 'Tim',
                  'lastName': 'Zarges',
                  'countryCode': 'DE',
                  'sports': ['TRIATHLON'],
                },
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final privacyBtn = find.byKey(const Key('v1_profile_privacy_button'));
      final imprintBtn = find.byKey(const Key('v1_profile_imprint_button'));
      final deleteBtn =
          find.byKey(const Key('v1_profile_delete_account_button'));

      await tester.scrollUntilVisible(
        deleteBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(privacyBtn, findsOneWidget);
      expect(imprintBtn, findsOneWidget);
      expect(deleteBtn, findsOneWidget);
      expect(find.text('ORBIT v1.0.0 (Build 1)'), findsOneWidget);
      expect(find.textContaining('Closed Beta'), findsNothing);
    });

    testWidgets('SettingsScreen bietet 1-Klick Impressum & Konto löschen',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final legalTile = find.byKey(const Key('settings_legal_imprint_tile'));
      final deleteTile = find.byKey(const Key('settings_delete_account_tile'));

      await tester.scrollUntilVisible(
        deleteTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(legalTile, findsOneWidget);
      expect(deleteTile, findsOneWidget);
    });
  });

  group('4. Zweistufiger Kontolösch-Dialog & AccountDeletionService', () {
    testWidgets(
        'TwoStepAccountDeletionDialog erzwingt 2 Schritte + Checkbox und führt Callback aus',
        (tester) async {
      var deletedCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => TwoStepAccountDeletionDialog.show(
                      ctx,
                      onDeleteOverride: () async {
                        deletedCount++;
                      },
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Schritt 1: Datenkategorien sichtbar -> Weiter
      expect(find.textContaining('Art. 17 DSGVO'), findsWidgets);
      await tester.tap(find.byKey(const Key('delete_step1_continue_btn')));
      await tester.pumpAndSettle();

      // Schritt 2: Button ohne Checkbox deaktiviert
      final confirmBtn = tester.widget<FilledButton>(
        find.byKey(const Key('delete_step2_confirm_btn')),
      );
      expect(confirmBtn.onPressed, isNull);
      expect(deletedCount, equals(0));

      // Checkbox aktivieren und endgültig löschen
      await tester.tap(find.byKey(const Key('delete_step2_confirm_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_step2_confirm_btn')));
      await tester.pumpAndSettle();

      expect(deletedCount, equals(1));
    });

    test(
        'AccountDeletionService ruft Remote-Löschung und authService.signOut() auf',
        () async {
      final mockAuth = _MockAuthService();
      var remoteCalled = false;

      final service = AccountDeletionService(
        authService: mockAuth,
        deleteRemoteOverride: () async {
          remoteCalled = true;
        },
      );

      await service.deleteAccountAndSignOut();

      expect(remoteCalled, isTrue);
      expect(mockAuth.signOutCalled, isTrue);
    });
  });

  group('5. V1.0.0 E-Mail-Verifikations-Banner', () {
    testWidgets(
        'zeigt Verifikations-Banner bei emailVerified == false und blendet es bei true aus',
        (tester) async {
      var resendCalls = 0;
      var openVerifyCalls = 0;

      // 1. Unbestätigtes Konto -> Banner sichtbar (DE)
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: EmailVerificationBanner(
                userOverride: _FakeVerifyUser(
                  emailVerified: false,
                  email: 'neu@orbit.training',
                ),
                onResendOverride: (_) async => resendCalls++,
                onTapVerifyOverride: () => openVerifyCalls++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unverified_email_banner')), findsOneWidget);
      expect(find.text('neu@orbit.training'), findsOneWidget);

      await tester.tap(find.byKey(const Key('unverified_email_resend_button')));
      await tester.pumpAndSettle();
      expect(resendCalls, equals(1));

      await tester.tap(find.byKey(const Key('unverified_email_open_button')));
      await tester.pumpAndSettle();
      expect(openVerifyCalls, equals(1));

      // 2. Bestätigtes Konto (wie Athletenkonto) -> Banner unsichtbar
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: EmailVerificationBanner(
                userOverride: _FakeVerifyUser(
                  emailVerified: true,
                  email: 'tim@orbit.training',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unverified_email_banner')), findsNothing);
    });
  });

  group('6. V1.0.0 Topbar-Bugmeldung & Dauerhaftes Profilbild', () {
    testWidgets(
        'V1.0.0 hat keinen schwebenden Bug-Overlay-Button, aber Topbar-Bugbutton öffnet Feedback-Sheet',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
            viewedAthleteIdProvider.overrideWith((ref) => 'ath_1'),
            currentAthleteIdProvider.overrideWith((ref) => 'ath_1'),
            activitiesProvider.overrideWith((ref) => Stream.value(const [])),
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(
                const GarminStatus(state: GarminConnectionState.disconnected),
              ),
            ),
            userDocumentProvider.overrideWith(
              (ref) => Stream.value({
                'role': 'TRAINER',
                'photoUrl':
                    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
                'profile': {'firstName': 'Tim', 'lastName': 'Coach'},
              }),
            ),
            v1CoachAthletesStreamProvider.overrideWith(
              (ref) => Stream.value(const <V1CoachAthleteLink>[]),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final isV2 = ref.watch(
                releaseConfigProvider.select((cfg) => cfg.isV2Enabled),
              );
              return MaterialApp(
                theme: AppTheme.darkTheme,
                builder: (ctx, child) => Stack(
                  children: [
                    if (child != null) child,
                    if (isV2) const GlobalFloatingBugBeetle(),
                  ],
                ),
                home: const DashboardScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Topbar-Avatar ist im Dashboard vorhanden
      expect(
        find.byKey(const Key('dashboard_avatar_menu_button')),
        findsOneWidget,
      );
      expect(find.byType(UserAvatarCircle), findsOneWidget);

      expect(find.byKey(const Key('global_floating_bug_beetle')), findsNothing);
      final topbarBug = find.byKey(const Key('beta_bug_report_icon_button'));
      expect(topbarBug, findsOneWidget);

      await tester.tap(topbarBug);
      await tester.pumpAndSettle();

      expect(find.byType(BetaBugReporterSheet), findsOneWidget);
    });

    testWidgets(
        'V1SimpleProfileView zeigt gespeicherte photoUrl/avatarUrl und überschreibt sie beim Speichern anderer Felder nicht',
        (tester) async {
      const tinyPngDataUri =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      Map<String, dynamic>? savedPayload;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(
                const GarminStatus(state: GarminConnectionState.disconnected),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: V1SimpleProfileView(
              initialUserDocOverride: const {
                'role': 'ATHLETE',
                'photoUrl': tinyPngDataUri,
                'avatarUrl': tinyPngDataUri,
                'profile': {
                  'firstName': 'Tim',
                  'lastName': 'Zarges',
                  'weightKg': 74.0,
                  'countryCode': 'DE',
                  'sports': ['TRIATHLON'],
                },
              },
              onSaveOverride: (payload) async {
                savedPayload = payload;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Avatar-Widget nutzt das geladene Profilbild (kein Fallback-Icon)
      final avatarWidget = tester.widget<UserAvatarCircle>(
        find.byKey(const Key('v1_profile_avatar_circle')),
      );
      expect(avatarWidget.photoUrlOverride, equals(tinyPngDataUri));

      // Andere Profilfelder ändern (Gewicht & Nachname) und speichern
      await tester.enterText(
        find.byKey(const Key('v1_profile_last_name_field')),
        'Tester',
      );
      await tester.enterText(
        find.byKey(const Key('v1_profile_weight_field')),
        '73.5',
      );
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('v1_profile_save_button'));
      await tester.scrollUntilVisible(
        saveBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedPayload, isNotNull);
      expect(savedPayload!['photoUrl'], equals(tinyPngDataUri));
      expect(savedPayload!['avatarUrl'], equals(tinyPngDataUri));
      expect(savedPayload!['profile']['photoUrl'], equals(tinyPngDataUri));
      expect(savedPayload!['profile']['avatarUrl'], equals(tinyPngDataUri));
      expect(savedPayload!['profile']['lastName'], equals('Tester'));
      expect(savedPayload!['profile']['weightKg'], equals(73.5));
    });
  });
}
