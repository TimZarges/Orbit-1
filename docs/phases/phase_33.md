# PHASE 33 — Gründlicher Deutscher & EU Sicherheits-, Datenschutz- & Urheberrechts-Audit

## Modus & Zielsetzung
- **Modus:** AUTONOMER BETRIEB & RECHTLICHER AUDIT
- **Ziel:** Vollständige Beseitigung von Technik-Jargon in den Datenschutz-Erklärungen, umfassende rechtliche und urheberrechtliche Absicherung (DSGVO, TDDDG, DDG) sowie Zero-Open-Data Verifikation aller Cloud-Ressourcen.
- **Status:** [x] Vollständig abgeschlossen & per Hardware-Screenshot sowie Rules-Tests verifiziert.

---

## Arbeitspakete

### 33.1 Verständliche Datenschutz-Texte (Bürgernahe Sprache)
- [x] 1. **Beseitigung von Technik-Jargon:**
  - Entfernung aller internen Kürzel (`europe-west3`, `Google Secret Manager`), Datenformate (`JSON`) und Paragrafen-Aufzählungen (`Art. 9, 17, 20 DSGVO`) aus den sichtbaren UI-Texten.
- [x] 2. **Klares, vertrauensbildendes Wording:**
  - Formulierung: *„Sicherer Serverstandort Deutschland – Geschützt nach strengen deutschen und europäischen Datenschutzgesetzen.“*
  - Transparente Erklärung: Datenexport und vollständige Kontolöschung jederzeit auf Knopfdruck.
  - Überarbeitung des Datenschutz-Sheets in den Einstellungen (`privacy_settings_sheet.dart`) und der Coach-Tabelle (`coach_athletes_table.dart`, `athlete_coach_tab_screen.dart`).

### 33.2 Rechtlicher & Urheberrechtlicher Check (App & Website)
- [x] 1. **Rechtskonforme Pflichtseiten:**
  - Impressum mit sauberen Platzhaltern für Anbieterangaben (§ 5 DDG & § 18 Abs. 2 MStV) in `public/imprint.html` und `public/impressum/index.html`.
  - Datenschutzerklärung, Nutzungsbedingungen (AGB) und Widerrufsbelehrung für Gesundheitsdaten.
- [x] 2. **Marken- & IP-Bereinigung:**
  - Konsequente Ersetzung fremder, geschützter Begriffe (z. B. TrainingPeaks-Marken wie `TSS`, `IF`, `NP`) durch eigenständige, wissenschaftliche ORBIT-Begrifflichkeiten:
    - `TSS` $\rightarrow$ **ORBIT Load** / **Belastung**
    - `NP` $\rightarrow$ **Iso-Power** / **Normalisierte Leistung**
    - `IF` $\rightarrow$ **Intensitäts-Faktor**
  - Einhaltung der GPL-Cleanroom-Vorgaben bezüglich GoldenCheetah (kein fremder Code, nur offizielle Formeln).

### 33.3 Zero-Open-Data Security-Audit
- [x] 1. **Firestore & Storage Security Rules:**
  - Automatisierte Negativ-Tests: Nachweis, dass kein einziges Profil-, Trainings- oder Gesundheitsdokument sowie keine Datei ohne aktive, autorisierte Session über das Internet abrufbar ist (`functions/src/__tests__/rules.test.ts` Sektion 12, 36/36 Tests bestanden).
- [x] 2. **Cloud Functions:**
  - Absicherung aller Callables gegen unberechtigte Aufrufe und Überprüfung der Datenminimierung in allen Payloads.

---

## Verifikation & Nachweise
- Screenshot der bürgernahen Datenschutz-Texte auf dem Google Pixel 10 Pro: `docs/beta/screenshots/phase33_plain_privacy_screen.png`.
- Emulator-Testprotokoll der Zero-Open-Data Security Rules: 36/36 Tests grün in `functions/src/__tests__/rules.test.ts`.
- Vollständiger Durchlauf aller 177 Flutter-Tests (`flutter test`) ohne Fehler.
- Dokumentation der Rechtskonformität in `docs/CHECKPOINTS.md`.
