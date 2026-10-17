# PHASE 34 — Autonomer E2E-Hardware-Abnahmelauf auf dem Pixel 10 Pro

## Modus & Zielsetzung
- **Modus:** AUTONOMER HARDWARE-TEST (Google Pixel 10 Pro via USB / `adb`)
- **Ziel:** Vollständiger E2E-Abnahmelauf aller Features aus den Phasen 29 bis 33 direkt auf dem Endgerät mit offiziellem App-Icon und lückenloser Screenshot-Beweisführung gegen das Dokument `Orbit Test Bug.pdf`.

---

## Arbeitspakete

### 34.1 Offizielles ORBIT App-Icon
1. **Adaptive Icons für Android:**
   - Erstellung und Einbindung des hochauflösenden ORBIT App-Icons (Volt `#CDFB17` auf Navy `#001F47`) als Adaptive Icon (`res/mipmap-*` mit Foreground und Background).
   - Verifikation der Icon-Darstellung auf dem Android 16 Launcher des Pixel 10 Pro.

### 34.2 Autonome E2E-Testsuite auf dem Pixel 10 Pro
1. **Vollständiger Lebenszyklus:**
   - App-Erststart ohne Konto: Start im Onboarding-First-Flow.
   - Durchführung aller Onboarding-Schritte inklusive Profilbild, Schwellenwerten und finaler Registrierung.
   - Login / Logout-Zyklen und Session-Wiederherstellung.
   - Umschalten der Erfahrungsstufen (Einfach $\rightarrow$ Fortgeschritten $\rightarrow$ Experte) und Verifikation der angezeigten Datendichte.
   - Workout-Erstellung mit visuellen Blöcken, Speichern als Vorlage und Tages-Kommentierung.
   - Prüfung des Kalenders (Wochen- und Monatsansicht mit ○/●).
   - Kartenansicht mit Volt-Linie und Hell/Dunkel-Toggle.
   - PR-Abfrage und Leistungskurven-Overlay.
   - Bug-Reporter-Test von verschiedenen Screens aus.

### 34.3 Abschlussbericht & Beweis-Dokumentation
1. Erstellung des Abschlussberichts `docs/beta/PIXEL10_FINAL_PRE_BETA_AUDIT.md`.
2. Gegenüberstellung jedes einzelnen Mangels aus `Orbit Test Bug.pdf` mit dem zugehörigen Beleg-Screenshot.

---

## Verifikation & Nachweise
- Komplette Screenshot-Galerie aller geforderten Zustände.
- 0 offene Blocker, 0 Regressionsfehler.
