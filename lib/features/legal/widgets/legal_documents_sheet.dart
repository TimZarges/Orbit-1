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
    final bgColor = isDark ? AppColors.anthraciteCard : Colors.white;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0);
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF475569);

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
            ? '2. Health & Training Data (Art. 9 GDPR)'
            : '2. Gesundheits- & Trainingsdaten (Art. 9 DSGVO)',
        body: isEn
            ? 'ORBIT processes endurance training & health telemetry (heart rate, power, pace, duration, distance, and original .FIT/.TCX/.GPX files) exclusively based on your explicit GDPR Art. 9(2)(a) consent.'
            : 'ORBIT verarbeitet Trainings-, Leistungs- und Gesundheitsdaten (Herzfrequenz, Wattwerte, Pace, Dauer, Distanz sowie Original-.FIT-/.TCX-/.GPX-Dateien) ausschließlich auf Grundlage deiner ausdrücklichen Einwilligung nach Art. 9 Abs. 2 lit. a DSGVO.',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn
            ? '3. Garmin Connect & Optional Coach Sharing (.FIT)'
            : '3. Garmin Connect & Optionale Coach-Freigabe (.FIT)',
        body: isEn
            ? 'Garmin Connect uses OAuth 1.0a; we never store your Garmin password. A connected coach only gains read access to your completed calendar workouts and .fit file downloads after your explicit GDPR confirmation and can be revoked with 1 click at any time.'
            : 'Die Garmin Connect Verknüpfung nutzt sicheres OAuth 1.0a (ohne Speicherung deines Garmin-Passworts). Ein verbundener Coach erhält erst nach deiner ausdrücklichen DSGVO-Freigabe Einsicht in deine absolvierten Trainings im Kalender sowie den .FIT-Datei-Download – jederzeit mit 1 Klick widerrufbar.',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn
            ? '4. Server Location Germany & Processors (Art. 28 GDPR)'
            : '4. Serverstandort Deutschland & Auftragsverarbeiter (Art. 28 DSGVO)',
        body: isEn
            ? 'All data is stored and processed exclusively inside the European Union in Frankfurt am Main (Germany / EU) via Google Cloud EMEA Limited / Google Ireland Limited (Firebase Auth, Firestore, Cloud Storage, Cloud Functions) under an EU Data Processing Addendum (DPA). No ad trackers or external font servers are loaded.'
            : 'Sicherer Serverstandort Deutschland: Sämtliche Daten werden ausschließlich innerhalb der EU in Frankfurt am Main (Deutschland / EU) über Google Cloud EMEA Limited / Google Ireland Limited (Firebase Auth, Firestore, Cloud Storage, Cloud Functions) auf Basis eines EU-Auftragsverarbeitungsvertrags (Art. 28 DSGVO) verarbeitet. Keine Werbe-Tracker, keine externen Schriftart-Abrufe.',
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
      _LegalSection(
        title: isEn
            ? '5. Storage Duration, Erasure & Your GDPR Rights (Art. 15–21, 77)'
            : '5. Speicherdauer, Kontolöschung & Betroffenenrechte (Art. 15–21, 77 DSGVO)',
        body: isEn
            ? 'Data is stored only for the duration of your active account. You can irreversibly delete your account, profile, coach connections, workouts, and all .fit files in Storage at any time under Profile / Settings -> "Delete Data & Account" in the app or ORBIT Web (/app/) (rolling backups are overwritten within max. 30 days). You also have the right of access (Art. 15), rectification (Art. 16), restriction (Art. 18), data portability via direct .FIT download & JSON export (Art. 20), withdrawal of consent (Art. 7(3)), and the right to lodge a complaint with a data protection supervisory authority (Art. 77 GDPR).'
            : 'Daten werden nur für die Dauer deines aktiven Kontos gespeichert. Du kannst dein Konto samt Profil, Trainingshistorie, Coach-Verknüpfungen und sämtlichen .FIT-Dateien in Cloud Storage jederzeit über Profil Einfach / Einstellungen -> „Daten & Konto löschen“ (in App & ORBIT Web /app/) sofort unwiderruflich löschen (verschlüsselte Sicherheits-Backups werden innerhalb von max. 30 Tagen rollierend überschrieben). Zudem stehen dir die Rechte auf Auskunft (Art. 15), Berichtigung (Art. 16), Einschränkung (Art. 18), Datenübertragbarkeit per direktem .FIT-Download & Export (Art. 20), Widerruf deiner Einwilligung (Art. 7 Abs. 3) sowie das Beschwerderecht bei einer Datenschutz-Aufsichtsbehörde (Art. 77 DSGVO) zu.',
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
            ? '${ContactConfig.brandName}\nOperated by: ${ContactConfig.operatorName}\nRepresentative: ${ContactConfig.representativeName}\nLocation: ${ContactConfig.locationLabelEn}\nSupport: ${ContactConfig.supportEmail}\nPrivacy: ${ContactConfig.privacyEmail}\nWebsite: ${ContactConfig.websiteUrl}'
            : '${ContactConfig.brandName}\nBetreiber: ${ContactConfig.operatorName}\nVerantwortlich nach § 5 DDG & § 18 Abs. 2 MStV: ${ContactConfig.representativeName}\nStandort: ${ContactConfig.locationLabelDe}\nE-Mail Support: ${ContactConfig.supportEmail}\nE-Mail Datenschutz: ${ContactConfig.privacyEmail}\nWebseite: ${ContactConfig.websiteUrl}',
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
