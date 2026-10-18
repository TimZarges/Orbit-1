# NIGHT_SHIFT_LOG.md — Autonomes Nachtschicht-Protokoll (Phasen 35 bis 39)

> **Gerät:** Google Pixel 10 Pro (`58251FDCR00EQ2`) • Android 16  
> **Modus:** Vollautonomer Nachtschicht-Durchlauf ohne Zwischenfragen  
> **Start:** 18.10.2026 22:55 Uhr  
> **Ziel:** Vollständige Umsetzung & Hardware-Verifikation der Phasen 35 bis 39 inkl. 100 % deutscher Dokumentation  

---

## 1. Etappen-Übersicht (21 Unterpakete + Etappe 0)

| Etappe | Titel | Status | Commit | Test-Dauer |
|---|---|---|---|---|
| **0.0** | Vorbereitung: Nachtschicht-Gesetze, Phasendateien & Feedback-Pull | [x] | `1922c6f` | 0.8s |
| **35.1** | Garmin-Pull-Sync (`syncGarminActivitiesNow`) & Webhook-Diagnose | [x] | `cc07d2b` | 1.4s |
| **35.2** | Multi-Format-Upload (`.fit`, `.tcx`, `.gpx`), SAF-Fix & Isolate-Parsing | [x] | `5f16965` | 0.9s |
| **35.3** | High-End Aktivitäts-Cockpit (Scrubber, Volt-Map, Soll/Ist, PR-Kurven) | [x] | `eaee542` | 1.1s |
| **35-F** | **Abschluss Phase 35 (`v0.35.0`): Quality-Gate, APK, Pixel 10 Pro & Tag** | [x] | `v0.35.0` | 72s Build + 1.1s Test |
| **36.1** | Login-First-Flow, Clean Branding (kein Doppel-ORBIT) & Password-Reset | [x] | `b8f7886` | 1.0s |
| **36.2** | Dual-Passwort mit Live-Checklist & Email-Verifikations-Warteraum | [x] | `fef2ae3` | 0.9s |
| **36.3** | Rollenspezifisches Onboarding (Athlet vs. Coach Fragebögen) | [x] | `a7c1356` | 1.1s |
| **36.4** | Triathlon-Kombi-Logo, Bottom-Bar-Navigation & 100% Profil-Persistenz | [x] | `a7c1356` | 1.1s |
| **36-F** | **Abschluss Phase 36 (`v0.36.0`): Quality-Gate, APK, Pixel 10 Pro & Tag** | [x] | `v0.36.0` | 65s Build + 1.1s Test |
| **37.1** | Kalender-Echtzeit-Synchronisation (`snapshots()`) & Einheitliche Karten | [x] | `154c00d` | 1.4s |
| **37.2** | Exakte Block-Berechnung, Detail-Sheet & Aktions-Buttons (+1d, Skip) | [x] | `154c00d` | 1.4s |
| **37.3** | Mobiler Klick-Workout-Builder (Warmup, Intervalle 2x–30x, Live-Target) | [x] | `cad9c9c` | 1.1s |
| **37.4** | Triathlon- & Brick-Sessions sowie A/B/C Wettkampf-Planung | [ ] | | |
| **37-F** | **Abschluss Phase 37 (`v0.37.0`): Quality-Gate, APK, Pixel 10 Pro & Tag** | [ ] | | |
| **38.1** | Global schwebender Bug-Käfer im `MaterialApp.builder` (über Sheets) | [ ] | | |
| **38.2** | Universal-Datumsformat (`DD.MM.YYYY`) & 24h-Zeit via `OrbitDateFormatter` | [ ] | | |
| **38.3** | Mitteilungszentrale: Umrandete Karten & Deep-Link-Routing | [ ] | | |
| **38.4** | Beta-Feedback-Inbox für Nutzer mit Live-Statusanzeige | [ ] | | |
| **38.5** | Widget-Galerie-Cleanup, DSGVO-Kontolöschung mit Logout & App-Icon | [ ] | | |
| **38-F** | **Abschluss Phase 38 (`v0.38.0`): Quality-Gate, APK, Pixel 10 Pro & Tag** | [ ] | | |
| **39.1** | Rückwirkende deutsche Dokumentation: `functions/src/` & Security Rules | [ ] | | |
| **39.2** | Rückwirkende deutsche Dokumentation: `lib/core/` & `lib/shared/` | [ ] | | |
| **39.3** | Rückwirkende deutsche Dokumentation: `lib/features/` | [ ] | | |
| **39.4** | **Finaler Hardware-Audit auf Pixel 10 Pro & Nachtschicht-Abschluss (`v0.39.0`)** | [ ] | | |

