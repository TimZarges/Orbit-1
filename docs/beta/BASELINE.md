# ORBIT Beta-Planung: Baseline- und Bestandsaufnahmebericht

> **Datum:** 2026-10-14  
> **Repository:** `Orbit`  
> **Status:** Reine Bestandsaufnahme vor Beta-Planung. **Kein Anwendungscode wurde verändert.**  
> **Beleg-Konvention:** Jede Aussage ist durch Dateipfad und Zeilennummer (`Datei:Zeile`) oder konkrete Befehlsausgaben belegt. Nicht prüfbare Aspekte sind ausdrücklich als „nicht prüfbar" deklariert.

---

## Inhaltsverzeichnis
1. [Git-Stand & Verzweigungsanalyse](#1-git-stand--verzweigungsanalyse)
2. [Test-Ist-Stand & Code-Qualität](#2-test-ist-stand--code-qualität)
3. [Feature-Inventar (Routen & Screens)](#3-feature-inventar-routen--screens)
4. [Externe Anbindungen & Schnittstellen-Status](#4-externe-anbindungen--schnittstellen-status)
5. [Datenmodell, Cloud Functions & Security Rules](#5-datenmodell-cloud-functions--security-rules)
6. [Prüfung unbestätigter Behauptungen (Audit & Releases)](#6-prüfung-unbestätigter-behauptungen-audit--releases)
7. [Abhängigkeiten, Sicherheitsaudits & Lizenzen](#7-abhängigkeiten-sicherheitsaudits--lizenzen)
8. [Web-Plattform, Hosting & Domain-Stand](#8-web-plattform-hosting--domain-stand)
9. [Nachträgliche ADR-Rekonstruktion (Phasen 01, 02, 03, 04, 06)](#9-nachträgliche-adr-rekonstruktion-phasen-01-02-03-04-06)
10. [Bekannte Fehler & Auffälligkeiten](#10-bekannte-fehler--auffälligkeiten)
11. [Die 10 wichtigsten Befunde](#11-die-10-wichtigsten-befunde)

---

## 1. Git-Stand & Verzweigungsanalyse

### 1.1 Branch-Übersicht und Basis
Befehl: `git branch -a`
- **Aktiver Branch:** `feature/phase-16-release`
- **Basis-Branch:** `main`
- **Lokale Feature-Branches:**
  - `feature/phase-00-foundation`
  - `feature/phase-01-auth-onboarding`
  - `feature/phase-02-coach-link`
  - `feature/phase-03-profile-settings`
  - `feature/phase-04-activity-import`
  - `feature/phase-05-metrics-core`
  - `feature/phase-06-garmin-connector`
  - `feature/phase-07-health-data`
  - `feature/phase-08-calendar`
  - `feature/phase-09-workout-builder`
  - `feature/phase-10-analysis-simple`
  - `feature/phase-11-analysis-cockpit`
  - `feature/phase-12-diagnostics`
  - `feature/phase-13-chat-push`
  - `feature/phase-14-home`
  - `feature/phase-15-coach-desktop`
  - `feature/phase-16-release`
- **Remote-Branches (`origin`):**
  Identisch zu den lokalen Branches, **mit Ausnahme von** `feature/phase-02-coach-link`, welcher nur lokal existiert und nie zu `origin` gepusht wurde.

### 1.2 Merge-Status je Phase in `main`
Befehl: `git log --oneline main`
```
fef019b (origin/main, origin/feature/phase-03-profile-settings, main, feature/phase-03-profile-settings) feat: implement phase 03 profile, settings and thresholds
16ed00e (feature/phase-02-coach-link) feat(phase-02): trainer link, UI, and rules prototype
76316b7 (origin/feature/phase-01-auth-onboarding, origin/feature/phase-00-foundation) feat(phase-00): foundation setup
e0bd482 chore: Antigravity-Setup
```
- **In `main` gemergt:** Ausschließlich Phasen 00, 01, 02 und 03 (Stand: Commit `fef019b` vom 2026-10-08).
- **Ungemergte Arbeit:** Die Phasen 04 bis 16 wurden jeweils aufeinander gestapelt (linearer Verlauf), jedoch **keine einzige davon wurde in `main` gemergt**. Zwischen `main` und `feature/phase-16-release` liegen 15 ungemergte Commits.
- **Git-Tags:** Befehl `git tag -l` liefert ein leeres Ergebnis (0 Tags im gesamten Repository).
- **Working Tree Status auf `feature/phase-16-release`:**
  Der Arbeitsbaum ist unsauber („dirty"). Es existieren 20 modifizierte Dateien (unstaged) sowie ein unversionierter Ordner:
  - Modifiziert: `.gitignore`, `lib/core/design/app_colors.dart`, `lib/core/design/app_spacing.dart`, `lib/core/design/widget_gallery.dart`, `lib/features/activities/models/activity.dart`, `lib/features/activities/screens/activity_cockpit_screen.dart`, `lib/features/activities/screens/activity_detail_screen.dart`, `lib/features/analysis/screens/analysis_tab_screen.dart`, `lib/features/auth/providers/user_provider.dart`, `lib/features/calendar/models/planned_workout.dart`, `lib/features/calendar/screens/calendar_screen.dart`, `lib/features/coach_link/services/batch_assign_service.dart`, `lib/features/coach_link/widgets/coach_athletes_table.dart`, `lib/features/coach_link/widgets/multi_athlete_week_grid.dart`, `lib/features/diagnostics/screens/diagnostics_screen.dart`, `lib/features/diagnostics/widgets/recompute_confirmation_dialog.dart`, `lib/features/health/widgets/readiness_card.dart`, `lib/features/home/providers/home_dashboard_provider.dart`, `lib/features/home/widgets/home_recent_activity_card.dart`, `lib/features/settings/providers/settings_provider.dart`.
  - Untracked: `lib/features/workout_builder/providers/`.

---

## 2. Test-Ist-Stand & Code-Qualität

### 2.1 Statische Code-Analyse (`flutter analyze`)
Befehl: `flutter analyze`
- **Status:** Fehlgeschlagen (Exit-Code 1).
- **Gefundene Probleme gesamt:** **230 issues**
  - **Errors:** 0
  - **Warnings:** 36
  - **Infos:** 194
- **Auszug wesentlicher Warnungen:**
  - `lib/features/workout_builder/screens/workout_builder_screen.dart:3:8`: `unused_import` (GoRouter).
  - `lib/features/workout_builder/screens/workout_template_library_screen.dart:3:8`: `unused_import` (GoRouter).
  - `lib/features/workout_builder/widgets/workout_block_editor_sheet.dart:450:36` & `457:25`: `invalid_use_of_visible_for_testing_member` und `invalid_use_of_protected_member` (`state` von StateNotifier unzulässig aufgerufen).
  - `lib/firebase_options_dev.dart:1:8`: `depend_on_referenced_packages` (`firebase_core`).
  - `lib/firebase_options_prod 2.dart:1:1`: `file_names` (unzulässiger Bezeichner durch Duplikat).
  - `lib/main.dart:15:8`: `depend_on_referenced_packages` (`flutter_web_plugins`).
  - `lib/main.dart:33:34`: `unawaited_futures`.
*(Hinweis: `AGENTS.md` fordert strikt: `flutter analyze (null Warnungen)`).*

### 2.2 Flutter Unit- & Widget-Tests (`flutter test --coverage`)
Befehl: `flutter test --coverage`
- **Status:** Fehlgeschlagen (Exit-Code 1).
- **Anzahl Tests gesamt:** 103 Tests
  - **Bestanden:** 96
  - **Fehlgeschlagen:** **7**
- **Detaillierte Liste der 7 Fehlschläge:**
  1. `test/features/chat/models/chat_message_test.dart`:
     *Test:* `ChatMessage Model Tests serialisiert ActivityShareSnapshot korrekt`
     *Fehler:* `Expected: 'ACTIVITY_SHARE', Actual: 'ACTIVITYSHARE'` (String-Mismatch im Enum/JSON).
  2. `test/features/workout_builder/domain/workout_parser_test.dart:56`:
     *Test:* `3. Rad: VO2max Kurz-Kurz 30/30s (Verschachtelt Tiefe 2)`
     *Fehler:* `Expected: <2>, Actual: <3>` (Fehlerhafte Tiefenberechnung bei Block-Verschachtelung).
  3. `test/features/workout_builder/domain/workout_parser_test.dart:74`:
     *Test:* `4. Lauf: Schwellenlauf mit Pace-Vorgabe (@min:sec/km)`
     *Fehler:* `Expected: true, Actual: <false>` (Pace-Format-Parsing schlägt fehl).
  4. `test/features/workout_builder/domain/workout_parser_test.dart:171`:
     *Test:* `9. Schwimmen: Verschachteltes Sprintset (Tiefe 2)`
     *Fehler:* `Expected: <2>, Actual: <3>` (Verschachtelungstiefe falsch ermittelt).
  5. `test/features/workout_builder/domain/workout_parser_test.dart:192`:
     *Test:* `10. Kraft: Rumpf- und Athletikzirkel`
     *Fehler:* `Expected: WorkoutStructure, Actual: WorkoutStructure` (Struktureller Ungleichheitsfehler).
  6. `test/features/workout_builder/domain/workout_parser_test.dart:201`:
     *Test:* `Kurzformen & Toleranz Kurzform ohne Klammern: 8x100m CSS / 20"`
     *Fehler:* `Expected: true, Actual: <false>`.
  7. `test/features/workout_builder/domain/workout_calculator_test.dart:51`:
     *Test:* `WorkoutCalculator Warnt wenn keine CSS hinterlegt ist für Schwimm-Distanzziel`
     *Fehler:* `Expected: true, Actual: <false>` (Warnung wird nicht emittiert).

### 2.3 Testabdeckung (Coverage-Analyse)
Auswertung der generierten Datei `coverage/lcov.info` über alle erfassten Dateien:
- **Gesamtabdeckung:** **56.72%** (1275 von 2248 Zeilen abgedeckt).

| Feature / Modul | Zeilen getroffen (LH) | Zeilen vorhanden (LF) | Abdeckung (%) | Bewertung |
|---|---|---|---|---|
| `core/formatters` | 33 | 37 | **89.2%** | Gut |
| `core/metrics` | 46 | 56 | **82.1%** | Gut |
| `core/widgets` | 23 | 29 | **79.3%** | Gut |
| `coach_link` | 97 | 124 | **78.2%** | Gut (nur Grid & Models) |
| `workout_builder` | 702 | 935 | **75.1%** | Befriedigend (Parser/Models) |
| `diagnostics` | 110 | 197 | **55.8%** | Mäßig (nur Estimators) |
| `home` | 28 | 52 | **53.8%** | Mäßig (nur Resolver) |
| `activities` | 94 | 181 | **51.9%** | Mäßig (LTTB, MMP, Decoder) |
| `analysis` | 109 | 329 | **33.1%** | Gering |
| `chat` | 31 | 122 | **25.4%** | Sehr gering |
| `calendar` | 1 | 92 | **1.1%** | Nahezu ungetestet |
| `settings` | 0 | 7 | **0.0%** | Ungetestet |
| `auth` / `onboarding` | 0 | - | **0.0%** | Keine Tests in `test/` vorhanden |
| `integrations` / Garmin | 0 | - | **0.0%** | Keine Tests in `test/` vorhanden |
| `health` | 0 | - | **0.0%** | Keine Tests in `test/` vorhanden |
| UI Widgets / Screens | 0 | - | **0.0%** | Keine Widget-Tests vorhanden |

### 2.4 Integrationstests
- **Status:** **Nicht vorhanden.**
- **Befund:** Ein Verzeichnis `integration_test/` oder `test_driver/` existiert im Repository nicht. Es gibt keine Ende-zu-Ende-Tests für User-Flows (Login $\rightarrow$ Onboarding $\rightarrow$ Dashboard $\rightarrow$ Upload).

### 2.5 Cloud Functions Tests
Befehl: `cd functions && npm test`
- **Status:** Erfolgreich (Exit-Code 0).
- **Test-Suites:** 4 passed, 4 total (`metrics.test.ts`, `diagnostics.test.ts`, `auth.test.ts`, `chat.test.ts`).
- **Tests:** 17 passed, 17 total.

### 2.6 Security Rules Tests
- **Status:** **Nicht ausführbar / Vollständig fehlend.**
- **Befund:** `docs/RULES_TESTPLAN.md` beschreibt auf 833 Zeilen ein theoretisches Test-Setup mit `@firebase/rules-unit-testing`. Im gesamten Codebase existiert jedoch **keine einzige Rules-Testdatei**. In `functions/package.json` ist `@firebase/rules-unit-testing` nicht als Abhängigkeit installiert. Die Anforderung aus `AGENTS.md` (*„Firestore-/Storage-Rules: Standard 'deny all', jede Freigabe explizit, per Emulator-Test bewiesen"*) ist im aktuellen Stand nicht erfüllt.

---

## 3. Feature-Inventar (Routen & Screens)

Untersuchung der Verdrahtung in `lib/core/routing/app_router.dart`, `lib/features/dashboard/screens/dashboard_screen.dart` und allen Screen-Klassen:

| Route / Pfad | Screen-Klasse | Datei | Rolle | Status | Beleg / Begründung |
|---|---|---|---|---|---|
| `/login` | `LoginScreen` | `lib/features/auth/screens/login_screen.dart` | PUBLIC | **Echt verdrahtet** | Ruft `FirebaseAuth.instance.signInWithEmailAndPassword` bzw. `createUserWithEmailAndPassword` auf (`lib/features/auth/providers/auth_provider.dart:22, 26`). |
| `/onboarding` | `OnboardingScreen` | `lib/features/onboarding/screens/onboarding_screen.dart` | AUTH | **Echt verdrahtet / Teil-Mock** | Ruft Cloud Function `setInitialRole` auf, übergibt aber fest hardcodierte Dummy-Daten (`Nutzer Test`, `M`, `75kg`) statt Nutzerangaben (`lib/features/onboarding/screens/onboarding_screen.dart:40-46`). |
| `/` (Tab 0, Athlet) | `TodayTabScreen` | `lib/features/activities/screens/today_tab_screen.dart` | ATHLETE | **Echt verdrahtet** | Liest Firestore `users/{uid}/aggregates`, `plannedWorkouts`, `activities` via `homeDashboardProvider` (`lib/features/home/providers/home_dashboard_provider.dart:21-55`). |
| `/` (Tab 0, Trainer) | `TrainerAthletesTabScreen` | `lib/features/coach_link/screens/trainer_athletes_tab_screen.dart` | TRAINER | **Echt verdrahtet / Demo-Fallback** | Liest `coachDashboard/{coachId}/athletes`. Wenn leer, automatischer Fallback auf 28 synthetische Demo-Athleten (`lib/features/coach_link/providers/coach_dashboard_provider.dart:43-46`). Ruft Cloud Function `createInvite` auf (`Zeile 58`). |
| `/calendar` (Tab 1) | `CalendarScreen` | `lib/features/calendar/screens/calendar_screen.dart` | BOTH | **Echt verdrahtet** | Liest und schreibt `plannedWorkouts` via `PlannedWorkoutRepository` (`lib/features/calendar/repositories/planned_workout_repository.dart:12-29`). |
| `/analysis` (Tab 2) | `AnalysisTabScreen` | `lib/features/analysis/screens/analysis_tab_screen.dart` | BOTH | **Echt verdrahtet** | Liest `users/{athleteId}/aggregates` via `AnalysisRepository` (`lib/features/analysis/repositories/analysis_repository.dart:20-26`). |
| `/templates` (Tab 3, Coach) | `WorkoutTemplateLibraryScreen` | `lib/features/workout_builder/screens/workout_template_library_screen.dart` | BOTH | **Echt verdrahtet** | Liest und schreibt `workoutTemplates` via `WorkoutTemplateRepository` (`lib/features/workout_builder/repositories/workout_template_repository.dart:12-25`). |
| Tab 3 (Athlet) | `AthleteCoachTabScreen` | `lib/features/coach_link/screens/athlete_coach_tab_screen.dart` | ATHLETE | **Nur UI / Mock** | **Reine UI:** Code-Eingabe, Verknüpfungstrennung und Berechtigungsschalter zeigen lediglich SnackBars und rufen weder Cloud Functions noch Firestore auf (`lib/features/coach_link/screens/athlete_coach_tab_screen.dart:108, 138, 203`). |
| `/workout-builder` | `WorkoutBuilderScreen` | `lib/features/workout_builder/screens/workout_builder_screen.dart` | BOTH | **Echt verdrahtet** | Erstellt geplante Einheiten (`PlannedWorkoutRepository.create`) und Vorlagen (`WorkoutTemplateRepository.createTemplate`) in Firestore (`lib/features/workout_builder/screens/workout_builder_screen.dart:491, 544`). |
| `/diagnostics` | `DiagnosticsScreen` | `lib/features/diagnostics/screens/diagnostics_screen.dart` | BOTH | **Echt verdrahtet / Fehler** | Liest `users/{athleteId}/thresholdProposals` und `thresholdHistory`. Schreibt jedoch bei Recompute in nicht autorisierte Collection `recomputeRequests` (`lib/features/diagnostics/repositories/diagnostics_repository.dart:174`). |
| `/chat/:chatId` | `ChatScreen` | `lib/features/chat/screens/chat_screen.dart` | BOTH | **Echt verdrahtet** | Liest und schreibt `chats/{chatId}/messages` und Storage via `ChatRepository` (`lib/features/chat/repositories/chat_repository.dart:20-60`). |
| `/chats` | `ChatListScreen` | `lib/features/chat/screens/chat_list_screen.dart` | TRAINER | **Echt verdrahtet** | Liest alle aktiven Chats des Trainers aus `chats` (`lib/features/chat/repositories/chat_repository.dart:27-37`). |
| `/profile` | `ProfileScreen` | `lib/features/profile/screens/profile_screen.dart` | BOTH | **Echt verdrahtet** | Liest und aktualisiert `users/{uid}`. Bild-Upload ist als TODO markiert (`lib/features/profile/screens/profile_screen.dart:32`). |
| `/thresholds` | `ThresholdsScreen` | `lib/features/profile/screens/thresholds_screen.dart` | BOTH | **Echt verdrahtet** | Liest und schreibt Schwellenwerte in `users/{uid}/thresholdHistory` (`lib/features/profile/screens/thresholds_screen.dart:88-120`). |
| `/settings` | `SettingsScreen` | `lib/features/settings/screens/settings_screen.dart` | BOTH | **Echt verdrahtet** | Aktualisiert Theme, Sprache und Datenschutzeinstellungen in `users/{uid}`. |
| `/settings/garmin` | `GarminConnectionScreen` | `lib/features/integrations/screens/garmin_connection_screen.dart` | ATHLETE | **Echt verdrahtet (Logik)** | Ruft Cloud Functions `garminAuthStart`, `garminDisconnect` auf; liest `users/{uid}/integrationStatus/garmin`. Live nicht funktionsfähig wegen fehlender Secrets. |
| *Modal / Push* | `ActivityDetailScreen` | `lib/features/activities/screens/activity_detail_screen.dart` | BOTH | **Echt verdrahtet** | Aufgerufen aus `TodayTabScreen:318`. Zeigt Aktivitätsdaten und bietet Absprung zum Cockpit sowie Löschung via Cloud Function `deleteActivity` (`Zeile 288`). |
| *Modal / Push* | `ActivityCockpitScreen` | `lib/features/activities/screens/activity_cockpit_screen.dart` | BOTH | **Echt verdrahtet / Teil-Mock** | Aufgerufen aus `ActivityDetailScreen:307`. Lädt 1Hz-Streams aus Storage (`StreamDecoder`). Karte nutzt jedoch ein Canvas-Gitter statt echter Kacheln (`telemetry_map_widget.dart:226`). |
| `/gallery` | `WidgetGalleryScreen` | `lib/core/design/widget_gallery.dart` | DEV | **Nur UI (Design-Showcase)** | Nur für Entwicklungszwecke zur Prüfung von Design-Tokens. |

---

## 4. Externe Anbindungen & Schnittstellen-Status

| Dienst / Integration | Implementiert | Gegen Emulator getestet | Live getestet | Detailbefund & Status |
|---|---|---|---|---|
| **Garmin Connect** | **Ja** | **Nein** | **Nein (nicht prüfbar)** | OAuth 1.0a Flow (`functions/src/import/garmin/auth.ts`), Webhook (`webhook.ts`) und Backfill (`backfill.ts`) sind implementiert. Keine Unit- oder Emulator-Tests in `functions/src/__tests__`. Live-Test nicht möglich, da `GARMIN_CONSUMER_KEY` und `GARMIN_CONSUMER_SECRET` im GCP Secret Manager nicht hinterlegt sind. Webhook-Payload wird zudem aktuell verworfen (`webhook.ts:51`). |
| **FCM (Firebase Cloud Messaging)** | **Ja** | **Mocks** | **Nein (nicht prüfbar)** | Client-Registrierung (`devices/{deviceId}`) und serverseitiger Versand (`admin.messaging().sendEachForMulticast` in `functions/src/chat/index.ts:132`) sind implementiert. Emulator unterstützt FCM nicht nativ (wurde im Test `chat.test.ts` gemockt). Live-Push wurde nicht verifiziert. |
| **Karten-Kacheln (Map Tiles)** | **Nein** | **Nein** | **Nein** | **Täuschung/Mock:** In `pubspec.yaml` existiert keine Kartenbibliothek (`flutter_map` fehlt entgegen ADR vom 2026-10-08). `TelemetryMapWidget` fragt per Dialog nach Zustimmung zur IP-Übertragung, zeichnet bei Aktivierung jedoch lediglich ein lokales 40-Pixel-Canvas-Gitter (`telemetry_map_widget.dart:226-236`). |
| **Firebase App Check** | **Nein (deaktiviert)** | **Nein** | **Nein** | In `pubspec.yaml` als Dependency vorhanden (`firebase_app_check: ^0.4.8`), wird jedoch in `lib/main.dart` oder sonstigem App-Code **an keiner Stelle importiert oder initialisiert**. Weder Play Integrity noch reCAPTCHA Enterprise sind scharfgeschaltet. |
| **Auth-Provider** | **Teilweise** | **Ja (Auth-Emulator)** | **Nein (nicht prüfbar)** | **E-Mail/Passwort:** Vollständig implementiert und gegen Emulator getestet (`lib/features/auth/providers/auth_provider.dart:21-31`). **Google Sign-In:** Zwar in `pubspec.yaml` deklariert (`google_sign_in: ^7.2.0`), aber im Flutter-Code **an keiner Stelle aufgerufen**. **Apple Sign-In:** Nicht implementiert. |

---

## 5. Datenmodell, Cloud Functions & Security Rules

### 5.1 Tatsächlich genutzte Collections vs. `docs/DATA_MODEL.md`

| Collection / Pfad | Im Code genutzt | In `DATA_MODEL.md` | In `firestore.rules` | Abweichung / Befund |
|---|---|---|---|---|
| `users/{uid}` | Ja | Ja | Ja | Konform. |
| `users/{uid}/thresholdHistory/{id}` | Ja | Ja | Ja | In Rules aktuell mit Vermerk `// Prototype for now` versehen (`firestore.rules:215`). |
| `users/{uid}/dailyMetrics/{date}` | Ja | Ja | Ja | In Rules mit Vermerk `// Prototype for now` (`firestore.rules:231`). |
| `users/{uid}/aggregates/{date}` | Ja | Ja | Ja | Konform (Schreibzugriff nur Cloud Functions). |
| `users/{uid}/bests/{sport}` | Ja | Ja | Ja | Konform (Schreibzugriff nur Cloud Functions). |
| `users/{uid}/thresholdProposals/{id}`| Ja | Ja | Ja | Konform (Trainer darf erstellen, Athlet aktualisieren). |
| `users/{uid}/integrationStatus/{p}` | Ja | Ja | Ja | Konform (Schreibzugriff nur Cloud Functions). |
| `users/{uid}/devices/{deviceId}` | Ja | Ja | Ja | Konform (Nutzer darf eigene FCM-Tokens verwalten). |
| `users/{uid}/notificationState/{id}` | Ja | Ja | Ja | Konform (Schreibzugriff nur Cloud Functions). |
| `users/{uid}/preferences/{prefId}` | Ja | Ja | Ja | Konform. |
| `users/{uid}/private/integrations` | Ja | Ja | Ja | Konform (Client-Zugriff durch Rules komplett gesperrt). |
| `users/{uid}/recomputeRequests/{id}` | **Ja** (`diagnostics_repository.dart:174`) | **Nein** | **Nein** | **Gravierende Abweichung:** Client schreibt in diese Collection. Fehlt in Rules (wird durch Root Deny geblockt) und wird von keiner Function verarbeitet. |
| `activities/{activityId}` | Ja | Ja | Ja | **Trigger-Diskrepanz:** Client und Rules nutzen Root-Collection. Cloud Function `activityTrigger.ts:5` lauscht jedoch fälschlicherweise auf `users/{uid}/activities/{activityId}`! |
| `plannedWorkouts/{workoutId}` | Ja | Ja | Ja | Konform. |
| `workoutTemplates/{templateId}` | Ja | Ja | Ja | Konform. Unterstützt `PRIVATE`, `SHARED_WITH_MY_ATHLETES`, `PUBLIC`. |
| `coachLinks/{linkId}` | Ja | Ja | Ja | Konform (Schreibzugriff nur Cloud Functions). |
| `invites/{code}` | Ja | Ja | Ja | Konform (Schreibzugriff nur Cloud Functions). |
| `chats/{chatId}` | Ja | Ja | Ja | Konform (Schreibzugriff nur Cloud Functions). |
| `chats/{chatId}/messages/{messageId}`| Ja | Ja | Ja | Konform (Ausschließlich Soft-Delete erlaubt). |
| `chats/{chatId}/state/{uid}` | Ja | Ja | Ja | Konform (`lastReadAt`). |
| `coachDashboard/{coachId}/athletes/{a}`| Ja | Ja | Ja | **Inhaltliche Abweichung:** `DATA_MODEL.md` definiert `formStatus: FRESH\|OPTIMAL\|TIRED\|OVERTRAINED`. Code und Function nutzen `wellLoaded\|optimal\|caution\|fresh\|building` (`functions/src/coach/dashboard.ts:14`). |
| `webhookEvents/{eventId}` | Ja | Ja | Ja | Konform (Client-Zugriff gesperrt). |

### 5.2 Alle Cloud Functions im Backend
Kompiliert aus `functions/src/index.ts` (Region global auf `europe-west3` gesetzt):

| Function Name | Exportiert | Typ / Trigger | Pfad / Event | Region | Befund / Status |
|---|---|---|---|---|---|
| `helloWorld` | Ja | HTTPS Callable | `helloWorld` | `europe-west3` | Dummy-Funktion aus `functions/src/metrics.ts`. |
| `setInitialRole` | Ja | HTTPS Callable | `setInitialRole` | `europe-west3` | Weist Rolle & Custom Claims zu. |
| `deleteAccount` | Ja | HTTPS Callable | `deleteAccount` | `europe-west3` | Rekursives Löschen aller Daten (Art. 17 DSGVO). |
| `exportAccount` | Ja | HTTPS Callable | `exportAccount` | `europe-west3` | JSON-Export (Art. 20 DSGVO). |
| `createInvite` | Ja | HTTPS Callable | `createInvite` | `europe-west3` | Erstellt 8-stelligen Einladungscode in `invites`. |
| `redeemInvite` | Ja | HTTPS Callable | `redeemInvite` | `europe-west3` | Löst Code ein und erstellt `coachLinks` transaktional. |
| `updatePermissions` | Ja | HTTPS Callable | `updatePermissions` | `europe-west3` | Aktualisiert Berechtigungen auf `coachLinks`. |
| `revokeLink` | Ja | HTTPS Callable | `revokeLink` | `europe-west3` | Trennt Trainer-Verknüpfung. Bereinigt Aktivitäten nicht. |
| `onCoachLinkChanged` | Ja | Firestore Written | `coachLinks/{linkId}` | `europe-west3` | Synchronisiert `coachDashboard/{coachId}/athletes`. |
| `onActivityCreatedForCoachDashboard` | Ja | Firestore Created | `activities/{activityId}` | `europe-west3` | Aktualisiert Trainer-Dashboard bei neuer Aktivität. |
| `seedCoachAthletes` | Ja | Helper-Export | - | - | Seed-Skript für 28 Test-Athleten. |
| `parseFitAndSave` | Ja | Helper-Export | - | - | Kein Trigger! FIT-Parser ohne Auslöser. |
| `deleteActivity` | Ja | HTTPS Callable | `deleteActivity` | `europe-west3` | Löscht Aktivität, Storage-Stream und triggert Recompute. |
| `garminAuthStart` | Ja | HTTPS Callable | `garminAuthStart` | `europe-west3` | Erfordert Secrets `GARMIN_CONSUMER_KEY/SECRET`. |
| `garminAuthCallback` | Ja | HTTPS Callable | `garminAuthCallback` | `europe-west3` | Schließt OAuth 1.0a Flow ab. |
| `garminDisconnect` | Ja | HTTPS Callable | `garminDisconnect` | `europe-west3` | Trennt Verbindung, löscht `private/integrations/garmin`. |
| `garminWebhook` | Ja | HTTPS Request | `/garminWebhook` | `europe-west3` | Öffentlicher HTTP-Endpunkt für Garmin Push-Events. |
| `garminBackfill` | Ja | HTTPS Callable | `garminBackfill` | `europe-west3` | Fordert historische Daten über Backfill-API an. |
| `onPlannedWorkoutWritten`| Ja | Firestore Written | `plannedWorkouts/{workoutId}`| `europe-west3` | Pflegt denormalisiertes `coachId`-Feld. |
| `onMessageCreated` | Ja | Firestore Created | `chats/{chatId}/messages/{msgId}`| `europe-west3` | Aktualisiert Chat-Status und sendet FCM-Push. |
| `sendChatPushNotification`| Ja | Helper-Export | - | - | Helper für FCM Multicast. |
| `sendSystemNotification` | Ja | Helper-Export | - | - | Helper für System-Pushes. |
| **`processFitUpload`** | **NEIN (FEHLT)** | Storage Finalized | `users/{uid}/fit/{file}` | `europe-west3` | **In Commit `de08c2bb` versehentlich gelöscht!** Uploaded FIT-Dateien werden nicht verarbeitet. |
| **`onActivityWritten`** | **NEIN (SHADOWED)**| Firestore Written | `users/{uid}/activities/{id}` | `europe-west3` | In `metrics/activityTrigger.ts`. Wird nicht exportiert, da `metrics.ts` den Ordner `metrics/` verdeckt. Lauscht zudem auf falschem Pfad. |
| **`recomputeMetrics`** | **NEIN (SHADOWED)**| HTTPS Callable | `recomputeMetrics` | `europe-west3` | In `metrics/recompute.ts`. Durch Namenskonflikt nicht exportiert. |

### 5.3 Rules-Matrix (Collection × Rolle)

| Collection | Unauthentifiziert | Athlet (Besitzer) | Trainer (mit Freigabe) | Fremder Athlet/Trainer | Cloud Functions (Admin SDK) |
|---|---|---|---|---|---|
| `users/{uid}` | Deny | Read, Create*, Update* | Deny | Deny | Full Access |
| `users/{uid}/private/*` | Deny | Deny | Deny | Deny | Full Access |
| `users/{uid}/dailyMetrics/*` | Deny | Read, Create, Update, Delete | Read (wenn `health == true`) | Deny | Full Access |
| `users/{uid}/aggregates/*` | Deny | Read | Read (wenn `activities == true`) | Deny | Full Access |
| `users/{uid}/bests/*` | Deny | Read | Read (wenn `activities == true`) | Deny | Full Access |
| `users/{uid}/thresholdProposals/*` | Deny | Read, Update (nur Status), Delete | Read, Create (wenn `activities == true`) | Deny | Full Access |
| `users/{uid}/thresholdHistory/*` | Deny | Read, Create, Update, Delete | Deny | Deny | Full Access |
| `users/{uid}/devices/*` | Deny | Read, Create, Update, Delete | Deny | Deny | Full Access |
| `users/{uid}/preferences/*` | Deny | Read, Create, Update, Delete | Deny | Deny | Full Access |
| `activities/{activityId}` | Deny | Read, Create, Update, Delete | Read (wenn `coachId == uid`) | Deny | Full Access |
| `plannedWorkouts/{workoutId}` | Deny | Read, Create, Update, Delete | Read, Create, Update, Delete (wenn `calendar == true`) | Deny | Full Access |
| `workoutTemplates/{templateId}` | Deny | Read, Create, Update, Delete | Read (wenn `SHARED_WITH_MY_ATHLETES` und aktiv) | Read (wenn `PUBLIC`) | Full Access |
| `coachLinks/{linkId}` | Deny | Read (wenn Beteiligter) | Read (wenn Beteiligter) | Deny | Full Access |
| `invites/{code}` | Deny | Read | Read | Read | Full Access |
| `chats/{chatId}` | Deny | Read (wenn Teilnehmer) | Read (wenn Teilnehmer) | Deny | Full Access |
| `chats/{chatId}/messages/*` | Deny | Read, Create, Soft-Delete (wenn Sender) | Read, Create, Soft-Delete (wenn Sender) | Deny | Full Access |
| `coachDashboard/{c}/athletes/*` | Deny | Deny | Read (nur eigener Coach-Ordner) | Deny | Full Access |
| `webhookEvents/*` | Deny | Deny | Deny | Deny | Full Access |

---

## 6. Prüfung unbestätigter Behauptungen (Audit & Releases)

Gegenüberstellung von Behauptungen in `docs/release/*`, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md` mit dem tatsächlichen Codebefund:

| Nr. | Dokument : Zeile | Behauptung | Tatsächlicher Befund | Verifizierungsvorschlag |
|---|---|---|---|---|
| 1 | `docs/release/PERFORMANCE.md:3` | „Flüssiges Scrollen (60/120 fps), schnelle App-Starts (< 1.5 s)..." | Es existieren keinerlei Performance-Benchmarks, Trace-Dateien oder automatisierte Startzeit-Messungen im Repository. | `flutter run --profile --trace-startup` auf Android-Referenzgerät ausführen und Traces via Chrome Tracing (`chrome://tracing`) auswerten. |
| 2 | `docs/release/PERFORMANCE.md:9-16` | „Firestore Read-Budget je Screen: Home <= 4 Reads, Kalender 1 Query..." | Zwar architektonisch so konzipiert, aber nie durch Integrationstests oder Emulator-Request-Logging verifiziert. | Integrationstest gegen den Emulator schreiben, der vor und nach Screen-Aufruf `firestore.emulator` Request-Counter abfragt. |
| 3 | `docs/release/ACCESSIBILITY.md:36` | „Sämtliche interaktiven Elemente weisen eine Mindestgröße von 48x48 dp auf." | Viele Custom-IconButtons und Tab-Elemente (z. B. in `widget_gallery.dart` oder Header-Buttons) definieren kein `minTargetSize` und wurden nie getestet. | Automatisierter Widget-Test mit `meetsGuideline(androidTapTargetGuideline)`. |
| 4 | `docs/release/ACCESSIBILITY.md:43` | „UI unterstützt Schriftgrößenskalierungen von bis zu 130% ohne Textabschneidungen." | Kein einziger Goldentest oder Widget-Test mit `textScaleFactor = 1.3` vorhanden. Einige Dialoge weisen feste Höhen auf. | Screenshot-/Golden-Tests aller Screens mit `MediaQueryData(textScaler: TextScaler.linear(1.3))` anlegen. |
| 5 | `docs/release/SECURITY_AUDIT.md:11` | „Secret Scan: Regex-Scan nach AWS, GitHub, GCP Private Keys... Keine Secrets gefunden. Status: BESTANDEN." | Wurde von früheren Agenten als Behauptung dokumentiert; kein CI-Script oder Scan-Tool (`gitleaks`, `trufflehog`) war eingerichtet. | Ausführen von `npx gitleaks detect --source .` über die gesamte Git-Historie. |
| 6 | `docs/CHECKPOINTS.md:58` & `docs/release/OPEN_ITEMS.md:15` | „AthleteCoachTabScreen um Code-Eingabe-Dialog, Bestätigungsdialog zur Verknüpfungstrennung und Berechtigungsschalter erweitert (bereinigt)." | **Falsch:** Die UI-Aktionen sind reine Mocks (zeigen nur lokale SnackBars) und sprechen weder Backend noch Firestore an (`athlete_coach_tab_screen.dart:108, 138, 203`). | Manuelle Prüfung der Datei `lib/features/coach_link/screens/athlete_coach_tab_screen.dart` und Anbindung an `redeemInvite`, `revokeLink`, `updatePermissions`. |
| 7 | `docs/DECISIONS.md:73` | „Nutzung von flutter_map mit datenschutzkonformen Tiles..." | `flutter_map` existiert nicht in `pubspec.yaml`. Die Karte ist ein CustomPainter ohne externe Kacheln (`telemetry_map_widget.dart:226`). | Entscheidung in `docs/DECISIONS.md` korrigieren: Reines Vektor-Routing ohne Kachelserver. |
| 8 | `docs/PROGRESS.md:Phase 01` & `docs/RULES_TESTPLAN.md` | „Rules-Unit-Tests gegen den Emulator (@firebase/rules-unit-testing) bestanden." | Im Repository existiert kein einziger Rules-Test. `@firebase/rules-unit-testing` ist nicht installiert. | Anlegen von `functions/src/__tests__/rules.test.ts` und Ausführung gegen `firebase emulators:start --only firestore`. |

---

## 7. Abhängigkeiten, Sicherheitsaudits & Lizenzen

### 7.1 Veraltete Abhängigkeiten (Flutter)
Befehl: `flutter pub outdated`
- **Große Versionssprünge (Major-Versionen verfügbar):**
  - `flutter_riverpod`: aktuell `2.6.1` $\rightarrow$ `3.4.3` verfügbar
  - `go_router`: aktuell `13.2.5` $\rightarrow$ `18.0.2` verfügbar
  - `fl_chart`: aktuell `0.66.2` $\rightarrow$ `1.2.0` verfügbar
  - `flutter_lints`: aktuell `3.0.2` $\rightarrow$ `6.0.0` verfügbar
- **Eingestellte Pakete („discontinued"):**
  - `build_resolvers` (discontinued)
  - `build_runner_core` (discontinued)

### 7.2 Sicherheits-Audit (Cloud Functions)
Befehl: `cd functions && npm audit`
- **Ergebnis:** **53 Schwachstellen** (15 moderate, 38 high).
- **Hauptursachen:**
  - Veraltetes `firebase-admin` (12.7.0) und abhängiges `node-forge` (High: RSA PKCS#1 v1.5 Signatur-Schwachstelle).
  - Veraltetes `uuid` (< 11.1.1, Buffer-Bounds-Check).
  - Veraltetes `micromatch` in Jest/ESLint Transitive Dependencies.

### 7.3 Lizenz-Audit & GPL-Prüfung
Überprüfung aller 133 aufgelösten Dart-Pakete (`.dart_tool/package_config.json`) und NPM-Pakete (`functions/node_modules/`):
- **GPL-Pakete in Dart/Flutter:** **0**
- **GPL-Pakete in NPM/Functions:** **0**
- **Ergebnis:** Alle verwendeten Bibliotheken nutzen zulässige Open-Source-Lizenzen (Apache-2.0, MIT, BSD-3-Clause). Es liegt kein Verstoß gegen die GPL-Regel aus `AGENTS.md` vor.

---

## 8. Web-Plattform, Hosting & Domain-Stand

### 8.1 Verzeichnis-Struktur & Diskrepanz
- **`firebase.json:8`:**
  ```json
  "hosting": {
    "public": "public",
    "rewrites": [{ "source": "/datenschutz", "destination": "/privacy/index.html" }]
  }
  ```
- **Inhalt `public/`:** Enthält statische HTML-Seiten (`index.html`, `impressum/index.html`, `privacy/index.html`, `callback/index.html`).
- **Inhalt `web/`:** Enthält das Flutter-Web-Gerüst (`index.html`, `manifest.json`, `favicon.png`) sowie `delete-account.html`.
- **Befund:** Firebase Hosting ist so konfiguriert, dass es den Ordner `public/` bereitstellt, **nicht** den Flutter-Web-Build (`build/web`) und **nicht** den Quellordner `web/`. Die für die Google Play Store Freigabe erforderliche Seite `web/delete-account.html` wird daher bei einem `firebase deploy` **nicht mit ausgeliefert**.

### 8.2 Domain- und Bereitstellungsstand
- **Hardcodierte MVP-Domain:** In `functions/src/import/garmin/auth.ts:14` ist fest hinterlegt:
  `const CALLBACK_URL = "https://orbit-app-mvp.web.app/callback/garmin";`
- **Eigene Domain:** Es ist keine produktive eigene Domain (wie `orbit-training.de`) verknüpft oder in den DNS-Einstellungen hinterlegt.
- **Aufgaben in `docs/MANUAL_STEPS.md:39-47`:**
  Alle Aufgaben bezüglich Web-Hosting, DNS-Records, App Check reCAPTCHA Enterprise und Google Sign-In Web-Credentials sind noch als **offen** markiert.

---

## 9. Nachträgliche ADR-Rekonstruktion (Phasen 01, 02, 03, 04, 06)

In `docs/DECISIONS.md` fehlten die Architekturentscheidungen für die Phasen 01, 02, 03, 04 und 06. Sie wurden nachfolgend anhand der Git-Commits und des Quellcodes rekonstruiert:

### [Rekonstruktion] Phase 01: Auth-Architektur & DSGVO-Rollenmodell
- **Datum:** 2026-10-08 (Commit `76316b7`)
- **Kontext:** Registrierung und Login von Athleten und Trainern mit DSGVO-konformer Trennung und Rollenschutz.
- **Entscheidung & Begründung:**
  1. Login ausschließlich über Firebase Auth mit E-Mail und Passwort im ersten Schritt (`auth_provider.dart`).
  2. Strikt serverseitige Rollenvergabe: Das Feld `role` kann vom Client niemals direkt in Firestore geschrieben werden (`firestore.rules:87-100`). Stattdessen setzt die Cloud Function `setInitialRole` (`functions/src/auth.ts:8`) die Rolle atomar im Firestore-Nutzerdokument und als Firebase Custom User Claim (`setCustomUserClaims`).
  3. Festhalten von Art. 9 DSGVO-Einwilligungen mit ISO8601-Zeitstempel und Schemaversion (`consents.healthData`, `consents.privacyVersion`).
  4. Bereitstellung serverseitiger Funktionen für Kontolöschung (`deleteAccount` mit `recursiveDelete`) und DSGVO-Datenexport (`exportAccount`).
- **Alternativen:** Direkter Schreibzugriff des Clients auf das Nutzerdokument mit Rollenangabe (verworfen wegen Privilege-Escalation-Gefahr).

### [Rekonstruktion] Phase 02: Inverse Coach-Verknüpfung & Granulare Freigaben
- **Datum:** 2026-10-08 (Commit `16ed00e`)
- **Kontext:** Sichere Verbindung zwischen Trainer und Athlet ohne Offenlegung aller Daten.
- **Entscheidung & Begründung:**
  1. Inverses Einladungsmodell: Trainer erzeugen einen 8-stelligen Hex-Code (`createInvite`, `functions/src/coach.ts:13`) in der Collection `invites/{code}` mit 7 Tagen Gültigkeit.
  2. Annahme ausschließlich durch den Athleten via Cloud Function `redeemInvite` (`functions/src/coach.ts:37`) in einer Firestore-Transaktion.
  3. Granulares 3-Säulen-Rechtemodell in `coachLinks/{athleteId}_{coachId}`: `permissions: { calendar: bool, activities: bool, health: bool }`. Bei Annahme ist `health` standardmäßig `false` (Art. 9 DSGVO).
  4. Firestore Security Rules sperren Client-Schreibzugriffe auf `coachLinks` komplett (`allow write: if false;`).
- **Alternativen:** Direkte Einladung per E-Mail-Suche (verworfen wegen PII-Offenlegung in Suchanfragen).

### [Rekonstruktion] Phase 03: Profil, Einstellungen & Unveränderliche Schwellenwert-Historie
- **Datum:** 2026-10-08 (Commit `fef019b`)
- **Kontext:** Verwaltung von Athletenprofilen, Einheiten und Schwellenwerten (FTP, LTHR, CSS, Pace).
- **Entscheidung & Begründung:**
  1. Trennung von Stammdaten (`users/{uid}`) und Schwellenwerten: Schwellenwerte werden in einer chronologischen Subcollection `users/{uid}/thresholdHistory/{id}` mit `effectiveFrom` gespeichert (`DATA_MODEL.md:38`).
  2. Immutabilitäts-Prinzip: Änderungen an Schwellenwerten wirken nur für zukünftige Einheiten. Historische Aktivitäten behalten ihren `thresholdsSnapshot`.
  3. Automatische Berechnung von 7 Trainingszonen nach Coggan (Power) und 5 Herzfrequenzzonen im Client (`training_zones_model.dart`).
- **Alternativen:** Überschreiben der aktuellen Schwellenwerte im Nutzerdokument (hätte historische Belastungswerte verfälscht).

### [Rekonstruktion] Phase 04: Server-seitiger FIT-Import & Speicheroptimierung
- **Datum:** 2026-10-08 (Commits `310e99e`, `6f00679`)
- **Kontext:** Import hochfrequenter FIT-Dateien (bis zu 25 MB) ohne Überlastung des mobilen Clients oder Firestore.
- **Entscheidung & Begründung:**
  1. Client lädt Rohdateien direkt in Firebase Storage hoch (`users/{uid}/fit/{activityId}.fit`).
  2. Parsing serverseitig in Node.js via `@garmin/fitsdk` mit dynamischem ESM-Import (`functions/src/import/fitParser.ts`).
  3. Resampling aller Sensorströme auf 1 Hz und komprimiertes Speichern als `users/{uid}/streams/{activityId}.json.gz` im Cloud Storage, um das Firestore 1-MB-Dokumentenlimit nicht zu verletzen.
  4. Hauptdokument in der Root-Collection `activities/{activityId}` speichert nur Zusammenfassungswerte und den Pfad zum Stream.
- **Alternativen:** Clientseitiges FIT-Parsing in Dart (verworfen wegen hohem RAM-Bedarf und App-Größe).

### [Rekonstruktion] Phase 06: Garmin Connect OAuth 1.0a & Provider-Schicht
- **Datum:** 2026-10-13 (Commit `de08c2b`)
- **Kontext:** Automatische Synchronisation von Aktivitäten und Health-Daten direkt von Garmin.
- **Entscheidung & Begründung:**
  1. 3-Wege OAuth 1.0a Flow mit HMAC-SHA1-Signierung (`functions/src/import/garmin/auth.ts`).
  2. Speicherung der Garmin User-Tokens in `users/{uid}/private/integrations/garmin`, durch Security Rules für Clients unlesbar gesperrt.
  3. Trennung des öffentlichen Status in `users/{uid}/integrationStatus/garmin` für die UI-Anzeige (`state: CONNECTED`).
  4. Bereitstellung eines öffentlichen Webhook-Endpunkts (`garminWebhook`) zur Entgegennahme von Push-Benachrichtigungen.
- **Alternativen:** Direkter Token-Austausch über den mobilen Client (verworfen, da OAuth 1.0a Client Secrets erfordert, die niemals in die App kompiliert werden dürfen).

---

## 10. Bekannte Fehler & Auffälligkeiten

1. **Functions Metrics Index Shadowing (Kritischer Backend-Bug):**
   In `functions/src/` existiert sowohl die Datei `metrics.ts` als auch das Verzeichnis `metrics/index.ts`. Der Aufruf `export * from "./metrics"` in `functions/src/index.ts:6` löst auf die Datei `metrics.ts` auf (welche nur `helloWorld` enthält). Sämtliche Funktionen aus `metrics/` (`activityTrigger.ts`, `diagnostics.ts`, `bests.ts`, `recompute.ts`, `load.ts`, `power.ts`, `zones.ts`) werden **nicht exportiert** und gelangen nicht in das Cloud-Functions-Deployment!
2. **Gelöschter FIT-Upload Storage-Trigger:**
   In Commit `de08c2bb` wurde der Cloud Storage Trigger `processFitUpload` versehentlich aus `functions/src/import/index.ts` gelöscht. Wenn ein Nutzer in der App eine `.fit`-Datei hochlädt, wird diese in Storage gespeichert, jedoch **vom Backend niemals verarbeitet**. Es wird kein `activities`-Dokument angelegt.
3. **Falscher Firestore-Pfad in `activityTrigger.ts`:**
   In `functions/src/metrics/activityTrigger.ts:5` lauscht der Trigger auf `users/{uid}/activities/{activityId}`. Aktivitäten liegen im Datenmodell und Client jedoch unter `activities/{activityId}`. Selbst wenn die Funktion exportiert würde, würde sie niemals auslösen.
4. **Hardcodierte Dummy-Werte im Metrics-Trigger:**
   In `functions/src/metrics/activityTrigger.ts:42, 56` schreibt der Trigger bei Aktivitätseingang hardcodiert `'metrics.tss': 50` und `dailyLoad: 50`. Die echte Neuberechnung von CTL/ATL ist als `// TODO` markiert.
5. **Garmin Webhook wirft Payloads weg:**
   In `functions/src/import/garmin/webhook.ts:51` ist das Parsing der eingehenden Webhook-Meldungen als `// TODO: Payload parsen` markiert.
6. **Fehlende Security Rules für `recomputeRequests`:**
   `DiagnosticsRepository` (`lib/features/diagnostics/repositories/diagnostics_repository.dart:174`) schreibt in `users/{athleteId}/recomputeRequests`. Diese Subcollection existiert weder in `docs/DATA_MODEL.md` noch in `firestore.rules` und schlägt im Emulator/Live-Betrieb mit `PERMISSION_DENIED` fehl.
7. **Fehlende Anbindung im `AthleteCoachTabScreen`:**
   Die Athletenansicht zur Trainer-Verknüpfung (`lib/features/coach_link/screens/athlete_coach_tab_screen.dart`) ist ein reiner UI-Mock. Code-Eingabe, Verknüpfungstrennung und Berechtigungsschalter rufen keine Funktionen auf.
8. **Kartenkacheln-Täuschung:**
   `TelemetryMapWidget` zeigt einen DSGVO-Einwilligungsdialog für externe Kartenkacheln, zeichnet bei Zustimmung jedoch nur Linien auf ein Canvas-Gitter. Es sind keine Kacheln angebunden.
9. **App Check & Google Sign-In ungenutzt:**
   Beide Pakete sind in `pubspec.yaml` definiert, werden im Code jedoch nicht initialisiert.
10. **Hosting-Fehlkonfiguration für `delete-account.html`:**
    `firebase.json` stellt den Ordner `public/` bereit. Die Seite `web/delete-account.html` liegt in `web/` und wird daher nicht gehostet.
11. **Diskrepanz im Form-Status Enum:**
    `docs/DATA_MODEL.md:100` definiert `FRESH | OPTIMAL | TIRED | OVERTRAINED`. Code und Cloud Function nutzen `wellLoaded | optimal | caution | fresh | building`.
12. **Verwaiste Duplikat-Ordner im Dateisystem:**
    Im Repository existieren mehrere leere bzw. duplizierte Verzeichnisse/Dateien:
    - `functions/src/__tests__ 2/`
    - `lib/features/auth/providers 2/`
    - `lib/features/auth/screens 2/`
    - `web/icons 2/`
    - `lib/firebase_options_prod 2.dart`
13. **Unsauberer Arbeitsbaum:**
    Branch `feature/phase-16-release` enthält 20 ungesicherte modifizierte Dateien und untracked Files.

---

## 11. Die 10 wichtigsten Befunde

1. **Cloud Functions Metrics-Trigger sind komplett lahmgelegt (Shadowing-Bug):**  
   Weil `functions/src/metrics.ts` neben dem Ordner `functions/src/metrics/` existiert, exportiert `index.ts` nur die Dummy-Funktion `helloWorld`. Sämtliche serverseitigen Metrik-, Diagnostik- und Aggregations-Trigger sind im kompilierten Backend nicht vorhanden.
2. **FIT-Datei-Upload ohne Backend-Verarbeitung:**  
   Der Cloud Storage Trigger `processFitUpload` wurde in Phase 06 versehentlich gelöscht. Manuell hochgeladene `.fit`-Dateien werden in Storage abgelegt, aber niemals geparst; es entsteht keine Aktivität in der App.
3. **Zero Rules-Unit-Tests trotz gegenteiliger Doku:**  
   Trotz des 833 Zeilen langen `docs/RULES_TESTPLAN.md` existiert kein einziger automatisierter Rules-Test im Repository, und `@firebase/rules-unit-testing` ist nicht in `package.json` installiert.
4. **Trainer-Verknüpfung aus Athletensicht ist ein reiner UI-Mock:**  
   Im Screen `AthleteCoachTabScreen` sind Einladungscode-Eingabe, Trennung vom Trainer und die Art. 9 DSGVO-Freigabeschalter reine Attrappen (SnackBars). Ein Athlet kann sich im aktuellen Frontend weder mit einem Trainer verbinden noch Rechte entziehen.
5. **Garmin Connect nicht funktionsfähig:**  
   Die Garmin-Anbindung besitzt weder konfigurierte Secrets im Secret Manager noch einen Payload-Parser im Webhook (`TODO` in `webhook.ts:51`). Ein Live-Test fand nicht statt.
6. **7 fehlschlagende Unit-Tests & 36 Linter-Warnungen:**  
   `flutter test` bricht mit 7 Fehlern ab (Chat-Serialisierung und 6 Workout-Builder/Parser-Tests). `flutter analyze` meldet 36 Warnungen (darunter unzulässige Aufrufe geschützter StateNotifier-Members).
7. **Kartenkacheln existieren nicht (Canvas-Grid-Fake):**  
   Entgegen den Spezifikationen und dem Nutzer-Einwilligungsdialog existiert keine Kartenbibliothek (`flutter_map` fehlt in `pubspec.yaml`). Es wird lediglich ein 40px-Canvas-Gitter gerendert.
8. **Phasen 04 bis 16 nie in `main` gemergt:**  
   Der Branch `main` steht unverändert auf Stand von Phase 03 (2026-10-08). 13 Phasen und 15 Commits sind ungemergt; es existieren keinerlei Git-Tags.
9. **Sicherheits- und DSGVO-Lücke bei Trainer-Trennung:**  
   In `functions/src/coach.ts:125, 164` ist vermerkt, dass bei Berechtigungsentzug oder Trennung das Feld `coachId` auf bestehenden Aktivitäten und Plänen nicht auf `null` gesetzt wird. Der Trainer behält unberechtigten Lesezugriff auf historische Daten.
10. **Fehlkonfiguration bei Kontolöschungs-Webseite:**  
    `web/delete-account.html` (Play Store Pflicht) wird nicht bereitgestellt, da `firebase.json` ausschließlich den Ordner `public/` hostet. Zudem weist `functions` laut `npm audit` 53 Sicherheitslücken auf.
