# AGENTS.md – ORBIT

ORBIT ist eine Mobile-First-Trainingsplattform für Ausdauersportler (Schwerpunkt Triathlon: Schwimmen, Rad, Lauf; zusätzlich Kraft). Nutzer sind Athleten und Trainer, vom Hobbysportler bis zum Leistungssportler. Leitprinzip: **einfach zuerst, Details eine Ebene tiefer** (Progressive Disclosure).

## Arbeitsweise (wichtig)
- Stand: `docs/PROGRESS.md`. Plan: `docs/ROADMAP.md`. Aktive Phase: `docs/phases/phase-NN-*.md`.
- **Eine Phase pro Unterhaltung.** Standard (`/phase-start`): Arbeite selbstständig, **stoppe aber an jedem `STOPP`-Punkt** der Phasendatei: kurz zusammenfassen, dann auf mein „weiter" warten. **Autopilot (`/phase-run`):** STOPP-Punkte werden zu Einträgen in `docs/CHECKPOINTS.md`, du hältst nur bei harten Blockern an (Regeln im Skill). Starte `/goal` oder `/teamwork-preview` nie eigenmächtig.
- Alle Phasen 00–16 sind vorab in `docs/phases/` geplant. Pläne können veralten: **Plan-Check vor jeder Phase** (Phasendatei gegen Code und `docs/DECISIONS.md` prüfen). Fehlt eine Phasendatei, schreibe keinen Code, sondern erstelle zuerst den Plan (Skill `/phase-plan`). Pläne liegen als Datei in `docs/phases/`, nicht nur als Artefakt.
- Nachfragen nur bei echten Blockern (fehlende Zugangsdaten, Widersprüche mit großer Tragweite). Sonst pragmatisch entscheiden, Annahme in `docs/DECISIONS.md` festhalten, weitermachen.
- Alles, was nur ich tun kann (Konsolen, Schlüssel, Anträge), trägst du in `docs/MANUAL_STEPS.md` ein und sagst es mir klar.
- **Ändere `AGENTS.md`, `.agents/rules/` und `.agents/skills/` nie ohne meine Freigabe.** Auch `/learn` darf Regeln nur vorschlagen, nicht schreiben.
- Nur ein Agent gleichzeitig am Repository. Keine parallelen Agenten auf demselben Branch.

## Detailwissen (wird bei passenden Dateien automatisch geladen, sonst bei Bedarf selbst lesen)
- `docs/DESIGN.md`: **vor jeder UI-Arbeit** (Regel `.agents/rules/design.md`)
- `docs/DATA_MODEL.md`: **vor jeder Firestore-, Rules- oder Functions-Arbeit** (Regel `.agents/rules/data-and-security.md`)
- `docs/specs/METRICS.md`: bei Kennzahlen und Score · `docs/specs/GARMIN.md`: bei Garmin/Import · `docs/specs/WORKOUT_SYNTAX.md`: bei Workout Builder
- `docs/REQUIREMENTS.md`: Produktanforderungen · `docs/MANUAL_STEPS.md`: Aufgaben für mich

## Stack
- Flutter/Dart (`sdk ^3.11.1`). Prioritäten: **Android > iOS > Web/Desktop**. Kein Offline-Modus nötig.
- Firebase: Auth, Firestore, Storage, Cloud Functions (TypeScript, 2nd Gen), FCM, App Check, Crashlytics. Region **`europe-west3`** (DSGVO).
- Zwei Firebase-Projekte (dev/prod) mit Flavors. Entwicklung gegen den **Emulator**.
- Anbieterneutrale `ProviderConnector`-Schicht. Garmin zuerst, Strava u. a. später. Kein Stripe/Bezahlmodell (Datenmodell offen halten, nichts bauen).

## Befehle
- `flutter pub get` · `flutter analyze` (null Warnungen) · `flutter test` · `dart format .`
- Functions: `cd functions && npm ci && npm run build && npm test`
- Emulatoren: `firebase emulators:start`. Rules-Tests laufen gegen den Emulator.
- Terminal-Sandbox: Befehle mit Netzwerk (`pub get`, `npm ci`, Emulator, `adb`) laufen außerhalb der Sandbox. Das ist normal. Sie sind in meinen Antigravity-Berechtigungen als erlaubt hinterlegt.

## Code-Konventionen
- **Kommentare auf Deutsch, Bezeichner auf Englisch.** Jede öffentliche Klasse/Funktion bekommt einen `///`-Kommentar (Zweck, Parameter, Besonderheiten). Formeln stehen im Kommentar.
- Struktur: feature-first (`lib/features/<feature>/`), Gemeinsames in `lib/core/`, Datenzugriff in `lib/data/`.
- **Repository-Pattern:** Widgets sprechen nie direkt mit Firebase.
- **Athlete-Kontext:** Alle Athleten-Screens hängen von einer `athleteId` ab (eigene ID oder die des gerade betrachteten Athleten, wenn ein Trainer sie öffnet). Niemals `currentUser.uid` fest in Feature-Screens verdrahten.
- Keine hartkodierten Farben, Größen oder Texte. Design nur über `lib/core/design/`, Texte nur über ARB (de = Standard, en umschaltbar).
- Keine Magic Numbers. Jede Netzwerk-/Firebase-Operation hat Lade-, Fehler- und Leerzustand.
- Zeiten: UTC + `utcOffsetMinutes` + `localDate` speichern, nie nur lokale Zeit.
- Zeitreihen nie ins Firestore-Hauptdokument (1-MB-Limit), sondern heruntergesampelt in Storage.
- **Metriken werden serverseitig berechnet** (Cloud Functions). Dart hat nur eine kleine Vorschau-Variante (Workout Builder). Beide Seiten testen gegen dieselben JSON-Testvektoren (`testvectors/`).
- Neue Dependencies nur mit Begründung in `docs/DECISIONS.md`.

## Sicherheit, Datenschutz, Recht
- Rollen `ATHLETE` (Standard), `TRAINER`. **Rolle, `coachId`, `trainerVerified` sind nie vom Client schreibbar** (nur Cloud Functions).
- Firestore-/Storage-Rules: Standard „deny all", jede Freigabe explizit, per Emulator-Test bewiesen.
- Tokens/Secrets nur serverseitig (Secret Manager, `users/{uid}/private/*` für Clients gesperrt). **Nie committen.** `.env`/Service-Accounts nicht lesen.
- Gesundheitsdaten = Art. 9 DSGVO: ausdrückliche Einwilligung (Zeitstempel + Version), Löschung und Export müssen funktionieren. Weitergabe an Trainer nur mit Athleten-Freigabe (granular).
- Keine Laufzeit-Abrufe von Google Fonts. Keine personenbezogenen Daten in Logs oder Push-Texten.
- **Kein Übernehmen** von Texten, Grafiken, Logos, Namen oder Code von MATS, TrainingPeaks oder Golden Cheetah (GPL). Formeln selbst implementieren. Der Belastungsindex heißt **ORBIT Score**.
- UI nutzt neutrale Begriffe (siehe `docs/DESIGN.md`, Erfahrungsstufen). Fachkürzel nur in der Experten-Ebene.

## Git
- Branch pro Phase: `feature/phase-NN-name`. Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`). Kein Force-Push, kein Direkt-Commit auf `main`. Nicht selbst mergen.
- Phase fertig, wenn: `flutter analyze` und `flutter test` grün, Functions-Tests grün, `docs/PROGRESS.md` aktualisiert (Skill `/phase-finish`).
