# ORBIT — Verbindliche Projekt-Roadmap (V1.0.0 bis V4.0.0) & Phasenplan (Phase 40 bis Phase 46)

**Status:** Verbindlich beschlossen (Phase 40)  
**Plattform:** ORBIT (`app.orbit.training`) — High-End Performance-, Telemetrie- & Health-Plattform für Ausdauersportler (Rad, Lauf, Schwimmen, Triathlon) und deren Trainer.  
**Architektur-Grundsatz:** 100 % DSGVO-konform (`europe-west3` Frankfurt), 120-Hz-optimiertes Flutter UI (`const`, `RepaintBoundary`, `ListView.builder`, granulare Riverpod-Selektoren) und lückenlose deutsche Code-Kommentierung (`AGENTS.md` Regel 6, 9 & 10).

---

## 1. Versions-Matrix: V1.0.0 bis V4.0.0

Die Weiterentwicklung von ORBIT folgt einer klaren, gestuften Produkt-Architektur von einem fokussierten, blitzschnellen **V1.0.0 Core-Release** (Fokus: Datei-Hub, Kalender, Garmin-Sync, Athlet-Coach-Brücke & `.FIT`-Download) bis hin zur vollwertigen Wissenschafts-, Coaching- und KI-Plattform (**V2.0.0 bis V4.0.0**).

### 1.1 Gesamtübersicht nach Funktionsbereichen

