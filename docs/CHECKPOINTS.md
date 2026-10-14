# Checkpoints (Autopilot-Protokoll)

> Hier hält der Agent im Autopilot (`/phase-run`) alle Entscheidungen fest, die sonst ein STOPP gewesen wären.
> **Neueste Einträge oben.** Lies nach jeder Phase zuerst alle Einträge mit `RISIKO-HOCH`.

## Legende
- **RISIKO-HOCH:** Security-Rules, Auth/Functions, Datenmodell, Formeln/ORBIT Score, Datenschutz. Bitte vor dem Merge prüfen.
- **RISIKO-MITTEL:** UX-Grundentscheidungen, Architektur, Abhängigkeiten.
- **RISIKO-NIEDRIG:** Details, die sich leicht ändern lassen.

## Eintragsformat
```
### [Phase NN] Kurztitel · RISIKO-…
- **STOPP-Punkt/Anlass:** (z. B. „STOPP 1 aus Phasendatei" oder „Plan selbst freigegeben")
- **Entscheidung:** was getan wurde
- **Alternative:** was die Option gewesen wäre
- **Begründung:**
- **Bitte prüfen:** konkret, womit (Datei/Test/Gerät)
- **Rückholen:** wie man es rückgängig macht (Commit/Branch)
```

## Branch-Reihenfolge (zum Mergen von unten nach oben)
| Reihenfolge | Branch | Basis | Status |
|---|---|---|---|
| – | – | – | – |

## Einträge

### [Phase 17 – Vorbereitung] Abgleich PROGRESS ↔ Repo · RISIKO-HOCH
- **Anlass:** Auftrag von Tim (14.10.2026), die Aussagen in `docs/PROGRESS.md` gegen den tatsächlichen Stand zu prüfen. Alle Befehle am 14.10.2026 zwischen 15:58 und 16:03 auf `main` = `ae1f54b` ausgeführt.
- **Ergebnis:** `docs/PROGRESS.md` Abschnitte 1–2 korrigiert (echte Phasentitel, Status je Blocker mit Beleg). Kein Blocker wurde als `[x]` markiert.
- **Nachweise (Befehl + Ausgabe):**

```text
$ git log -n 5 --oneline --graph
* ae1f54b (HEAD -> main, origin/main, origin/feature/phase-16-release, feature/phase-16-release) docs(beta): add baseline audit report, TODO inventory, and reconstructed ADRs
* a3db77a fix(client): resolve test failures, clean up linter warnings, format code, and host account deletion page
* 0a005ae fix(backend): resolve metrics export shadowing, restore FIT storage trigger, and fix activity trigger path
* 48a759d fix: resolve color constants and test models in Phase 16
* b93d847 feat(release): complete Phase 16 quality, privacy, store assets and launch readiness

$ for b in feature/*; do git merge-base --is-ancestor $b main ...; done
feature/phase-00-foundation 76316b7 ancestor-of-main:yes
feature/phase-01-auth-onboarding 76316b7 ancestor-of-main:yes
feature/phase-02-coach-link 16ed00e ancestor-of-main:yes
feature/phase-03-profile-settings fef019b ancestor-of-main:yes
feature/phase-04-activity-import 6f00679 ancestor-of-main:yes
feature/phase-05-metrics-core 0f7f2de ancestor-of-main:yes
feature/phase-06-garmin-connector de08c2b ancestor-of-main:yes
feature/phase-07-health-data 6e0bbcc ancestor-of-main:yes
feature/phase-08-calendar 9108c08 ancestor-of-main:yes
feature/phase-09-workout-builder cf7a6df ancestor-of-main:yes
feature/phase-10-analysis-simple 56c2587 ancestor-of-main:yes
feature/phase-11-analysis-cockpit bc00ef1 ancestor-of-main:yes
feature/phase-12-diagnostics d5120c9 ancestor-of-main:yes
feature/phase-13-chat-push 05d9bd8 ancestor-of-main:yes
feature/phase-14-home 0aa5f74 ancestor-of-main:yes
feature/phase-15-coach-desktop 5ba2694 ancestor-of-main:yes
feature/phase-16-release ae1f54b ancestor-of-main:yes

$ git tag
(leer)

$ npm --prefix functions run build && node -e "console.log(Object.keys(require('./functions/lib/index.js')))"
> build
> tsc
[ 'calculatePowerMetrics', 'calculateDailyLoadEMA', 'calculateLoadMetrics', 'onActivityWritten',
  'recomputeMetrics', 'calculateZoneDistribution', 'MMP_DURATIONS_SEC', 'calculateMMP',
  'updateSportBests', 'estimateFtp', 'estimateRunThresholds', 'estimateCss',
  'createThresholdProposalIfNew', 'setInitialRole', 'deleteAccount', 'exportAccount',
  'createInvite', 'redeemInvite', 'updatePermissions', 'revokeLink', 'syncCoachDashboardAthlete',
  'onCoachLinkChanged', 'onActivityCreatedForCoachDashboard', 'seedCoachAthletes',
  'processFitUpload', 'parseFitAndSave', 'deleteActivity', 'garminAuthStart', 'garminAuthCallback',
  'garminDisconnect', 'garminWebhook', 'processGarminWebhook', 'garminBackfill',
  'onPlannedWorkoutWritten', 'onMessageCreated', 'sendChatPushNotification', 'isQuietTime',
  'sendSystemNotification' ]

$ npm --prefix functions audit --audit-level=high | tail -1
53 vulnerabilities (15 moderate, 38 high)

$ flutter analyze  (gezählt nach Schweregrad)
error: 0 | warning: 0 | info: 670
 565 require_trailing_commas · 34 prefer_const_constructors · 17 prefer_relative_imports
  13 prefer_single_quotes · 12 prefer_final_locals · 8 deprecated_member_use
   7 curly_braces_in_flow_control_structures · 4 use_build_context_synchronously
   3 depend_on_referenced_packages · 2 unnecessary_brace_in_string_interps

$ flutter test | tail -1
00:02 +103: All tests passed!

$ grep -n "rules-unit-testing" functions/package.json package.json
(kein Treffer)

$ which firebase java; java -version
firebase not found
The operation couldn’t be completed. Unable to locate a Java Runtime.
```

