# PHASE 32 — Zwei globale Coach-Modi (Einfach/Datei-Download vs. Analyse) & Header-Benachrichtigungsglocke

## Modus & Zielsetzung
- **Modus:** AUTONOMER BETRIEB (Google Pixel 10 Pro via USB / `adb`)
- **Ziel:** Entflechtung der Kommunikation (Header-Mitteilungszentrale vs. Coach-Chat) und Einführung zweier globaler Betriebsmodi für Trainer inklusive Originaldateien-Archivierung und -Download.

---

## Arbeitspakete
 
- [x] **32.1 Header-Benachrichtigungsglocke vs. „Coach“-Tab:**
  - [x] Umbau des Chat-Icons oben rechts in der App-Bar zu einer **Glocke (`Icons.notifications`) mit Ungelesen-Badge (`#CDFB17` Volt)**.
  - [x] Bottom-Sheet Mitteilungszentrale (`NotificationCenterSheet`) mit Deep-Linking für alle System-Ereignisse (PRs, Garmin-Sync, Trainer-Planung, System-Updates).
  - [x] Bündelung des direkten 1:1-Austauschs zwischen Athlet und Trainer ausschließlich im unteren Tab **„Coach“**.
- [x] **32.2 Original-Datei-Archivierung & Download:**
  - [x] Bei FIT-Upload und Garmin-Import wird die Rohdatei in Cloud Storage archiviert: `users/{uid}/rawActivities/{activityId}.{ext}` in `europe-west3`.
  - [x] Abgesichert durch Cloud Storage Rules (`storage.rules`) und Firestore Rules (`firestore.rules` für `users/{userId}/notifications/{id}`).
  - [x] Download-Button in `ActivityDetailScreen` und Trainer-Tabelle (`CoachAthletesTable`) integriert.
- [x] **32.3 Zwei globale Ansichtsmodi für den Coach:**
  - [x] Zentraler Modus-Umschalter für Trainer (`CoachGlobalModeProvider`):
    - **Modus 1 — „Einfach & Download (.FIT)“:** Schlanke Athleten-Tabelle mit Fokus auf Kernfakten und direktem .FIT-Download-Button.
    - **Modus 2 — „Analyse (Volles Cockpit)“:** Vollständiges ORBIT Cockpit mit Form-Ampel, Fitness/Ermüdung/Frische und Tiefentelemetrie.

---

## Verifikation & Nachweise
- [x] Screenshot der Glocken-Mitteilungszentrale mit Badge (`docs/beta/screenshots/phase32_notification_center.png`).
- [x] Nachweis der Originaldatei-Archivierung in Cloud Storage (`europe-west3`) und Security Rules live deployt.
- [x] Screenshot des Coach-Tabs auf dem Pixel 10 Pro (`docs/beta/screenshots/phase32_coach_tab.png`).
- [x] 100% bestandene Test-Suite (`test/features/phase32_coach_modes_notifications_test.dart` & alle 10 Functions Unit Tests).
