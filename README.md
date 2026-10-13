# ORBIT – Trainingsplattform für Ausdauersportler

> **ORBIT** ist eine Mobile-First-Trainingsplattform für ambitionierte Triathleten (Schwimmen, Rad, Lauf; zusätzlich Kraft) und ihre Trainer. Vom Hobbysportler bis zum Leistungssportler.

---

## 🎯 Leitprinzip & Vision

*„Einfach zuerst, Details eine Ebene tiefer“* (**Progressive Disclosure**).
- **Ruhige Übersicht:** Keine Reizüberflutung. Der Home-Screen („Heute“) zeigt mit dem Volt Daily Ring und der Form-Ampel das Wesentliche für den Tag.
- **Tiefgehende Analytik:** Telemetrie-Cockpit mit Zoom, Leistungskurven, Zonenverteilung und Rundenvergleichen für Athleten und Coaches, die tief eintauchen wollen.
- **Datenschutz & Souveränität:** Hosting ausschließlich in der EU (Frankfurt, `europe-west3`). Strikte Einhaltung von Art. 9 DSGVO für Gesundheitsdaten.

---

## 🏗 Architektur & Tech-Stack

- **Frontend:** Flutter / Dart (`sdk ^3.11.1`).
  - Prioritäten: **Android > iOS > Web/Desktop**.
  - State Management: **Riverpod**.
  - Navigation: **GoRouter** mit Deep Links.
  - Diagramme: **Fl_Chart** mit angepasster Zeitreihen-Interpolation.
  - Design-System: Zentralisiert in `lib/core/design/` (Deep Navy `#0A0F1D`, Performance-Volt `#CDFB17`, Dark Surface `#0F172A`).
- **Backend (Serverless):** Firebase (Google Cloud Platform).
  - Region: **`europe-west3`** (Frankfurt, Deutschland).
  - **Firebase Authentication:** E-Mail/Passwort, Google Sign-In, Sign in with Apple vorbereitet.
  - **Cloud Firestore:** NoSQL-Datenbank mit Least-Privilege Security Rules (`firestore.rules`).
  - **Cloud Storage:** Komprimierte 1-Hz-Sensorstreams (`.json.gz`), FIT-Dateien und Chat-Anhänge (`storage.rules`).
  - **Cloud Functions:** TypeScript (2nd Gen) für serverseitige Metrikberechnung, Webhook-Verarbeitung, Push-Benachrichtigungen und Coach-Dashboard-Aggregation.
  - **Cloud Secret Manager:** Sichere Verwahrung von Drittanbieter-Tokens (Garmin OAuth).

---

## 📁 Projektstruktur

```
Orbit/
├── lib/
│   ├── core/                  # Gemeinsame Utilities, Design-Tokens, globale Widgets
│   │   ├── design/            # AppColors, AppTheme, Widget-Galerie
│   │   └── metrics/           # Zonenmodelle, Vorschau-Berechnungen
│   ├── features/              # Feature-First Organisation
│   │   ├── activities/        # Cockpit, Telemetrie, Runden, Home-Tab
│   │   ├── auth/              # Registrierung, Login, Rollenauswahl
│   │   ├── calendar/          # Wochen-/Monatskalender, Soll-Ist-Abgleich
│   │   ├── chat/              # 1:1 Chat, Aktivitäts-Snapshots, FCM
│   │   ├── coach_link/        # Trainer-Athlet-Verknüpfung, Kader-Raster, Massenzuweisung
│   │   ├── diagnostics/       # Schwellenwert-Erkennung (FTP, LTHR, CSS), Feldtests
│   │   ├── home/              # Home-Dashboard Karten-Resolver & Widgets
│   │   ├── profile/           # Profil, Schwellenwerte, Zonenkonfiguration
│   │   ├── settings/          # Einstellungen, Garmin-Verbindung, Datenschutz
│   │   └── workout_builder/   # Strukturierter Trainingseditor, Vorlagenbibliothek
│   └── l10n/                  # Lokalisierung (app_de.arb, app_en.arb)
├── functions/                 # Cloud Functions Backend (TypeScript)
│   └── src/
│       ├── chat/              # Push-Trigger & FCM-Benachrichtigungen
│       ├── coach/             # O(1) Dashboard-Aggregation & Triggers
│       ├── import/            # FIT-Parser, Garmin Webhook & Idempotenz
│       ├── metrics/           # TSS, NP, CTL/ATL/TSB Berechnung
│       └── seeds/             # Test-Athleten-Generator (abgesichert)
├── docs/                      # Architektur, Spezifikationen, Phasen und Release-Doku
│   ├── release/               # Store-Listings, DSFA, Security-Audit, Checklisten
│   └── phases/                # Detaillierte Phasenpläne (Phase 00–16)
└── test/                      # Unit- und Widget-Tests
```

---

## 🚀 Erste Schritte (Entwicklung)

### 1. Voraussetzungen
- Flutter SDK `^3.11.1` (oder aktuell)
- Node.js LTS (für Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)

### 2. Abhängigkeiten installieren
```bash
flutter pub get
cd functions && npm install && cd ..
```

### 3. Statische Analyse & Formatierung
```bash
flutter analyze
dart format .
```

### 4. Tests ausführen
```bash
# Flutter Tests
flutter test

# Backend Functions Tests
cd functions && npm test && cd ..
```

### 5. Lokale Entwicklung mit Emulatoren
```bash
firebase emulators:start
```
Die App verbindet sich in Flavor `dev` automatisch mit den lokalen Emulatoren für Auth, Firestore und Functions.

---

## 🔒 Sicherheit & Datenschutz

- **Art. 9 DSGVO:** Gesundheitsdaten (Herzfrequenz, HRV, Schlaf) werden ausschließlich nach ausdrücklicher, protokollierter Nutzereinwilligung verarbeitet.
- **Rollen-Souveränität:** Wichtige Rollen- und Berechtigungsfelder (`role`, `coachId`, `trainerVerified`) können niemals direkt vom Client in Firestore geschrieben werden.
- **Datensparsame Pushs:** Push-Benachrichtigungen enthalten standardmäßig keine sensitiven Inhalte.
- **Echte Athleten-Souveränität:** Schwellenwertvorschläge vom Trainer oder Algorithmus können niemals ohne Bestätigung des Athleten übernommen werden.

---

## 📄 Lizenz & Dokumentation

- Ausführliche Dokumentation unter [`docs/`](file:///Users/timzarges/Desktop/source/Orbit/docs/).
- Release-Vorbereitungsdokumente unter [`docs/release/`](file:///Users/timzarges/Desktop/source/Orbit/docs/release/).
