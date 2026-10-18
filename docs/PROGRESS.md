# ORBIT — Projektfortschritt & Phasen-Tracking (`PROGRESS.md`)

**Letztes Update:** 14. Oktober 2026
**Aktueller Fokus:** Beta-Stabilisierung & Ausbau (Phasen 17–24)
**Ziel-Termin Google Play Beta:** 31. Oktober 2026
**Aktueller Modus:** Standardmodus mit zwingenden STOPP-Punkten & Git-Tagging

---

## 1. Historie: Phasen 00–16 (Fundament & Basis-Implementierung)

> **Wichtiger Audit-Hinweis (aus `docs/beta/BASELINE.md` vom 14.10.2026):**
> Die Phasen 00–16 wurden vom vorherigen Agenten als `[x] Abgeschlossen` markiert, befanden sich jedoch **nicht auf `main`** (Branch-Stand `main` war Phase 03, Commit `fef019b`) und enthielten **9 kritische Blocker** (u. a. totgelegte Cloud-Function-Trigger, fehlender FIT-Storage-Trigger, 0 automatisierte Rules-Tests, UI-Mocks im Coach-Screen und Canvas-Fake statt Karten).
> **Abgleich 14.10.2026, 16:01 (Nachweise: `docs/CHECKPOINTS.md`, Eintrag „Abgleich PROGRESS ↔ Repo“):** Ein Teil der Blocker wurde bereits in den Commits `0a005ae`, `a3db77a`, `ae1f54b` technisch behoben und per Fast-Forward nach `main` übernommen. Die formale Abnahme durch Tim steht aus.
> **Status:** `[~] Code erstellt — Konsolidierung & Reparatur erfolgt in Phase 17 & 18.`
>
> **Legende:** `[x]` von Tim abgenommen · `[~]` Code vorhanden, Mängel offen oder Abnahme ausstehend · `[ ]` offen

Phasentitel gemäß `docs/phases/phase-NN-*.md` (die frühere Fassung dieser Datei nannte abweichende Titel):

- [~] **Phase 00:** Audit, Fundament, Design-System, Spikes *(Commit `76316b7`)*
- [~] **Phase 01:** Auth, Onboarding, Rollen, Rules, Datenschutz-Basis *(Kein eigener Commit: Branch `feature/phase-01-auth-onboarding` zeigt auf `76316b7` = Phase 00; Code steckt in `16ed00e`. ADR rekonstruiert in `docs/DECISIONS.md`.)*
- [~] **Phase 02:** Trainer-Verknüpfung, Freigaben, Athleten-Kontext *(`16ed00e`. Backend `createInvite`/`redeemInvite`/`revokeLink` existiert, aber `AthleteCoachTabScreen` ist UI-Mock (`athlete_coach_tab_screen.dart:112, 145, 212, 227, 243`) und `revokeLink` hinterlässt `coachId` auf Aktivitäten/Plänen (`functions/src/coach.ts:125, 164`) -> Ph. 17 & 18)*
- [~] **Phase 03:** Profil, Einstellungen, Schwellenwerte *(`fef019b`)*
- [~] **Phase 04:** Aktivitäts-Import (FIT-Upload, Parser, Demo-Modus) *(`6f00679`. Storage-Trigger `processFitUpload` war in `de08c2b` gelöscht und wurde in `0a005ae` wiederhergestellt -> Abnahme Ph. 17)*
- [~] **Phase 05:** Metrik-Kern (Berechnung, Aggregation, ORBIT Score) *(`0f7f2de`. Shadowing-Bug `metrics.ts` vs. `metrics/` in `0a005ae` behoben, Trigger werden exportiert -> Formel-Verifikation Ph. 20)*
- [~] **Phase 06:** Garmin-Connector *(`de08c2b`. OAuth + `defineSecret` + Backfill-Callable vorhanden; `processGarminWebhook` verwirft `activityDetails` (`webhook.ts:51–66`); Secrets nicht hinterlegt -> Ph. 18)*
- [~] **Phase 07:** Health-Daten *(`6e0bbcc`. Daily/Sleep/HRV-Upsert vorhanden (`webhook.ts:103–163`), nicht live getestet)*
- [~] **Phase 08:** Kalender und Soll-Ist-Abgleich *(`9108c08`)*
- [~] **Phase 09:** Workout Builder und Vorlagenbibliothek *(`cf7a6df`. 6 Unit-Test-Fehler in `a3db77a` behoben)*
- [~] **Phase 10:** Analyse einfach (Ampel, Wochenbelastung, Erfahrungsstufen) *(`56c2587`)*
- [~] **Phase 11:** Analyse Cockpit (Telemetrie, Karte, Power-Kurve) *(`bc00ef1`. Karte ist 40px-Canvas-Gitter (`telemetry_map_widget.dart:108, 243–246`), kein `flutter_map` in `pubspec.yaml` -> Ph. 19)*
- [~] **Phase 12:** Leistungsdiagnostik *(`d5120c9`)*
- [~] **Phase 13:** Chat und Push-Benachrichtigungen *(`05d9bd8`. Serialisierungs-Testfehler in `a3db77a` behoben; geplante Pushes & Logo fehlen -> Ph. 23)*
- [~] **Phase 14:** Home-Dashboard („Heute“) *(`0aa5f74`. Hero-Karte/Daily Ring nutzt `#0F172A` statt `#001F47` (`home_hero_card.dart:28`) -> Ph. 17)*
- [~] **Phase 15:** Coach-Desktop und Web *(`5ba2694`)*
- [~] **Phase 16:** Qualität, Datenschutz-Abschluss, Release *(`b93d847`. Vom Agenten eigenmächtig ohne Freigabe abgehakt -> Zurückgesetzt auf offen für Ph. 24. Performance-/Barrierefreiheits-Aussagen unbelegt.)*

