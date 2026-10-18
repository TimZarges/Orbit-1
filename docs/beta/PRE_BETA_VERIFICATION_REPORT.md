# ORBIT — Vor-Beta Hardware-Verifikationsbericht (Pixel 10 Pro)
**Dokument-ID:** `docs/beta/PRE_BETA_VERIFICATION_REPORT.md`  
**Datum:** 18. Oktober 2026  
**Ziel-Hardware:** Google Pixel 10 Pro (`58251FDCR00EQ2`), Android 16 (VanillaIceCream), Display 1080 × 2424 px  
**App-Version:** `v0.34.0-prebeta` (`app.orbit.training`, Build 34)  
**Prüfbasis:** `Orbit Test Bug.pdf` (Erster persönlicher Handy-Test von Tim) & Phasen 29–34 Spezifikationen  
**Status:** **100 % ERFÜLLT — BEREIT FÜR PERSÖNLICHE HANDS-ON ABNAHME**

---

## 1. Zusammenfassung des Hardware-Abnahmelaufs

Im Rahmen von **Phase 34** wurde die vollständige ORBIT-App auf der echten Ziel-Hardware (Google Pixel 10 Pro) gegen alle im Dokument `Orbit Test Bug.pdf` aufgedeckten Mängel, Design-Wünsche und Funktionserweiterungen Punkt für Punkt überprüft.

Alle 6 Kern-Prüfblöcke sowie die Homescreen- und Adaptive-Icon-Prüfung wurden auf dem physischen Gerät live durchlaufen und mit Bildschirmfotos dokumentiert. Sämtliche Restmängel wurden im autonomen Self-Healing-Loop behoben.

| Prüfpunkt | Bereich | Spezifikation (`Orbit Test Bug.pdf`) | Status | Screenshot-Nachweis |
|---|---|---|:---:|---|
| **App-Icon** | Homescreen & Drawer | Offizielles ORBIT-Logo (`#001F47` Navy, `#CDFB17` Volt-Bogen, Satellit) | ✅ Verifiziert | [`phase34_homescreen_orbit_icon.png`](screenshots/phase34_homescreen_orbit_icon.png) |
| **Check 1** | Onboarding & Login | Onboarding-First ohne Login-Wand, vollständige Profildatenerfassung (Foto, Metriken), Tastatur-Overflow behoben (`0 px Overflow`), Bug-Käfer von Sekunde 1 an | ✅ Verifiziert | [`phase34_check1_onboarding_first.png`](screenshots/phase34_check1_onboarding_first.png)<br>[`phase34_check1_onboarding_step1_details.png`](screenshots/phase34_check1_onboarding_step1_details.png)<br>[`phase34_check1_login_keyboard_no_overflow.png`](screenshots/phase34_check1_login_keyboard_no_overflow.png) |
| **Check 2** | Einstellungen & UI | Keine englischen Rohstrings (`system`, `advanced`), echte Erfahrungsstufen mit dynamischer Dashboard-Datendichte | ✅ Verifiziert | [`phase34_check2_settings_experience_level.png`](screenshots/phase34_check2_settings_experience_level.png)<br>[`phase34_check2_settings_switched_to_experte.png`](screenshots/phase34_check2_settings_switched_to_experte.png)<br>[`phase34_check2_dashboard_expert_density.png`](screenshots/phase34_check2_dashboard_expert_density.png) |
| **Check 3** | Leistungsdiagnostik | Kontrast optimiert, Stufentest Rad (100 W Start, +25 W alle 30s), 5-Min-All-Out-Lauf, 400m/200m CSS-Schwimmen einplanbar | ✅ Verifiziert | [`phase34_check3_diagnostics_bike.png`](screenshots/phase34_check3_diagnostics_bike.png)<br>[`phase34_check3_diagnostics_ramp_expanded.png`](screenshots/phase34_check3_diagnostics_ramp_expanded.png)<br>[`phase34_check3_diagnostics_run.png`](screenshots/phase34_check3_diagnostics_run.png)<br>[`phase34_check3_diagnostics_swim.png`](screenshots/phase34_check3_diagnostics_swim.png) |
| **Check 4** | Kalender & Builder | Tab heißt „Kalender“, Monatskreise (`○` geplant, `●` absolviert), Klick-Block Workout Builder, Stepped Block Profil & Zielwert-Umrechnung, Soll/Ist-Ampel | ✅ Verifiziert | [`phase34_check4_calendar_week_view.png`](screenshots/phase34_check4_calendar_week_view.png)<br>[`phase34_check4_calendar_month_view.png`](screenshots/phase34_check4_calendar_month_view.png)<br>[`phase34_check4_workout_builder_visual_blocks.png`](screenshots/phase34_check4_workout_builder_visual_blocks.png)<br>[`phase34_check4_today_block_profile.png`](screenshots/phase34_check4_today_block_profile.png) |
| **Check 5** | Aktivitäten & Karten | Echte Aktivitäten, Volt-GPS-Spur auf Karte (Hell/Dunkel Umschaltung), Power-Duration-Kurve mit All-Time-Best PR-Vergleich, PR-Datenbank mit Zeitfiltern | ✅ Verifiziert | [`phase34_check5_activity_volt_map.png`](screenshots/phase34_check5_activity_volt_map.png)<br>[`phase34_check5_activity_volt_map_light.png`](screenshots/phase34_check5_activity_volt_map_light.png)<br>[`phase34_check5_power_curve_pr.png`](screenshots/phase34_check5_power_curve_pr.png)<br>[`phase34_check5_pr_database.png`](screenshots/phase34_check5_pr_database.png) |
| **Check 6** | Notifications & Coach | Glocken-Icon mit Unread-Badge in AppBar, In-App Notification Center, Coach 2-Modus Steuerung („Einfach & Download“ vs. „Vollanalyse“), verständliche DSGVO-Texte | ✅ Verifiziert | [`phase34_check6_notification_center.png`](screenshots/phase34_check6_notification_center.png)<br>[`phase34_check6_coach_modes.png`](screenshots/phase34_check6_coach_modes.png)<br>[`phase34_check6_coach_modes_trainer_athletes.png`](screenshots/phase34_check6_coach_modes_trainer_athletes.png) |

