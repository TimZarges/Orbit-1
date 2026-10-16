# ORBIT — Google Play Store Einreichungs- & Data Safety Leitfaden

> **Ziel:** Google Play Console Closed Testing Track (Closed Beta Start zum 31. Oktober 2026)  
> **App-Paket-ID:** `training.orbit.app` (bzw. `com.example.orbit`)  
> **Server-Region:** `europe-west3` (Frankfurt, Deutschland — 100 % DSGVO-konform)

Dieses Dokument enthält alle schlüsselfertigen Kopiervorlagen für Metadaten, den Google Play Data Safety Bogen und die Build-/Upload-Befehle.

---

## 1. Store-Listing Metadaten (Kopiervorlagen)

### Name der App:
- **DE & EN:** `ORBIT — Telemetrie & Coaching`

### Kurzbeschreibung (Max. 80 Zeichen):
- **DE (74 Zeichen):** `High-End Telemetrie, Leistungsdiagnostik & Coaching für Ausdauersportler.`
- **EN (73 Zeichen):** `High-end telemetry, performance analytics & coaching for endurance sports.`

### Langbeschreibung (Deutsch, ca. 2.600 Zeichen):
```text
ORBIT ist die professionelle Leistungsdiagnostik-, Telemetrie- und Coaching-Plattform für ambitionierte Radsportler, Triathleten, Läufer und deren Vereinstrainer. Entwickelt mit sportwissenschaftlicher Präzision und modernster Technologie.

WARUM ORBIT?
Die meisten Sport-Apps bieten nur einfache Durchschnitte. ORBIT analysiert deine Trainingseinheiten mit der analytischen Tiefe professioneller Diagnostik-Software (GoldenCheetah-Standard) – kombiniert mit der aufgeräumten Klarheit des modernen MATS.coachings und einer täglichen Whoop-inspirierten 3-Ringe-Tagessteuerung.

HIGHLIGHTS FÜR ATHLETEN:
• DREI-RINGE-TAGESSTEUERUNG: Erholung (0–100 %), dynamischer Tagesbelastungskorridor und Schlafqualität auf einen Blick im eleganten Navy-Design (#001F47) mit Volt-Signatur (#CDFB17).
• 30-TAGE-NORM-BÄNDER: Erkenne kardiovaskuläre Trends bei Herzfrequenzvariabilität (HRV) und Ruhepuls sofort anhand deines individuellen µ ± 1σ Korridors.
• PROFISPORT-METRIKEN: Exakte Berechnung von Normalized Power (NP), Intensity Factor (IF), TSS, Critical Power (CP / W') und sekündlichem W'bal-Verlauf (Skiba-Modell) zur Überwachung deiner anaeroben Arbeitskapazität.
• BANISTER PMC: Verfolge Fitness (CTL), Ermüdung (ATL) und Form (TSB) über 90 Tage mit 14-Tage-Zukunftsprojektion und Ramp-Rate-Warnungen.
• WETTKAMPF-COUNTDOWN: Plane deine Saison-Ziele nach A-, B- und C-Priorität mit Countdown, Ziel-Watt und Taper-Korridor im PMC-Chart.
• NAHTLOSE VERBINDUNG: Offizielle Garmin Connect™ Integration (Live-Webhook & 90-Tage-Backfill) sowie manueller Multi-File-Upload für Wahoo, SRM und Zwift (.fit, .tcx, .gpx).

HIGHLIGHTS FÜR VEREINSTRAINER:
• ATHLETEN-DASHBOARD: Behalte deine Vereinsgruppe mobil oder im Web-Browser (/app) im Blick.
• INTERVALL-KOMMENTARE: Hinterlasse Feedback direkt an einzelnen Belastungsintervallen.
• SCHNELLE KOPPLUNG: Lade Athleten sekundenschnell per 6-stelligem Einladungscode ein.

STRENGER DATENSCHUTZ (ART. 9 DSGVO):
• Echte Privatsphäre: Deine Gesundheitsdaten (HRV, Schlaf) sind durch Art. 9 DSGVO geschützt. Trainer sehen Erholungsdaten nur bei deiner expliziten Freigabe. Nach Trennung erlischt der Zugriff sofort.
• Server-Standort Frankfurt am Main (europe-west3). Keine Werbe-Tracker, keine Weitergabe an Dritte.
• Volle Kontrolle: Vollständiger Datenexport und Account-Löschung jederzeit direkt in der App oder online unter app.orbit.training/delete-account.

Werde Teil der Closed Beta und hebe dein Ausdauertraining auf die nächste Stufe!
```