| Bereich / Dimension | **V1.0.0 (Core Launch / Datei- & Kalender-Hub)** | **V2.0.0 (Profi-Coaching, Workout-Builder & Analyse Einfach)** | **V3.0.0 (Wissenschaftliches Telemetrie- & Health-Cockpit)** | **V3.1.0 / V4.0.0 (Team-Ökosystem, Drittanbieter & KI-Co-Coach)** |
| :--- | :--- | :--- | :--- | :--- |
| **Allgemein & System** | • Login-First & E-Mail-Verifikation<br>• Onboarding & Profil **Einfach** (Athlet & Coach)<br>• Hell-/Dunkel-Modus (`#F8FAFC` / `#001F47`)<br>• Sprachen: **DE & EN**<br>• Datumsformat `dd.mm.yy` & **24h-Zeitformat** nach Wohnland<br>• Volle DE/EU-Rechtskonformität (DSGVO Art. 9, 13/14, 17 & DDG § 5) | • Erfahrungsstufen (*Einfach*, *Fortgeschritten*)<br>• In-App Notification Center (Header-Glocke) & Push-Mitteilungen<br>• Athleten-Verfügbarkeitsprofil (Wochentage & Zeitfenster nach MATS-Vorbild)<br>• Mehrsprachiger Ausbau | • Erfahrungsstufe *Experte* (volle wissenschaftliche Tiefe)<br>• Web-Desktop-Plattform (3-Spalten-Analyse nach TrainingPeaks-Vorbild)<br>• Offline-Caching für Telemetrie-Streams | • **V3.1.0:** Erweiterte Hardware-Ökosysteme (Wahoo Cloud, Polar, Coros, Zwift, Apple Health, Android Health Connect)<br>• **V4.0.0:** ORBIT AI Co-Coach (automatische Trainingsplan-Adaption & Belastungsprognose) |
| **Athleten-Funktionen** | • **Heute-Ansicht:** Zeigt ausschließlich **absolviertes Training** + Schnellzugriff auf **Garmin Sync** & **Datei-Upload** (`.fit`, `.tcx`, `.gpx`)<br>• **Trainings-Vorschaukarte (COROS-Stil):** Nicht klickbar in V1.0.0, rechts direkter **`.FIT`-Download-Button** statt GPX-Grafik<br>• **Kalender:** Absolviertes Training in **Woche, Monat und Liste**<br>• Sportarten inkl. **Triathlon** | • **Heute-Ansicht:** Geplante Einheiten + Soll/Ist-Erfüllungs-Ampel (🟢/🟡/🔴) + 7-Tage-Wochen-Strip<br>• **2D Post-Workout-Puck** (Wohlbefinden vs. Intensität nach MATS-Vorbild)<br>• **Klickbare Trainingskarten** → Basis-Aktivitätsdetail<br>• Wettkampf-Kalender (A/B/C-Rennen) | • **High-End Aktivitäts-Cockpit:** 1Hz Multi-Stream-Graph (Watt, HF, Pace, Cadenz), LTTB-Scrubber, GPS-Karte mit Metrik-Gradienten (Volt, HF, Pace)<br>• **Wissenschaftliche Metriken:** NP/Iso-Power, IF, ORBIT Load, VI, EF, Aerobic Decoupling (`Pw:Hr`), Skiba $W'\text{bal}$, MMP Power-Duration-Kurve & PR-Medaillen<br>• **Health & Recovery Cockpit:** 3 Ringe, 30d-Baselines ($\mu \pm 1\sigma$), Schlafphasen & 45s Morgen-Check-in | • **Vereins- & Team-Funktionen:** Trainingsgruppen, gemeinsame Trainingslager, Vereins-Leaderboards<br>• **Equipment- & Verschleiß-Tracking** (Räder, Laufschuhe, Komponenten)<br>• Strukturierter Workout-Export direkt auf Garmin-/Wahoo-Radcomputer |
| **Coach-Funktionen** | • **Verbindung mit Athleten** (6-stelliger Einladungscode & granulare DSGVO-Freigaben)<br>• **Eigene Coach-Navigation:** Bottom-Bar mit 3 Tabs (*Athleten*, *Kalender*, *Profil/Einstellungen*)<br>• **Direkter `.FIT`-Originaldatei-Download** für jedes absolvierte Training (für WKO5 / GoldenCheetah) | • **Visueller Block-Workout-Builder** (Warm-up, Intervalle 2x–30x, Cool-down, `#lit`/`#mit`/`#hit` Tags & Ernährungs-Notiz)<br>• Trainings-Vorlagenbibliothek<br>• Echtzeit-Chat & Kommentar-Stream direkt an der Einheit | • **Zwei globale Coach-Modi:** *Modus 1 (Einfach & `.FIT`-Download)* vs. *Modus 2 (Vollanalyse mit Banister PMC CTL/ATL/TSB, Ramp-Raten & Erholungs-Ampel)*<br>• Geführte Leistungsdiagnostik (Rad-Stufentest, 5-Min-Lauftest, CSS-Schwimmtest) mit automatischen Schwellenwert-Vorschlägen | • **Multi-Coach / Vereins-Lizenzverwaltung**<br>• KI-gestützte Anomalie-Erkennung für Trainer (Frühwarnung bei Übertraining / Infekt-Anzeichen im Kader)<br>• Saison-Makrozyklus-Planer (ATP – Annual Training Plan) |
| **Design von Key-Features** | • **COROS-inspirierte Aktivitätskarte:** Links Sportart-Icon + Titel + Datum (`dd.mm.yy • HH:mm`), Mitte 3 prägnante Kernwerte (Dauer, Distanz, Ø Watt/Pace oder HF), **rechts direkter `.FIT`-Download-Icon-Button** (kein GPX-Minigraph, kein Detail-Drilldown)<br>• **Clean Navy/Alabaster Look:** Fokus auf maximale Übersichtlichkeit ohne visuelle Überfrachtung | • **MATS-inspirierter 2D Feedback-Quadrant** (interaktiver Koordinaten-Puck)<br>• **Gestufte Block-Vorschau** (farbcodierte Leistungsblöcke direkt in der Kalender- und Heute-Karte)<br>• **Verfügbarkeits-Hinterlegung** im Kalender | • **Orbital 3-Ringe Hero-Card** (`#001F47` Navy + `#CDFB17` Volt Leitring)<br>• **TrainingPeaks-inspirierte PMC- & Fitness-Rampen-Karten** (7d, 28d, 90d, 365d)<br>• **Polarisierte 3-Zonen-Ampel** (`LIT / MIT / HIT`) neben 7-Zonen Coggan/Friel | • **Interaktives 3D/Heat-Map Strecken-Rendering**<br>• **Konversationelles AI-Briefing-UI** im Morgen-Dashboard |