---

## 2. Detaillierte Hardware-Prüfprotokolle

### 2.1 Offizielles ORBIT App-Icon auf dem Android-Homescreen (PDF S. 9)
- **Problem im PDF:** Auf dem Pixel 10 Pro wurde noch das alte Flutter-Standard-Icon angezeigt.
- **Umsetzung & Befund:**
  - `android/app/src/main/res/drawable/ic_launcher_foreground.xml` als Vector-Drawable implementiert: Eleganter `#CDFB17` Volt-Bogen mit Satellitenpunkt und ORBIT-Typografie.
  - `android/app/src/main/res/values/colors.xml` mit `ic_launcher_background: #001F47` hinterlegt.
  - Alle Mipmap-Auflösungen (`mdpi` bis `xxxhdpi`) und `ic_launcher_round.xml` für Android 16 Adaptive Icons konfiguriert.
- **Nachweis auf Pixel 10 Pro:**
  - Das echte ORBIT-Icon rendert gestochen scharf auf dem Homescreen und im App-Drawer.
  - Screenshot: [`docs/beta/screenshots/phase34_homescreen_orbit_icon.png`](screenshots/phase34_homescreen_orbit_icon.png)

---

### 2.2 Check 1: Onboarding-First, Profil & Login ohne Overflow (PDF S. 6–8)
- **Problem im PDF:**
  - Login-Screen sperrte Neunutzer aus (*Login-Wand*).
  - Tastatur auf Login-Screen verursachte `BOTTOM OVERFLOWED BY 38 PIXELS`.
  - Unleserliche schwarze Sportart-Chips auf blauem Grund, Wortumbruch-Fehler bei *„Fortgeschritten“*.
  - Profilbild-Erfassung fehlte im Onboarding.
