/// Datei-Header: `lib/features/legal/widgets/legal_documents_sheet.dart`
/// Zweck: Zentrale, zweisprachige (DE & EN) und Theme-adaptive (Hell & Dunkel)
/// In-App-Ansicht für Datenschutz (DSGVO Art. 9, 13, 14, 17) und Impressum
/// (§ 5 DDG / § 18 Abs. 2 MStV) mit offiziellen Marken- & Betreiberdaten.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/legal/widgets/`),
/// direkt aufrufbar von Webseite, Login, Onboarding, Profil Einfach und Einstellungen
/// (`AGENTS.md` Regel 10).
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/contact_config.dart';
import '../../../core/design/app_colors.dart';

/// Reiter-Auswahl für die rechtlichen Dokumente in ORBIT.
enum LegalDocumentTab {
  /// Datenschutzerklärung nach DSGVO Art. 9, 13, 14 & 17.
  privacy,

  /// Impressum gemäß § 5 DDG und § 18 Abs. 2 MStV.
  imprint,
}

/// Zweisprachige In-App-Ansicht für Datenschutz & Impressum (DE & EN, Light & Dark).
///
/// Was: Zeigt die vollständige Datenschutzerklärung (Art. 9 Gesundheits-/Trainingsdaten,
/// Garmin Sync, Coach-`.FIT`-Freigabe, Serverstandort Frankfurt am Main (Deutschland / EU),
/// Anleitung zur Art.-17-Kontolöschung) sowie das Impressum mit offiziellen
/// Marken-/Kontaktdaten von `ORBIT Performance / ORBIT Training`.
/// Warum: Stellt die sofortige 1-Klick-Erreichbarkeit aus jedem V1.0.0-Screen sicher.
class LegalDocumentsSheet extends StatefulWidget {
  /// Vorausgewählter Reiter (Datenschutz oder Impressum).
  final LegalDocumentTab initialTab;

  /// Aktive Sprache (`'de'` oder `'en'`).
  final String lang;

  /// Erstellt das [LegalDocumentsSheet].
  const LegalDocumentsSheet({
    super.key,
    required this.initialTab,
    required this.lang,
  });

  /// Öffnet Datenschutz oder Impressum als aufgeräumtes Bottom-Sheet.
  static Future<void> show(
    BuildContext context, {
    LegalDocumentTab initialTab = LegalDocumentTab.privacy,
    String lang = 'de',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalDocumentsSheet(
        initialTab: initialTab,
        lang: lang,
      ),
    );
  }

  @override
  State<LegalDocumentsSheet> createState() => _LegalDocumentsSheetState();
}

