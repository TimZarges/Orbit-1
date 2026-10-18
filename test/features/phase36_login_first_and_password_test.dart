import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit/features/auth/screens/login_screen.dart';
import 'package:orbit/features/settings/screens/settings_screen.dart';

/// Tests für Etappe 36.1: Login-First, kein Doppel-ORBIT & Passwort-Reset.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 36.1: Login-First & Passwort-Reset', () {
    testWidgets('LoginScreen rendert sauberes Branding, Passwort vergessen und Registrierungs-Button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand Title existiert genau einmal
      expect(find.byKey(const Key('login_brand_title')), findsOneWidget);
      expect(find.text('ORBIT'), findsOneWidget);

      // Buttons
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('login_register_button')), findsOneWidget);
      expect(find.text('Konto erstellen / Registrieren'), findsOneWidget);

      // Passwort vergessen Button
      expect(find.byKey(const Key('login_forgot_password_button')), findsOneWidget);
      expect(find.text('Passwort vergessen?'), findsOneWidget);
    });

    testWidgets('Passwort-vergessen-Dialog lässt sich aufrufen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_forgot_password_button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwort zurücksetzen'), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_email_field')), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_submit_button')), findsOneWidget);
    });

    testWidgets('SettingsScreen enthält Option zum Passwort ändern', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_change_password_tile')),
        300,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_change_password_tile')), findsOneWidget);
      expect(find.text('Passwort ändern'), findsOneWidget);
    });
  });
}