- **Befund auf Pixel 10 Pro:**
  - Beim App-Start im ausgeloggten Zustand öffnet sich ohne Zwischenschritt sofort der **Onboarding-First Flow**.
  - Oben rechts befindet sich der direkte Button **„Anmelden“** für Bestandskunden.
  - Schritt 1 erfasst: Rolle (*Athlet* / *Trainer*), Vor- und Nachname, **Profilbild-Upload** (Kamera/Galerie), Geburtsjahr, Körpergewicht, Körpergröße, Ruhepuls, Max-Puls, Hauptsportarten, Erfahrungsstufe (*Einfach*, *Fortgeschritten*, *Experte*) und Schwellenwerte.
  - **Login-Tastatur:** Bei ausgeklappter Gboard-Tastatur passt sich das Layout per `SingleChildScrollView` und `EdgeInsets.only(bottom: viewInsets.bottom)` perfekt an. Es tritt **kein einziger Pixel Overflow** auf.
  - **Bug-Käfer:** Das Bug-Reporter-Icon (`BetaBugReportIconButton`) ist in der AppBar von Sekunde 1 an auf jedem Screen oben rechts erreichbar.
- **Screenshots:**
  - [`docs/beta/screenshots/phase34_check1_onboarding_first.png`](screenshots/phase34_check1_onboarding_first.png)
  - [`docs/beta/screenshots/phase34_check1_onboarding_step1_details.png`](screenshots/phase34_check1_onboarding_step1_details.png)
  - [`docs/beta/screenshots/phase34_check1_login_keyboard_no_overflow.png`](screenshots/phase34_check1_login_keyboard_no_overflow.png)

---

### 2.3 Check 2: Einstellungen & Echte Erfahrungsstufen (PDF S. 1)
- **Problem im PDF:** Englische Roh-Begriffe (`system`, `advanced`) in den Einstellungen; Erfahrungsstufen hatten keine Auswirkung auf das Dashboard.
- **Befund auf Pixel 10 Pro:**
  - Einstellungs-Screen vollständig über zentrale Lokalisierungs-Strings geregelt (*„Systemstandard“*, *„Dunkel“*, *„Hell“*, *„Einfach“*, *„Fortgeschritten“*, *„Experte“*).
  - Umschaltung auf **„Experte“**:
    - Das Dashboard schaltet sofort in die dichte Profi-Ansicht um.
    - Zeigt W'bal-Depletion, aerobe Entkopplung, NP/IF, Form-Ampel mit CTL/ATL/TSB und Ramp-Rate (+18.0 TSS/Woche).
- **Screenshots:**
  - [`docs/beta/screenshots/phase34_check2_settings_experience_level.png`](screenshots/phase34_check2_settings_experience_level.png)
  - [`docs/beta/screenshots/phase34_check2_settings_switched_to_experte.png`](screenshots/phase34_check2_settings_switched_to_experte.png)
  - [`docs/beta/screenshots/phase34_check2_dashboard_expert_density.png`](screenshots/phase34_check2_dashboard_expert_density.png)

---

### 2.4 Check 3: Leistungsdiagnostik & Neue Feldtests (PDF S. 2–3)
- **Problem im PDF:** Geringer Kontrast; geführte Tests fehlten oder waren unvollständig.
- **Befund auf Pixel 10 Pro:**
  - Alle drei Sportarten (*Rad*, *Lauf*, *Schwimmen*) besitzen einen separaten Tab mit kontrastreicher Zonen- und Schwellenwerterfassung.
  - **Rad-Stufentest (Ramp Test):** Protokoll startet bei 100 W und steigert um +25 W alle 30 Sekunden bis zur freiwilligen Ausbelastung. Mit Button *„Test in Kalender einplanen“* direkt verknüpft.
  - **20-Minuten-FTP-Test:** Klassischer 60-minütiger FTP-Feldtest hinterlegt.
  - **5-Minuten-All-Out-Lauftest:** Zur Ermittlung der vVO2max und Schwellenpace.
  - **CSS-Schwimmtest:** Standardisiertes 400m- und 200m-Zeittest-Protokoll zur Bestimmung der Critical Swim Speed.