class _LegalDocumentsSheetState extends State<LegalDocumentsSheet> {
  late LegalDocumentTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  /// Öffnet eine externe Rechts- oder Website-URL sicher im Standardbrowser.
  Future<void> _openExternalUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.lang == 'en';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = AppColors.cardBg(isDark: isDark);
    final borderColor = AppColors.cardBorderFor(isDark: isDark);
    final primaryText = AppColors.primaryText(isDark: isDark);
    final secondaryText = AppColors.secondaryText(isDark: isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) {
        return Container(
          key: const Key('legal_documents_sheet'),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // Griffleiste oben
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryText.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Reiter-Umschalter: Datenschutz vs. Impressum
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<LegalDocumentTab>(
                        key: const Key('legal_tab_segmented'),
                        segments: [
                          ButtonSegment<LegalDocumentTab>(
                            value: LegalDocumentTab.privacy,
                            icon: const Icon(
                              Icons.privacy_tip_outlined,
                              size: 18,
                            ),
                            label:
                                Text(isEn ? 'Privacy Policy' : 'Datenschutz'),
                          ),
                          ButtonSegment<LegalDocumentTab>(
                            value: LegalDocumentTab.imprint,
                            icon: const Icon(Icons.business_outlined, size: 18),
                            label: Text(isEn ? 'Legal Notice' : 'Impressum'),
                          ),
                        ],
                        selected: {_activeTab},
                        onSelectionChanged: (sel) =>
                            setState(() => _activeTab = sel.first),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      key: const Key('legal_close_btn'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollbarer Rechts-Inhalt
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: _activeTab == LegalDocumentTab.privacy
                      ? _buildPrivacyContent(
                          isEn: isEn,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                        )
                      : _buildImprintContent(
                          isEn: isEn,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Baut die DSGVO-Datenschutzerklärung (Art. 9, 13, 14, 17).
  List<Widget> _buildPrivacyContent({
    required bool isEn,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return [
      Text(
        isEn
            ? 'Privacy Policy (GDPR Art. 9, 13, 14 & 17)'
            : 'Datenschutzerklärung (DSGVO Art. 9, 13, 14 & 17)',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: primaryText,
        ),
      ),
      const SizedBox(height: 12),
      _LegalSection(
        title: isEn ? '1. Controller' : '1. Verantwortlicher (Art. 13 DSGVO)',
        body: isEn
            ? '${ContactConfig.brandName} (${ContactConfig.operatorName})\nRepresentative: ${ContactConfig.representativeName}\nPrivacy: ${ContactConfig.privacyEmail}\nSupport: ${ContactConfig.supportEmail}'
            : '${ContactConfig.brandName} (${ContactConfig.operatorName})\nVerantwortlich: ${ContactConfig.representativeName}\nDatenschutz: ${ContactConfig.privacyEmail}\nSupport: ${ContactConfig.supportEmail}',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn
            ? '2. Data Categories, Health Data & Legal Bases (Art. 6 & 9 GDPR)'
            : '2. Datenkategorien, Gesundheitsdaten & Rechtsgrundlagen (Art. 6 & 9 DSGVO)',
        body: isEn
            ? 'ORBIT processes account/profile data (name, email, role, country of residence for dd.mm.yy / 24h formatting) to perform the platform service and prevent abuse (Art. 6(1)(b) & (f) GDPR, Firebase App Check). Endurance training & health telemetry (heart rate, power, pace, duration, distance, optional body height/weight/birth date/gender, and original .FIT/.TCX/.GPX files) is processed strictly based on your explicit, freely revocable consent (Art. 9(2)(a) & Art. 7 GDPR). Providing optional body metrics or Garmin sync is voluntary. No automated profiling or AI scoring occurs in Version 1.0.0 (Art. 13(2)(f) GDPR).'
            : 'ORBIT verarbeitet Konto- und Stammdaten (Name, E-Mail, Rolle, Wohnland für dd.mm.yy / 24h) zur Bereitstellung der Plattform und Missbrauchsabwehr (Art. 6 Abs. 1 lit. b & lit. f DSGVO, Firebase App Check). Trainings-, Leistungs- und Gesundheitsdaten (Herzfrequenz, Wattwerte, Pace, Dauer, Distanz, optionale Körper-/Altersangaben sowie Original-.FIT-/.TCX-/.GPX-Dateien) werden ausschließlich auf Grundlage deiner ausdrücklichen, jederzeit widerruflichen Einwilligung nach Art. 9 Abs. 2 lit. a DSGVO (i. V. m. Art. 7 DSGVO) verarbeitet. Optionale Angaben und Garmin-Sync sind freiwillig. Es findet in Version 1.0.0 kein automatisiertes Profiling oder KI-Scoring statt (Art. 13 Abs. 2 lit. f DSGVO).',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn
            ? '3. Garmin Connect™ & Optional Coach Sharing (.FIT)'
            : '3. Garmin Connect™ & Optionale Coach-Freigabe (.FIT)',
        body: isEn
            ? 'Garmin Connect™ authentication uses OAuth 1.0a (no Garmin password stored). ORBIT is an independent platform and is not affiliated with, sponsored, or certified by Garmin Ltd. A connected coach only gains read access to completed calendar workouts and .fit downloads after your explicit GDPR opt-in and can be revoked in 1 click at any time (ending all platform access immediately). Please note: .fit files a coach already downloaded locally before revocation cannot be deleted remotely from the coach\'s local device.'
            : 'Die Garmin Connect™ Verknüpfung nutzt OAuth 1.0a (ohne Speicherung deines Garmin-Passworts). ORBIT ist eine unabhängige Plattform ohne Partnerschaft oder Zertifizierung durch Garmin Ltd. Ein verbundener Coach erhält erst nach deiner ausdrücklichen DSGVO-Freigabe Einsicht in deine absolvierten Trainings im Kalender sowie den .FIT-Datei-Download – jederzeit mit 1 Klick widerrufbar (sofortiger Entzug aller Plattform-Rechte). Wichtiger Hinweis: Bereits vor dem Widerruf vom Coach lokal auf dessen Endgerät heruntergeladene .FIT-Dateien können technisch bedingt nicht automatisch remote beim Coach gelöscht werden.',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn
            ? '4. Server Location Germany, Processors (Art. 28 GDPR) & Device Storage (§ 25 TDDDG)'
            : '4. Serverstandort Deutschland, Auftragsverarbeitung (Art. 28 DSGVO) & Endgeräte (§ 25 TDDDG)',
        body: isEn
            ? 'All data is stored and processed exclusively inside the European Union in Frankfurt am Main (Germany / EU) via Google Cloud EMEA Limited / Google Ireland Limited (Firebase Auth, Firestore, Cloud Storage, Cloud Functions) under an EU Data Processing Addendum (Art. 28 GDPR). No ad trackers, analytics cookies, or external font servers are loaded. Local browser storage (IndexedDB / localStorage) is used solely where strictly necessary for login sessions, theme, and language settings (Section 25(2) No. 2 TDDDG).'
            : 'Sicherer Serverstandort Deutschland: Sämtliche Daten werden ausschließlich innerhalb der EU in Frankfurt am Main (Deutschland / EU) über Google Cloud EMEA Limited / Google Ireland Limited (Firebase Auth, Firestore, Cloud Storage, Cloud Functions) auf Basis eines EU-Auftragsverarbeitungsvertrags (Art. 28 DSGVO) verarbeitet. Keine Werbe-Tracker, keine Analyse-Cookies, keine externen Schriftart-Abrufe. Lokale Speicherung im Browser/Endgerät (IndexedDB / localStorage) erfolgt ausschließlich für technisch zwingend erforderliche Login-Sitzungen sowie Sprach-/Design-Einstellungen (§ 25 Abs. 2 Nr. 2 TDDDG).',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn
            ? '5. Storage Duration, Erasure & Your GDPR Rights (Art. 15–21, 77)'
            : '5. Speicherdauer, Kontolöschung & Betroffenenrechte (Art. 15–21, 77 DSGVO)',
        body: isEn
            ? 'Data is stored only for the duration of your active account. You can irreversibly delete your account, profile, coach connections, workouts, and all .fit files in Storage at any time under Profile / Settings -> "Delete Data & Account" in the app or ORBIT Web (/app/) (rolling backups are overwritten within max. 30 days). You also have the right of access (Art. 15), rectification (Art. 16), restriction (Art. 18), data portability via direct .FIT download & JSON export in Settings -> Privacy (Art. 20), objection (Art. 21), withdrawal of consent (Art. 7(3)), and the right to lodge a complaint with a data protection supervisory authority (Art. 77 GDPR).'
            : 'Daten werden nur für die Dauer deines aktiven Kontos gespeichert. Du kannst dein Konto samt Profil, Trainingshistorie, Coach-Verknüpfungen, Garmin-Tokens und sämtlichen .FIT-Dateien in Cloud Storage jederzeit über Profil Einfach / Einstellungen -> „Daten & Konto löschen“ (in App & ORBIT Web /app/) sofort unwiderruflich löschen (verschlüsselte Sicherheits-Backups werden innerhalb von max. 30 Tagen rollierend überschrieben). Zudem stehen dir die Rechte auf Auskunft (Art. 15), Berichtigung (Art. 16), Einschränkung (Art. 18), Datenübertragbarkeit per direktem .FIT-Download & JSON-Export unter Einstellungen -> Datenschutz (Art. 20), Widerspruch (Art. 21), Widerruf deiner Einwilligung (Art. 7 Abs. 3) sowie das Beschwerderecht bei einer Datenschutz-Aufsichtsbehörde (Art. 77 DSGVO) zu.',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('legal_open_web_privacy_btn'),
        onPressed: () => _openExternalUrl(ContactConfig.privacyUrl),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(
          isEn
              ? 'Open Online Privacy Policy'
              : 'Datenschutzerklärung im Browser öffnen',
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('legal_open_main_website_btn'),
        onPressed: () => _openExternalUrl(ContactConfig.websiteUrl),
        icon: const Icon(Icons.public, size: 18),
        label: Text(
          isEn ? 'Back to ORBIT Website' : 'Zur ORBIT Haupt-Webseite',
        ),
      ),
    ];
  }

  /// Baut das Impressum (§ 5 DDG / § 18 Abs. 2 MStV).
  List<Widget> _buildImprintContent({
    required bool isEn,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return [
      Text(
        isEn
            ? 'Legal Notice (Section 5 DDG)'
            : 'Impressum (§ 5 DDG / § 18 Abs. 2 MStV)',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: primaryText,
        ),
      ),
      const SizedBox(height: 12),
      _LegalSection(
        title: isEn ? 'Brand & Operator' : 'Marke & Betreiber der Plattform',
        body: isEn
            ? '${ContactConfig.brandName}\nOperator: ${ContactConfig.representativeName} (${ContactConfig.operatorName})\nLocation: ${ContactConfig.locationLabelEn}\nSupport Email: ${ContactConfig.supportEmail}\nPrivacy Email: ${ContactConfig.privacyEmail}\nDirect Web Contact: ${ContactConfig.websiteUrl}#contact\nWebsite: ${ContactConfig.websiteUrl}'
            : '${ContactConfig.brandName}\nBetreiber & Verantwortlicher nach § 5 DDG & § 18 Abs. 2 MStV: ${ContactConfig.representativeName} (${ContactConfig.operatorName})\nStandort: ${ContactConfig.locationLabelDe}\nE-Mail Support: ${ContactConfig.supportEmail}\nE-Mail Datenschutz: ${ContactConfig.privacyEmail}\nDirektkontakt-Webformular: ${ContactConfig.websiteUrl}#contact\nWebseite: ${ContactConfig.websiteUrl}',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn
            ? 'Trademarks & Open Source Licenses'
            : 'Markenhinweis & Open-Source-Lizenzen',
        body: isEn
            ? 'Garmin Connect™ is a trademark of Garmin Ltd. ORBIT is an independent platform. Client & backend software incorporates open-source packages under MIT, BSD-3-Clause, and Apache-2.0 licenses.'
            : 'Garmin Connect™ ist eine Marke der Garmin Ltd. ORBIT ist eine unabhängige Plattform ohne offizielle Zertifizierung durch Garmin Ltd. Die App und Cloud-Komponenten nutzen Open-Source-Pakete unter MIT-, BSD-3-Clause- und Apache-2.0-Lizenz.',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn ? 'Medical Disclaimer' : 'Medizinischer Hinweis',
        body: isEn
            ? 'ORBIT is a sports training and coaching documentation tool and is not a medical device.'
            : 'ORBIT dient der sportwissenschaftlichen Trainingsdokumentation und Zusammenarbeit zwischen Athleten und Trainern. ORBIT ist kein Medizinprodukt und ersetzt keine ärztliche Diagnose.',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      Text(
        'ORBIT ${AppInfo.fullVersionString} · ${AppInfo.region}',
        style: TextStyle(fontSize: 12, color: secondaryText),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('legal_open_source_licenses_btn'),
        onPressed: () {
          showLicensePage(
            context: context,
            applicationName: ContactConfig.brandName,
            applicationVersion: AppInfo.fullVersionString,
            applicationLegalese: isEn
                ? '© 2026 ${ContactConfig.brandName} (${ContactConfig.representativeName})'
                : '© 2026 ${ContactConfig.brandName} (${ContactConfig.representativeName})',
          );
        },
        icon: const Icon(Icons.description_outlined, size: 18),
        label: Text(
          isEn ? 'Open Source Licenses' : 'Open-Source-Lizenzen anzeigen',
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('legal_open_web_imprint_btn'),
        onPressed: () => _openExternalUrl(ContactConfig.imprintUrl),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(
          isEn ? 'Open Legal Notice Online' : 'Impressum im Browser öffnen',
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('legal_open_main_website_imprint_btn'),
        onPressed: () => _openExternalUrl(ContactConfig.websiteUrl),
        icon: const Icon(Icons.public, size: 18),
        label: Text(
          isEn ? 'Back to ORBIT Website' : 'Zur ORBIT Haupt-Webseite',
        ),
      ),
    ];
  }
}

/// Einzelner formatierter Absatzblock innerhalb von [LegalDocumentsSheet].
class _LegalSection extends StatelessWidget {
  final String title;
  final String body;
  final Color primaryText;
  final Color secondaryText;

  const _LegalSection({
    required this.title,
    required this.body,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
