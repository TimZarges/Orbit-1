# PHASE 34 — Autonomer E2E-Hardware-Abnahmelauf auf dem Pixel 10 Pro & Vor-Beta-Bereitstellung

## Modus & Zielsetzung
- **Modus:** AUTONOMER HARDWARE-TEST (Google Pixel 10 Pro via USB / `adb`)
- **Ziel:** Vollständiger E2E-Abnahmelauf aller Features aus den Phasen 29 bis 33 direkt auf dem Endgerät mit offiziellem App-Icon und lückenloser Screenshot-Beweisführung gegen das Dokument `Orbit Test Bug.pdf`.
- **Status:** **[x] Abgeschlossen** (Release-Tag `v0.34.0-prebeta`)
- **Verifikationsbericht:** [`docs/beta/PRE_BETA_VERIFICATION_REPORT.md`](../beta/PRE_BETA_VERIFICATION_REPORT.md)

---

## Arbeitspakete

### 34.1 Offizielles ORBIT App-Icon
1. [x] **Adaptive Icons für Android:**
   - Erstellung und Einbindung des hochauflösenden ORBIT App-Icons (Volt `#CDFB17` auf Navy `#001F47`) als Adaptive Icon (`res/mipmap-*` mit Foreground und Background).
   - Verifikation der Icon-Darstellung auf dem Android 16 Launcher des Pixel 10 Pro.
   - Screenshot-Beweis: `docs/beta/screenshots/phase34_homescreen_orbit_icon.png`

### 34.2 Autonome E2E-Testsuite auf dem Pixel 10 Pro
1. [x] **Vollständiger Lebenszyklus & Check 1–6 gegen `Orbit Test Bug.pdf`:**
   - [x] **Check 1 (Onboarding-First & Login ohne Overflow):** Start im Onboarding-First Flow, Erfassung aller Daten inkl. Profilbild, Gboard-Tastatur auf Login ohne Pixel Overflow (`0 px Overflow`), Bug-Käfer von Sekunde 1.
   - [x] **Check 2 (Einstellungen & Echte Erfahrungsstufen):** Keine englischen Rohstrings (`system`, `advanced`), Umschalten auf *Experte* schaltet hohe Datendichte im Dashboard frei.
   - [x] **Check 3 (Leistungsdiagnostik):** Rad-Stufentest (100 W, +25 W alle 30s), 5-Minuten-All-Out-Lauftest, 400m/200m CSS-Schwimmtest.
   - [x] **Check 4 (Kalender, Monatsansicht, Workout Builder & Soll/Ist-Ampel):** Tab heißt „Kalender“, Monats-Kreise (`○`/`●`), mobiler Klick-Block Workout Builder, Stepped Block Profil & Zielwert-Umrechnung, Soll/Ist-Ampel.
   - [x] **Check 5 (Aktivitäten & Karten):** Echte Aktivitäten, Volt-GPS-Spur mit Tag/Nacht-Kartenumschaltung, Power-Duration-Kurve mit All-Time Best PR-Vergleich, PR-Filter nach Zeitraum.
   - [x] **Check 6 (Notification-Bell & Coach 2-Modus Steuerung):** Glocken-Icon mit Unread-Badge in AppBar, In-App Notification Center, Coach 2-Modus Steuerung („Einfach & Download“ vs. „Vollanalyse“), verständliche DSGVO-Texte.

### 34.3 Abschlussbericht & Beweis-Dokumentation
1. [x] Erstellung des Abschlussberichts `docs/beta/PRE_BETA_VERIFICATION_REPORT.md`.
2. [x] Gegenüberstellung jedes einzelnen Mangels aus `Orbit Test Bug.pdf` mit dem zugehörigen Beleg-Screenshot.

---

## Verifikation & Nachweise
- Komplette Screenshot-Galerie aller geforderten Zustände in `docs/beta/screenshots/phase34_*.png`.
- 0 offene Blocker, 0 Regressionsfehler.
- Pre-Merge-Gate `scripts/check_phase_ready.sh` erfolgreich durchlaufen.