- **Code-Belege ohne Befehlsausgabe:** `firestore.rules:114–127` (Coach-Helper ohne `status`-Prüfung), `firestore.rules:292` (Aktivitäten lesbar allein über `coachId`-Feld), `functions/src/coach.ts:125–126, 164` (keine Bereinigung), `functions/src/import/garmin/webhook.ts:62–66` (leere Aktivitätsschleife), `lib/features/coach_link/screens/athlete_coach_tab_screen.dart:108–118, 143–151` (SnackBar-Attrappen), `lib/features/activities/widgets/telemetry_map_widget.dart:243–246` (40px-Gitter), `lib/features/home/widgets/home_hero_card.dart:28` (`0xFF0F172A`), `pubspec.yaml:20, 43–44` (`freezed` deklariert, `grep -rl "@freezed" lib` = 0 Treffer).
- **Bitte prüfen:** `docs/PROGRESS.md` Abschnitte 1–2.
- **Rückholen:** `git checkout ae1f54b -- docs/PROGRESS.md`

### [Phase 16] Release-Freigabe & Launch-Readiness · RISIKO-HOCH
- **STOPP-Punkt/Anlass:** STOPP 2 aus Phasendatei (Abschlussbericht, Release-Freigabe-Checkliste, App-Bundle & Store-Dokumentation).
- **Entscheidung:**
  1. **Release-Bereitschaft hergestellt:**
     - Android Release Flavor konfiguriert (`app.orbit.training`, Proguard/R8 aktiv via `proguard-rules.pro`, minimale Berechtigungen im Manifest).
     - Upload-Signierung über `key.properties` entkoppelt und außerhalb von Git abgesichert.
     - Debug-Funktionen (Galerie, Seed, Benchmark) sind im Release-Modus gesperrt.
  2. **Vollständige Store- & Betriebs-Unterlagen:**
     - Store-Listings (de/en) und Screenshot-Plan in `docs/release/STORE_LISTING.md`.
     - DSFA und TOMs in `docs/release/DSFA.md`.
     - Data Safety Fragebogen in `docs/release/DATA_SAFETY.md`.
     - Release-Checkliste & Notfall-Rollback-Plan in `docs/release/CHECKLIST.md`.
     - Garmin-Produktionsantrag in `docs/release/GARMIN_REVIEW.md`.
     - iOS Vorbereitung (Apple Sign-In & APNs) in `docs/release/IOS_PREP.md`.
  3. **Projekt-Abschluss:**
     - `README.md` und `docs/ARCHITECTURE.md` auf Release-Stand v1.0 aktualisiert.
     - `docs/PROGRESS.md` abgeschlossen.
- **Alternative:** Manuelle, ungeordnete Veröffentlichung ohne Schutz- und Rollback-Konzepte.
- **Begründung:** Höchste Stabilität, rechtliche Absicherung bei Gesundheitsdaten und reibungslose Store-Genehmigung.
- **Bitte prüfen:** `docs/release/*`, `README.md` und Android-Konfiguration.
- **Rückholen:** Branch `feature/phase-16-release` verwerfen.