---

## 2. Offene Kritische Audit-Befunde (Blocker-Liste aus `BASELINE.md`)

Diese 9 Punkte müssen vor dem Beta-Start zwingend auf `[x]` gebracht und in `CHECKPOINTS.md` bewiesen werden. `[x]` setzt ausschließlich Tim.

- [x] **Blocker 1 (Backend):** Shadowing-Bug (`functions/src/metrics.ts` vs. `functions/src/metrics/`) behoben, saubere Top-Level-Exporte echter Cloud Functions *(Von Tim abgenommen am 14.10.2026, Nachweis CHECKPOINTS)*.
- [x] **Blocker 2 (FIT-Upload):** Gelöschten Storage-Trigger `processFitUpload` (`functions/src/import/index.ts`) wiederhergestellt und auf `.fit`, `.tcx`, `.gpx` inkl. `.gz` erweitert *(Von Tim abgenommen am 16.10.2026)*.
- [x] **Blocker 3 (Rules-Tests):** `@firebase/rules-unit-testing` installiert und 18 automatisierte Tests gegen den Emulator implementiert *(Von Tim abgenommen am 14.10.2026)*.
- [x] **Blocker 4 (Coach-Mock):** `AthleteCoachTabScreen` von Dummy-SnackBars auf echte Einladungscode-, Trennungs- und Art.-9-Consent-Logik umgebaut *(Von Tim abgenommen am 16.10.2026, Phase 18)*.
- [x] **Blocker 5 (Garmin Live & History):** Garmin Consumer Key/Secret über Secret Manager angebunden, `webhook.ts` (Push + Ping/callbackURL + `activityDetails` Streams/Laps) verarbeitet und 90-Tage-Backfill (3×30-Tage-Chunks) implementiert *(Von Tim abgenommen am 16.10.2026, Phase 18)*.
- [x] **Blocker 6 (Tests & Linter):** Flutter-Tests (103/103 grün) und Analyzer (0 Errors, 0 Warnings) bereinigt *(Von Tim abgenommen am 14.10.2026)*.
- [x] **Blocker 7 (Karten-Fake):** 40px-Canvas-Gitter in `telemetry_map_widget.dart` durch echte `flutter_map` mit DSGVO-Opt-in ersetzen *(Von Tim abgenommen am 16.10.2026, Phase 19)*.
- [x] **Blocker 8 (Git-Chaos):** Phasen 04–16 sauber in `main` gemergt, Tagging-Struktur (`v0.16.0-baseline`, `v0.17.0`) etabliert *(Von Tim abgenommen am 14.10.2026)*.
- [x] **Blocker 9 (Security & Hosting):** DSGVO-Leak bei Trainer-Trennung in `coach.ts` und `firestore.rules` geschlossen *(Phase 17 abgenommen)*; Hosting-Bereitstellung mit Pflichtseiten (`/delete-account`, `/privacy`, `/imprint`, `/help`, `/app`) in *(Phase 22 abgenommen)*.

---

## 3. Beta-Sprint: Phasen 17–24 (Ziel: Play Store Beta am 31.10.2026)

