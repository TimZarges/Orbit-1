/// Datei-Header: `lib/features/auth/providers/auth_provider.dart`
/// Zweck: Riverpod-Provider und Authentifizierungs-Service für Firebase Auth
/// inklusive reaktiver E-Mail-Verifikations-Synchronisation (`userChanges`,
/// `idTokenChanges` und explizitem `reloadAndRefreshEmailVerification()`).
/// Architektur-Einordnung: Service- & State-Management-Schicht
/// (`lib/features/auth/providers/`), strikt getrennt von UI-Widgets
/// (`AGENTS.md` Regel 6 & 10).
library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_guard_service.dart';

/// Stellt die zentrale [FirebaseAuth]-Instanz als Provider bereit.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Überwacht Anmelde- und Abmeldeereignisse von Firebase Auth.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Überwacht Profil- und Verifizierungsänderungen (z. B. nach `user.reload()`).
final userChangesProvider = StreamProvider<User?>((ref) {
  try {
    return ref.watch(firebaseAuthProvider).userChanges();
  } catch (_) {
    // Fallback für isolierte Widget-Tests ohne initialisiertes Firebase
    return Stream<User?>.value(null);
  }
});

/// Überwacht ID-Token-Erneuerungen inklusive Aktualisierungen von `emailVerified`.
final idTokenChangesProvider = StreamProvider<User?>((ref) {
  try {
    return ref.watch(firebaseAuthProvider).idTokenChanges();
  } catch (_) {
    // Fallback für isolierte Widget-Tests ohne initialisiertes Firebase
    return Stream<User?>.value(null);
  }
});

/// Monoton steigender Zähler zur reaktiven Benachrichtigung nach manuellen `reload()`-Prüfungen.
final emailVerificationRefreshTickProvider = StateProvider<int>((ref) => 0);

/// Unveränderlicher UI-Zustand für die reaktive E-Mail-Bestätigung.
@immutable
class EmailVerificationState {
  /// Gibt an, ob die E-Mail-Adresse des aktuellen Nutzers bestätigt wurde.
  final bool isVerified;

  /// Gibt an, ob gerade eine Server-Prüfung (`reload()`) läuft.
  final bool isChecking;

  /// Zeitstempel der letzten abgeschlossenen Prüfung.
  final DateTime? lastCheckedAt;

  /// Erstellt einen [EmailVerificationState].
  const EmailVerificationState({
    required this.isVerified,
    this.isChecking = false,
    this.lastCheckedAt,
  });

