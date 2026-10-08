# ORBIT × Antigravity: Anleitung

Diese Anleitung überträgt das komplette ORBIT-Setup von Claude Code auf **Google Antigravity**. Die Inhalte (Design, Datenmodell, Phasen, Specs) sind dieselben. Angepasst wurden nur Dateinamen, Orte und Mechanik, damit Antigravity alles automatisch erkennt.

---

## 1. Das Prinzip in drei Sätzen
1. Antigravity lädt die `AGENTS.md` immer. Deshalb ist sie **kurz**. Detailwissen steckt in `docs/` und wird über **Regeln mit Auslöser** (`.agents/rules/`) nur dann geladen, wenn der Agent an passenden Dateien arbeitet.
2. Gearbeitet wird in **Phasen** mit **STOPP-Punkten** (hier hält der Agent an und wartet auf dein „weiter") und Abnahmekriterien (automatisch prüfbar vs. von dir manuell zu prüfen).
3. **Pro Phase eine neue Unterhaltung.** Der Stand steht in `docs/PROGRESS.md`, nicht im Gedächtnis des Chats.

## 2. Was sich gegenüber Claude Code ändert

| Thema | Claude Code | Antigravity |
|---|---|---|
| Zentrale Regeln | `CLAUDE.md` | **`AGENTS.md`** (immer aktiv, ohne Frontmatter) |
| Bedarfsweise Doku | Verweis „bei Bedarf lesen" | **`.agents/rules/*.md`** mit `trigger: glob` bzw. `model_decision` (lädt automatisch bei passenden Dateien/Aufgaben) |
| Eigene Befehle | `.claude/commands/*.md` | **Skills:** `.agents/skills/<name>/SKILL.md`, aufrufbar als `/<name>` |
| Berechtigungen | `.claude/settings.json` im Repo | **Einstellungen** (Oberfläche bzw. `~/.gemini/antigravity-cli/settings.json`), siehe `02_PERMISSIONS.md` |
| Argument `$ARGUMENTS` | in Befehlen verfügbar | nicht dokumentiert. Die Skills lesen die **Nummer aus deiner Nachricht** (`/phase-start 02`) |
| Neue Sitzung | `/clear` | **Neue Unterhaltung/Thread** starten |
| Plan-Modus | Shift+Tab | Eingebauter **`/plan`** (Analyse, Interview, Implementation-Plan-Artefakt) |
| Kontext prüfen | `/context` | Bereich **Customizations** (Rules/Skills-Tabs) |

**Warum Skills statt Workflows?** Antigravity-Workflows sind laut offizieller Doku **veraltet und werden am 1. November 2026 abgeschaltet**. Skills sind der Nachfolger (offener Standard, gleiche `/name`-Aufrufe).

## 3. Das Paket

```
orbit-antigravity-setup/
├── 00_ANLEITUNG_ANTIGRAVITY.md   ← diese Datei (nicht ins Repo)
├── 01_STARTPROMPTS.md            ← Texte zum Kopieren (nicht ins Repo)
├── 02_PERMISSIONS.md             ← Listen für deine Antigravity-Einstellungen (nicht ins Repo)
├── 03_PHASEN_PROMPTS.md          ← Startnachrichten, Vorab-Checks und Tests für ALLE Phasen (nicht ins Repo)
├── optional/CLAUDE.md            ← nur, falls du auch Claude Code im selben Repo nutzt
└── repo/                         ← DER INHALT KOMMT INS REPO-ROOT
    ├── AGENTS.md                         Dauerhafte Regeln (schlank)
    ├── .agents/
    │   ├── rules/                        4 Regeln mit Auslöser
    │   │   ├── design.md                 glob: lib/**/*.dart, ARB, Assets
    │   │   ├── data-and-security.md      glob: Rules, Functions, lib/data
    │   │   ├── metrics.md                model_decision: Kennzahlen
    │   │   └── garmin.md                 model_decision: Import/Garmin
    │   └── skills/                       10 Skills (= Slash-Befehle)
    │       ├── phase-plan/               /phase-plan NN   Plan einer Phase schreiben
    │       ├── phase-start/              /phase-start NN  Phase umsetzen
    │       ├── phase-finish/             /phase-finish    Phase abschließen
    │       ├── phase-run/                /phase-run NN    AUTOPILOT: Phase ohne Pausen ausführen
    │       ├── resume-phase/             /resume-phase    nach Unterbrechung weiter
    │       ├── design-check/             /design-check    UI gegen DESIGN.md prüfen
    │       ├── security-check/           /security-check  Rules/Functions-Review
    │       ├── scope-check/              /scope-check     zurück in den Phasenrahmen
    │       ├── split-phase/              /split-phase NN  Phase aufteilen
    │       └── bugfix/                   /bugfix <Text>   strukturierter Bugfix
    ├── docs/                             DESIGN, DATA_MODEL, REQUIREMENTS, ROADMAP,
    │                                     MANUAL_STEPS, PROGRESS, DECISIONS, CHECKPOINTS,
    │                                     specs/GARMIN+METRICS+WORKOUT_SYNTAX,
    │                                     phases/00–16 + Vorlage
    └── testvectors/README.md
```

**Alle 17 Phasen (00–16) sind vorab vollständig ausgearbeitet** (Aufgaben, STOPP-Punkte, Abnahme automatisch/manuell, Nicht-Ziele). Weil Pläne veralten, beginnt jede Phase mit einem **Plan-Check** gegen den tatsächlichen Code: Der Agent gleicht die Phasendatei mit dem Code und `docs/DECISIONS.md` ab und passt sie bei Abweichungen an (im Standardmodus nach deiner Freigabe, im Autopilot mit Eintrag in `docs/CHECKPOINTS.md`). Übersicht, Abhängigkeiten und zulässige Umstellungen: `docs/ROADMAP.md`. Startnachrichten, Vorab-Checks und Testlisten je Phase: **`03_PHASEN_PROMPTS.md`**.

## 4. Einmalige Einrichtung

**Voraussetzungen:** Flutter SDK, Android Studio mit Emulator (oder Android-Gerät), Node.js (LTS), Java (für den Firebase-Emulator), Firebase CLI, Git, Antigravity (Desktop-App, IDE oder CLI).

1. **Repo klonen** und Branch anlegen: `git checkout -b chore/antigravity-setup`
2. **Dateien kopieren:** Den **Inhalt** von `repo/` ins Repo-Root kopieren. `.agents/` ist ein **versteckter Ordner** und muss mit (Windows: „Ausgeblendete Elemente" aktivieren; Terminal: `cp -r repo/. /pfad/zu/Orbit/`).
3. **Alte Datei entfernen:** `git rm requierment.md` (ersetzt durch `docs/REQUIREMENTS.md`).
4. **`.gitignore` ergänzen** (falls nicht vorhanden):
   ```
   .env
   .env.*
   **/serviceAccount*.json
   **/key.properties
   *.jks
   *.keystore
   functions/node_modules/
   functions/lib/
   ```
   Zu `google-services.json`: keine geheimen Schlüssel im engeren Sinn, aber projektbezogen. Dein Repo ist **privat**, daher darfst du sie committen (Service-Account-Schlüssel, Keystores und `.env` nie). Der Agent spricht das im Audit an, du entscheidest.
5. **Committen und mergen**: `git add . && git commit -m "chore: Antigravity-Setup"`, push, nach `main` mergen.
6. **Berechtigungen einrichten:** `02_PERMISSIONS.md` öffnen und die Listen in die Antigravity-Einstellungen übernehmen (Preset **Default**, nicht Turbo).
7. **Sofort erledigen** (siehe `docs/MANUAL_STEPS.md`):
   - **Garmin-Entwicklerantrag stellen.** Das dauert am längsten und blockiert sonst später Phase 06.
   - Zwei Firebase-Projekte (`orbit-dev`, `orbit-prod`) in Region **`europe-west3`** anlegen, Blaze-Tarif. Die Region lässt sich später nicht ändern.
   - Package-ID der Android-App festlegen (z. B. `de.deinname.orbit`) und in Phase 00 mitteilen.
8. **Repo in Antigravity öffnen** (Ordner = Repo-Root).
9. **Einrichtung prüfen:**
   - **Customizations** öffnen: Unter **Rules** erscheinen `AGENTS.md` und die vier Regeln, unter **Skills** die zehn Skills. Ist etwas nicht sichtbar, siehe Abschnitt 9.
   - Den **Test-Prompt** aus `01_STARTPROMPTS.md` einfügen. Der Agent soll die Regeln korrekt wiedergeben und nichts ändern.
10. **Phase 00 starten** (Abschnitt 5).

## 5. Der Arbeitsablauf pro Phase

```
 Neue Unterhaltung starten
   │
   ├─ Phasendatei vorhanden? ── nein ──► /phase-plan NN
   │                                       └─ du liest docs/phases/phase-NN-*.md,
   │                                          korrigierst im Chat, gibst frei
   ▼
 /phase-start NN
   │   Der Agent arbeitet selbstständig …
   ├─► STOPP-Punkt: Zusammenfassung → du prüfst → „weiter" (oder Korrektur)
   │   … weiter bis zum nächsten STOPP / Ende
   ▼
 /phase-finish  (läuft am Ende automatisch mit)
   │   analyze, test, Doku, Zusammenfassung, PR-Text
   ▼
 Du: manuelle Tests auf dem Gerät (Liste „Manuell" in der Phasendatei)
 Du: Pull Request prüfen und mergen  →  nächste Phase in neuer Unterhaltung
```

**Wichtig für dich**
- **An STOPP-Punkten wirklich lesen.** Sie liegen dort, wo ein Fehler später teuer wird (Datenmodell, Rules, Formeln, Garmin-Doku, Chart-/Kartenwahl).
- **Manuelle Tests nie überspringen.** Login, Push, Flüssigkeit der Charts auf einem echten Android-Gerät kann der Agent nicht prüfen.
- **Du mergst.** Der Agent erstellt Branch und PR-Text, mergt aber nie selbst.
- Nutze die **Artefakte** von Antigravity (Implementation Plan, Walkthrough mit Screenshots) zum Gegenlesen. Maßgeblich bleibt die Datei in `docs/phases/`.

## 6. Befehle

**Eigene Skills** (siehe Baum oben). Die Nummer schreibst du hinter den Befehl: `/phase-start 02`.

**Eingebaute Antigravity-Befehle, die hier nützlich sind**

| Befehl | Einsatz bei ORBIT |
|---|---|
| `/plan` | Eingebaute Planung mit Interview. Gut für Fragen **innerhalb** einer Phase (z. B. „wie soll der Kalender im Detail aussehen?"). Den Phasenplan selbst erzeugst du mit `/phase-plan` |
| `/grill-me` | Wenn du eine Anforderung noch nicht sauber formulieren kannst: Der Agent interviewt dich |
| `/boost` | Für wirklich harte Bugs (Mehr-Agenten-Reasoning, nur in Bezahltarifen) |
| `/btw` | Zwischenfrage, ohne die laufende Arbeit zu unterbrechen |
| `/browser` | UI im Browser prüfen (z. B. Flutter-Web-Build) |
| `/learn` | Fasst Korrekturen als Regel zusammen. **Nur Vorschläge übernehmen**, die Ask-Regel aus `02_PERMISSIONS.md` fragt vor jedem Schreiben nach |

⚠️ **Nicht für Phasen mit STOPP-Punkten verwenden:** `/goal` (arbeitet „ohne Zwischenpausen" bis zum Ziel) und `/teamwork-preview` (Mehr-Agenten-Kampagnen). Beide umgehen die STOPP-Punkte. Normale Phasen laufen über `/phase-start`, die maximal selbstständige Variante ist `/phase-run` (Abschnitt 12).

## 7. Oberflächen
Rules und Skills im Repo (`AGENTS.md`, `.agents/`) funktionieren laut Doku in **Antigravity 2.0 (Desktop/Web)**, in der **IDE** und in der **CLI** gleich. Unterschiede gibt es nur bei den Berechtigungen:
- **2.0 / IDE:** Oberfläche (`Settings → General → Permission Settings`).
- **CLI (`agy`):** Datei `~/.gemini/antigravity-cli/settings.json`.

Für den Start empfehle ich **Antigravity 2.0 oder die IDE**: Du siehst Artefakte, Diffs und Screenshots direkt.

## 8. Kontext-Hygiene
- **Pro Phase eine neue Unterhaltung.** Bricht sie ab oder wird zu lang: `/phase-finish` (falls sinnvoll), neue Unterhaltung, `/resume-phase`.
- **Ein Agent zugleich** am Repo. Nutze die Mehr-Agenten-Ansicht nicht, um mehrere Phasen parallel auf demselben Branch zu bearbeiten.
- **Wiederholt der Agent einen Fehler?** Lass dir per `/learn` einen Regelvorschlag machen, prüfe ihn und nimm höchstens **einen kurzen Satz** in `AGENTS.md` auf. `AGENTS.md` bleibt unter ca. 150 Zeilen (aktuell ca. 55).
- **Keine Schlüssel in den Chat!** Passwörter, API-Keys, Garmin-Secrets trägst du selbst in Secret Manager oder `.env` ein. Die Deny-Liste sperrt das Lesen der `.env`.
- Regeln sind begrenzt (laut aktueller Doku 24 KB je Datei, 20.000 Token insgesamt für alle immer aktiven Regeln). Das Paket liegt weit darunter.

## 9. Wenn etwas schiefgeht

| Problem | Lösung |
|---|---|
| Rules oder Skills erscheinen nicht unter Customizations | Liegt `.agents/` im **Repo-Root**, hast du genau diesen Ordner geöffnet? Antigravity neu laden. **Ältere Version?** Aktuell gilt `.agents/` (Mehrzahl), ältere Versionen kennen nur `.agent/`. Dann den Ordner in `.agent` umbenennen (die aktuelle Version unterstützt beides) |
| Eine Regel wird still ignoriert | In `.agents/rules/` braucht **jede** Datei Frontmatter mit gültigem `trigger` (`always_on`, `model_decision`, `glob`, `manual`, snake_case!). Dateien in Unterordnern werden nicht gelesen |
| Skill erscheint, aber startet von selbst | Skills können vom Agenten selbst gewählt werden. Die Beschreibungen sind auf „nur auf Aufruf" formuliert. Passiert es trotzdem, sag: „Stopp, ich habe das nicht aufgerufen" und nenne den Befehl, den du wirklich willst |
| Der Agent springt über einen STOPP | „Stopp. Du hast STOPP-Punkt X übersprungen. Fasse den Stand zusammen und warte." |
| Der Agent baut mehr als in der Phase steht | `/scope-check` |
| Code weicht vom Design ab | `/design-check` |
| Zu viele Rückfragen nach Berechtigungen | Allow-Liste in `02_PERMISSIONS.md` prüfen. `pub get`, `npm ci`, Emulator und `adb` brauchen Netzwerk bzw. Host-Zugriff und fragen sonst außerhalb der Sandbox nach |
| Konflikt mit eigenen globalen Regeln | `~/.gemini/GEMINI.md` wirkt **zusätzlich** (Regeln sind kumulativ). Bei Widerspruch gewinnt die spezifischere Regel. Gibt es im Repo zusätzlich eine `GEMINI.md`, hat sie Vorrang vor `AGENTS.md`. Ich habe bewusst **keine** `GEMINI.md` angelegt |

## 10. Hinweise zur Zuverlässigkeit dieses Pakets
- **Dein Repository konnte ich nie lesen.** Alles zum Bestandscode beruht auf deinen Angaben. Phase 00 beginnt deshalb mit Audit und Stopp, bevor etwas umgebaut wird.
- **Antigravity-Mechanik** (Ordner `.agents/`, Frontmatter-Schlüssel und Trigger, Skills mit `/name`, Workflow-Abschaltung am 1.11.2026, Permission-Format `aktion(ziel)`, eingebaute Slash-Befehle) habe ich gegen die **offizielle Antigravity-Dokumentation** geprüft (Stand 8. Oktober 2026), und die YAML-Frontmatter aller Dateien mit einem Parser validiert. **Im Programm selbst konnte ich es nicht testen.** Antigravity ändert sich schnell: Schau bei Abweichungen in die Doku unter antigravity.google/docs.
- **Nicht dokumentiert** ist, ob Skills Argumente als Variable erhalten. Deshalb lesen die Skills die Nummer aus deiner Nachricht. Funktioniert das nicht zuverlässig, schreib die Phase ausgeschrieben („Phase 02, Datei docs/phases/phase-02-…").
- **Berechtigungen:** Die Listen sind ein Vorschlag. Ob Platzhalter in Dateipfaden unterstützt werden, ist nicht dokumentiert, deshalb stehen Pfade einzeln da.
- **Garmin:** Die Anbindung ist als Architektur beschrieben, nicht als Endpunktliste. Der Agent liest vor der Umsetzung die aktuelle Garmin-Doku (Stopp in Phase 06).
- **Recht und Datenschutz:** Die Dokumente sind Arbeitsgrundlagen, keine Rechtsberatung.
- Farbwerte der Kanäle und Sport-Identität in `DESIGN.md` sind Vorschläge, die in Phase 00 gegen deinen Code geprüft werden. Dein Code hat Vorrang.

## 11. Phasenübersicht
00 Fundament · 01 Auth/Onboarding/Rules · 02 Trainer-Verknüpfung · 03 Profil/Einstellungen · **04 Import (FIT, Demo)** · 05 Metrik-Kern · **06 Garmin** · 07 Health · **08 Kalender** · **09 Workout Builder** · **10–12 Analyse** · **13 Chat/Push** · 14 Home · 15 Coach-Desktop · 16 Release.
(Fett = deine Top-Prioritäten.) Möchtest du Chat oder Analyse früher, tausche die Reihenfolge in der `ROADMAP.md`. Phase 02 hat dafür die Grundlage gelegt.

## 12. Autopilot-Modus (`/phase-run`): maximale Selbstständigkeit

### Ehrliche Einordnung
Ich (Claude im Chat) habe **keinen Zugriff** auf dein Repo oder auf Antigravity: kein GitHub-Zugriff, kein Netzwerk, kein Flutter. Die Ausführung übernimmt der **Agent in Antigravity**. Der Autopilot ist dafür da, dass er dabei möglichst selten anhält.

### Was `/phase-run NN` anders macht als `/phase-start NN`

| | `/phase-start` | `/phase-run` |
|---|---|---|
| STOPP-Punkt | Agent hält an, du sagst „weiter" | Agent schreibt einen Eintrag in `docs/CHECKPOINTS.md`, entscheidet **konservativ** und macht weiter |
| Plan-Check (Phasendatei vs. Code) | zeigt Änderungen, **wartet auf deine Freigabe** | passt die Datei **selbst** an, Eintrag in `CHECKPOINTS.md` |
| Fehlende Phasendatei (z. B. nach `/split-phase`) | bricht ab, verweist auf `/phase-plan` | plant **selbst**, vermerkt „Plan selbst freigegeben" |
| Branches | pro Phase von `main` | **gestapelt** (von der vorherigen Phase), damit er nicht auf deinen Merge warten muss |
| Fehlende Zugänge | meldet | baut gegen **Emulator/Mock**, markiert `TODO(manual)`, arbeitet am Unabhängigen weiter |
| Anhalten | an jedem STOPP | nur bei **harten Stopps** (nur-ich-Blocker, Irreversibles/Kostenpflichtiges, Regelverstoß, Audit-Befund, 3× gleicher Fehler) |
| Abschluss | `phase-finish` | `phase-finish` + Bericht „Bitte zuerst prüfen" |

### Vorab-Check (ca. 15 Minuten, einmalig)
1. **Working Tree sauber**, Setup committet. Sicherheitsnetz: `git tag pre-autopilot`.
2. **Android-Emulator oder Gerät** startklar.
3. **Package-ID** festgelegt (z. B. `de.deinname.orbit`) und in der ersten Nachricht genannt.
4. **Firebase:** Entweder Projekt `orbit-dev` anlegen und einmal `flutterfire configure` ausführen **oder** bewusst „Emulator-only" starten. Dann bleiben Google-Login und Push bis zu deinem Setup unverifiziert und sind als `TODO(manual)` markiert.
5. **Berechtigungen** gesetzt (`02_PERMISSIONS.md`, inkl. Abschnitt 7). Beobachte die ersten Minuten, welche Befehle noch nachfragen, und erlaube sichere dauerhaft. Jede Rückfrage hält den Autopiloten an.
6. Credits im Blick behalten: Autopilot-Läufe können viel verbrauchen. `/usage` zeigt dein Kontingent.

### Realistische Erwartung, wie weit er kommt
| Phase | Ohne dich machbar? |
|---|---|
| 00 Fundament | Weitgehend. Spike-Messung auf dem Gerät und Flavor-Konfiguration brauchen dich |
| 01 Auth/Rules | Logik, Rules und Tests ja (Emulator). Echter Google-Login und App Check erst nach deinem Firebase-Setup |
| 02 Trainer-Link | Ja, gut testbar im Emulator |
| 03–05 Profil, Import, Metriken | Ja. Reine Logik mit Testvektoren. **ORBIT Score bleibt „VORLÄUFIG"** |
| 06 Garmin | Nur gegen Mocks. Live-Test erst nach Garmin-Freigabe |
| 07–09 Health, Kalender, Builder | Ja, mit Mocks bzw. Demo-Daten |
| 10–12 Analyse | Logik ja. Flüssigkeit und „fühlt sich gut an" nur du auf dem Gerät |
| 13 Chat/Push | Chat, Rules, Functions ja. Push nur auf echtem Gerät |
| 14–15 | Überwiegend ja |
| 16 Release | Nur teilweise: Konten, Signierung, Rechtstexte sind deine |

**Nie ohne dich:** Konsolen und Konten, Garmin-Antrag, Geräte- und UX-Tests, rechtliche Texte, Merge.

### Review-Rhythmus (wichtig!)
Gestapelte Branches pflanzen einen Fehler aus Phase 1 in alle weiteren fort. Deshalb **nicht alles am Stück laufen lassen**, sondern nach jeder Phase 10 Minuten prüfen:
1. `docs/CHECKPOINTS.md`: zuerst alle Einträge `RISIKO-HOCH`.
2. Bei Rules/Functions: `/security-check`.
3. App auf dem Gerät: Liste „Manuell" der Phasendatei.
4. Branches in der Reihenfolge der Tabelle in `CHECKPOINTS.md` mergen.
5. Neue Unterhaltung, `/phase-run NN+1`.

Mein Vorschlag: **Phase 00 bis 02 im Autopilot**, dann Review-Runde, dann 03 bis 05, dann Review usw.

### Wenn der Agent trotzdem zu oft anhält
Antigravity beschreibt `/goal` als autonome Ausführung bis zum Ziel ohne Zwischenpausen. Optional kannst du es damit versuchen: `/goal Phase 02 gemäß Skill phase-run vollständig abschließen`. Ich habe das nicht getestet.

### Review hier im Chat
Du kannst mir nach einem Lauf `docs/AUDIT.md`, `docs/CHECKPOINTS.md` oder einzelne Dateien (z. B. `firestore.rules`, die Rules-Tests, `main.dart`) hier einfügen. Ich prüfe sie dann aus Sicht von Entwicklung, Sicherheit und UX und sage dir, was du vor dem Merge ändern solltest.