| Phase | Titel & Kern-Deliverables | Risiko | Ziel-Tag | Status |
| :--- | :--- | :---: | :---: | :---: |
| **Phase 17** | **Notfall-Reparatur: Git, Build, Backend-Trigger, Rules-Tests & Security**<br>Merge 04–16 -> `main`, ADRs 01–08 nachziehen, `metrics.ts` Shadowing & `processFitUpload` fixen, DSGVO-Fix bei Trainer-Trennung, echte `@firebase/rules-unit-testing` Suite, 0 Test-/Analyzer-Fehler, Bereinigung Funktions-Exporte. | **HOCH** | `v0.17.0` | `[x] Abgeschlossen` |
| **Phase 18** | **Echte Daten-Pipeline: Garmin Live + Backfill, Multi-Format-Upload & Coach-Kopplung**<br>Garmin Secret Manager + echter Webhook-Handler + **90-Tage-History-Backfill**, manueller Einzel- & Batch-Upload für `.fit`, `.tcx`, `.gpx` (Wahoo/SRM), echter `AthleteCoachTabScreen` inkl. Art.-9-Consent. | **HOCH** | `v0.18.0` | `[x] Abgeschlossen` |
| **Phase 19** | **Onboarding-Redesign, In-App-Bug-Reporter, Error-UX & Echte Karten**<br>Neuer 4-Schritte-Onboarding-Wizard (Athlet/Coach), menschliche Fehlermeldungen (`OrbitErrorHandler`), schwebender **Beta-Bug-Reporter** (inkl. Screenshot/Logs), echte `flutter_map` statt Canvas-Gitter. | **MITTEL** | `v0.19.0` | `[x] Abgeschlossen` |
| **Phase 20** | **Profi-Analyse nach GoldenCheetah-Vorbild & Formel-Verifikation**<br>Eigene Implementierung + Referenz-Testsuite (< 0,5 % Abweichung) für NP/IF/TSS, Critical Power (CP/W′) & Skiba W′bal-Verlauf, Banister PMC (CTL/ATL/TSB), Aerobic Decoupling (EF), Auto-Intervalle & SWOLF. | **HOCH** | `v0.20.0` | `[x] Abgeschlossen` |
| **Phase 21** | **Health & Recovery Cockpit (Whoop-Vorbild im ORBIT-Design, Punkte a–h)**<br>3 Ringe (Erholung, Tagesbelastung mit dynamischem Ziel, Schlaf) auf „Heute“ (`#001F47`), dunkles Health-Cockpit unter „Analyse“ + Avatar-Menü, 30-Tage-Baselines, Schlafschuld, Kurz-Journal mit Korrelationen, Wochen-/Monatsberichte, Erholungs-Ampel für Trainer & finaler ORBIT Score. | **HOCH** | `v0.21.0` | `[x] Abgeschlossen` |
| **Phase 22** | **10x Brand-Exploration, Marketing-Landingpage, Pflichtseiten & Web-Coach**<br>`brand-showcase.html` mit 10 Logo-/Design-Richtungen zur Auswahl, Rollout als App- & Push-Icon, Hosting-Fix (`/delete-account`, `/privacy`, `/imprint`), Werbe-Landingpage mit Beta-Warteliste, Metrik-Lexikon (`/help`) & Web-Login (`/app`). | **MITTEL** | `v0.22.0` | `[x] Abgeschlossen` |
| **Phase 23** | **Push-Notifications mit Logo, Wettkampf-Ziele (A/B/C), App Check & Hardening**<br>Geplante & Event-Pushes mit eigenem ORBIT-Statusbar-Logo, Saison-/Wettkampf-Planung (A/B/C-Rennen als Countdown & Flaggen im PMC-Chart), Crashlytics (DSGVO-Opt-in), Force-Update-Gate, Feature-Flags & App Check. | **MITTEL** | `v0.23.0` | `[x] Abgeschlossen` |
| **Phase 24** | **Generalprobe (100–200 FIT-Files), Pixel 10 Pro Test & Vorbereitung**<br>Stresstest mit 100–200 echten Vereins-FIT-Dateien, echte Performance-Messung auf Pixel 10 Pro (`PERFORMANCE_REPORT.md`), manuelle Rollentestpläne (`TESTPLAN_ROLES.md`), Firestore Indexes & APK-Build. | **HOCH** | `v0.24.0-rc.1` | `[x] Abgeschlossen` |
| **Phase 25** | **Autonomer Live-Hardware-Testlauf & E2E-Audit auf dem Google Pixel 10 Pro (Vorgeschaltet!)**<br>Autonomer Testlauf per USB (`adb` + `integration_test`) direkt auf dem Pixel 10 Pro gegen das echte Backend (`europe-west3`), automatische Screenshots aller Screens (`docs/beta/screenshots/`) & schonungslose Fehlerdokumentation in `docs/beta/PIXEL10_LIVE_AUDIT.md`. | **HOCH** | `v0.25.0` | `[x] Abgeschlossen` |
| **Phase 26** | **Backend-Regionen-Fix (europe-west3), Package-Konsistenz, App Check & Onboarding-Reparatur**<br>Vollständige Umstellung aller Client-Aufrufe auf Frankfurt (`europe-west3`), Konsistenz für `app.orbit.training`, App Check Entschärfung & fehlerfreies 4-Schritte-Onboarding inkl. sofortigem USB-Update per `adb install -r`. | **HOCH** | `v0.26.0` | `[x] Abgeschlossen` |
| **Phase 27** | **Garmin Connect Live-OAuth, Android 11–16 `<queries>`, Deep-Link-Callback & 90-Tage-Backfill**<br>Android `<queries>`-Visibility, Browser-Handshake, Callback-Deep-Link, OAuth-Token-Austausch, Secret Manager Bereitstellung & automatischer 90-Tage-Backfill auf dem Pixel 10 Pro. | **HOCH** | `v0.27.0` | `[x] Abgeschlossen` |
| **Phase 28** | **Live-Reparatur der Kernfunktionen + Geschlossener Bug-, Ideen- & Kontakt-Workflow**<br>Behebung aller UI/UX-Mängel aus Phase 25; Ticket-System (`#ORB-xxx`) mit Admin-Push & Admin-Inbox (`/admin/feedback`); CLI-Tool `feedback:pull`; offizielle E-Mails & Web-Kontaktformular (`contactRequests`). Abmeldung & Release-Tag `v0.28.0`. | **MITTEL** | `v0.28.0` | `[x] Abgeschlossen` |
| **Phase 29** | **Zentrale Sprach-/Farb-Indizes, Onboarding-First-Flow, Komplettes Profil & Echte Erfahrungsstufen**<br>Tokens `OrbitThemeTokens` & `AppStrings`, Onboarding-First ohne Login-Wand, Tastatur-Overflow-Fix, Profilbild-Upload & Abfrage aller Sportdaten, Bug-Käfer von Sekunde 1, Erfahrungsstufen mit echter Daten-Auswirkung. | **HOCH** | `v0.29.0` | `[x] Abgeschlossen` |
| **Phase 30** | **Kalender-Neubau, Visueller Block-Workout-Builder, Echt-Watt/Pace-Umrechnung & Soll/Ist-Ampel**<br>Tab-Umbenennung („Kalender“), Kontrast-Fixes & ○/●-Monatsansicht, Visueller Block-Builder auf Smartphone, automatische Schwellenwert-Umrechnung (Watt/Pace/HF) & Soll/Ist-Erfüllungs-Ampel (Grün/Gelb/Rot am Folgetag). | **HOCH** | `v0.30.0` | `[x] Abgeschlossen` |
| **Phase 31** | **Garmin-Daten-Empfang reparieren, Karten (Hell/Dunkel + Volt-Linie), Neue Tests & PR-Datenbank**<br>Behebung 0 Einheiten nach Garmin-Sync, Test-Aktivitäten (Rad & Lauf), GPS-Strecke in Volt mit Kontur + Hell/Dunkel-Toggle, Stufentest (Rad) & 5-Minuten-All-Out (Lauf), PR-Datenbank & Leistungskurven. | **HOCH** | `v0.31.0` | `[x] Abgeschlossen` |
| **Phase 32** | **Zwei globale Coach-Modi (Einfach/Datei-Download vs. Analyse) & Header-Benachrichtigungsglocke**<br>Header-Glocke mit Badge für System-Meldungen vs. Coach-Tab für Chat, Originaldatei-Archivierung (`users/{uid}/rawActivities/`) & globale Coach-Modi: Modus 1 (Einfach / Download), Modus 2 (Analyse). | **MITTEL** | `v0.32.0` | `[x] Abgeschlossen` |
| **Phase 33** | **Gründlicher Deutscher & EU Sicherheits-, Datenschutz- & Urheberrechts-Audit**<br>Bürgernahe Datenschutz-Texte ohne Technik-Jargon, rechtlicher & Urheberrechts-Check (Markenbereinigung von TSS, IF, NP zu ORBIT Load etc.), Zero-Open-Data Security-Audit (Rules & Callables). | **HOCH** | `v0.33.0` | `[x] Abgeschlossen` |
| **Phase 34** | **Autonomer E2E-Hardware-Abnahmelauf auf dem Pixel 10 Pro & Vor-Beta-Bereitstellung**<br>Offizielles ORBIT App-Icon (Adaptive), autonomer E2E-Hardware-Testlauf aller Funktionen per USB auf dem Pixel 10 Pro, Gegenüberstellung aller Mängel aus `Orbit Test Bug.pdf` mit Screenshot-Beweisen (`docs/beta/PRE_BETA_VERIFICATION_REPORT.md`). | **HOCH** | `v0.34.0-prebeta` | `[x] Abgeschlossen` |

