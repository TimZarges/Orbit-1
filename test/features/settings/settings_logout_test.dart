import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit/features/settings/screens/settings_screen.dart';
import 'package:orbit/features/auth/providers/auth_provider.dart';

class MockAuthService implements AuthService {
  bool signedOut = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  testWidgets('SettingsScreen zeigt Abmelden-Option und führt signOut bei Bestätigung aus', (tester) async {
    final mockAuth = MockAuthService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuth),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    // Scroll down to find Abmelden
    final logoutFinder = find.widgetWithText(ListTile, 'Abmelden');
    await tester.scrollUntilVisible(logoutFinder, 200);
    expect(logoutFinder, findsOneWidget);

    // Tap Abmelden
    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Abmelden?'), findsOneWidget);
    expect(find.text('Möchtest du dich wirklich von ORBIT abmelden?'), findsOneWidget);

    // Tap Abbrechen
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(mockAuth.signedOut, isFalse);

    // Tap Abmelden again and confirm
    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abmelden'));
    await tester.pumpAndSettle();

    expect(mockAuth.signedOut, isTrue);
  });
}