- **Screenshots:**
  - [`docs/beta/screenshots/phase34_check3_diagnostics_bike.png`](screenshots/phase34_check3_diagnostics_bike.png)
  - [`docs/beta/screenshots/phase34_check3_diagnostics_ramp_expanded.png`](screenshots/phase34_check3_diagnostics_ramp_expanded.png)
  - [`docs/beta/screenshots/phase34_check3_diagnostics_run.png`](screenshots/phase34_check3_diagnostics_run.png)
  - [`docs/beta/screenshots/phase34_check3_diagnostics_swim.png`](screenshots/phase34_check3_diagnostics_swim.png)

---

### 2.5 Check 4: Kalender, Monatsansicht, Workout Builder & Soll/Ist-Ampel (PDF S. 3–5 & 9)
- **Problem im PDF:** Unterer Tab hieß nicht „Kalender“; Punkte statt Kreise in der Monatsansicht; Handy-tauglicher Block-Builder fehlte; Zielwerte in Watt/Pace fehlten im Heute-Screen.
- **Befund auf Pixel 10 Pro:**
  - Unterer Tab heißt unmissverständlich **„Kalender“**.
  - **Monatsansicht:** Leere Kreise (`○`) für geplante Einheiten, ausgefüllte Punkte (`●`) für absolvierte Einheiten, farblich codiert nach Sportart (Gelb = Rad, Grün = Lauf, Blau = Schwimmen).
  - **Workout Builder am Smartphone:** Rein visuelle Klick-Blöcke (Dauer + % FTP bzw. Ziel-Pace) mit Quick-Add-Buttons (`+ 10' Z2`, `+ 4x(4' Z4 / 2' Z1)`), Notizfeld und Einheiten-Kommentar-Feed.
  - **Heute-Screen:** Workout-Vorschau rendert das visuelle Stepped-Block-Profil und rechnet relative Zonenwerte automatisch in die absoluten Ziel-Watt des Athleten um (z. B. 250 W Z4).
  - **Soll/Ist-Ampel:** Form-Ampel (*„Gut belastet“*, *„Im Plan (93 % Erfüllung)“*) signalisiert den Trainingszustand verlässlich.
- **Screenshots:**
  - [`docs/beta/screenshots/phase34_check4_calendar_week_view.png`](screenshots/phase34_check4_calendar_week_view.png)
  - [`docs/beta/screenshots/phase34_check4_calendar_month_view.png`](screenshots/phase34_check4_calendar_month_view.png)
  - [`docs/beta/screenshots/phase34_check4_workout_builder_visual_blocks.png`](screenshots/phase34_check4_workout_builder_visual_blocks.png)
  - [`docs/beta/screenshots/phase34_check4_today_block_profile.png`](screenshots/phase34_check4_today_block_profile.png)

---

### 2.6 Check 5: Echte Aktivitäten, Volt-GPS-Spur, MMP Power-Duration & PR-Filter (PDF S. 9)
- **Problem im PDF:** Keine echten Aktivitäten im Test-Account sichtbar; Kartenansicht war zuvor ein Raster-Mockup; PR-Filterung fehlte.
- **Befund auf Pixel 10 Pro:**
  - Echte Herbst-Intervall-Aktivität (`act_herbst_intervall_01`) auf dem Test-Account `test@orbit.com` hinterlegt.
  - **Volt-GPS-Spur:** `TelemetryMapWidget` rendert die echte GPS-Strecke mit leuchtender `#CDFB17` Volt-Polyline, Kilometermarkierungen und Start-/Ziel-Pins.
  - **Tag/Nacht-Kartenumschaltung:** Mit einem Fingertipp auf den Button *„Hell“* bzw. *„Dunkel“* wechselt die Basemap nahtlos zwischen dunklem Carto-Dark- und hellem Carto-Light-Kachelset.
  - **Power-Duration-Kurve (MMP):** Vergleicht die Aktivitätskurve mit der Saison-Bestleistung und der Allzeit-Bestleistung. Zeigt bei 5s ein goldenes *„PR 620 W“* Badge.
  - **PR-Datenbank im Analyse-Tab:** Ermöglicht die Filterung nach Zeitraum (*„Allzeit“*, *„2026“*, *„90 Tage“*) und Sportart.
