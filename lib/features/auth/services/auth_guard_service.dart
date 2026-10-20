import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Prüft den aktuellen Authentifizierungs- und Onboarding-Status des Nutzers.
///
/// In der Beta-Phase (`kBetaAllowUnverifiedEmail = true`) blockiert eine noch
/// ausstehende E-Mail-Bestätigung (`emailVerified == false`) NICHT den Zugang
/// zum Onboarding oder zum Haupt-Cockpit, da Firebase-Bestätigungs-Mails
/// verzögert eintreffen oder fehlen können.
class AuthGuardService {
  /// Schaltet die harte E-Mail-Verifizierungsschranke für Beta-Tests frei.
  static const bool kBetaAllowUnverifiedEmail = true;

  /// Bestimmt, ob der Nutzer Zugriff auf das Onboarding und die App erhält.
  ///
  /// Gibt `true` zurück, sobald ein gültiger Firebase-[User] eingeloggt ist
  /// und entweder die E-Mail bestätigt wurde oder das Beta-Flag aktiv ist.
  static bool canAccessApp(User? user) {
    if (user == null) return false;
    if (kBetaAllowUnverifiedEmail) return true;
    return user.emailVerified;
  }

  /// Sendet die Bestätigungs-E-Mail sicher im Hintergrund, ohne den
  /// Registrierungs- oder Onboarding-Flow bei Fehlern abzubrechen.
  static Future<void> triggerVerificationEmailSafely(User user) async {
    if (user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } catch (e) {
      // Fehler wird protokolliert, blockiert aber nicht das Onboarding
      debugPrint(
        'Warnung: Bestätigungs-E-Mail konnte nicht gesendet werden: $e',
      );
    }
  }
}
