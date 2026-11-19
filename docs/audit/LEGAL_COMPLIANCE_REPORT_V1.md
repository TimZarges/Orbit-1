# Rechtssicherheits- und Formalitäten-Prüfbericht — ORBIT V1.0.0 / V1.0.1

- **Prüfgegenstand:** ORBIT Plattform — Android-App (`app.orbit.training`, `1.0.0+1`), ORBIT Web (`/app/`) und öffentliche Webseite (`/`, `/imprint.html`, `/privacy.html`, `/delete-account.html`, `/help.html`)
- **Projekt / Hosting:** `orbit-app-mvp` (Region: `europe-west3`, Frankfurt am Main, Deutschland / EU)
- **Prüfdatum:** 2026-11-19
- **Prüfmaßstab:** Deutsches und europäisches IT-, Datenschutz- und Wettbewerbsrecht (UWG, DSGVO, DDG, MStV, TDDDG), Google Play Data Safety / Account Deletion Richtlinien, Garmin Developer & Brand Guidelines sowie Open-Source-Lizenzrecht (MIT / BSD / Apache-2.0)

---

## Zusammenfassung (Executive Summary)

Im Rahmen der tiefgehenden Prüfung wurden neben einem bereits sehr soliden Grundgerüst (EU-only Region `europe-west3`, kein Tracking, keine externen Schriftart-Abrufe, Art.-9-Opt-in ohne vorangekreuzte Checkboxen, sofortiger Coach-Widerruf über Rules & Functions, zweistufige Kontolöschung) **sechs konkrete technische bzw. rechtlich-textliche Lücken identifiziert und unmittelbar behoben**:

1. **Mock-Datenexport entfernt (`PrivacySettingsSheet._triggerExport` + `exportAccount`):** Bisher simulierte das UI den Art.-20-DSGVO-Datenexport mit `Future.delayed(1s)` und falscher E-Mail-Meldung. Jetzt wird die echte Cloud Function `exportAccount` (`europe-west3`) aufgerufen, um Profildaten, Aktivitäten, Coach-Verknüpfungen, Einwilligungen, `dailyMetrics` und `thresholdHistory` als maschinenlesbares JSON im UI bereitzustellen (inkl. Kopierfunktion).
2. **Offener Kontaktformular-Fehler-Fake behoben (`public/index.html` `submitContactRequest`):** HTTP-Fehler wurden nicht geprüft (`!res.ok`) und im `catch`-Block wurde fälschlich `✓ Vielen Dank!` statt einer ehrlichen Fehlermeldung angezeigt. Zudem fehlte ein direkter Datenschutzhinweis am Formular. Beides behoben.
3. **Open-Source-Lizenzanzeige ergänzt (`SettingsScreen`, `LegalDocumentsSheet`, `public/imprint.html`):** Alle Flutter- und npm-Drittanbieterpakete sind nun über `showLicensePage` (MIT / BSD-3-Clause / Apache-2.0) mit 1 Klick aus Einstellungen und Impressum abrufbar.
4. **Transparenz zu lokalen Coach-`.FIT`-Downloads & `deleteAccount`-Bereinigung (`V1AthleteCoachConnectionCard`, `LegalDocumentsSheet`, `public/privacy.html`, `functions/src/auth.ts`):** Athleten werden explizit vorab darauf hingewiesen, dass nach Trennung jeder Plattform-Zugriff sofort endet, aber vorab lokal heruntergeladene `.fit`-Dateien beim Coach technisch nicht remote gelöscht werden können. Zudem bereinigt `deleteAccount` nun auch `coachInvites` (`athleteId == uid`) und `invites.usedBy`.
5. **TDDDG, Art. 6/13/21 DSGVO & Garmin™ Marken-Compliance (`LegalDocumentsSheet`, `public/privacy.html`, `GarminConnectionScreen`, `public/delete-account.html`):** Duale Rechtsgrundlagen (Art. 6 Abs. 1 lit. b/f + Art. 9 Abs. 2 lit. a DSGVO), Speicherpflicht- & Nicht-Profiling-Hinweis (Art. 13 Abs. 2 lit. e/f DSGVO), § 25 Abs. 2 Nr. 2 TDDDG (`IndexedDB` / `localStorage`), Widerspruchsrecht (Art. 21 DSGVO), `public/delete-account.html` auf V1.0.0-Realität bereinigt sowie unabhängiger Garmin Connect™ Markenhinweis ergänzt.
6. **Erreichbarkeit auf E-Mail-Verifikations-Screen (`EmailVerificationWaitingScreen`):** Auch vor Abschluss der E-Mail-Bestätigung sind `Datenschutz` und `Impressum` nun mit 1 Klick erreichbar.

