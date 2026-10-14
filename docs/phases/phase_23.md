# PHASE 23 — Push-Notifications mit ORBIT-Logo, Wettkampf-Ziele, App Check & Beta-Infrastruktur

## Modus & Leitplanken
- **Modus:** STANDARDMODUS mit STOPP am Phasenende (RISIKO: MITTEL).

## Arbeitspakete

### 23.1 Geplante & Event-basierte Push-Benachrichtigungen mit ORBIT-Logo
1. Konfiguriere `firebase_messaging` und `flutter_local_notifications` auf Android so, dass jede Push-Nachricht das in Phase 22 gewählte **ORBIT-Notification-Icon (`ic_stat_orbit`)** und die Markenfarbe `#001F47` als Akzentfarbe nutzt (plus optionales Large-Icon).
2. Implementiere in `functions/src/notifications/` folgende Trigger (jeweils in den Nutzereinstellungen einzeln an-/abschaltbar):
   - **Aktivitäts-Analyse fertig:** Sobald eine Garmin- oder Upload-Einheit verarbeitet wurde (*„Dein Radtraining (84 TSS) ist analysiert. Neue 5-Minuten-Bestleistung: 365 W!“*).
   - **Neues Workout / Plan-Update vom Trainer:** Push an den Athleten, wenn der Coach eine Einheit plant oder kommentiert.
   - **Morgendliches Recovery- & Trainings-Briefing (Scheduled Function, 07:30 Uhr lokal):** Kurze Übersicht zu Erholungs-Score und heutigem geplanten Training.
   - **Wöchentlicher Sonntags-Report (Sonntag, 19:00 Uhr):** Zusammenfassung der Trainingswoche.
   - **Schwellenwert-Vorschlag:** Wenn aus der MMP-Kurve eine signifikante Steigerung von FTP, CP oder Schwellen-Pace erkannt wird (*„Neue FTP erkannt: 285 W (+8 W). Jetzt in deinem Profil übernehmen?“*).

### 23.2 Wettkampf-Planung & Saison-Ziele (A-, B-, C-Rennen)
Da die Vereinsathleten auf konkrete Wettkämpfe hintrainieren (Antwort 20):
1. Erweitere das Datenmodell um `races/{raceId}` (Titel, Datum, Sportart/Distanz, Priorität **A-Hauptwettkampf / B-Vorbereitung / C-Trainingswettkampf**, Zielzeit/Ziel-Watt, Notizen).
2. **UI-Integration:**
   - Countdown-Karte für das nächste **A-Rennen** auf dem „Heute“-Screen und im Trainer-Dashboard.
   - Vertikale **Wettkampf-Flaggen direkt im PMC-Chart (Fitness/Form)**, damit Athlet und Trainer sofort sehen, wie der Taper (TSB im Zielbereich +10 bis +25) zum Wettkampftag verläuft.

### 23.3 Beta-Infrastruktur (Crashlytics Opt-in, Force-Update, Feature-Flags & App Check)
1. **Remote Config / Firestore `app_config/version_gate`:**
   - Zeige die exakte Build-Version im Profil-Footer an.
   - Baue einen `MinVersionGuard`: Wenn wir während der Beta einen kritischen Bugfix ausrollen, können wir `minRequiredBuild` hochsetzen und alle Tester erhalten beim Start einen sauberen Dialog *„Neues Beta-Update verfügbar – Bitte aktualisieren“*.
   - **Feature-Flags:** Steuerbare Flags für experimentelle Features ohne erneutes App-Update.
2. **Firebase Crashlytics (streng mit DSGVO-Opt-in):**
   - Crashlytics ist standardmäßig deaktiviert (`setCrashlyticsCollectionEnabled(false)`) und wird erst aktiviert, wenn der Tester im Onboarding oder in den Einstellungen den Schalter *„Absturzberichte zur Verbesserung der Beta teilen“* aktiviert.
3. **Firebase App Check:**
   - Aktiviere Play Integrity (Android) und reCAPTCHA Enterprise (Web) inklusive Debug-Token-Support für das lokale Testen auf dem Pixel 10 Pro.

## STOPP-Punkt & Abnahmekriterien
- **STOPP:** Nachweis der Push-Trigger im Emulator-Test, Screenshot der Wettkampf-Flaggen im PMC-Chart und Verifikation des Force-Update-Screens.
- Nach meiner Freigabe: Commit & Push auf GitHub mit Tag `v0.23.0`.