---

## 2. Verbindliche Detail-Entscheidungen für V1.0.0

Für das erste produktive Haupt-Release (**V1.0.0**) gelten strikt folgende sechs Produkt- und Architekturentscheidungen. Alle darüber hinausgehenden Analyse-, Planungs- und Cockpit-Ansichten bleiben im Code modular gekapselt und werden erst in V2.0.0 bzw. V3.0.0 im UI freigeschaltet:

### 2.1 Trainings-Vorschaukarte (COROS-Stil)
1. **Nicht klickbar in V1.0.0:** Ein Tippen auf die Trainings-Vorschaukarte öffnet in V1.0.0 **kein** untergeordnetes Aktivitäts-Cockpit (`onTap: null` bzw. deaktivierter Drilldown in V1.0.0).
2. **Kein Mini-GPX-Track:** Auf der rechten Kartenseite wird **keine** GPX-Strecken-Silhouette gerendert.
3. **Direkter `.FIT`-Download-Button rechts:** Stattdessen befindet sich auf der rechten Seite der Karte ein klar erkennbarer, direkt bedienbarer **`.FIT`-Download-Button** (48×48 dp Touch-Target), über den sowohl der Athlet als auch der verknüpfte Coach die originale Binärdatei (`users/{uid}/rawActivities/{id}.fit`) sofort herunterladen bzw. teilen kann.
4. **Karten-Metriken im COROS-Stil:** Kompakte, hochkontrastreiche Darstellung mit Sportart-Icon (inkl. `TriathlonCombinedIcon`), Aktivitätstitel, lokalisiertem Zeitstempel (`dd.mm.yy • HH:mm`) sowie Dauer, Distanz und primärer Leistungs-/Pace-/HF-Kennzahl.

### 2.2 Heute-Ansicht in V1.0.0
1. **Fokus auf absolviertes Training:** Die Heute-Ansicht (`TodayTabScreen`) zeigt in V1.0.0 **ausschließlich absolviertes Training** (heutige und zuletzt absolvierte Einheiten als COROS-Vorschaukarten mit `.FIT`-Download).
2. **Schnellzugriff Daten-Import:** Oben bzw. prominent erreichbar befinden sich die beiden primären Datenquellen für V1.0.0:
   - **Garmin Sync Button** (direkter REST-Pull `syncGarminActivitiesNow` + Statusanzeige der Garmin-Verknüpfung).
   - **Datei-Upload Button** (direkter `.fit` / `.tcx` / `.gpx` Upload über Android 16 SAF / FilePicker).
3. **Ausblendung von V2/V3-Elementen in V1.0.0:** 3-Ringe-Health-Hero, geplante Soll-Workouts, Erfüllungs-Ampel und Wettkampf-Countdowns werden in V1.0.0 auf der Heute-Ansicht nicht eingeblendet (sauberes Feature-Gating für V2.0.0/V3.0.0).

### 2.3 Kalender in V1.0.0
1. **Drei Ansichtsmodi:** Der Kalender (`CalendarScreen`) stellt das absolvierte Training übersichtlich in den drei Modi **Woche**, **Monat** und **Liste** dar.
2. **Konsistente COROS-Vorschaukarten:** In der Tages- und Listenauswahl unterhalb des Kalenderrasters werden die Einheiten mit derselben COROS-Vorschaukarte (inkl. direktem `.FIT`-Download-Button rechts, nicht klickbar) dargestellt.

