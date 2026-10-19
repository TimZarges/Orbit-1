import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    // Wir senden direkt eine Verifizierungs-E-Mail
    if (cred.user != null && !cred.user!.emailVerified) {
      await cred.user!.sendEmailVerification();
    }
  }

  /// Sendet eine E-Mail zum Zurücksetzen des Passworts.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Ändert das Passwort des aktuell angemeldeten Nutzers nach Re-Authentifizierung.
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
          code: 'no-user', message: 'Kein aktiver Benutzer angemeldet.');
    }
    final cred =
        EmailAuthProvider.credential(email: user.email!, password: oldPassword);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  /// Sendet eine neue E-Mail-Bestätigung an den aktuellen Nutzer.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Lädt das Nutzerprofil neu und prüft, ob die E-Mail inzwischen bestätigt wurde.
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    }
    return false;
  }

  /// Meldet den aktuellen Nutzer ab.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