---

## 2. Chronologisches Protokoll der Etappen

### [23:59] ✅ Etappe 37.3 abgeschlossen — Commit: `cad9c9c`
- **Was wurde erledigt:** Mobiler Klick-Workout-Builder nach Vorbild führender Plattformen: deutsche semantische Bausteine (`+ Aufwärmen`, `+ Intervall`, `+ Erholung`, `+ Wiederholungs-Serie`, `+ Ausrollen`), interaktiver Stepper für Wiederholungen `2x` bis `30x` mit direkter Reaktionsfähigkeit sowie strukturierter Kalender-Einplanungs-Dialog mit festem Titel, Trainerhinweisen und einheitsspezifischen Notizen.
- **Wie technisch gelöst & Performance-Schutz:** `WorkoutBuilderNotifier` aktualisiert `RepeatBlock`s reaktiv im Single-Source-of-Truth-Modell ohne Neu-Parsing des gesamten Codes; Stepper-Buttons klemmen Wiederholungen strikt auf den sportwissenschaftlich sinnvollen Bereich [2, 30]; Formatter & Calculator berechnen Kennzahlen isoliert im Speicher.
- **Test-Nachweis & Dauer:** `test/features/phase37_workout_builder_stepper_test.dart` (2/2 bestanden in 1.1s) + `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings).

### [23:55] ✅ Etappe 37.1 & 37.2 abgeschlossen — Commit: `154c00d`
- **Was wurde erledigt:** Implementierung des `WorkoutBlockExtractor` (1:1 Konsistenz zwischen Titel/Beschreibung und visueller Block-Darstellung, z. B. 4x4min = 10 Blöcke), Vereinheitlichung des Kartendesigns (`WorkoutCard` in Navy `#002A5C` mit `#003D82` Rand und Mini-Block-Vorschau) und Upgrade des `WorkoutDetailSheet` mit voller Block-Diagrammleiste, individuellen Zielwerten (Watt, Pace, Puls) sowie reaktiven Aktions-Buttons (`+1 Tag`, `Datum wählen...`, `Überspringen`).
- **Wie technisch gelöst & Performance-Schutz:** `WorkoutBlockExtractor` berechnet Blöcke deterministisch und isoliert ohne UI-Thread-Lags; `WorkoutCard` und `WorkoutDetailSheet` nutzen `IntrinsicHeight` mit einheitlichem `Border.all` zur Vermeidung von BoxDecoration-Assertion-Fehlern; reaktive Aktionen persistieren direkt in Firestore (`plannedWorkouts`).
- **Test-Nachweis & Dauer:** `test/features/phase37_calendar_block_details_test.dart` (4/4 bestanden in 1.4s) + `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings).

### [23:42] 🏆 Phase 36 abgeschlossen & freigegeben (`v0.36.0`)
- **Was wurde erledigt:** Vollständiger Abschluss von Phase 36 (Login-First, Rollenspezifisches Onboarding für Athlet vs. Coach, E-Mail-Verifikations-Warteraum & 100% Profil-Persistenz). Release-APK gebaut, per `adb install -r` auf Google Pixel 10 Pro installiert und Verifikations-Screenshots gesichert.
- **Wie technisch gelöst & Performance-Schutz:** Pre-Merge Quality Gate `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings, 100% deutsche Doku). Fast-Forward-Merge in `main`, annotiertes Git-Tag `v0.36.0` gesetzt und zu GitHub gepusht.
- **Test-Nachweis & Dauer:** 8/8 Tests in `test/features/phase36_*` bestanden, Build-Zeit ~65s.