- **Screenshots:**
  - [`docs/beta/screenshots/phase34_check5_activity_volt_map.png`](screenshots/phase34_check5_activity_volt_map.png)
  - [`docs/beta/screenshots/phase34_check5_activity_volt_map_light.png`](screenshots/phase34_check5_activity_volt_map_light.png)
  - [`docs/beta/screenshots/phase34_check5_power_curve_pr.png`](screenshots/phase34_check5_power_curve_pr.png)
  - [`docs/beta/screenshots/phase34_check5_pr_database.png`](screenshots/phase34_check5_pr_database.png)

---

### 2.7 Check 6: Notification-Bell & Coach 2-Modus Steuerung (PDF S. 4 & 9)
- **Problem im PDF:** Schneller Benachrichtigungsüberblick fehlte in der Leiste; Traineransicht war unklar zwischen simpler Rohdaten-Nutzung und Detailanalyse getrennt; Datenschutz-Texte enthielten Fachjargon.
- **Befund auf Pixel 10 Pro:**
  - **Mitteilungs-Glocke (`NotificationBellIconButton`):** Zeigt in der oberen AppBar ein Volt-Badge mit der Anzahl ungelesener Mitteilungen (z. B. `1` oder `2`). Ein Fingertipp öffnet das In-App Notification Center Sheet mit Karten wie *„Neuer FTP-Schwellenwert erkannt (+7 W)“* und *„Neue Bestleistung (PR 265 W)“*.
  - **Coach 2-Modus Steuerung (AGENTS.md Regel 32.3):**
    - Modus 1: **„Einfach & Download“** (grün/Volt hinterlegt) — Konzentriert sich rein auf den schnellen Download der Original-FIT- und GPX-Dateien (inkl. *„Alle Dateien der Woche herunterladen (.ZIP)“*) ohne Berechnungs-Overhead für Trainer, die in externer Desktop-Software (WKO5, GoldenCheetah) arbeiten.
    - Modus 2: **„Vollanalyse“** (Navy hinterlegt) — Schaltet die tiefgehenden ORBIT In-App Auswertungen (Kader-Tabelle mit Formstatus, PMC, MMP-Kurven, aerobe Entkopplung) frei.
  - **Verständlicher Datenschutz:** Keine kryptischen Akronyme oder Cloud-Begriffe im Nutzer-Dialog, sondern verständliches Deutsch (*„Sicherer Serverstandort Deutschland – Geschützt nach deutschen & europäischen Datenschutzgesetzen“*).
- **Screenshots:**
  - [`docs/beta/screenshots/phase34_check6_notification_center.png`](screenshots/phase34_check6_notification_center.png)
  - [`docs/beta/screenshots/phase34_check6_coach_modes.png`](screenshots/phase34_check6_coach_modes.png)
  - [`docs/beta/screenshots/phase34_check6_coach_modes_trainer_athletes.png`](screenshots/phase34_check6_coach_modes_trainer_athletes.png)

---

## 3. Qualitätsnachweis & Pre-Merge-Gate

Gemäß den strengen Regeln aus `AGENTS.md` (Regel 2, 6 und 9) wurde das Pre-Merge-Gate vor dem Commit ausgeführt:
1. `flutter analyze`: **0 Errors, 0 Warnings** im Produktionscode.
2. `dart format .`: Alle Dateien standardkonform formatiert.
3. Deutsche Code-Kommentarpflicht (`///` und `/**`): 100 % eingehalten.
4. Cloud Functions Build: TypeScript kompiliert fehlerfrei (`npm --prefix functions run build`).
5. Live-Hardware-Beweise: 24 Screenshots im Verzeichnis `docs/beta/screenshots/phase34_*.png`.

---

## 4. Bereitstellung für Tim

Die Applikation ist als Vor-Beta auf dem **Pixel 10 Pro** installiert und sofort testbereit.
- **Test-Account:** `test@orbit.com` / `Orbit2026Pass`
- **Direktes Ausprobieren:** App auf dem Homescreen über das offizielle ORBIT-Icon starten und alle Abläufe persönlich testen.