| **Phase 35** | **Garmin-Datenempfang, Echter `.fit`-Upload & Aktivitäts-Cockpit nach Strava/Garmin/Coros/MATS-Vorbild**<br>Aktiver REST-Pull-Sync (`syncGarminActivitiesNow`), Multi-Format Upload (`.fit`, `.tcx`, `.gpx`) mit Isolate-Parsing auf Android 16, High-End Cockpit mit Scrubber, Volt-Streckenlinie, Soll/Ist-Banner & PR-Kurven. | **HOCH** | `v0.35.0` | `[x] Abgeschlossen` |
| **Phase 36** | **Login-First, Rollenspezifisches Onboarding (Athlet vs. Coach), E-Mail-Verifikations-Warteraum & Profil-Persistenz**<br>Login-First beim App-Start, Bereinigung Doppel-ORBIT, Passwort-Reset, Dual-Passwort mit 8+ Zeichen Live-Checkliste, `EmailVerificationWaitingScreen` mit Polling, getrennte Fragebögen & 100% Profil-Persistenz. | **HOCH** | `v0.36.0` | `[x] Abgeschlossen` |
| **Phase 37** | **Kalender-Echtzeit-Sync, Visueller Workout-Builder (Garmin/MATS-Vorbild), Block-Konsistenz, Detail-Aktionen & Triathlon/Wettkampf-Planung**<br>Reaktiver Kalender-Stream (`snapshots()`), einheitliche Karten, 1:1 Block-Berechnung, Detail-Sheet (+1 Tag, Datum wählen, Überspringen), mobiler Klick-Builder mit Repeats 2x–30x, Koppeleinheiten & A/B/C Rennen. | **HOCH** | `v0.37.0` | `[ ] Offen` |
| **Phase 38** | **Global greifbarer Bug-Käfer, Metrisches 24h-Datumsformat (`DD.MM.YYYY`), Mitteilungs-Routing, Nutzer-Beta-Inbox, App-Icon-Präzision & Cleanup**<br>Top-Level Bug-Käfer im `MaterialApp.builder` (über Modal-Sheets bedienbar), `OrbitDateFormatter` (DD.MM.YYYY & 24h), gerahmte Mitteilungen mit Deep-Link-Routing, Beta-Inbox für Tester, Widget-Galerie-Entfernung, DSGVO-Löschung mit Logout & App-Icon-Zentrierung. | **MITTEL** | `v0.38.0` | `[ ] Offen` |
| **Phase 39** | **Rückwirkende 100 % deutsche Code-Kommentierung über das gesamte Projekt & Finaler Hardware-Audit**<br>Lückenlose deutsche Dokumentation (`///` & `/** ... */`) in `functions/src/`, Security Rules, `lib/core/`, `lib/shared/` und allen `lib/features/` Modulen, finaler E2E-Hardware-Audit auf Pixel 10 Pro & Tag `v0.39.0`. | **HOCH** | `v0.39.0` | `[ ] Offen` |

---

## 4. Post-Beta Roadmap (Geparkt für nach dem Beta-Launch)
- [ ] **Phase 40:** Mehrwochen-Trainingspläne, Plan-Bibliothek & Strukturierter Workout-Export direkt auf die Garmin-Uhr.
- [ ] **Phase 41:** Vereins- & Team-Funktionen (Gruppen-Boards, gemeinsame Trainingslager, Vereins-Rankings) & Equipment-Tracking.
- [ ] **Phase 42:** Erweiterte Integrationen (Android Health Connect, Strava-Sync, Apple Health).
- [ ] **Phase 43:** ORBIT KI-Assistent & Intelligenter Co-Coach.