  /// Erstellt eine modifizierte Kopie des Zustands.
  EmailVerificationState copyWith({
    bool? isVerified,
    bool? isChecking,
    DateTime? lastCheckedAt,
  }) {
    return EmailVerificationState(
      isVerified: isVerified ?? this.isVerified,
      isChecking: isChecking ?? this.isChecking,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }
}

/// Controller zur sofortigen, relogin-freien Aktualisierung von `emailVerified`.
///
/// Was: Lauscht gleichzeitig auf `userChanges()` und `idTokenChanges()` von Firebase
/// Auth und bietet `reloadAndRefreshEmailVerification()`, um bei Rückkehr in die App
/// oder auf Knopfdruck `user.reload()` + Token-Refresh auszulösen.
/// Warum: Firebase Auth aktualisiert ein bereits geöffnetes Client-Session-Objekt
/// nach Klick auf den Verifizierungslink im Postfach nicht automatisch; erst `reload()`
/// plus reaktiver State-Aktualisierung blendet Banner/Wartebildschirm sofort aus.
class EmailVerificationController
    extends StateNotifier<EmailVerificationState> {
  final FirebaseAuth? _auth;
  final Ref _ref;
  StreamSubscription<User?>? _userSub;
  StreamSubscription<User?>? _tokenSub;
  Future<bool>? _inFlightCheck;

  /// Erstellt einen [EmailVerificationController] und bindet Auth-Streams.
  EmailVerificationController(this._auth, this._ref)
      : super(
          EmailVerificationState(
            isVerified: _safeReadEmailVerified(_auth),
          ),
        ) {
    // Reagiert auf Profil- und Verifikationsänderungen
    final auth = _auth;
    if (auth == null) return;
    try {
      _userSub = auth.userChanges().listen(_syncFromUser);
      _tokenSub = auth.idTokenChanges().listen(_syncFromUser);
    } catch (_) {
      // Defensive Absicherung in Widget-Tests ohne initialisiertes Firebase
    }
  }

  /// Liest `emailVerified` sicher ohne Exception in Test-Umgebungen ohne Firebase.
  static bool _safeReadEmailVerified(FirebaseAuth? auth) {
    if (auth == null) return false;
    try {
      return auth.currentUser?.emailVerified ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Übernimmt den Verifikationsstatus aus eingehenden Firebase-Auth-Streams.
  void _syncFromUser(User? user) {
    final verified = user?.emailVerified ?? false;
    if (verified != state.isVerified) {
      state = state.copyWith(
        isVerified: verified,
        lastCheckedAt: DateTime.now(),
      );
    }
  }

  /// Lädt den aktuellen Firebase-Nutzer per `reload()` neu, aktualisiert optional
  /// das ID-Token und überträgt `emailVerified` sofort in den UI-State.
  ///
  /// Gibt `true` zurück, wenn die E-Mail bestätigt ist, andernfalls `false`.
  Future<bool> reloadAndRefreshEmailVerification() {
    // Verhindert parallele Doppel-Aufrufe bei gleichzeitigem Resume + Button-Tap
    if (_inFlightCheck != null) return _inFlightCheck!;

    final future = _performReload();
    _inFlightCheck = future;
    future.whenComplete(() => _inFlightCheck = null);
    return future;
  }

  /// Interne Ausführungslogik für `user.reload()` und State-Synchronisation.
  Future<bool> _performReload() async {
    final auth = _auth;
    if (auth == null) return false;
    User? current;
    try {
      current = auth.currentUser;
    } catch (_) {
      return false;
    }
    if (current == null) {
      state = state.copyWith(
        isVerified: false,
        isChecking: false,
        lastCheckedAt: DateTime.now(),
      );
      return false;
    }

    if (current.emailVerified) {
      state = state.copyWith(
        isVerified: true,
        isChecking: false,
        lastCheckedAt: DateTime.now(),
      );
      return true;
    }

    state = state.copyWith(isChecking: true);
    try {
      await current.reload();
      final refreshed = auth.currentUser;
      final isNowVerified = refreshed?.emailVerified ?? false;

      // Bei neuer Verifizierung Token erzwingen, damit idTokenChanges & Rules sofort greifen
      if (isNowVerified && refreshed != null) {
        try {
          await refreshed.getIdToken(true);
        } catch (_) {
          // Optionaler Token-Refresh darf Statusübernahme nie blockieren
        }
      }

      state = EmailVerificationState(
        isVerified: isNowVerified,
        isChecking: false,
        lastCheckedAt: DateTime.now(),
      );
      _ref.read(emailVerificationRefreshTickProvider.notifier).state++;
      return isNowVerified;
    } catch (_) {
      state = state.copyWith(
        isChecking: false,
        lastCheckedAt: DateTime.now(),
      );
      return auth.currentUser?.emailVerified ?? false;
    }
  }

  @override
  void dispose() {
    unawaited(_userSub?.cancel());
    unawaited(_tokenSub?.cancel());
    super.dispose();
  }
}

/// Globaler Controller-Provider für die E-Mail-Bestätigung.
final emailVerificationControllerProvider =
    StateNotifierProvider<EmailVerificationController, EmailVerificationState>(
  (ref) {
    FirebaseAuth? auth;
    try {
      auth = ref.watch(firebaseAuthProvider);
    } catch (_) {
      // Defensive Absicherung in Widget-Tests ohne initialisiertes Firebase
      auth = null;
    }
    return EmailVerificationController(auth, ref);
  },
);

/// Stellt den [AuthService] als Provider bereit.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider), ref);
});

/// Kapselt Authentifizierungs-, Passwort- und E-Mail-Verifikationsaktionen.
class AuthService {
  final FirebaseAuth _auth;
  final Ref _ref;

  /// Erstellt einen [AuthService].
  AuthService(this._auth, this._ref);

  /// Meldet einen bestehenden Nutzer mit E-Mail und Passwort an.
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final verified = _auth.currentUser?.emailVerified ?? false;
    _ref.read(emailVerificationRefreshTickProvider.notifier).state++;
    if (verified) {
      await _ref
          .read(emailVerificationControllerProvider.notifier)
          .reloadAndRefreshEmailVerification();
    }
  }

  /// Registriert ein neues Konto und stößt einmalig die Bestätigungs-E-Mail an.
  Future<void> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Verifizierungs-E-Mail sicher anstoßen, ohne bei Fehlern abzubrechen
    if (cred.user != null) {
      await AuthGuardService.triggerVerificationEmailSafely(cred.user!);
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
        code: 'no-user',
        message: 'Kein aktiver Benutzer angemeldet.',
      );
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
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

  /// Lädt das Nutzerprofil neu und synchronisiert den UI-State sofort ohne Relogin.
  Future<bool> reloadAndRefreshEmailVerification() {
    return _ref
        .read(emailVerificationControllerProvider.notifier)
        .reloadAndRefreshEmailVerification();
  }

  /// Abwärtskompatibler Alias für [reloadAndRefreshEmailVerification].
  Future<bool> reloadAndCheckEmailVerified() {
    return reloadAndRefreshEmailVerification();
  }

  /// Meldet den aktuellen Nutzer ab.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