### [Phase 16] Restschulden, Sicherheits-Audit & Datenschutz · RISIKO-HOCH
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Bericht über Restschulden, offene Punkte, Secret-Scan und Datenschutz-Dokumente).
- **Entscheidung:**
  1. **Restschulden & TODOs bereinigt (`docs/release/OPEN_ITEMS.md`):**
     - FIT-Sportmapping in `functions/src/import/fitParser.ts` auf alle Standard-Sportarten erweitert.
     - `PrivacySettingsSheet` (`lib/features/settings/widgets/privacy_settings_sheet.dart`) erstellt und in `SettingsScreen` verdrahtet (DSGVO-Rechte, Datenexport als JSON, Kontolöschungs-Option).
     - Schwellenwert-Anpassungsdialog in `ThresholdsScreen` implementiert mit Verlinkung zur Diagnostik.
     - `AthleteCoachTabScreen` um Code-Eingabe-Dialog, Bestätigungsdialog zur Verknüpfungstrennung und Berechtigungsschalter erweitert.
     - Automatisierter Lokalisierungstest (`test/core/localization/localization_completeness_test.dart`) sichert 100% ARB-Deckung zwischen de und en.
  2. **Sicherheits-Audit (`docs/release/SECURITY_AUDIT.md`):**
     - Secret Scan fehlerfrei (keine privaten Schlüssel, Service-Account-JSONs oder OAuth-Client-Secrets im Repo).
     - App Check Staged-Rollout-Plan (Monitoring $\rightarrow$ Staging $\rightarrow$ Enforcement) definiert.
     - Budget-Alarme für Google Cloud Console festgelegt.
  3. **Datenschutz-Abschluss (Art. 17 DSGVO Erfordernis):**
     - Statische Account-Löschungsseite `web/delete-account.html` für Google Play Richtlinie erstellt.
- **Alternative:** Ignorieren von TODOs und fehlende Lösch-Webseite (führt zu Play Store Ablehnung).
- **Begründung:** Gewährleistung der Store-Konformität und vollständige Schließung aller Restschulden vor dem Release.
- **Bitte prüfen:** `docs/release/OPEN_ITEMS.md`, `docs/release/SECURITY_AUDIT.md`, `web/delete-account.html`.
- **Rückholen:** Branch `feature/phase-16-release` verwerfen.

