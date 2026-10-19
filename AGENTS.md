# AGENTS.md — Verbindliches Regelwerk für KI-Entwicklungsagenten (ORBIT)

## 1. Projekt-Identität & Zielsetzung
- **Projekt:** ORBIT (`app.orbit.training`) — High-End Performance-, Telemetrie- & Health-Plattform für Ausdauersportler (Rad, Lauf, Schwimmen, Triathlon) und deren Vereinstrainer.
- **Vorbilder:**
  - **UI & Coaching-Erlebnis:** MATS.coach (Mobile-First, aufgeräumt, klare Athlet-Trainer-Interaktion).
  - **Leistungsdiagnostik:** GoldenCheetah (wissenschaftliche Tiefe bei CP, W′bal, PMC, Aero/Decoupling — **ACHTUNG: GPL v2! Niemals Code kopieren, nur öffentliche sportwissenschaftliche Formeln selbst implementieren!**).
  - **Recovery & Health:** Whoop-inspirierte Tagessteuerung (3 Ringe, 30-Tage-Baselines, Schlafschuld — **ACHTUNG: Keine geschützten Whoop-Begriffe wie „Strain“ oder „Whoop Recovery“ nutzen! Eigene 0–100 Skalen verwenden!**).
- **Aktuelles Hauptziel:** Absturzfreier, DSGVO-konformer **Google Play Store Closed Beta Launch zum 31.10.** (inkl. Firebase App Distribution Vorab-Test mit 5–10 Vereinsathleten + Trainer).

---

## 2. Eiserne Arbeitsregeln (Zero-Trust & Anti-Mock Policy)

### Regel 0: Oberstes Gesetz — Strikte Einzel-Verifikation & Verbot von Schein-Fixes
- **Verbot von Sammel-Abnahmen & Schein-Fixes:** Eine Funktion gilt NIEMALS als erledigt, nur weil ein Dialog aufgeht oder ein Unit-Test grün ist.
- **Verbot von verschluckten Fehlern (`catch (_) {}` oder Fake-Success-Responses):** Kein API- oder Datei-Fehler darf im Code stillschweigend abgefangen und als Erfolg getarnt werden.
- **Echter End-to-End-Beweis auf dem Pixel 10 Pro:** Bei jedem Datei- oder Sync-Feature muss der komplette Pfad bis zum fertig gerenderten Datensatz in Firestore UND im UI auf dem Pixel 10 Pro durchlaufen sein!

### Regel 1: Kein Autopilot über STOPP-Punkte hinweg
- Jede Phase von **Phase 17 bis Phase 24** besitzt explizite **STOPP-Punkte**.
- An einem STOPP-Punkt **MUSS** der Agent die Ausführung beenden, die geforderten Nachweise in `CHECKPOINTS.md` eintragen und auf die explizite Freigabe durch Tim warten.
- **STRENG VERBOTEN:** Der Agent darf niemals eine Benutzer-Freigabe oder ein Release-Gate selbst als `[x]` abhaken!

### Regel 2: Beweispflicht statt Selbstauskunft (Evidence-Only)
- Aussagen wie *„Tests sind grün“*, *„Garantiert ≤ 16 ms Frame-Zeit“*, *„Rules sind sicher“* oder *„Keine Linter-Fehler“* sind **wertlos und verboten**, solange nicht die **exakte Terminal-Befehlsausgabe** (Command + Output) in `CHECKPOINTS.md` dokumentiert ist.
- Was in der aktuellen Umgebung nicht live getestet werden kann (z. B. echte Garmin-Prod-Webhooks vor Hinterlegung der Secrets), MUSS zwingend als **`[NICHT PRÜFBAR IN LOKALER UMGEBUNG – ERFORDERT LIVE-TEST]`** markiert werden.