### 2.4 Onboarding & Profil Einfach (Athlet & Coach)
1. **Onboarding & Profil im Modus „Einfach“:** Reduziert auf die für V1.0.0 essenziellen Stammdaten für **Athlet** und **Coach** ohne komplexe Schwellenwert-Matrizen oder überladene Fragebögen.
2. **Triathlon als vollwertige Sportart:** In der Sportarten-Auswahl (Onboarding & Profil) ist **Triathlon** (mit eigenem Kombi-Piktogramm `TriathlonCombinedIcon`) neben Radfahren, Laufen und Schwimmen fest wählbar.
3. **Darstellung & Lokalisierung:**
   - **Hell-/Dunkel-Modus:** Umschaltbar zwischen Light Mode (`#F8FAFC` Alabaster) und Dark Mode (`#001F47` Deep Orbital Navy).
   - **Sprache:** Vollständige Unterstützung für **Deutsch (`DE`)** und **Englisch (`EN`)** über zentrale Sprach-Indizes (`AppStrings` / `AppLocalizations`).
   - **Datums- und Zeitformat nach Wohnland:** Standardmäßiges kurzes Datumsformat **`dd.mm.yy`** (z. B. `16.11.26`) und **24-Stunden-Zeitformat (`HH:mm`)**, abgeleitet aus dem gewählten Wohnland (DACH/EU-Standard: `dd.mm.yy` & `24h`).

### 2.5 Coach-Funktionen in V1.0.0
1. **Verbindung mit Athleten:** Sichere Kopplung über den 6-stelligen Einladungscode (`createInvite` / `redeemInvite` / `revokeLink`) inklusive granularer DSGVO-Freigabe durch den Athleten.
2. **Eigene Coach-Navigation:** Wenn ein Nutzer mit der Rolle `TRAINER` (Coach) eingeloggt ist, zeigt die App eine dedizierte Coach-Navigation mit genau drei Hauptbereichen:
   - **Athleten** (Übersicht aller verknüpften Athleten + Schnellzugriff auf deren jüngste Einheiten).
   - **Kalender** (Kalenderansicht des ausgewählten Athleten in Woche, Monat und Liste).
   - **Profil / Einstellungen** (Coach-Profil, Einladungscode-Generator, Hell/Dunkel-Modus, Sprache DE/EN, Rechtliches & Logout).
3. **Direkter `.FIT`-Datei-Download:** Der Coach kann sowohl in der Athleten-Übersicht als auch im Athleten-Kalender auf jeder Trainings-Vorschaukarte rechts direkt die originale **`.FIT`-Datei herunterladen**, um sie in externen Profi-Tools (WKO5, GoldenCheetah, Excel) weiterzuverarbeiten.

### 2.6 Gesetzliche Anforderungen DE / EU für V1.0.0
1. **DSGVO Art. 9 Abs. 2 lit. a (Ausdrückliches Opt-In für Gesundheitsdaten):** Pflicht-Einwilligung im Onboarding (mit Zeitstempel und Versionsnummer in Firestore dokumentiert) sowie jederzeitige Widerrufsmöglichkeit in den Einstellungen.
2. **DSGVO Art. 17 (Recht auf Löschung / „Recht auf Vergessenwerden“):** Vollständige, rückstandslose Konto- und Datenlöschung (Firestore-Dokumente, Subcollections, Cloud Storage `.fit`-Dateien, Garmin-Tokens & Firebase Auth User) sowohl **In-App** (Einstellungen → Datenschutz → Konto löschen mit sofortigem Auto-Logout) als auch über die öffentliche **Web-Löschseite** (`/delete-account`).
3. **DSGVO Art. 13/14 (Datenschutzerklärung) & DDG § 5 / MStV § 18 (Impressum):** Jederzeit ohne Login im Web (`/privacy`, `/imprint`) sowie direkt aus dem Login-, Onboarding- und Einstellungs-Screen abrufbar, ausgestattet mit den offiziellen Kontaktdaten der Marke/Firma und bürgernaher deutscher Sprache ohne Technik-Jargon.

---

## 3. Detaillierter Phasenplan: Phase 40 bis Phase 46 (Weg zum V1.0.0 Release)

