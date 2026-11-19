/// Datei-Header: `test/phase43_onboarding_simple_profile_and_auth_v1_test.dart`
/// Zweck: Automatisierte Unit- und Widget-Tests für Phase 43 (`v0.43.0`):
/// 1. Schlankes V1.0.0-Onboarding (`V1SimpleOnboardingWizard`): Rollenwahl Athlet
///    vs. Coach, Triathlon-Auswahl, Wohnland-Format (`dd.mm.yy • 24h`) und
///    verpflichtende, nicht vorangekreuzte DSGVO-Einwilligung.
/// 2. „Profil Einfach“ (`V1SimpleProfileView` / `ProfileScreen`): Anzeige aller
///    Onboarding-Daten inkl. Triathlon, Garmin Sync & `.fit`-Upload ohne V2-Zonen.
/// 3. Auth-Flows (`LoginScreen` Passwort-Reset & `EmailVerificationWaitingScreen`
///    mit 60s-Cooldown und `reload()`-Statusprüfung auf DE & EN).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/config/release_config.dart';
import 'package:orbit/core/design/app_theme.dart';
import 'package:orbit/features/auth/providers/auth_provider.dart';
import 'package:orbit/features/auth/screens/email_verification_waiting_screen.dart';
import 'package:orbit/features/auth/screens/login_screen.dart';
import 'package:orbit/features/integrations/models/garmin_status.dart';
import 'package:orbit/features/integrations/providers/garmin_provider.dart';
import 'package:orbit/features/onboarding/widgets/triathlon_combined_icon.dart';
import 'package:orbit/features/onboarding/widgets/v1_simple_onboarding_wizard.dart';
import 'package:orbit/features/profile/widgets/v1_simple_profile_view.dart';
import 'package:orbit/features/settings/providers/settings_provider.dart';

/// Mock für [AuthService] zum Testen von Passwort-Reset und E-Mail-Verifikation.
class _MockAuthService implements AuthService {
  String? lastResetEmail;
  int sendVerificationCount = 0;
  int reloadCheckCount = 0;
  bool nextReloadVerified = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<void> resetPassword(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<void> sendEmailVerification() async {
    sendVerificationCount++;
  }

  @override
  Future<bool> reloadAndCheckEmailVerified() async {
    reloadCheckCount++;
    return nextReloadVerified;
  }

  @override
  Future<bool> reloadAndRefreshEmailVerification() {
    return reloadAndCheckEmailVerified();
  }
}

void main() {
  tearDown(() {
    ReleaseConfig.resetTestingOverrides();
  });

  group('1. V1.0.0 Onboarding (Athlet vs. Coach, Triathlon & DSGVO-Opt-In)', () {
    testWidgets(
        'Athlet wählt Triathlon, füllt Stammdaten aus und benötigt DSGVO-Opt-In zum Abschluss',
        (tester) async {
      V1OnboardingResult? submitted;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: V1SimpleOnboardingWizard(
              onCompleteOverride: (res) async => submitted = res,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Schritt 1: Rolle Athlet ist vorausgewählt -> Weiter zu Schritt 2
      expect(
        find.byKey(const Key('v1_onboarding_role_athlete')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('v1_onboarding_role_trainer')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('v1_onboarding_next_button')));
      await tester.pumpAndSettle();

      // Schritt 2: Vorname, Nachname + Triathlon auswählen
      await tester.enterText(
        find.byKey(const Key('v1_onboarding_first_name_field')),
        'Tim',
      );
      await tester.enterText(
        find.byKey(const Key('v1_onboarding_last_name_field')),
        'Zarges',
      );
      await tester.pumpAndSettle();

      final triathlonChip =
          find.byKey(const Key('v1_onboarding_sport_TRIATHLON'));
      await tester.ensureVisible(triathlonChip);
      await tester.tap(triathlonChip);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('v1_onboarding_next_button')));
      await tester.pumpAndSettle();

      // Schritt 3: Datenquellen & DSGVO-Checkbox (nicht vorangekreuzt!)
      final gdprFinder = find.byKey(const Key('v1_onboarding_gdpr_checkbox'));
      final checkbox = tester.widget<CheckboxListTile>(gdprFinder);
      expect(checkbox.value, isFalse);

      // Abschluss ohne DSGVO-Haken muss blockieren & Warnung anzeigen
      await tester.tap(find.byKey(const Key('v1_onboarding_finish_button')));
      await tester.pumpAndSettle();
      expect(submitted, isNull);
      expect(
        find.textContaining('Bitte bestätige zuerst'),
        findsOneWidget,
      );

      // DSGVO anhaken und abschließen
      await tester.ensureVisible(gdprFinder);
      await tester.tap(gdprFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('v1_onboarding_finish_button')));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.role, equals('ATHLETE'));
      expect(submitted!.firstName, equals('Tim'));
      expect(submitted!.lastName, equals('Zarges'));
      expect(submitted!.sports, contains('TRIATHLON'));
      expect(submitted!.gdprConsentAccepted, isTrue);
    });