### Regel 3: Absolutes Mock- und Platzhalter-Verbot im Produktionscode
- Im Rahmen des Audits (`docs/beta/BASELINE.md`) wurden gravierende Fassaden aufgedeckt (Dummy-SnackBars im `AthleteCoachTabScreen`, 40px-Canvas-Gitter statt `flutter_map`, verworfene Webhooks in `webhook.ts`).
- Ab Phase 17 gilt: **Keine UI-Attrappen, keine Fake-SnackBars, keine stillschweigend verworfenen Payloads und keine ungelösten `TODO`-Kommentare** in abgenommenen Phasen! Jeder Button in der UI muss mit echter Riverpod-/Backend-Logik verdrahtet sein.

### Regel 4: Pflicht-Verifikation der Cloud Functions Exporte
- Um Typescript-Shadowing-Bugs (wie `metrics.ts` vs. `metrics/`) auszuschließen, muss nach jeder Änderung im Ordner `functions/` kompiliert (`npm --prefix functions run build`) und der reale Export-Baum geprüft werden:
  ```bash
  node -e "console.log(Object.keys(require('./functions/lib/index.js')))"
  ```

### Regel 5: Strikte Phasen-, To-Do- & Git-Merge-Disziplin (Kein Branch-Aufstau!)
- Es darf niemals über mehrere Phasen hinweg auf einem einzigen Sammel-Branch ohne Merge gearbeitet werden.
- Am Ende **jeder einzelnen Phase** (und jedes abgeschlossenen Reparatur-Pakets) gilt zwingend und ohne dass Tim es extra im Prompt erwähnen muss:
  1. Alle erledigten Punkte in `docs/phases/phase_XX.md`, `PROGRESS.md` und `docs/PROGRESS.md` auf `[x]` setzen.
  2. Nachweise in `docs/CHECKPOINTS.md` eintragen.
  3. Sauberen Commit erstellen, **Fast-Forward-Merge in `main`** durchführen, annotiertes **Git-Tag (`v0.XX.0`)** setzen und `main` inkl. Tags **sofort zu GitHub pushen (`git push origin main --tags`)**.

### Regel 6: Durchgängige deutsche Code-Kommentarpflicht (`///` & `/** ... */`)
- Jede neu erstellte oder geänderte Datei, Klasse, Provider-Logik, Cloud Function und Security Rule (`firestore.rules`, `storage.rules`) MUSS mit verständlichen **deutschen Dokumentations-Kommentaren** versehen werden.
- Kommentiere immer das **„Was & Warum“**: Welchen fachlichen Zweck erfüllt die Datei? Welche sportwissenschaftliche Formel oder Schwellenwert-Grenze wird berechnet? Warum erlaubt oder blockiert eine Sicherheitsregel den Zugriff?

### Regel 7: Zentrale Sprach- & Farb-Indizes (Zero Hardcoding)
- Keine hartcodierten UI-Texte oder willkürlichen Hex-Farben in Widgets! Alle Farben laufen über zentrale Design-Tokens (`#001F47` Navy, `#CDFB17` Volt etc. aus `AppColors`) und alle Texte über den zentralen Sprach-Index (`AppStrings` / `.arb` DE/EN).

### Regel 8: Verständlicher Datenschutz, Marken-Reinheit & Zero-Open-Data
- In Nutzertexten niemals Technik-Jargon (`europe-west3`, `JSON`, `Secret Manager`, `Art. 9 DSGVO`) verwenden, sondern klares Deutsch (*„Sicherer Serverstandort Deutschland – Geschützt nach deutschen & europäischen Datenschutzgesetzen“*).
- Keine fremden geschützten Markenbegriffe (`TSS®`, `IF®`, `NP®`) nutzen, sondern eigenes ORBIT-Wording (z. B. ORBIT Belastung / Load, Intensität, Normalisierte Leistung).
- Niemals dürfen Nutzer-, Gesundheits- oder Trainingsdaten ungeschützt im Internet liegen.

### Regel 9: Automatischer Qualitäts-Gate vor Merge (`scripts/check_phase_ready.sh`)
- Vor jedem Phasen-Merge muss `bash scripts/check_phase_ready.sh` erfolgreich durchlaufen:
  1. `flutter analyze` 0 Errors, 0 Warnings.
  2. Alle geänderten `.dart`- und `.ts`-Dateien besitzen deutsche Dokumentations-Kommentare (`///` bzw. `/**`).
  3. `PROGRESS.md` und Phasendatei sind auf aktuellem Stand abgehakt.

