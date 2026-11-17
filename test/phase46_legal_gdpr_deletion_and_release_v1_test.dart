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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/config/app_config.dart';
import 'package:orbit/core/config/contact_config.dart';
import 'package:orbit/core/config/release_config.dart';
import 'package:orbit/core/design/app_theme.dart';
import 'package:orbit/features/auth/providers/auth_provider.dart';
import 'package:orbit/features/auth/screens/login_screen.dart';
import 'package:orbit/features/auth/services/account_deletion_service.dart';
import 'package:orbit/features/auth/widgets/two_step_account_deletion_dialog.dart';
import 'package:orbit/features/integrations/models/garmin_status.dart';
import 'package:orbit/features/integrations/providers/garmin_provider.dart';
import 'package:orbit/features/legal/widgets/legal_documents_sheet.dart';
import 'package:orbit/features/onboarding/widgets/v1_simple_onboarding_wizard.dart';
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
}
