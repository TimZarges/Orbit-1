import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orbit/features/auth/services/auth_guard_service.dart';

/// Minimaler Mock für [User], der `noSuchMethod` nutzt, um die Schnittstelle zu erfüllen.
class FakeTestUser implements User {
  @override
  final bool emailVerified;

  FakeTestUser({this.emailVerified = false});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthGuardService Beta Soft-Gate Tests', () {
    test('canAccessApp liefert false bei nicht-eingeloggt (null)', () {
      expect(AuthGuardService.canAccessApp(null), isFalse);
    });

    test(
        'canAccessApp erlaubt Zugang bei emailVerified = false wenn Beta aktiv',
        () {
      final unverifiedUser = FakeTestUser(emailVerified: false);
      expect(AuthGuardService.canAccessApp(unverifiedUser), isTrue);
    });

    test('canAccessApp erlaubt Zugang bei emailVerified = true', () {
      final verifiedUser = FakeTestUser(emailVerified: true);
      expect(AuthGuardService.canAccessApp(verifiedUser), isTrue);
    });
  });
}
