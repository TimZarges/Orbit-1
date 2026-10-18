import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/design/app_colors.dart';
import 'package:orbit/features/auth/screens/email_verification_waiting_screen.dart';
import 'package:orbit/features/auth/widgets/password_criteria_checklist.dart';
import 'package:orbit/features/onboarding/widgets/triathlon_combined_icon.dart';
import 'package:orbit/features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Testsuite für Phase 36 (Dual Password Checklist, Email Verification Screen, Coach Onboarding & Triathlon Icon).
void main() {
  group('Phase 36.2: Passwort-Validierung & Kriterien-Checkliste', () {
    test('isPasswordValid prüft alle 4 Sicherheitskriterien korrekt', () {
      // Zu kurz (< 8 Zeichen)
      expect(PasswordCriteriaChecklist.isPasswordValid('Abc1', 'Abc1'), isFalse);

      // Keine Zahl
      expect(
          PasswordCriteriaChecklist.isPasswordValid('Abcdefgh', 'Abcdefgh'),
          isFalse);

      // Kein Buchstabe
      expect(PasswordCriteriaChecklist.isPasswordValid('12345678', '12345678'),
          isFalse);

      // Passwörter stimmen nicht überein
      expect(
          PasswordCriteriaChecklist.isPasswordValid(
              'Sicher123', 'Sicher124'),
          isFalse);

      // Gültig: >= 8 Zeichen, Buchstabe, Zahl, identisch
      expect(
          PasswordCriteriaChecklist.isPasswordValid(
              'Sicher123', 'Sicher123'),
          isTrue);
    });

    testWidgets('PasswordCriteriaChecklist Widget visualisiert Kriterien live',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordCriteriaChecklist(
              password: 'Short1',
              confirmPassword: 'Short1',
            ),
          ),
        ),
      );

      // Kriterien vor Erfüllung
      expect(find.text('Mindestens 8 Zeichen'), findsOneWidget);
      expect(find.text('Mindestens 1 Zahl oder Sonderzeichen'), findsOneWidget);
      expect(find.text('Mindestens 1 Großbuchstabe (A-Z)'), findsOneWidget);
      expect(find.text('Mindestens 1 Kleinbuchstabe (a-z)'), findsOneWidget);
      expect(find.text('Passwörter stimmen überein'), findsOneWidget);

      // Rebuild mit erfülltem Passwort
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordCriteriaChecklist(
              password: 'SuperPasswort123',
              confirmPassword: 'SuperPasswort123',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(5));
    });
  });

  group('Phase 36.2: EmailVerificationWaitingScreen', () {
    testWidgets('zeigt Wartestatus und Aktions-Buttons an', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EmailVerificationWaitingScreen(),
          ),
        ),
      );

      expect(find.text('Bestätige deine E-Mail'), findsOneWidget);
      expect(find.byKey(const Key('verify_email_check_now_button')),
          findsOneWidget);
      expect(find.byKey(const Key('verify_email_resend_button')),
          findsOneWidget);
      expect(find.byKey(const Key('verify_email_signout_button')),
          findsOneWidget);
    });
  });

  group('Phase 36.3 & 36.4: TriathlonCombinedIcon & Onboarding Screen', () {
    testWidgets('TriathlonCombinedIcon rendert 3 Sportart-Icons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TriathlonCombinedIcon(size: 20, color: AppColors.volt),
          ),
        ),
      );

      expect(find.byIcon(Icons.pool), findsOneWidget);
      expect(find.byIcon(Icons.directions_bike), findsOneWidget);
      expect(find.byIcon(Icons.directions_run), findsOneWidget);
    });

    testWidgets('Onboarding Rolle Athlete vs Coach schaltet Felder um',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Standardrolle ist ATHLETE -> Geburtsjahr, Gewicht, Größe sichtbar
      expect(find.byKey(const Key('onboarding_birth_year_field')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_weight_field')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_height_field')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_coach_club_field')), findsNothing);

      // Auf Coach umschalten
      await tester.tap(find.byKey(const Key('onboarding_role_trainer')));
      await tester.pumpAndSettle();

      // Nun Coach-spezifische Felder sichtbar, Athleten-Körpermaße verborgen
      expect(find.byKey(const Key('onboarding_coach_club_field')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_coach_company_field')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_coach_mode_simple')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_birth_year_field')), findsNothing);

      // Sportart-Chips: Keine Checkmarks & TriathlonCombinedIcon gerendert
      expect(find.byType(TriathlonCombinedIcon), findsOneWidget);
    });
  });
}