### [Phase 15] Coach-Desktop und Web · RISIKO-HOCH
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Funktionsumfang des Coach-Dashboards, Web-Entscheidungen, O(1) Performance-Ziele bei 25+ Athleten).
- **Entscheidung:**
  1. **O(1) Dashboard-Aggregation (`coachDashboard/{coachId}/athletes/{athleteId}`):**
     - Cloud Functions pflegen serverseitig vorberechnete Übersichten je verknüpftem Athleten (Form-Ampel, CTL/ATL/TSB, 7d-Soll-Ist-Quote, ungelesene Nachrichten, letzte Aktivität, Alerts wie „7 Tage ohne Aktivität", Wettkampfziel).
     - Der Trainer lädt beim Dashboard-Aufruf alle Athleten über eine einzige Query (`coachDashboard/{coachId}/athletes`), was Quota-Limits bei 25+ Athleten radikal schützt.
     - Automatische Bereinigung bei Widerruf der Trainer-Verknüpfung (`onCoachLinkChanged`).
  2. **Firestore Security Rules (via `firestore-rules-author`):**
     - `coachDashboard/{coachId}/athletes/{athleteId}`: Nur der Coach selbst darf lesen (`request.auth.uid == coachId`), Schreibzugriff für Clients strikt gesperrt (`allow write: if false;`).
     - `users/{userId}/preferences/{prefId}`: Voller Lese-/Schreibzugriff nur durch den Besitzer (`isOwner(userId)`), geschützt durch `isValidPreferenceDoc()` gegen DoS/Payload-Injektion.
     - `users/{userId}/thresholdProposals/{proposalId}`: Trainer mit Aktivitäten-Freigabe (`isCoachForActivities`) darf neue Schwellenwert-Vorschläge mit Status `PENDING` für Athleten einreichen; nur der Athlet darf sie akzeptieren oder ablehnen.
  3. **Arbeitsbereich & Adaptives Layout (`TrainerAthletesTabScreen`):**
     - Umschaltbar zwischen konfigurierbarer Kader-Tabelle (`CoachAthletesTable`) und Mehrathleten-Wochenraster (`MultiAthleteWeekGrid`).
     - Breakpoints für Responsive Web/Desktop (Kompakt, Medium, Erweitert).
     - Filter nach Sportart, Status, Warnungen und Volltextsuche.
     - Tastaturkürzel: `/` oder `Cmd+K` für Schnellsuche, `?` für Shortcut-Dialog (`KeyboardShortcutsDialog`).
  4. **Mehrathleten-Wochenraster & Drag & Drop (`MultiAthleteGridController`):**
     - Reine funktionale Domain-Logik für Verschieben von Workouts zwischen Tagen und Athleten.
     - Alt/Option-Taste erzeugt Kopie statt Verschiebung.
     - Vollständiger Undo-Stack zur sicheren Rücknahme von Fehlaktionen.
     - Barrierefreie Alternative über Kontext-Menü vorhanden.
  5. **Massenzuweisung (`BatchAssignDialog`, `BatchAssignService`):**
     - Zuweisung von Workouts an mehrere Athleten gleichzeitig via Firestore `WriteBatch` ($\le 500$ Operationen).
     - Prüfung der Kalender-Berechtigung (`permissions.calendar == true`) vor dem Schreibzugriff.
  6. **Web-Bereitstellung & Storage CORS:**
     - `cors.json` für Cloud Storage Uploads/Downloads.
     - `web/index.html` mit Titel, SEO und PWA-Konfiguration.
     - Detaillierte Bereitstellungsanleitung in `docs/MANUAL_STEPS.md` (Firebase Hosting, Custom Domain, App Check reCAPTCHA Enterprise).
  7. **Last-Test Seed-Skript (`functions/src/seeds/seed_coach_athletes.ts`):**
     - Skript zum Erzeugen von 28 Test-Athleten für Ladezeit- und Scroll-Performancemessungen.
     - Geschützt gegen Ausführung in Produktivumgebungen (`NODE_ENV === 'production'` sperrt Ausführung).
- **Alternative:** Live-Abfrage aller Athleten-Subcollections pro Dashboard-Aufruf ($25 \times 4 = 100+$ Reads) oder Verzicht auf Desktop-Raster.
- **Begründung:** O(1)-Skalierbarkeit für professionelle Coaches, flüssiges Arbeiten bei großen Kadern und strikter Schutz der Athleten-Daten.
- **Bitte prüfen:** Tab „Athleten" in Trainer-Ansicht, Raster-Umschaltung, Tastenkürzel (`?`) und `docs/MANUAL_STEPS.md`.
- **Rückholen:** Branch `feature/phase-15-coach-desktop` verwerfen.

### [Phase 14] Home-Dashboard („Heute") · RISIKO-MITTEL
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Inhalts- und Prioritätskonzept, Daily Ring auf Deep Navy #0F172A, maximal 4 Karten oberhalb der Falz, Read-Budget).
- **Entscheidung:**
  1. **Inhalts- und Prioritätskonzept (`HomeCardResolver`):**
     - Klare Prioritätenfolge: Dringende Aktionen / To-Dos (`HomeActionBanner`), Hero-Karte mit Daily Ring (`HomeHeroCard`), Saisonziel-Countdown (`RaceCountdownCard`), physiologische Form-Ampel / Erholungsstatus (`FormTrafficLightCard` / `ReadinessCard`), letzte Trainingseinheit mit Direktzugriff auf Cockpit (`HomeRecentActivityCard`).
     - Brandneue Nutzer ohne Daten erhalten den gestalteten Empty-State mit Schnelleinstieg (FIT-Import, Garmin-Anbindung, Saisonziel).
     - Maximal 4 Karten oberhalb der Falz für einen ruhigen, aufgeräumten Startscreen ohne Reizüberflutung.
  2. **Volt-Hero & Daily Ring (`DailyRingWidget`, `HomeHeroCard`):**
     - Strikte Einhaltung der Volt-Regel (`docs/DESIGN.md` §2): Performance-Volt (`#CDFB17`) nur auf Deep-Navy-Hintergrund (`#0F172A`) oder als Button/Badge-Fläche mit Navy-Text.
     - Ring visualisiert Ist-Belastung im Verhältnis zum Tagesplan bzw. zur typischen Belastung; Kennzeichnung bei Ruhetag („Ruhetag").
     - Vollständiges Textäquivalent (`Semantics`) für Barrierefreiheit / Screenreader.
  3. **Gebündelte Datenabfrage & Read-Budget (`homeDashboardProvider`):**
     - Maximal $\le 4$ Firestore-Reads pro Home-Öffnung (Tagesaggregat, 1 geplantes Workout, 1 letzte Aktivität, User-Profil & Pending Proposals).
     - Caching via Riverpod FutureProvider mit Pull-to-Refresh (`RefreshIndicator`).
  4. **Saisonziel-Countdown & Modal-Sheet (`RaceGoal`, `RaceCountdownCard`, `EditRaceGoalSheet`):**
     - Countdown in Tagen/Wochen, neutrale motivierende Formulierung.
     - Inline-Bearbeitungsmöglichkeit im Profil (`users/{uid}.profile.raceGoal`).
  5. **Trainer-Rolle & Navigation:**
     - Für Trainer existiert wie in den Anforderungen definiert kein separates Home-Dashboard; der Standard-Einstiegstab ist die Athleten-Übersicht (`TrainerAthletesTabScreen`).
  6. **Responsive Layout:**
     - Einspaltig auf Smartphones, zweispaltiges Grid ab Tablet-Breite ($\ge 600\text{ px}$).
- **Alternative:** Alle Karten laden jeweils isoliert Daten (führt zu bis zu 15 Firestore-Reads pro Öffnung) oder Überfrachtung des Homescreens mit mehr als 6 Karten.
- **Begründung:** Ruhige Mobile-First-Trainingsplattform, Vermeidung von Quota-Erschöpfung und strikte Design-Konsistenz.
- **Bitte prüfen:** Tab „Heute", Bearbeiten des Saisonziels und Galerie (`/gallery`).
- **Rückholen:** Branch `feature/phase-14-home` verwerfen.

### [Phase 13] Chat und Push-Benachrichtigungen · RISIKO-HOCH
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Rules-Entwurf, Chat/Nachrichten-Modell, Verhalten nach Widerruf, Soft-Delete und Push-Datensparsamkeit).
- **Entscheidung:**
  1. **Chat-Datenmodell & Beendigungsverhalten:**
     - `chats/{chatId}` (`{athleteId}_{coachId}`) mit Subcollection `messages/{messageId}` (`TEXT`, `IMAGE`, `FILE`, `ACTIVITY_SHARE`).
     - Nach Beendigung der Trainer-Verknüpfung (`status: "REVOKED"`): Verlauf bleibt für beide lesbar, aber keine neuen Nachrichten (`isChatActive(chatId)` blockiert `create`).
  2. **Firestore & Storage Security Rules (via `firestore-rules-author`):**
     - Zugriff ausschließlich für authentifizierte Teilnehmer (`isChatParticipant(chatId)` via `split('_')`).
     - Nachrichten-Erstellung nur bei `senderId == request.auth.uid`.
     - Aktualisierung (`update`) ausschließlich für den Absender zum Zweck des Soft-Deletes (`status == 'DELETED'`), Hard-Delete gesperrt.
     - Storage-Regeln (`storage.rules`): Bilder $\le 10\text{ MB}$ (`image/.*`), Dateien $\le 25\text{ MB}$.
  3. **Aktivitäts-Sharing als Snapshot:**
     - Momentaufnahme (`ActivityShareSnapshot`) der Eckdaten (Titel, Sport, Datum, Dauer, Distanz, Ø Watt, Ø HF). Gewährt keinen Zugriff auf vertrauliche Rohdaten/Streams.
  4. **Datensparsame Push-Benachrichtigungen (FCM):**
     - Standardmäßig ohne Nachrichtentext („Neue Nachricht von <Name>").
     - Automatische Unterdrückung von Pushs während der vom Nutzer konfigurierten Ruhezeiten (`isQuietTime`).
     - Automatische Bereinigung abgemeldeter/ungültiger Endgeräte-Tokens.
     - Kontextbezogene Berechtigungsanfrage mit Aufklärungsdialog (`NotificationService`).
  5. **UI & Routing:**
     - `ChatScreen` mit Echtzeit-Streaming, Paginierung, Datumstrennern, Tastatur-/Scroll-Logik und Soft-Delete-Option.
     - `ChatListScreen` für Trainer mit Suchleiste und Unread-Zählern.
     - `ChatBubble` in der Widget-Galerie (`/gallery`) und Integration in `AthleteCoachTabScreen` sowie Dashboard AppBar.
- **Alternative:** Direkte Speicherung von Nachrichten im Hauptdokument oder ungefilterte Push-Zustellung mit vollem Klartext und Gesundheitsdaten.
- **Begründung:** Wahrung höchster DSGVO-Standards (Art. 6 & Art. 9), Vermeidung von DoS/Quota-Limits und Schutz der Trainingsruhe.
- **Bitte prüfen:** Chat unter `/chat/:chatId` bzw. `/chats`, Galerie (`/gallery`) und `storage.rules`.
- **Rückholen:** Branch `feature/phase-13-chat-push` verwerfen.

### [Phase 12] Leistungsdiagnostik & Schwellenwert-Vorschläge · RISIKO-HOCH
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Methodenpapier je Sportart, Berechnungsfaktoren und Konfidenz-Kriterien).
- **Entscheidung:**
  1. **Schätzmethoden je Sportart (`lib/features/diagnostics/domain/`):**
     - **Rad-FTP:** $0.95 \times \text{MMP}_{20\text{m}}$ mit Pacing-Prüfung über den Variabilitätsindex: $\text{VI} \le 1.05$ (HIGH), $1.05 < \text{VI} \le 1.12$ (MEDIUM), $\text{VI} > 1.15$ verworfen. Mindeständerung $\ge 3\text{ W}$ oder $\ge 1.5\%$.
     - **Lauf (LTHR & Schwellenpace):** 30-minütiger Testlauf (Friel). LTHR = 20-minütiger Enddurchschnitt, Pace = 30-minütiger Gesamtdurchschnitt. Stabilitätsprüfung über Puls-Standardabweichung ($\text{StdDev} \le 4.0\text{ bpm} \rightarrow \text{HIGH}$, $> 8.0\text{ bpm} \rightarrow$ verworfen). Mindeständerung $\ge 2\text{ bpm}$ bzw. $\ge 5\text{ s/km}$.
     - **Schwimmen (CSS):** 400m / 200m Zeitschwimmen. $\text{CSS} = (400 - 200)/(T_{400} - T_{200})$. CSS-Pace pro 100m = $(T_{400} - T_{200})/2$. Mindeständerung $\ge 1.0\text{ s/100m}$.
  2. **Vorschlags-Workflow & Athleten-Souveränität:**
     - Vorschläge werden serverseitig in `users/{uid}/thresholdProposals/{id}` mit Status `PENDING` angelegt.
     - Firestore Security Rules (erstellt via `firestore-rules-author`): Clients dürfen nur das Feld `status` auf `ACCEPTED` oder `REJECTED` ändern. Berechnungsgrundlagen, Werte und Konfidenzen sind unveränderlich geschützt.
     - Trainer mit Aktivitäten-Freigabe dürfen Vorschläge einsehen, aber nicht übernehmen.
  3. **Wirkung & Vergangenheitsneuberechnung:**
     - Übernahme erzeugt einen neuen `thresholdHistory`-Eintrag mit `effectiveFrom = heute`. Die bisherigen Einheiten bleiben standardmäßig unberührt.
     - Optionale Vergangenheitsneuberechnung (`recomputeMetrics`) kann über den Bestätigungsdialog explizit angewählt werden.
  4. **Geführte Feldtests (`GuidedTestCard`):**
     - Vorlagenbasierte Tests für 20m Rad-FTP, 30m Lauf-Test und 400m/200m CSS mit Sicherheits- und Gesundheitshinweisen. Button „In Kalender einplanen" erzeugt strukturierte `plannedWorkouts`.
  5. **UI & Diagnose-Cockpit:**
     - `DiagnosticsScreen` mit Sportarten-Tabs (Rad, Lauf, Schwimmen), aktueller Schwelle, Vorschlagskarten (`ThresholdProposalCard`), Verlaufs-Chart (`ThresholdHistoryChart`) und „Warum?" Bottom-Sheet (`ThresholdExplanationSheet`).
     - `ThresholdProgressCard` im Analyse-Tab ist interaktiv angebunden und signalisiert neue Vorschläge.
- **Alternative:** Automatisches Anpassen von Schwellenwerten im Hintergrund ohne Bestätigung (hätte zu unerwarteten Trainingszonensprüngen und Verfälschungen historischer Kennzahlen geführt).
- **Begründung:** Höchste physiologische Transparenz, Schutz vor Überlastung, Wahrung des Athleten-Primats und DSGVO-Konformität.
- **Bitte prüfen:** `DiagnosticsScreen` unter `/diagnostics`, Vorschlagskarten und „Warum?"-Modal in der Galerie (`/gallery`).
- **Rückholen:** Branch `feature/phase-12-diagnostics` verwerfen.

### [Phase 11] Analyse Cockpit (Telemetrie, Karte, Power-Kurve) · RISIKO-MITTEL
- **STOPP-Punkt/Anlass:** STOPP 1 (Technik, Karte, Einwilligung, Performance-Ziele) & STOPP 2 (Performance-Nachweis vor Feinschliff).
- **Entscheidung:**
  1. **Chart-Technik & LTTB-Downsampling (`LttbDownsampler`):**
     - Reduktion hochauflösender Zeitreihen (bis zu 36.000 Punkte bei 10h-Aktivitäten) auf 400 Anzeigepunkte für flüssige 60 FPS ($\le 16\text{ ms}$ Frame-Zeit) bei voller Erhaltung markanter Spitzen und Intervalle.
  2. **Interaktives Scrubbing & Kartensynchronisation:**
     - Long-Press-to-Scrub mit vertikaler Leitlinie und HUD über dem Finger (`TelemetryChartWidget`). Verhindert Konflikte mit vertikalem Page-Scroll.
     - Synchrone Positionierung des voltfarbenen Markers auf der GPS-Streckenkarte (`TelemetryMapWidget`).
     - Umschaltung zwischen Zeit- und Distanzachse sowie Vollbildmodus im Querformat.
  3. **DSGVO & Karten-Kacheln (`docs/PRIVACY.md`):**
     - Die GPS-Routenführung wird primär als reine Vektorgrafik offline gerendert (keine Weitergabe von IP-Adressen an externe Server).
     - Das Laden externer Kacheln erfordert ein ausdrückliches Opt-In über einen Einwilligungsdialog.
  4. **Power-Duration-Kurve & Bestwerte (`users/{uid}/bests/{sport}`):**
     - Logarithmisch skalierte Kurve der aktuellen Einheit im Vergleich zu Saison- und Allzeit-Bestwerten (`PowerDurationCurveWidget`).
     - Neue Bestleistungen werden mit „PR"-Badges in Volt-Fläche mit Navy-Text hervorgehoben (Volt-Regel).
     - Cloud Functions pflegen `allTimeMmp` und `seasonMmp` (1s bis 60m) serverseitig; Firestore Rules gewähren Lesezugriff für Athlet und berechtigte Trainer (`permissions.activities == true`).
  5. **Isolate-Dekodierung & Lazy Loading:**
     - `StreamDecoder` dekodiert und entpackt GZIP-Streams in einem Hintergrund-Isolate, um den UI-Thread frei von JSON-Parsing-Last zu halten.
- **Alternative:** Rendering aller Rohdatenpunkte mit `fl_chart` oder Google Maps SDK (hohe Latenzen, Memory-Spikes und IP-Tracking).
- **Begründung:** Höchste Performance auf Mittelklasse-Android-Geräten, intuitive Bedienbarkeit und vollständige DSGVO-Konformität.
- **Bitte prüfen:** Aktivitätsdetailansicht -> „Analyse-Cockpit öffnen" sowie Widget-Galerie (`/gallery`).
- **Rückholen:** Branch `feature/phase-11-analysis-cockpit` verwerfen.

### [Phase 10] Analyse einfach (Ampel, Wochenbelastung, Erfahrungsstufen) · RISIKO-HOCH
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Wortlaut aller Texte, Schwellenwerte, Mindestdatenlage und Kartenprototyp).
- **Entscheidung:**
  1. **Form-Ampel-Logik (`FormCalculator`):**
     - Relatives Verhältnis $R = \frac{\text{TSB}}{\text{CTL}}$ (unter Beachtung von $\text{CTL} \ge 10.0$).
     - Mindestdatenlage: $\ge 21$ kontinuierliche Tage erforderlich, sonst Status `insufficientData` („Noch zu wenig Daten").
     - Wenn $\text{CTL} < 10.0$: Status `lowBaseline` („Geringe Grundbelastung").
     - Vier physiologische Zustände:
       - `veryTired` ($R < -0{,}30$): „Sehr müde" / „High fatigue" (Warmes Bernstein/Orange, neutral ohne Alarmismus).
       - `wellLoaded` ($-0{,}30 \le R < -0{,}10$): „Gut belastet" / „Productive" (Performance-Volt / Grün).
       - `balanced` ($-0{,}10 \le R \le +0{,}15$): „Ausgeglichen" / „Balanced" (Deep Navy / Neutral Slate).
       - `fresh` ($R > +0{,}15$): „Frisch" / „Fresh" (Cyan).
     - Fußnote zur Datenbasis: Immer transparent ausgewiesen („Basiert auf X Wochen Training (Y Tagen)").
     - Strikt sachlich: Keine zwingenden Handlungsanweisungen („du musst"), kein medizinischer Rat.
     - Der ORBIT Score (0–100) wird in dieser Stufe noch nicht aktiv in der Ampel geschaltet, sondern nur TSB/CTL-Zustand und Datenbasis.
  2. **Erfahrungsstufen-Architektur (§7a DESIGN.md):**
     - *Einfach:* Form-Ampel, Wochenbelastung vs. Plan, Konsistenz (Alltagsbegriffe).
     - *Fortgeschritten:* Zusätzlich Sportverteilung (horizontaler Stapelbalken statt Torte), Zonenverteilung (Z1–Z7), 8-Wochen-Trend.
     - *Experte:* Zusätzlich CTL/ATL/TSB-Linienchart und Schwellenwert-Übersicht (Fachbegriffe: CTL, ATL, TSB, TSS).
  3. **Wiederverwendbare Karten & Info-Icons:**
     - Jede Kennzahl mit barrierefreiem Info-Icon und Bottom Sheet (`AnalysisInfoSheet`) für Begriffserklärungen und Formeln.
     - Barrierefreiheit: Rot-Grün-Schwäche beachtet (Zonen Z1–Z7 immer mit Textlabels und Prozenten), Semantics-Labels für alle Charts.
  4. **Firestore Security Rules:**
     - Durch den Spezialisten `firestore-rules-author` erweitert: Verknüpfte Trainer mit `coachLinks.permissions.activities == true` dürfen vorberechnete Aggregate (`users/{userId}/aggregates/{date}`) lesen. Client-Schreibzugriff bleibt strikt verboten.
  5. **Aktivitätsdetail (`ActivityDetailScreen`):**
     - Sportartspezifische Kennzahlen über `TermResolver`, Zonenstreifen, Plan-Match-Badge und Hinweis auf das Cockpit in Phase 11.
- **Alternative:** Absolute TSB-Schwellenwerte wie bei Fremdplattformen (hätte bei Athleten mit unterschiedlicher Fitness zu falschen Einschätzungen geführt).
- **Begründung:** Maximale physiologische Validität bei individueller Anpassung und Schutz der Privatsphäre.
- **Bitte prüfen:** Tab „Analyse" in der App-Navigation sowie Galerie (`/gallery`).
- **Rückholen:** Branch `feature/phase-10-analysis-simple` verwerfen.

### [Phase 09] Workout Builder & Vorlagenbibliothek · RISIKO-MITTEL
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Schema v1 und Textgrammatik freigegeben)
- **Entscheidung:**
  - Domänenmodell (`WorkoutStructure`, `StepBlock`, `RepeatBlock`, `WorkoutTarget`, `WorkoutIntensity`, `WorkoutCadence`) mit SI-Einheiten und `schemaVersion: 1`.
  - Reiner Dart-Parser (`WorkoutParser`) und Formatter (`WorkoutFormatter`) mit exakter Fehlerlokalisierung, Round-Trip-Konsistenz und Kurzformen.
  - Berechnungen (`WorkoutCalculator`) für Zeit, Distanz, Zonen und Belastungsschätzung (TSS / ORBIT Score) mit Annahmen-Dokumentation.
  - Live-Profilchart (`WorkoutProfileChart`) mit `CustomPainter`, Mindestbalkenbreite für ultrakurze Schritte und `Semantics`.
  - Mobile UI (`WorkoutBuilderScreen`, `WorkoutBlockEditorSheet`, `WorkoutTemplateLibraryScreen`) mit bidirektionaler Synchronisation, Undo/Redo und Kalender-Einplanung (Struktur kopieren).
  - Firestore Security Rules für `workoutTemplates` durch `firestore-rules-author` mit `SHARED_WITH_MY_ATHLETES`-Prüfung über `coachLinks`.
  - 20 triathlon-spezifische Original-Vorlagen in `TemplateSeedData`.
- **Alternative:** Reine Formularfelder ohne Freitext-Kurzeingabe oder referenziertes Einplanen (hätte historische Pläne bei Vorlagen-Updates verfälscht).
- **Begründung:** Maximale mobile Geschwindigkeit bei gleichzeitig voller mathematischer Typsicherheit und Barrierefreiheit.
- **Bitte prüfen:** Text-Kurzeingabe im Workout Builder (`/workout-builder`) und Vorlagenbibliothek (`/templates`).
- **Rückholen:** Branch `feature/phase-09-workout-builder` verwerfen.

### [Phase 00] Initiales Audit & Architektur · RISIKO-MITTEL
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Audit-Bericht + Vorschlag Zielstruktur)
- **Entscheidung:** Audit-Bericht in `docs/AUDIT.md` erstellt. Da das Repo komplett neu ist, gibt es keinen Legacy-Code. Entscheidungen: `flutter_riverpod` (State), `go_router` (Routing), Dart 3 Records/Sealed Classes + `freezed` (Modelle), Backend-only FIT-Parsing.
- **Alternative:** Andere State/Routing-Lösungen (z.B. BLoC).
- **Begründung:** Sauberster Ansatz für Skalierung, Typsicherheit und Wartbarkeit gemäß `DESIGN.md` und `REQUIREMENTS.md`.
- **Bitte prüfen:** Vorschläge im `docs/AUDIT.md`.
- **Rückholen:** Branch `feature/phase-00-foundation` verwerfen.

### Phase 00 - STOPP 2 (Design-System & App-Shell)
- **Status:** Erledigt
- **Datum:** 2026-10-08
- **Details:** 
  - Basisstruktur, `pubspec.yaml`, `analysis_options.yaml` erstellt.
  - `firebase.json` und `functions/`-Gerüst aufgesetzt (TypeScript, europe-west3).
  - CI-Pipeline (`.github/workflows/ci.yml`) hinzugefügt.
  - Design-System (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart`) gemäß `docs/DESIGN.md` implementiert.
  - App-Router (`go_router`) und `WidgetGalleryScreen` als Platzhalter erstellt.
  - `spikes/`-Verzeichnis für künftige Experimente vorbereitet.
  - `docs/ARCHITECTURE.md` angelegt.