    testWidgets(
        'Coach-Rolle blendet Athleten-Körpermaße und Datenquellen aus und zeigt Coach-Schwerpunkt',
        (tester) async {
      V1OnboardingResult? submitted;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: V1SimpleOnboardingWizard(
              onCompleteOverride: (res) async => submitted = res,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Auf Coach umschalten
      await tester.tap(find.byKey(const Key('v1_onboarding_role_trainer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('v1_onboarding_next_button')));
      await tester.pumpAndSettle();

      // Coach-Felder sichtbar, Athleten-Körpermaße verborgen
      expect(
        find.byKey(const Key('v1_onboarding_coach_bio_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('v1_onboarding_height_field')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('v1_onboarding_first_name_field')),
        'Max',
      );
      await tester.enterText(
        find.byKey(const Key('v1_onboarding_last_name_field')),
        'Coach',
      );
      await tester.enterText(
        find.byKey(const Key('v1_onboarding_coach_bio_field')),
        'Triathlon & Langdistanz',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('v1_onboarding_next_button')));
      await tester.pumpAndSettle();

      // Keine Athleten-Datenquellen im Coach-Schritt 3
      expect(
        find.byKey(const Key('v1_onboarding_garmin_button')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('v1_onboarding_gdpr_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('v1_onboarding_finish_button')));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.role, equals('TRAINER'));
      expect(submitted!.coachBio, equals('Triathlon & Langdistanz'));
    });
  });

  group('2. Profil Einfach (V1SimpleProfileView)', () {
    testWidgets(
        'zeigt Athleten-Stammdaten, Triathlon-Badge, Wohnland-Format und Garmin/.FIT-Sektion ohne V2-Zonen',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            garminStatusStreamProvider.overrideWith(
              (ref) => Stream.value(
                const GarminStatus(state: GarminConnectionState.connected),
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
                  'birthDate': '1992-05-14',
                  'gender': 'male',
                  'heightCm': 182,
                  'weightKg': 74.5,
                  'sports': ['TRIATHLON', 'BIKE', 'RUN'],
                },
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profil Einfach'), findsOneWidget);
      expect(find.text('Tim'), findsOneWidget);
      expect(find.text('Zarges'), findsOneWidget);
      expect(find.text('14.05.92'), findsOneWidget);
      expect(find.byType(TriathlonCombinedIcon), findsOneWidget);
      expect(find.text('Garmin Connect: Verbunden'), findsOneWidget);
      expect(
        find.byKey(const Key('v1_profile_fit_upload_button')),
        findsOneWidget,
      );
      // Keine V2-Zonen oder Diagnostik
      expect(find.textContaining('Schwellenwert'), findsNothing);
      expect(find.textContaining('FTP'), findsNothing);
    });
  });

  group('3. Auth-Flows (Passwort zurücksetzen & E-Mail-Bestätigung DE/EN)',
      () {
    testWidgets(
        'LoginScreen öffnet Passwort-zurücksetzen-Dialog und ruft resetPassword auf (DE & EN)',
        (tester) async {
      final mockAuth = _MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('login_forgot_password_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Passwort zurücksetzen'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('forgot_password_email_field')),
        'tim@orbit.training',
      );
      await tester.tap(
        find.byKey(const Key('forgot_password_submit_button')),
      );
      await tester.pumpAndSettle();

      expect(mockAuth.lastResetEmail, equals('tim@orbit.training'));

      // Auf Englisch umschalten und prüfen
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LoginScreen)),
      );
      container.read(settingsControllerProvider.notifier).setLanguage('en');
      await tester.pumpAndSettle();

      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets(
        'EmailVerificationWaitingScreen bietet Erneut senden mit Cooldown & Status prüfen (DE/EN)',
        (tester) async {
      final mockAuth = _MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EmailVerificationWaitingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Bereits bestätigt? Status prüfen'),
        findsOneWidget,
      );
      expect(
        find.text('Bestätigungs-E-Mail erneut senden'),
        findsOneWidget,
      );

      // Status prüfen -> ruft reloadAndCheckEmailVerified() auf
      await tester.tap(
        find.byKey(const Key('verify_email_check_now_button')),
      );
      await tester.pumpAndSettle();
      expect(mockAuth.reloadCheckCount, greaterThanOrEqualTo(1));

      // Erneut senden -> ruft sendEmailVerification() auf und aktiviert 60s Cooldown
      await tester.tap(
        find.byKey(const Key('verify_email_resend_button')),
      );
      await tester.pump();
      expect(mockAuth.sendVerificationCount, equals(1));
      expect(find.textContaining('60s'), findsOneWidget);
    });
  });
}
