# PHASE 22 — 10x Brand-Exploration, Werbe-Landingpage, Pflichtseiten & Web-Coach-Plattform

## Modus & Leitplanken
- **Modus:** STANDARDMODUS mit STOPP nach der Design-Auswahl und am Phasenende (RISIKO: MITTEL).
- **Wichtig:** Es gibt kein externes Figma und keine Designerin. Wir entwickeln das visuelle Erscheinungsbild direkt als klickbare HTML/CSS/SVG-Prototypen im Repo.

## Ausgangslage (aus BASELINE.md)
`web/delete-account.html` wird aktuell nicht ausgeliefert, weil `firebase.json:8` nur `public/` hostet. Außerdem fehlt eine überzeugende Marketing-Landingpage, die ORBIT erklärt, Funktionen präsentiert und Beta-Tester einsammelt.

## Arbeitspakete

### 22.1 Schritt 1: 10 interaktive Logo-, Wortmarken- & Design-Konzepte (`web/brand-showcase.html`)
Erstelle zuerst eine eigenständige Vorschau-Seite `public/brand-showcase.html`, die **10 unterschiedliche, hochprofessionelle Design- und Logo-Richtungen** für **ORBIT** (inspiriert von MATS, Whoop und High-End-Radsportmarken auf Basis von `#001F47` Navy & Inter Black) nebeneinander zeigt. Jede der 10 Varianten muss enthalten:
- **SVG-Wortmarke „ORBIT“** + eigenständiges **App-Icon (512×512)** + **Monochromes Android-Push-Notification-Icon (24×24)**.
- Eine Mini-Vorschau einer Hero-Section + einer App-Statistik-Karte im jeweiligen Stil (z. B. *1. Precision Telemetry*, *2. Orbital Rings*, *3. Swiss Aero Grid*, *4. Dark Cockpit Neon*, *5. Minimalist Endurance*, *6. Kinetic Typography*, *7. Chrono Lap*, *8. Deep Navy Glass*, *9. Tri-Sector Pulse*, *10. Pure Performance*).
- **STOPP 1:** Halte hier an, damit ich mir die 10 Designs im Browser anschauen und meinen Favoriten auswählen kann!

### 22.2 Schritt 2: Ausgewähltes Design als App-Icon, Splash & Push-Logo ausrollen
Sobald ich eines der 10 Designs ausgewählt habe:
1. Generiere daraus das finale App-Icon für Android (Adaptive Icon Foreground/Background), Favicon, Web-Manifest-Icons und das monochrome Android-Statusbar-Push-Icon (`android/app/src/main/res/drawable/ic_stat_orbit.xml`).

### 22.3 Schritt 3: Verkaufsstarke Landingpage, Hilfe/Metrik-Lexikon & Rechtliche Pflichtseiten
1. **Firebase Hosting Architektur korrigieren (`firebase.json`):**
   - Konfiguriere das Hosting sauber so, dass unter der Haupt-URL die schnelle, SEO-optimierte statische Website (Marketing, Hilfe, Rechtliches) ausgeliefert wird und unter `/app` (bzw. Subdomain-Vorbereitung `app.<domain>`) die Flutter-Web-App (Coach- & Athleten-Web-Login) erreichbar ist.
   - Stelle sicher, dass `/delete-account` (`delete-account.html`), `/privacy` (Datenschutzerklärung inkl. Garmin, Firebase, Art. 9 DSGVO) und `/imprint` (Impressum) ohne Login direkt per Direktlink erreichbar sind (Google Play Pflicht!).
   - **Keine externen Werbe-Tracker oder Cookies** auf der Website einbinden!
2. **Marketing-Landingpage (`public/index.html`, DE & EN umschaltbar):**
   - Hero-Sektion mit starkem Claim, interaktiver Vorschau der 3 Ringe, des PMC-Charts und des Trainer-Dashboards.
   - Feature-Sektionen: *1. Profi-Telemetrie (CP, W′bal, Aero)*, *2. Ganzheitliche Erholung & Schlaf*, *3. Nahtlose Verbindung zwischen Athlet & Vereinstrainer*, *4. Kompatibel mit Garmin, Wahoo & SRM*.
   - **Beta-Anmeldeformular:** Speichert Interessenten (Name, E-Mail, Rolle Athlet/Coach, genutztes Gerät) mit Double-Opt-In/Datenschutz-Haken direkt über eine geschützte Cloud Function in `beta_waitlist`.
   - Direkter **„Web-Login (Coach & Athlet)“**-Button oben rechts, der die Flutter-Web-App startet.
3. **Hilfe-Center & Kennzahlen-Lexikon (`public/help.html`):**
   - Leicht verständliche Erklärungen (mit Grafiken/Formel-Boxen) für alle ORBIT-Metriken: Was bedeuten CTL, ATL, TSB, Critical Power, W′bal, EF, Entkopplung, SWOLF, ORBIT Erholungs-Score und Schlafschuld? (Diese Seite verlinken wir auch direkt aus den Info-Icons in der App!).

## STOPP-Punkte & Abnahmekriterien
- **STOPP 1:** Auswahl eines der 10 Designs aus `public/brand-showcase.html`.
- **STOPP 2 (Phasenabschluss):** Lokaler Hosting-Test (`firebase emulators:start --only hosting`) zeigt Landingpage, `/help`, `/privacy`, `/imprint`, `/delete-account` und den Web-App-Login unter `/app` fehlerfrei auf Mobile- und Desktop-Viewports.
- Nach meiner Freigabe: Commit & Push auf GitHub mit Tag `v0.22.0`.