| Phase | Branch & Ziel-Tag | Fokus & Verbindliche Arbeitspakete | Abnahme-Kriterium |
| :--- | :--- | :--- | :--- |
| **Phase 40** | `feature/phase-40-login-onboarding-email-fix`<br>**Tag:** `v0.40.0` | **Verankerung Roadmap V1–V4, Phasenplan 40–46 & Code-Qualitäts-Gesetze**<br>• Verschärfung von `AGENTS.md` & `.cursorrules` (Effizienz-Gebot, Clean-Code-Gebot, 100 % deutsche Kommentierung inkl. Datei-Header & Inline-Kommentaren).<br>• Härtung von `scripts/check_phase_ready.sh` (`flutter analyze` mit 0 Errors, 0 Warnings, **0 Infos**; TypeScript-Build & ESLint in `functions/`; 100 % Kommentar-Prüfung auf allen bestehenden & geänderten Dateien; automatischer Test-Durchlauf).<br>• Verbindliche Dokumentation in `docs/ROADMAP_V1_TO_V4.md`, `docs/research/BENCHMARK_MATS_TRAININGPEAKS_GARMIN.md`, `PROGRESS.md` & `docs/CHECKPOINTS.md`.<br>• Merge von `feature/phase-40-login-onboarding-email-fix` (inkl. `AuthGuardService` & `verifyBetaUserEmail`) in `main` und Push auf GitHub. | `check_phase_ready.sh` 100 % grün, Tag `v0.40.0` auf `origin/main` gepusht. |
| **Phase 41** | `feature/phase-41-v1-onboarding-profile-locale`<br>**Tag:** `v0.41.0` | **Onboarding & Profil „Einfach“ (Athlet & Coach), Wohnland-Format (`dd.mm.yy` / 24h), DE/EN & Theme**<br>• Verschlankung des Onboardings und Profils auf den V1.0.0-Umfang („Einfach“) für Athlet und Coach.<br>• Wählbarkeit von **Triathlon** (inkl. `TriathlonCombinedIcon`) in Onboarding und Profil.<br>• Wohnland-Auswahl im Onboarding/Profil mit automatischer Kopplung an das Datumsformat **`dd.mm.yy`** (`OrbitDateFormatter.formatShortDate`) und **24h-Uhrzeitformat**.<br>• Vollständige Lokalisierungs-Abdeckung (`DE` & `EN`) ohne hartcodierte UI-Strings sowie verzögerungsfreier Hell-/Dunkel-Modus-Umschalter. | Unit-/Widget-Tests für Onboarding, Profil, `dd.mm.yy`-Formatter & DE/EN-Umschaltung grün; `check_phase_ready.sh` 0 Infos. |
| **Phase 42** | `feature/phase-42-v1-coros-card-fit-download`<br>**Tag:** `v0.42.0` | **Trainings-Vorschaukarte im COROS-Stil & Direkter `.FIT`-Download-Service**<br>• Neubau bzw. Fokus-Anpassung der Trainings-Vorschaukarte (`CorosActivityPreviewCard`):<br>  – In V1.0.0 **nicht klickbar** (kein Öffnen des Detail-Cockpits).<br>  – Entfernung der rechten GPX-Mini-Grafik.<br>  – Integration des direkten **`.FIT`-Download-Buttons** auf der rechten Kartenseite.<br>• Implementierung des plattformübergreifenden `.FIT`-Download- & Export-Services (`FitFileDownloadService`), der Originaldateien aus `users/{uid}/rawActivities/` streamt und lokal speichert/teilt. | E2E-Test des `.FIT`-Downloads auf Android (Pixel 10 Pro) & Unit-Tests für `CorosActivityPreviewCard`. |
| **Phase 43** | `feature/phase-43-v1-today-and-calendar`<br>**Tag:** `v0.43.0` | **Heute-Ansicht (Nur absolviertes Training + Sync/Upload) & Kalender (Woche, Monat, Liste)**<br>• Umbau der **Heute-Ansicht (`TodayTabScreen`)** für V1.0.0: Anzeige ausschließlich des absolvierten Trainings (COROS-Vorschaukarten) + prominente Schnellzugriffs-Leiste für **Garmin Sync** und **Datei-Upload** (`.fit`/`.tcx`/`.gpx`).<br>• Sauberes Feature-Flagging (`OrbitReleaseVersion.v1_0_0`) zum Ausblenden von 3-Ringe-Hero, Soll-Workouts und Analyse-Tab in V1.0.0.<br>• Härtung des **Kalenders (`CalendarScreen`)** für V1.0.0: Fokus auf absolviertes Training in **Woche**, **Monat** und **Liste** mit direktem `.FIT`-Download. | Widget-Tests für Heute-Ansicht & Kalender (Woche/Monat/Liste) im V1.0.0-Modus grün. |
| **Phase 44** | `feature/phase-44-v1-coach-navigation-and-fit`<br>**Tag:** `v0.44.0` | **Coach-Funktionen V1.0.0: Athleten-Kopplung, Eigene 3-Tab-Navigation & Coach-`.FIT`-Download**<br>• Dedizierte **Coach-Navigation** (`Athleten`, `Kalender`, `Profil/Einstellungen`) ohne überflüssige V2/V3-Tabs.<br>• Reibungsloser Einladungscode-Workflow zwischen Coach und Athlet inkl. granularer DSGVO-Freigaben.<br>• Direkter **`.FIT`-Datei-Download** für den Coach in der Athleten-Aktivitätsliste und im Athleten-Kalender (geprüft durch Firestore- & Storage-Security-Rules). | Emulator-Rules-Tests für Coach-`.FIT`-Download & Widget-Tests der Coach-Shell grün. |
| **Phase 45** | `feature/phase-45-v1-legal-gdpr-compliance`<br>**Tag:** `v0.45.0` | **Gesetzliche Anforderungen DE/EU (DSGVO Art. 9, 13/14, 17 & DDG § 5 Impressum)**<br>• Finale Verifikation des **DSGVO Art. 9 Opt-Ins** (explizite Einwilligung + Widerruf mit sofortigem Verarbeitungsstopp).<br>• End-to-End-Prüfung der **DSGVO Art. 17 Konto- und Datenlöschung** (In-App + Web `/delete-account`) inkl. Storage-Raw-Files und Garmin-Deregristrierung.<br>• Aktualisierung und Verlinkung von **Datenschutzerklärung (Art. 13/14 DSGVO)** und **Impressum (§ 5 DDG)** mit den offiziellen Kontaktdaten der Marke/Firma in App und Web-Hosting. | Security- & Privacy-Audit-Suite (100 % grün) + Hosting-Deploy. |
| **Phase 46** | `feature/phase-46-v1-efficiency-audit-and-release`<br>**Tag:** `v1.0.0` | **100 % Effizienz-/Kommentar-Audit, Pixel 10 Pro Hardware-Abnahme & V1.0.0 Gold-Release**<br>• Vollständiges Code-Audit gegen `AGENTS.md` Regel 10 (`const`, `RepaintBoundary`, `ListView.builder`, `.select()`, 0 Berechnungen in `build()`, 100 % Datei-Header, Doc-Comments & Inline-Kommentare).<br>• E2E-Hardware-Abnahme aller V1.0.0-Kriterien auf dem **Google Pixel 10 Pro** inkl. Screenshot-Nachweisen.<br>• Signierter Release-Build (`app-release.apk` / `.aab`), Tag **`v1.0.0`** und Push auf `origin/main`. | Alle V1.0.0-Abnahmekriterien erfüllt, Tag `v1.0.0` live. |