### Langbeschreibung (Englisch, ca. 2.400 Zeichen):
```text
ORBIT is the professional telemetry, performance analytics, and coaching platform for endurance cyclists, triathletes, runners, and club coaches. Built with sports science precision and cutting-edge mobile architecture.

WHY ORBIT?
Most fitness apps only scratch the surface with simple averages. ORBIT analyzes every second of your workout with the depth of specialized sports science tools (GoldenCheetah benchmark) — paired with clean modern coaching interaction and an intuitive 3-ring recovery system.

KEY FEATURES FOR ATHLETES:
• THREE-RING DAILY READINESS: Monitor Recovery (0–100%), personalized daily strain targets, and sleep debt at a glance in our signature #001F47 Navy with high-contrast Volt accents (#CDFB17).
• 30-DAY ROLLING BASELINES: Spot autonomic nervous system trends in HRV and Resting HR with personalized ±1σ normal ranges.
• ELITE TELEMETRY & DIAGNOSTICS: Calculate Normalized Power (NP), Intensity Factor (IF), TSS, Critical Power (CP/W'), and continuous Skiba W'bal tracking to monitor anaerobic capacity reserve.
• BANISTER PMC: Track Chronic Training Load (CTL), Acute Training Load (ATL), and Training Stress Balance (TSB) over 90 days with 14-day projection and ramp rate alerts.
• RACE GOALS & TAPERING: Plan your season across A, B, and C priority races with countdowns, target watts/pace, and visualized taper corridors in your PMC chart.
• HARDWARE COMPATIBILITY: Official Garmin Connect™ integration (instant webhooks & 90-day backfill) plus multi-file batch upload for Wahoo, SRM, and Zwift (.fit, .tcx, .gpx).

KEY FEATURES FOR CLUB COACHES:
• COACH DASHBOARD: Manage all your club athletes on mobile or via desktop web (/app).
• INTERVAL-SPECIFIC FEEDBACK: Leave comments and guidance on specific workout intervals.
• INSTANT PAIRING: Invite athletes via secure 6-character club invite codes.

GDPR & PRIVACY (ARTICLE 9 COMPLIANT):
• True athlete autonomy: Health metrics (HRV, sleep) are protected sensitive data. Coaches only access recovery stats with your granular consent. Revoking access takes effect immediately.
• European cloud infrastructure based exclusively in Frankfurt, Germany (europe-west3). No third-party ad networks, no data selling.
• Right to be forgotten: Complete data export and account deletion available in-app and at app.orbit.training/delete-account.

Join our closed beta today and experience next-generation endurance telemetry!
```

---

## 2. Google Play Data Safety (Datensicherheit) — Klick-für-Klick Vorlage

Beim Ausfüllen des Formulars **„Datensicherheit“ (Data Safety)** in der Google Play Console:

### Frage: Erhebt oder teilt Ihre App Nutzerdaten?
- **Antwort:** **Ja**

### Frage: Werden alle erfassten Nutzerdaten bei der Übertragung verschlüsselt?
- **Antwort:** **Ja** (HTTPS / TLS 1.3 über Google Cloud europe-west3)

### Frage: Bieten Sie Nutzern die Möglichkeit, ihr Konto und die zugehörigen Daten löschen zu lassen?
- **Antwort:** **Ja**
- **Link zur Löschseite:** `https://app.orbit.training/delete-account`

---

### Datentypen im Detail:

