/// Datei-Header: `lib/core/config/contact_config.dart`
/// Zweck: Zentrale Marken-, Impressums-, Support- und Rechts-URL-Konfiguration
/// für die ORBIT-Applikation gemäß § 5 DDG & Art. 13/14 DSGVO (Phase 46).
/// Architektur-Einordnung: Core-Konfigurationsschicht (`lib/core/config/`),
/// liefert unveränderliche Konstanten ohne Runtime-Allokationen.
library;

/// Offizielle Kontakt-, Marken- und Rechtskonfiguration für ORBIT V1.0.0.
///
/// Was: Stellt einheitliche Betreiber-, Kontakt- und Dokumentations-URLs
/// für Login, Onboarding, Profil, Einstellungen und Web-Links bereit.
/// Warum: Single Source of Truth für Impressum (§ 5 DDG) und Datenschutz
/// (DSGVO Art. 9, 13, 14, 17) über alle Plattformen hinweg.
class ContactConfig {
  const ContactConfig._();

  /// Offizieller Markenname der Plattform.
  static const String brandName = 'ORBIT Performance / ORBIT Training';

  /// Offizielle Betreiberbezeichnung.
  static const String operatorName = 'ORBIT Endurance Technologies';

  /// Verantwortliche Person gemäß § 5 DDG und § 18 Abs. 2 MStV.
  static const String representativeName = 'Tim Zarges';

  /// Standort / EU-Jurisdiktion.
  static const String locationLabelDe = 'Deutschland (EU)';

  /// Standort / EU-Jurisdiktion (Englisch).
  static const String locationLabelEn = 'Germany (European Union)';

  /// Serverregion (Frankfurt am Main).
  static const String serverRegion = 'Frankfurt am Main (europe-west3, EU)';

  /// Allgemeine Hilfe & Fragen zur Nutzung.
  static const String supportEmail = 'support@orbit-training.app';

  /// Technische Probleme, Abstürze & Parsing-Fehler.
  static const String bugsEmail = 'bugs@orbit-training.app';

  /// Feature-Ideen, UI-Vorschläge & Wünsche.
  static const String feedbackEmail = 'feedback@orbit-training.app';

  /// Kooperationen, Vereine, Trainer-Partnerschaften & Allgemeines.
  static const String generalEmail = 'hello@orbit-training.app';

  /// Datenschutz-Anfragen, Art. 15/17 DSGVO & Audit-Logs.
  static const String privacyEmail = 'privacy@orbit-training.app';

  /// Öffentliche Haupt-Webseite (`/`).
  static const String websiteUrl = 'https://orbit-app-mvp.web.app/';

  /// Öffentliche Web-App (`/app/`).
  static const String webAppUrl = 'https://orbit-app-mvp.web.app/app/';

  /// Web-URL für Support & Hilfe.
  static const String helpUrl = 'https://orbit-app-mvp.web.app/help.html';

  /// Web-URL für Datenschutzerklärung.
  static const String privacyUrl = 'https://orbit-app-mvp.web.app/privacy.html';

  /// Web-URL für Impressum.
  static const String imprintUrl = 'https://orbit-app-mvp.web.app/imprint.html';

  /// Web-URL für Account-Löschung.
  static const String deleteAccountUrl =
      'https://orbit-app-mvp.web.app/delete-account.html';
}