---

## 4. Übernahme der MATS.coach- und TrainingPeaks-Highlights für V2.0.0 und V3.0.0

Die in der Benchmark-Studie (`docs/research/BENCHMARK_MATS_TRAININGPEAKS_GARMIN.md`) analysierten Best-Practices von **MATS.coach**, **TrainingPeaks** und **Garmin Connect** sind fest für die Ausbaustufen **V2.0.0** und **V3.0.0** eingeplant:

### 4.1 Geplante Highlights für V2.0.0 (Coaching-Interaktion & Trainingsplanung)
1. **2D RPE- & Wohlbefindens-Quadrant (MATS.coach-Vorbild):**
   - Zweidimensionaler Koordinaten-Puck nach Abschluss einer Einheit (*X-Achse: Empfundene Intensität von Einfach bis Schwer*, *Y-Achse: Wohlbefinden von Schlecht bis Sehr gut*).
   - Erzeugt einen normierten subjektiven Belastungs-Score, der sofort für den Trainer sichtbar ist.
2. **Athleten-Verfügbarkeitsprofile (MATS.coach-Vorbild):**
   - Athleten hinterlegen pro Wochentag ihre verfügbaren Trainingszeitfenster (z. B. Mo–Fr max. 1,5 h, Sa–So bis 4 h), die dem Coach bei der Kalenderplanung direkt als visuelle Leitplanken angezeigt werden.
