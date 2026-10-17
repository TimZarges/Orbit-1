# PHASE 25 — Autonomer Live-Hardware-Testlauf & E2E-Audit auf dem Google Pixel 10 Pro

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH — Live-Hardware-Test auf Google Pixel 10 Pro gegen das Produktiv-Backend in Frankfurt `europe-west3`).
- **Pflicht (Regel 1 & 2):** Sämtliche Prüfungen werden direkt auf dem per USB verbundenen Pixel 10 Pro autonom ausgeführt. Zu jedem Screen wird ein echter Screenshot per ADB (`adb exec-out screencap -p`) unter `docs/beta/screenshots/` erfasst. Alle Fehler (insb. Garmin OAuth, Cloud Functions Regionen, App Check) werden mit echtem Terminal-, Logcat- und Cloud-Function-Log-Beleg in `docs/beta/PIXEL10_LIVE_AUDIT.md` dokumentiert.

---

## Arbeitspakete

### 25.1 Geräte-Inspektion & Logcat-Harness
1. Verbindung und Bereitschaft des Google Pixel 10 Pro per `adb devices -l` verifizieren.
2. Logcat leeren (`adb logcat -c`) und Filter auf `app.orbit.training`, `flutter`, `FirebaseApp` und Fehlerkanäle vorbereiten.
3. Sicheres Log-Handling: Niemals Passwörter, Authentifizierungs-Tokens oder OAuth-Secrets im Klartext loggen.

### 25.2 Vollautomatischer Live-E2E-Audit auf dem Pixel 10 Pro
1. **Auth & Onboarding:**
   - Registrierung / Login gegen Firebase Auth Live-System.
   - 4-Schritte-Onboarding-Wizard (Rolle, Schwellenwerte, Datenquellen, Trainer-Code/Art.-9-DSGVO-Zustimmung) durchlaufen.
   - Prüfung des `setInitialRole` Callable-Aufrufs und Anlegen des ersten Eintrags in `thresholdHistory`.
2. **Garmin Connect Live-Verbindungsanalyse:**
   - Klick auf „Garmin verbinden“ im Onboarding bzw. in den Einstellungen.
   - Aufruf von `garminAuthStart` analysieren (Prüfung auf Region `europe-west3` vs. Fallback `us-central1`).
   - Prüfung von Android 11–16 `<queries>` in `AndroidManifest.xml` für `https://` und `url_launcher`.
   - OAuth-Callback-URL (`garminAuthCallback`) und Secret-Manager-Bereitstellung (`GARMIN_CONSUMER_KEY`, `GARMIN_CONSUMER_SECRET`) in Cloud Functions Logs prüfen.
3. **Heute-Tab & Drei-Ringe-Hero-Card:**
   - Visuelle Prüfung der 3 konzentrischen Ringe (Erholung, Tagesbelastung, Schlaf) vor edlem `#001F47` Navy-Hintergrund mit `#CDFB17` Volt-Leitring.
   - A/B/C-Wettkampf-Countdown-Badge und Ziel-Dialog verifizieren.
4. **Manueller Datei-Upload (.fit / .tcx / .gpx):**
   - Datei-Upload über Storage-Bucket `orbit-app-mvp.firebasestorage.app` testen.
   - Cloud Functions Backend-Verarbeitung (`processActivityUpload` / `onActivityWritten`) überwachen.
5. **Aktivitäts-Cockpit & Telemetrie:**
   - Multi-Graphen (Watt `#F6C453`, Skiba $W'\text{bal}$ `#F43F5E`, HF, Pace, Kadenz, Höhe).
   - LTTB-Touch-Scrubbing auf dem 120-Hz-OLED des Pixel 10 Pro prüfen (flüssiges Verhalten ohne Ruckler).
   - `flutter_map` GPS-Track-Anzeige mit DSGVO-Opt-in und Zonen-Farbcodierung.
   - Intervall-Tabelle (Runden vs. Auto-Intervalle) & Aerobic Decoupling Badge.
6. **Analyse-Tab & Health-Cockpit (`/health`):**
   - Banister PMC (CTL Cyan, ATL Amber, TSB Emerald) mit 14-Tage-Projektion & Rennflaggen.
   - Power-Duration-Kurve (MMP mit $CP$ und $W'$).
   - Schnellzugriff `/health`: 30-Tage-Normbänder ($\mu \pm 1\sigma$), 15-Sekunden-Kurz-Journal-Chips und neutrale Berichtstexte.
7. **Trainer-Kopplung & Beta-Bug-Reporter:**
   - `AthleteCoachTabScreen`: 6-stelligen Trainer-Code einlösen, Art.-9-DSGVO-Berechtigungsschalter testen.
   - `BetaBugReporterSheet` öffnen, Screenshot-Vorschau prüfen und Diagnose-Metadaten verifizieren.

### 25.3 Screenshot-Galerie & Audit-Bericht (`docs/beta/PIXEL10_LIVE_AUDIT.md`)
1. Automatische Speicherung aller Screens in `docs/beta/screenshots/` (z. B. `01_login.png`, `02_onboarding.png`, `03_today_rings.png`, `04_activity_cockpit.png`, `05_health_cockpit.png` etc.).
2. Erstellung des detaillierten Prüfberichts `docs/beta/PIXEL10_LIVE_AUDIT.md` mit:
   - Übersicht aller getesteten Bereiche (`✅` Funktionsfähig / `❌` Fehlerhaft).
   - Exakte Ursachenanalyse für jeden Fehler mit Terminal-, Logcat- und Cloud-Function-Log-Belegen sowie `Datei:Zeile`.
   - Konkrete Aufgabenpakete für die Behebung in Phase 26, 27 und 28.

---

## STOPP-Punkt 1 (Abnahme Phase 25)
- Vorlage von `docs/beta/PIXEL10_LIVE_AUDIT.md`, der Screenshot-Galerie und des Eintrags in `docs/CHECKPOINTS.md`.
- Warten auf Tims Freigabe zur Umsetzung der identifizierten Reparaturen in Phase 26.
