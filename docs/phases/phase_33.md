# PHASE 33 — Gründlicher Deutscher & EU Sicherheits-, Datenschutz- & Urheberrechts-Audit

## Modus & Zielsetzung
- **Modus:** AUTONOMER BETRIEB & RECHTLICHER AUDIT
- **Ziel:** Vollständige Beseitigung von Technik-Jargon in den Datenschutz-Erklärungen, umfassende rechtliche und urheberrechtliche Absicherung (DSGVO, TDDDG, DDG) sowie Zero-Open-Data Verifikation aller Cloud-Ressourcen.

---

## Arbeitspakete

### 33.1 Verständliche Datenschutz-Texte (Bürgernahe Sprache)
1. **Beseitigung von Technik-Jargon:**
   - Entfernung aller internen Kürzel (`europe-west3`, `Google Secret Manager`), Datenformate (`JSON`) und Paragrafen-Aufzählungen (`Art. 9, 17, 20 DSGVO`) aus den sichtbaren UI-Texten.
2. **Klares, vertrauensbildendes Wording:**
   - Formulierung: *„Sicherer Serverstandort Deutschland – Geschützt nach strengen deutschen und europäischen Datenschutzgesetzen.“*
   - Transparente Erklärung: Datenexport und vollständige Kontolöschung jederzeit auf Knopfdruck.
   - Überarbeitung von Schritt 4 im Onboarding und des Datenschutz-Sheets in den Einstellungen.

### 33.2 Rechtlicher & Urheberrechtlicher Check (App & Website)
1. **Rechtskonforme Pflichtseiten:**
   - Impressum mit sauberen Platzhaltern für Anbieterangaben (niemals private Kontaktdaten des Entwicklers leaken).
   - Datenschutzerklärung, Nutzungsbedingungen (AGB) und Widerrufsbelehrung für Gesundheitsdaten.
2. **Marken- & IP-Bereinigung:**
   - Konsequente Ersetzung fremder, geschützter Begriffe (z. B. TrainingPeaks-Marken wie `TSS`, `IF`, `NP`) durch eigenständige, wissenschaftliche ORBIT-Begrifflichkeiten:
     - `TSS` $\rightarrow$ **ORBIT Load** / **Belastung**
     - `NP` $\rightarrow$ **Iso-Power** / **Normalisierte Leistung**
     - `IF` $\rightarrow$ **Intensitäts-Faktor**
   - Einhaltung der GPL-Cleanroom-Vorgaben bezüglich GoldenCheetah (kein fremder Code, nur offizielle Formeln).

### 33.3 Zero-Open-Data Security-Audit
1. **Firestore & Storage Security Rules:**
   - Automatisierte Negativ-Tests: Nachweis, dass kein einziges Profil-, Trainings- oder Gesundheitsdokument sowie keine Datei ohne aktive, autorisierte Session über das Internet abrufbar ist.
2. **Cloud Functions:**
   - Absicherung aller Callables gegen unberechtigte Aufrufe und Überprüfung der Datenminimierung in allen Payloads.

---

## Verifikation & Nachweise
- Screenshots der überarbeiteten Datenschutz-Texte auf dem Smartphone.
- Emulator-Testprotokoll der Zero-Open-Data Security Rules.
- Dokumentation der Rechtskonformität in `docs/CHECKPOINTS.md`.