---

## 3. Technischer Rahmen
- **Stack:** Flutter/Dart (Android > iOS > Web/Desktop), Firebase (Auth, Firestore, Storage, Cloud Functions 2nd Gen in TypeScript, FCM, App Check, Crashlytics).
- **Region:** Alle Cloud Functions, Firestore- und Storage-Ressourcen laufen ausschließlich in **`europe-west3` (Frankfurt)**. Abweichende Regionen sind verboten (DSGVO).
- **Kommentare auf Deutsch, Bezeichner auf Englisch.** Jede öffentliche Klasse/Funktion erhält einen `///`- bzw. `/** */`-Kommentar (Zweck, Parameter, Besonderheiten). Formeln stehen im Kommentar.
- **Pflicht-Befehle vor jedem Commit:** `dart format .` · `flutter analyze` (0 Errors, 0 Warnings) · `flutter test` · `npm --prefix functions run build && npm --prefix functions test` · Rules-Tests gegen den Emulator (`firebase emulators:exec --only firestore,storage "npm --prefix functions run test:rules"`).

## 4. Datenschutz (DSGVO)
- Gesundheitsdaten sind **Art. 9 DSGVO**: ausdrückliche Einwilligung (Zeitstempel + Version), funktionierende Löschung und Export.
- Trainer sehen Athletendaten **nur bei aktiver Verknüpfung und granularer Freigabe** des Athleten. Nach Trennung oder Widerruf endet der Zugriff **sofort** (per Rules-Test bewiesen).
- Keine personenbezogenen oder Gesundheitsdaten in Logs, Crash-Reports oder Push-Texten. Keine Laufzeit-Abrufe von Google Fonts. Drittanbieter (z. B. Karten-Kacheln, Crashlytics) nur mit Opt-in.

## 5. Sicherheit
- **Niemals Secrets committen** (API-Keys, Consumer-Secrets, Signing-Keys, Service-Accounts). Secrets ausschließlich über den GCP **Secret Manager** (`defineSecret`). `.env`-, `key.properties`- und Service-Account-Dateien werden vom Agenten nicht gelesen.
- Rollen `ATHLETE` / `TRAINER`. **`role`, `coachId`, `trainerVerified`, berechnete Metriken und Verknüpfungsstatus sind nie vom Client schreibbar** (nur Cloud Functions).
- Firestore-/Storage-Rules: Standard „deny all“, jede Freigabe explizit und durch einen automatisierten Emulator-Test belegt.

## 6. Git-Workflow
- **Jede Phase erhält einen eigenen Branch** `feature/phase-NN-kurzname`, abgezweigt vom aktuellen `main`. Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
- Kein Force-Push, kein Direkt-Commit auf `main`.
- **Am Phasenende wird der Branch in `main` gemergt** (bevorzugt Fast-Forward), sobald Tim den finalen STOPP-Punkt freigegeben hat. Danach Tag `v0.NN.0` setzen und `main`, Branch und Tag auf GitHub pushen.

## 7. Referenzdokumente
- `docs/PROGRESS.md` (Stand), `docs/phases/phase_NN.md` (aktive Phase ab 17), `docs/CHECKPOINTS.md` (Nachweise), `docs/DECISIONS.md` (ADRs), `docs/beta/BASELINE.md` (Audit).
- **`docs/DESIGN.md`** (vor jeder UI-Arbeit) und **`docs/DATA_MODEL.md`** (vor jeder Firestore-, Rules- oder Functions-Arbeit) bleiben verbindlich, sind aber **in Überarbeitung**: Sie weichen an einigen Stellen vom Code ab (siehe `docs/beta/BASELINE.md`). Bei Widerspruch gilt: Abweichung in `docs/DECISIONS.md` festhalten und das Dokument im selben Commit korrigieren.
- Änderungen an `AGENTS.md`, `.agents/rules/` und `.agents/skills/` nur mit Freigabe durch Tim.