3. **Visueller Block-Workout-Builder mit `#lit` / `#mit` / `#hit` & Ernährungs-Vorgabe:**
   - Mobiler Klick-Builder und Web-Editor mit gestufter Block-Vorschau, automatischer Umrechnung von `% FTP` / `% Schwellenpace` in reale Watt/Pace-Ziele sowie einem dedizierten Feld für **Kohlenhydrat- und Hydrationsvorgaben** (`g/h` CHO, `ml/h` Flüssigkeit) pro Einheit.
4. **Soll/Ist-Erfüllungs-Ampel & 7-Tage-Status-Strip:**
   - Dreistufige Plan-Erfüllungs-Ampel (Grün $\le 15\,\%$ Abweichung, Gelb $15\text{–}35\,\%$, Rot $> 35\,\%$) im Kalender und auf der Heute-Ansicht.

### 4.2 Geplante Highlights für V3.0.0 (Wissenschaftliche Telemetrie & Health-Cockpit)
1. **Vollständige TrainingPeaks-Telemetrie-Matrix im Aktivitäts-Cockpit:**
   - Klickbare Aktivitätskarten öffnen das High-End Aktivitäts-Cockpit mit **Normalisierter Leistung (Iso-Power / NP)**, **Intensitätsfaktor (IF)**, **ORBIT Load (TSS/rTSS/sTSS)**, **Variabilitätsindex ($VI = \text{NP}/\bar{P}$)**, **Effizienzfaktor ($EF = \text{NP}/\overline{\text{HR}}$)**, **Aerobem Drift ($\text{Pw:Hr}$ in %)** und **VAM ($m/h$)**.
2. **Banister PMC (CTL, ATL, TSB) & Fitness-Rampenraten (7d / 28d / 90d / 365d):**
   - Langfristige Belastungssteuerung mit exponentiell gewichteter Fitness (42d CTL), Ermüdung (7d ATL), Form (TSB) und numerischen Ramp-Rate-Warnungen zur Verletzungs- und Übertrainingsprävention.
3. **Farbcodierte GPS-Streckenlinie & Synchronisierter 1Hz-Multi-Stream-Scrubber:**
   - Umschaltbare GPS-Track-Einfärbung nach **Volt-Solid (`#CDFB17`)**, **Herzfrequenz-Gradient** oder **Pace-/Watt-Gradient** synchron zum 120-FPS-Diagramm-Scrubber.
4. **Polarisierte 3-Zonen-Analyse (`LIT / MIT / HIT`) & MMP Peak-Medaillen:**
   - Gegenüberstellung der 3-Zonen-Polarisierung (Seiler-Modell) und der 7 Coggan-/Friel-Zonen sowie logarithmische Power-Duration- / Critical-Speed-Kurven mit Gold-/Silber-/Bronze-Medaillen für Saison- und Allzeit-Bestwerte.
5. **Health & Recovery Cockpit (Garmin Connect & Whoop-Synthese):**
   - 3 Ringe (Erholung, Tagesbelastung, Schlaf), 30-Tage-Normbänder ($\mu \pm 1\sigma$ für HRV rMSSD und Ruhepuls), detaillierte Schlafphasen (Tief, Leicht, REM, Wach) und ein 45-Sekunden Morgen-Check-in zur Krankheits-Früherkennung.
