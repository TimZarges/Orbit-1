import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/auth/providers/auth_provider.dart';
import 'package:orbit/features/settings/widgets/privacy_settings_sheet.dart';

class _MockAuthService implements AuthService {
  bool signOutCalled = false;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signUpWithEmail(String email, String password) async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<bool> reloadAndCheckEmailVerified() async => true;
}

void main() {
  group('DSGVO-Kontolöschung & Galerie-Cleanup (Phase 38.5)', () {
    testWidgets('PrivacySettingsSheet öffnet Löschdialog und ruft signOut() auf', (tester) async {
      final mockAuth = _MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PrivacySettingsSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Kachel zur Kontolöschung finden und scrollen
      final tileFinder = find.byKey(const Key('delete_account_tile'));
      await tester.scrollUntilVisible(tileFinder, 200);
      await tester.pumpAndSettle();
      expect(tileFinder, findsOneWidget);

      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      // 2. Dialog ist sichtbar mit Warnung
      expect(find.text('Konto und Daten löschen?'), findsOneWidget);
      final confirmButtonFinder = find.byKey(const Key('confirm_delete_account_button'));
      expect(confirmButtonFinder, findsOneWidget);

      // 3. Bestätigung antippen
      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      // 4. authService.signOut() wurde ausgeführt
      expect(mockAuth.signOutCalled, isTrue);
    });
  });
}