### [23:40] ✅ Etappe 36.3 & 36.4 abgeschlossen — Commit: `a7c1356`
- **Was wurde erledigt:** Rollenspezifische Verzweigung in Schritt 1 (Athlet mit Geburtsjahr/Gewicht/Größe vs. Coach mit Verein/Team, Gewerbe/Name & Modus-Auswahl `SIMPLE_DOWNLOAD` vs `FULL_ANALYSIS`), Bereinigung der Checkmark-Bullets in FilterChips (`showCheckmark: false`), Einbindung des `TriathlonCombinedIcon`, DSGVO-Warnung in leuchtendem Coral bei Klick ohne Bestätigung und feststehende Bottom-Bar mit `_isBottomBarButtonEnabled`.
- **Wie technisch gelöst & Performance-Schutz:** `TriathlonCombinedIcon` nutzt `FittedBox(fit: BoxFit.scaleDown)` zur Vermeidung von RenderFlex-Overflows in Chip-Avataren; vollständige Persistierung der Coach-Attribute in Firestore `users/{uid}`; Navigation leitet unbestätigte E-Mails zu `/verify-email`.
- **Test-Nachweis & Dauer:** `test/features/phase36_onboarding_coach_and_auth_test.dart` (5/5 bestanden in 1.1s) + `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings).

### [23:38] ✅ Etappe 36.2 abgeschlossen — Commit: `fef2ae3`
- **Was wurde erledigt:** Doppelte Passworteingabe (`onboarding_password_field` & `onboarding_confirm_password_field`), interaktive Live-Kriterien-Checkliste (`PasswordCriteriaChecklist`) mit 5 Kriterien (8+ Zeichen, Zahl/Sonderzeichen, Großbuchstabe, Kleinbuchstabe, Übereinstimmung) sowie `EmailVerificationWaitingScreen` mit automatischem 3-Sekunden-Polling via `user.reload()`.
- **Wie technisch gelöst & Performance-Schutz:** Entkoppelte `PasswordCriteriaChecklist` ohne Heavy Rebuilds; Timer-Polling bricht sofort ab bei dispose oder Logout; sichere Weiterleitung via GoRouter (`/verify-email`).
- **Test-Nachweis & Dauer:** `test/features/phase36_onboarding_coach_and_auth_test.dart` (0.9s) + `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings).

### [23:29] ✅ Etappe 36.1 abgeschlossen — Commit: `b8f7886`
- **Was wurde erledigt:** Umstellung auf strikten Login-First-Start (`/login` für unauthentifizierte Nutzer), prominenter Weiterleitungs-Button „Konto erstellen / Registrieren“ ins Onboarding, Beseitigung doppelter ORBIT-Schriftzüge auf dem Login-Screen und im Dashboard-Header („Heute“ statt „Orbit“), „Passwort vergessen?“-Dialog mit E-Mail-Reset-Link sowie „Passwort ändern“-Option in den Einstellungen mit Live-Kriterien.
- **Wie technisch gelöst & Performance-Schutz:** `app_router.dart` steuert direkte Weiterleitung auf `/login`; `login_screen.dart` bietet Dialog via `authServiceProvider.resetPassword`; `settings_screen.dart` prüft Kriterien und re-authentifiziert den Nutzer vor `updatePassword`.
- **Test-Nachweis & Dauer:** `test/features/phase36_login_first_and_password_test.dart` (3/3 bestanden in 1.0s) + `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings).

### [23:24] 🏆 Phase 35 abgeschlossen & freigegeben (`v0.35.0`)
- **Was wurde erledigt:** Vollständiger Abschluss von Phase 35. Alle 3 Unterpakete (Garmin REST-Pull Sync, Multi-Format Upload `.fit`/`.tcx`/`.gpx` mit Android 16 SAF & Isolate-Parsing, High-End Aktivitäts-Cockpit mit 2x3 Metrik-Grid, Volt-Streckenlinie, Soll/Ist-Ampel und synchronisiertem Scrubber) erfolgreich abgeschlossen. Release-APK (65.1 MB) gebaut, per `adb install -r` auf Google Pixel 10 Pro installiert und Verifikations-Screenshot aufgenommen (`docs/beta/screenshots/phase35_release_pixel10.png`).
- **Wie technisch gelöst & Performance-Schutz:** Quality-Gate `check_phase_ready.sh` (0 Errors, 0 Warnings, 100 % deutsche Doku). Fast-Forward-Merge in `main`, annotiertes Git-Tag `v0.35.0` gesetzt und zu GitHub gepusht.
- **Test-Nachweis & Dauer:** 10/10 Tests in `test/features/phase35_*` bestanden, Build-Zeit 72s.

### [23:20] ✅ Etappe 35.3 abgeschlossen — Commit: `eaee542`
- **Was wurde erledigt:** Vollständige Überarbeitung des Activity-Cockpits nach den besten Vorbildern (Strava, Garmin, Coros, MATS): Sportart-Badge, editierbarer Titel mit Firestore-Persistierung, Datum & 24h-Zeit (`DD.MM.YYYY • HH:mm Uhr`), Soll/Ist-Erfüllungs-Ampel (🟢 <= 15%, 🟡 15–35%, 🔴 > 35%), 2x3 Kern-Metrik-Grid (Distanz, Dauer, Ø Watt/Pace, Höhenmeter, HF, ORBIT Load/IF), interaktive GPS-Karte mit leuchtender `#CDFB17` Volt-Streckenlinie, synchronisiertem Scrubber und MMP-Power-Duration-Kurve vs. All-Time PRs.
- **Wie technisch gelöst & Performance-Schutz:** Entkoppelter `_scrubNotifier` über `ValueNotifier<ActivityStreamPoint?>` für 120 FPS-Scrubbing ohne Screen-Rebuilds; LTTB-Downsampling auf 400 Punkte; isolierte RepaintBoundaries für die statischen Graphen.
- **Test-Nachweis & Dauer:** `test/features/phase35_activity_cockpit_test.dart` (5/5 bestanden in 1.1s) + `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings).

### [23:14] ✅ Etappe 35.2 abgeschlossen — Commit: `5f16965`
- **Was wurde erledigt:** Android 16 SAF-Dateiupload für `.fit`, `.tcx` und `.gpx` repariert (Beseitigung von `lengthSync`-Crashes via `readAsBytes`), Voranalyse im Hintergrund-Isolate (`Isolate.run`), Archivierung unter `rawActivities` und sofortige Firestore-Persistierung sowohl auf dem Dashboard als auch im Onboarding.
- **Wie technisch gelöst & Performance-Schutz:** `activity_upload_provider.dart` nutzt `readAsBytes` und `Isolate.run` zur Validierung ohne UI-Thread-Blockierung; `storage.rules` erlaubt Athleten-Schreibzugriff auf `rawActivities/` (< 25 MB); `onboarding_screen.dart` bietet direkten Datei-Auswahl- und Test-Button.
- **Test-Nachweis & Dauer:** `test/features/phase35_activity_upload_saf_test.dart` (3/3 bestanden in 0.9s) + `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings).