**Verbleibende offene organisatorische Pflichtpunkte des Betreibers (vor öffentlichem Marketing- / Play-Store-Produktionsstart zwingend umzusetzen)** sind in Abschnitt 6 gesondert ausgewiesen (insbesondere die **ladungsfähige Postanschrift nach § 5 Abs. 1 Nr. 1 DDG**, aktive E-Mail-Postfächer, Google-Cloud-AVV und Garmin-Produktionsfreigabe).

---

## 1. Transparenz & Irreführungsschutz (§ 5 / § 5a UWG)

| Prüfpunkt | Norm | Status | Fundstelle & Nachweis | Behobene Mängel / Bemerkung |
| :--- | :--- | :--- | :--- | :--- |
| Klare Trennung Live-Funktionsumfang V1.0.0 vs. Roadmap V2.0–V4.0 auf Webseite | §§ 5, 5a UWG | **ERFÜLLT** | [public/index.html](file:///Users/timzarges/Desktop/source/Orbit/public/index.html), [public/help.html](file:///Users/timzarges/Desktop/source/Orbit/public/help.html) | V1.0.0 klar abgegrenzt (`Heute`, `Kalender Woche/Monat/Liste`, `Profil Einfach`, `Garmin Sync`, `.fit`-Upload, Coach-Link & `.FIT`-Download); V2.0–V4.0 im eigenen Bereich als zukünftige Meilensteine markiert (`NICHT BESTANDTEIL VON V1.0.0`). |
| Ehrliche Datenkategorien auf öffentlicher Löschseite (keine vorgetäuschten V2/V3-Features) | § 5 UWG | **BEHOBEN** | [public/delete-account.html](file:///Users/timzarges/Desktop/source/Orbit/public/delete-account.html) | Vormals pauschale Nennung von Chat, Saisonzielen, HRV & Schlaf auf V1.0.0-Realität korrigiert (`sofern ab V2.0/V3.0 erfasst`). |
| Ehrliches Feedback im Kontaktformular & beim Datenexport (kein Fake-Success) | § 5 UWG | **BEHOBEN** | [public/index.html](file:///Users/timzarges/Desktop/source/Orbit/public/index.html), [privacy_settings_sheet.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/settings/widgets/privacy_settings_sheet.dart) | Mock-Export entfernt; Kontaktformular prüft `res.ok` und meldet Fehler ehrlich statt `✓ Vielen Dank!`. |
| Konsistente Versionsangabe über App, Web & Rechtstexte | § 5 UWG | **ERFÜLLT** | [app_config.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/core/config/app_config.dart), [pubspec.yaml](file:///Users/timzarges/Desktop/source/Orbit/pubspec.yaml), `public/*.html` | Einheitlich `Version 1.0.0` / `v1.0.0 (Build 1)` (Hotfix-Stände `v1.0.1` / `v1.0.2` sind interne Git-Release-Tags auf der V1.0.0-Linie). |

---

## 2. Datenschutz & Gesundheitsdaten (DSGVO Art. 5, 6, 7, 9, 12–21, 28, 77)

| Prüfpunkt | Norm | Status | Fundstelle & Nachweis | Behobene Mängel / Bemerkung |
| :--- | :--- | :--- | :--- | :--- |
| Ausdrückliches Opt-In ohne vorangekreuzte Checkboxen (Onboarding & Coach-Link) | Art. 7, 9 Abs. 2 lit. a DSGVO | **ERFÜLLT** | [v1_simple_onboarding_wizard.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/onboarding/widgets/v1_simple_onboarding_wizard.dart), [v1_athlete_coach_connection_card.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/profile/widgets/v1_athlete_coach_connection_card.dart) | `_gdprConsent = false`, `_gdprAcceptedForCode = false`, `_gdprAcceptedForRequest[id] = false`; Bestätigung blockiert ohne aktives Häkchen; Audit-Log in `users/{uid}/consents`. |
| Datenminimierung & Zweckbindung in V1.0.0 | Art. 5 Abs. 1 lit. b, c DSGVO | **ERFÜLLT** | [v1_simple_onboarding_wizard.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/onboarding/widgets/v1_simple_onboarding_wizard.dart), [v1_simple_profile_view.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/profile/widgets/v1_simple_profile_view.dart) | Keine versteckten V2/V3-Pflichtfelder; Körpermaße/Geburtsdatum/Geschlecht optional; Coaches nur Rolle/Name/Bio. |
| Transparenz zur Coach-Freigabe & Begrenzung bereits lokal gespeicherter `.fit`-Kopien | Art. 7, 9, 13 DSGVO | **BEHOBEN** | [v1_athlete_coach_connection_card.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/profile/widgets/v1_athlete_coach_connection_card.dart), [legal_documents_sheet.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/legal/widgets/legal_documents_sheet.dart), [privacy.html](file:///Users/timzarges/Desktop/source/Orbit/public/privacy.html) | Ausdrücklicher Hinweis (DE & EN) ergänzt, dass bereits vor dem 1-Klick-Widerruf vom Coach lokal heruntergeladene `.fit`-Dateien technisch nicht remote gelöscht werden können. |
| Vollständige Pflichtinformationen inkl. dualer Rechtsgrundlage, kein Profiling, Art. 21 & Aufsichtsbehörde | Art. 6, 13, 14, 21, 77 DSGVO | **BEHOBEN** | [legal_documents_sheet.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/legal/widgets/legal_documents_sheet.dart), [privacy.html](file:///Users/timzarges/Desktop/source/Orbit/public/privacy.html), [privacy/index.html](file:///Users/timzarges/Desktop/source/Orbit/public/privacy/index.html) | Art. 6 Abs. 1 lit. b/f + Art. 9 Abs. 2 lit. a, Art. 13 Abs. 2 lit. e/f (Freiwilligkeit, kein Profiling/KI in V1.0.0), Art. 21 Widerspruchsrecht, 30-Tage-Backupfrist & Art. 77 Beschwerderecht präzisiert. |
| Serverstandort EU & Auftragsverarbeiter (Google Cloud EMEA/Ireland Ltd.) | Art. 28, 44 ff. DSGVO | **ERFÜLLT** *(AVV org. prüfen)* | [functions/src/coach.ts](file:///Users/timzarges/Desktop/source/Orbit/functions/src/coach.ts), `firebase.json`, [privacy.html](file:///Users/timzarges/Desktop/source/Orbit/public/privacy.html) | Cloud Functions laufen in `europe-west3`; UI/Web erläutern Google Cloud EMEA/Ireland Ltd. und EU-AVV. |
| Recht auf Datenübertragbarkeit (`.FIT` & echter JSON-Export) | Art. 20 DSGVO | **BEHOBEN** | [auth.ts](file:///Users/timzarges/Desktop/source/Orbit/functions/src/auth.ts), [privacy_settings_sheet.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/settings/widgets/privacy_settings_sheet.dart) | `exportAccount` um `activities`, `coachLinks`, `consents`, `exportedAt` erweitert; `PrivacySettingsSheet` ruft `exportAccount` real auf und bietet JSON-Ansicht + Kopie. |
| Recht auf Löschung (2-Stufen-Dialog, Backend-Cleanup & Web-Löschseite) | Art. 17 DSGVO & Play Store | **BEHOBEN** | [two_step_account_deletion_dialog.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/auth/widgets/two_step_account_deletion_dialog.dart), [auth.ts](file:///Users/timzarges/Desktop/source/Orbit/functions/src/auth.ts), [delete-account.html](file:///Users/timzarges/Desktop/source/Orbit/public/delete-account.html) | `deleteAccount` bereinigt zusätzlich `coachInvites` (`athleteId == uid`) und `invites.usedBy` neben Garmin-Deregistrierung, `coachLinks`, `activities`, `users/{uid}`, Cloud Storage & Auth-User. |

---

## 3. Impressum & Digitale Dienste (§ 5 DDG, § 18 MStV, § 25 TDDDG)

| Prüfpunkt | Norm | Status | Fundstelle & Nachweis | Behobene Mängel / Bemerkung |
| :--- | :--- | :--- | :--- | :--- |
| 2-Klick-Erreichbarkeit von Impressum & Datenschutz in Web & App | § 5 DDG | **BEHOBEN** | `index.html`, `login_screen.dart`, `v1_simple_onboarding_wizard.dart`, `v1_simple_profile_view.dart`, `settings_screen.dart`, [email_verification_waiting_screen.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/auth/screens/email_verification_waiting_screen.dart) | Auf allen App-Ansichten inkl. Verifikations-Screen (`verify_email_privacy_link`, `verify_email_imprint_link`) und allen HTML-Unterseiten (inkl. Sprachübergabe `lang`) verlinkt. |
| Anbietername, § 18 Abs. 2 MStV Verantwortlicher & zweiter elektronischer Kontaktweg | § 5 Abs. 1 Nr. 1–2 DDG, § 18 MStV | **TEILWEISE ERFÜLLT** *(Blocker s. Abschn. 6)* | [imprint.html](file:///Users/timzarges/Desktop/source/Orbit/public/imprint.html), [impressum/index.html](file:///Users/timzarges/Desktop/source/Orbit/public/impressum/index.html), [contact_config.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/core/config/contact_config.dart) | Natürliche Person (`Tim Zarges`), Marke, E-Mail und Online-Direktkontakt (`/#contact`) ausgewiesen. **Offen (Blocker):** Es fehlt noch die vollständige **ladungsfähige Postanschrift** (Straße, Hausnr., PLZ, Ort) statt `Deutschland (EU)`. |
| Zero Third-Party Requests (keine Google Fonts CDN, keine Tracker) & § 25 TDDDG | § 25 Abs. 2 Nr. 2 TDDDG | **BEHOBEN / VERIFIZIERT** | `public/*.html`, `public/app/` (`--no-web-resources-cdn`), [privacy.html](file:///Users/timzarges/Desktop/source/Orbit/public/privacy.html) | 0 externe Font-/Analytics-/CDN-Abrufe; `IndexedDB` / `localStorage` ausschließlich für technisch notwendige Firebase-Auth-Sessions, Theme & Sprache — nun explizit erläutert. |

---

## 4. Drittanbieter-Bedingungen (Garmin™) & Open-Source-Lizenzen

| Prüfpunkt | Norm / Richtlinie | Status | Fundstelle & Nachweis | Behobene Mängel / Bemerkung |
| :--- | :--- | :--- | :--- | :--- |
| Garmin Connect™ Markenhinweis & Unabhängigkeitserklärung | Garmin Developer Brand Guidelines | **BEHOBEN** | [garmin_connection_screen.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/integrations/screens/garmin_connection_screen.dart), [legal_documents_sheet.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/legal/widgets/legal_documents_sheet.dart), `public/imprint.html`, `public/privacy.html`, `public/index.html` | Hinweis aufgenommen, dass Garmin Connect™ eine Marke der Garmin Ltd. ist und ORBIT unabhängig ohne offizielle Partnerschaft/Zertifizierung agiert; OAuth-Deregistrierung in `deleteAccount` aktiv. |
| In-App Open-Source-Lizenzausgabe (MIT, BSD-3-Clause, Apache-2.0) | Open-Source-Lizenzrecht | **BEHOBEN** | [settings_screen.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/settings/screens/settings_screen.dart), [legal_documents_sheet.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/features/legal/widgets/legal_documents_sheet.dart), [pubspec.yaml](file:///Users/timzarges/Desktop/source/Orbit/pubspec.yaml), [functions/package.json](file:///Users/timzarges/Desktop/source/Orbit/functions/package.json) | `showLicensePage(...)` unter *Einstellungen → Open-Source-Lizenzen* und im *Impressum*-Sheet ergänzt; Hinweis auf Backend-Bibliotheken in Web-Impressum aufgenommen. |

---

## 5. Verifizierte Prüfläufe nach Abschluss der Änderungen

- `bash scripts/check_phase_ready.sh` (Analyzer `0 Errors / 0 Warnings / 0 Infos`, Functions TypeScript/ESLint `0 Errors`, `100 %` deutsche Kommentare, Flutter Unit- & Widget-Tests inkl. neuer Rechts- & Export-Tests).
- Firebase Emulator Suite (`firestore`, `storage`): `rules.test.ts` + `coachLink.test.ts` + gesamte `functions` Testsuite.
- Web-Build (`--no-web-resources-cdn --base-href /app/`), Android Release-APK (`1.0.0+1`) auf Pixel 10 Pro (`58251FDCR00EQ2`) sowie Live-Deployment auf `orbit-app-mvp` inklusive Live-Prüfung im geöffneten Safari-Browser.

---

## 6. Offene organisatorische Pflichtpunkte für den Betreiber (Tim Zarges)

Diese Punkte liegen außerhalb des Quellcodes und **müssen vor dem breiten öffentlichen Rollout / Google Play Store Produktions-Release organisatorisch abgeschlossen werden**:

1. **[PFLICHT — § 5 Abs. 1 Nr. 1 DDG / § 18 Abs. 2 MStV] Ladungsfähige Postanschrift nachtragen:**
   - Derzeit steht im Impressum lediglich `Standort: Deutschland (EU)`. Vor Veröffentlichung im Google Play Store / öffentlicher Vermarktung muss in [contact_config.dart](file:///Users/timzarges/Desktop/source/Orbit/lib/core/config/contact_config.dart), [public/imprint.html](file:///Users/timzarges/Desktop/source/Orbit/public/imprint.html) und [public/impressum/index.html](file:///Users/timzarges/Desktop/source/Orbit/public/impressum/index.html) eine echte **ladungsfähige Anschrift** (Straße, Hausnummer, PLZ, Ort — z. B. Wohn-/Geschäftsadresse oder ladungsfähige c/o-Impressums-Adresse), ggf. die gewerbliche Rechtsform (`Einzelunternehmen`) und sofern vorhanden eine USt-IdNr. eingetragen werden.
2. **[PFLICHT — § 5 DDG & Art. 12–17 DSGVO] E-Mail-Postfächer produktiv aktivieren & überwachen:**
   - Sicherstellen, dass `support@orbit-training.app`, `privacy@orbit-training.app`, `bugs@orbit-training.app`, `feedback@orbit-training.app` und `hello@orbit-training.app` technisch zustellbar sind und Anfragen (insbesondere Art.-15/17-Lösch-/Auskunftsanfragen über `/delete-account.html`) fristgerecht innerhalb von max. 1 Monat beantwortet werden.
3. **[PFLICHT — Art. 28 DSGVO] Google Cloud / Firebase EU Data Processing Addendum (DPA) & App Check Enforcement prüfen:**
   - In der Google Cloud / Firebase Console prüfen, ob das **Cloud Data Processing Addendum (CDPA)** für Projekt `orbit-app-mvp` akzeptiert ist, und nach Play-Integrity-/Web-reCAPTCHA-Verifikation ggf. App-Check-Enforcement aktivieren.
4. **[PFLICHT — Art. 30 DSGVO & Play Store] Verzeichnis von Verarbeitungstätigkeiten (VVT) & Google Play Data Safety Formular abgleichen:**
   - Internes VVT (Art. 30 DSGVO) ablegen und im Google Play Console *Data Safety*-Formular exakt die erhobenen Daten (E-Mail, Name, Fitness-/Gesundheitsdaten, optionale Körperdaten, keine Weitergabe an Dritte zu Werbezwecken) inklusive Link zu `https://orbit-app-mvp.web.app/delete-account.html` angeben.
5. **[PFLICHT — Garmin Developer Portal] Garmin Production Key & Compliance-Abnahme:**
   - Sicherstellen, dass im Garmin Connect Developer Program die Produktions-Evaluation/Freigabe (inkl. Webhook- & Deregistrierungs-Endpunkten) abgeschlossen ist und keine Test-Evaluation-Limits überschritten werden.
