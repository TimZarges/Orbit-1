/// Datei-Header: `lib/features/auth/services/account_deletion_service.dart`
/// Zweck: Dedizierter Service für die vollständige, unwiderrufliche Konto- und
/// Datenlöschung gemäß Art. 17 DSGVO („Recht auf Vergessenwerden“) in `europe-west3`.
/// Architektur-Einordnung: Service-Schicht (`lib/features/auth/services/`),
/// entkoppelt Cloud-Function-Aufrufe und Firebase-Sign-out sauber von den
/// Dialog-Widgets und unterstützt Test-Mocks ohne Netzwerkanbindung (`AGENTS.md` Regel 10).
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Callback-Signatur für testbare Kontolösch-Aktionen.
typedef RemoteAccountDeleteCallback = Future<void> Function();

/// Service zur Durchführung der vollständigen DSGVO-Art.-17-Kontolöschung.
///
/// Was: Ruft die Cloud Function `deleteAccount` in `europe-west3` auf (welche
/// sämtliche Firestore-Dokumente, `coachLinks`, `authorizedCoachIds`, `invites`,
/// `activities`, Cloud-Storage-Dateien unter `users/{uid}/` und den Auth-User
/// restlos löscht) und meldet die lokale Sitzung danach sauber ab.
/// Warum: Trennt Sicherheits- und Backend-Logik sauber von UI-Komponenten und
/// verhindert verschluckte API-Fehler im Produktivbetrieb (`AGENTS.md` Regel 0).
class AccountDeletionService {
  /// Optionaler Override für die Remote-Löschfunktion (Unit- & Widget-Tests).
  final RemoteAccountDeleteCallback? _deleteRemoteOverride;

  /// Referenz auf den Riverpod-AuthService für den anschließenden Logout.
  final AuthService _authService;

  /// Erstellt einen [AccountDeletionService].
  AccountDeletionService({
    required AuthService authService,
    RemoteAccountDeleteCallback? deleteRemoteOverride,
  })  : _authService = authService,
        _deleteRemoteOverride = deleteRemoteOverride;

  /// Führt die endgültige Löschung von Konto & Daten aus und beendet die Sitzung.
  ///
  /// Wirft eine Exception weiter, falls das Backend die Löschung ablehnt,
  /// sodass der Nutzer im UI eine klare Rückmeldung erhält.
  Future<void> deleteAccountAndSignOut() async {
    final override = _deleteRemoteOverride;
    if (override != null) {
      await override();
    } else {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('deleteAccount');
      await callable.call();
    }

    // Lokale Auth-Sitzung sicher beenden (ignoriert erwartbaren Auth-User-Null-Zustand
    // nach serverseitiger Auth-Löschung, bereinigt aber lokalen Web-/Mobile-Cache).
    try {
      await _authService.signOut();
    } catch (_) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }
}

/// Riverpod-Provider für den [AccountDeletionService].
final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AccountDeletionService(authService: authService);
});