#### 1. Gesundheit und Fitness
- **Erfasst:** Ja
- **Geteilt:** Nein (Wird NIEMALS an Dritte geteilt)
- **Verwendungszwecke:** App-Funktionalität, Personalisierung (Berechnung von Training Stress Score, Erholung, W'bal, Schlafanalyse)
- **Verknüpfung mit Identität:** Ja (mit dem Nutzerkonto verknüpft)
- **Erforderlich oder Optional:** Erforderlich für Kernfunktionen (mit expliziter Art.-9-DSGVO-Zustimmung im Onboarding)

#### 2. Standort (Ungefährer und Genauer Standort)
- **Erfasst:** Ja (GPS-Strecken aus FIT/TCX/GPX-Aktivitäten)
- **Geteilt:** Nein
- **Verwendungszwecke:** App-Funktionalität (Darstellung von Aktivitäts-Streckenkarten und Höhenprofilen)
- **Verknüpfung mit Identität:** Ja
- **Erforderlich oder Optional:** Optional (Kartenanzeige erfordert DSGVO-Opt-in; Indoor-Einheiten funktionieren komplett ohne GPS)

#### 3. Personenbezogene Daten (Name, E-Mail-Adresse, Nutzer-IDs)
- **Erfasst:** Ja
- **Geteilt:** Nein
- **Verwendungszwecke:** Kontoverwaltung, Authentifizierung, App-Funktionalität
- **Verknüpfung mit Identität:** Ja
- **Erforderlich oder Optional:** Erforderlich

#### 4. App-Informationen und -Leistung (Absturzprotokolle, Diagnose)
- **Erfasst:** Ja (Firebase Crashlytics)
- **Geteilt:** Nein
- **Verwendungszwecke:** Analyse, Fehlerbehebung
- **Verknüpfung mit Identität:** Nein (Vollständig anonymisiert/pseudonymisiert, E-Mail-Adressen und Tokens werden vor dem Senden sanitisiert)
- **Erforderlich oder Optional:** **Optional** (Standardmäßig DEAKTIVIERT; nur aktiv, wenn der Nutzer im Onboarding oder Profil explizit eingewilligt hat)

---

## 3. Schritt-für-Schritt Build- & Release-Befehle

### A. Vorbereitung: Release Keystore & `key.properties`
Erstelle eine Datei `android/key.properties` (wird durch `.gitignore` geschützt und niemals ins Repository committed):
```properties
storePassword=DEIN_KEYSTORE_PASSWORT
keyPassword=DEIN_KEY_PASSWORT
keyAlias=orbit-upload-key
storeFile=/Users/timzarges/upload-keystore.jks
```

### B. Produktions-Release-Build erstellen
```bash
# 1. Abhängigkeiten prüfen & Code formatieren
dart format .
flutter analyze --no-fatal-infos

# 2. Universelle Release-APK bauen (für direktes Testen auf dem Pixel 10 Pro):
flutter build apk --release

# 3. Android App Bundle (.aab) bauen (für Google Play Console & Play Feature Delivery):
flutter build appbundle --release
```
*Die fertigen Artefakte liegen unter:*  
- APK: `build/app/outputs/flutter-apk/app-release.apk`  
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

### C. Stufe 1: Verteilung via Firebase App Distribution (5–10 Vereinsathleten)
```bash
# Firebase CLI App Distribution Upload
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:DEINE_FIREBASE_APP_ID:android:DEIN_HASH \
  --release-notes "ORBIT Closed Beta v0.24.0-rc.1: 3-Ringe-Tagessteuerung, Garmin Live-Webhook & Profi-Telemetrie." \
  --groups "vereins-beta-tester"
```

---

### D. Stufe 2: Google Play Console Closed Testing Track Upload
1. In der [Google Play Console](https://play.google.com/console) anmelden.
2. App **ORBIT** auswählen -> Im linken Menü unter **Testen** auf **Geschlossener Test** (Closed Testing) klicken.
3. Track anlegen oder öffnen: **Alpha / Closed Beta**.
4. Neuen Release erstellen:
   - Die Datei `build/app/outputs/bundle/release/app-release.aab` hochladen.
   - Versionsname: `1.0.0 (v0.24.0-beta.1)`.
   - Versionshinweise (DE & EN) aus Abschnitt 1 einfügen.
5. Testerliste zuweisen (E-Mail-Adressen der Vereinsfreunde).
6. **Release prüfen & einführen** -> Nach dem automatischen Google Pre-Launch Review steht der Testlink für Tester bereit.