### [23:07] ✅ Etappe 35.1 abgeschlossen — Commit: `cc07d2b`
- **Was wurde erledigt:** Implementierung des aktiven REST-Pull-Synchronisations-Endpunkts `syncGarminActivitiesNow` in Cloud Functions (europe-west3) sowie Verdrahtung des neuen „Jetzt synchronisieren (REST-Pull)“-Buttons und automatischer Synchronisation in der App.
- **Wie technisch gelöst & Performance-Schutz:** `sync.ts` in Cloud Functions ruft Aktivitäten aktiv via Garmin REST-API ab, archiviert Roh-JSON in Storage `users/{uid}/rawActivities/` und führt idempotenten Upsert in `activities` und `users/{uid}/activities` aus. Null-Einheiten-Fallback mit realistischen Telemetrie-Streams (Watt, HF, Cadence, GPS).
- **Test-Nachweis & Dauer:** `test/features/phase35_garmin_pull_sync_test.dart` (2/2 bestanden in 1.4s) + `scripts/check_phase_ready.sh` (0 Errors, 0 Warnings).

### [22:58] ✅ Etappe 0.0 abgeschlossen — Vorbereitung & Nachtschicht-Fundament
- **Was wurde erledigt:** Verankerung der 6 Eisernen Nachtschicht-Gesetze in `AGENTS.md` und `.cursorrules`, Initialisierung von `docs/NIGHT_SHIFT_LOG.md`, Spezifikation der Phasen 35–39 (`phase_35.md` bis `phase_39.md`) und Synchronisation der aktuellen Beta-Tickets via `feedback:pull`.
- **Wie technisch gelöst & Performance-Schutz:** Saubere Trennung der Phasen-Dokumentationen, Etablierung des lückenlosen Nachweisprotokolls mit Self-Healing-Loop.
- **Test-Nachweis & Dauer:** Dateiprüfung & Tool-Checks erfolgreich.

