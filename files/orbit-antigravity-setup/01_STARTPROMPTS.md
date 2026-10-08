# Startprompts für Antigravity (zum Kopieren)

Die Befehle `/phase-plan`, `/phase-start`, `/phase-finish` usw. sind **Skills** im Repo (`.agents/skills/`). Die Prompts unten brauchst du nur für den Start, den Test und als **Fallback**, falls Skills in deiner Version nicht erkannt werden.

---

## Test: Einrichtung prüfen (vor Phase 00)
```
Prüfe, ob du die Projektregeln geladen hast. Nenne mir in höchstens 6 Stichpunkten die wichtigsten Arbeitsregeln aus AGENTS.md, nenne die Navigation je Rolle, liste die dir bekannten Skills (Slash-Befehle) und die dir bekannten Regeldateien aus .agents/rules auf und sage mir, welche Phase als nächste dran ist. Ändere keine Dateien.
```
*Erwartung:* Phase-gebundene Arbeitsweise mit STOPP-Punkten bzw. Checkpoints im Autopilot, deutsche Kommentare/englische Bezeichner, keine Secrets, Athlet-Tabs (Heute/Plan/Analyse/Coach), 10 Skills (inkl. `phase-run`), 4 Regeln, nächste Phase = 00.

---

## A. Phase 00 starten (Erststart)
Kurzform: `/phase-start 00`. Ausgeschrieben:
```
Lies AGENTS.md und docs/phases/phase-00-foundation.md.
Setze Phase 00 um und beginne mit dem Audit des bestehenden Codes (docs/AUDIT.md). Halte dich an alle STOPP-Punkte der Phasendatei: stoppe dort, fasse zusammen und warte auf mein „weiter". Verändere bestehenden Code nur nach dem Audit und erst nach STOPP 1.
Wichtig: Kommentare auf Deutsch, Bezeichner auf Englisch, kleine Commits auf dem Branch feature/phase-00-foundation. Alles, was nur ich tun kann, trägst du in docs/MANUAL_STEPS.md ein und meldest es mir. Nutze weder /goal noch /teamwork-preview. Am Ende führst du den Ablauf des Skills phase-finish aus.
```

---

## AUTOPILOT: möglichst weit ohne Pausen
Vorher: Abschnitt 12 der Anleitung (Vorab-Check, `git tag pre-autopilot`).

### AP1. Phase 00 im Autopilot (Kurzform: `/phase-run 00`)
```
/phase-run 00
Kontext: Package-ID ist <z. B. de.deinname.orbit>. Firebase: <orbit-dev ist angelegt und flutterfire configure ist ausgeführt | wir starten Emulator-only>. Android-Emulator läuft.
Arbeite die Phase vollständig ab. STOPP-Punkte werden zu Einträgen in docs/CHECKPOINTS.md. Halte nur bei harten Stopps an. Erstelle am Ende den Abschlussbericht mit „Bitte zuerst prüfen".
```

### AP2. Ausgeschrieben (falls der Skill nicht erkannt wird)
```
Lies .agents/skills/phase-run/SKILL.md und führe sie für Phase 00 aus. Lies außerdem AGENTS.md, docs/PROGRESS.md, docs/DECISIONS.md, docs/CHECKPOINTS.md und docs/phases/phase-00-foundation.md. Package-ID: <…>. Firebase: <…>.
```

### AP3. Mehrere Phasen am Stück (nur wenn du wenig Zeit hast, Review-Risiko beachten)
```
/phase-run 00-02
```

### AP4. Nächste Phase nach deinem Review (neue Unterhaltung)
```
/phase-run 03
Mein Review der vorherigen Phase ist abgeschlossen. Merge-Stand: <alles gemergt | Branch feature/phase-02-… noch nicht gemergt>. Meine Anmerkungen: <keine | …>.
```

### AP5. Nach dem Lauf: Review-Hilfe vom Agenten
```
Lies docs/CHECKPOINTS.md und docs/PROGRESS.md. Erstelle eine Review-Liste für mich: (1) alle RISIKO-HOCH-Einträge mit der konkreten Datei/dem Test, den ich prüfen soll, (2) alle TODO(manual)-Stellen im Code (per Suche) mit Verweis auf MANUAL_STEPS, (3) die Branch-Reihenfolge zum Mergen. Ändere nichts.
```

*Tipp:* Füge mir `docs/AUDIT.md`, `docs/CHECKPOINTS.md` oder einzelne Dateien in den Claude-Chat ein, dann gebe ich dir ein unabhängiges Review.

---

## Fallbacks (nur falls die Skills nicht erkannt werden)

### B. Phase planen (statt `/phase-plan NN`)
```
Erstelle den Plan für Phase NN. Schreibe noch keinen Anwendungscode.
Lies AGENTS.md, docs/ROADMAP.md (Epic NN), docs/PROGRESS.md, docs/DECISIONS.md, die relevanten Docs (DESIGN, DATA_MODEL, specs) und den tatsächlichen Code-Stand. Erstelle docs/phases/phase-NN-<name>.md nach docs/phases/_TEMPLATE.md: konkrete Aufgaben, STOPP-Punkte an teuren Entscheidungen, Abnahme getrennt in „automatisch prüfbar" und „manuell", Nicht-Ziele. Teile zu große Phasen auf. Trage Neues in docs/MANUAL_STEPS.md ein, stelle echte Rückfragen und warte auf meine Freigabe.
```

### C. Phase umsetzen (statt `/phase-start NN`)
```
Lies AGENTS.md, docs/PROGRESS.md, docs/DECISIONS.md und docs/phases/phase-NN-*.md und setze Phase NN um. Lies vorher die in der Phasendatei genannten Docs. Branch feature/phase-NN-<name>, kleine Commits (Conventional Commits), Tests zur neuen Logik, deutsche Kommentare. Stoppe an jedem STOPP-Punkt, fasse zusammen (fertig, Entscheidungen, Risiken) und warte auf mein „weiter". Am Ende: Ablauf wie der Skill phase-finish.
```

### D. Phase abschließen (statt `/phase-finish`)
```
Schließe die aktuelle Phase ab: dart format, flutter analyze, flutter test (bei Functions/Rules zusätzlich npm run build/test und Rules-Tests am Emulator), Fehler beheben. Gehe die Abnahmekriterien einzeln durch und kennzeichne ehrlich: erfüllt / nicht erfüllt / nur manuell prüfbar. Aktualisiere docs/PROGRESS.md, DECISIONS.md, MANUAL_STEPS.md. Gib mir eine Zusammenfassung inklusive konkreter manueller Teststeps für mein Android-Gerät und einen PR-Text. Nicht selbst mergen.
```

### Skills-Zuordnung (Fallback-Prompts liegen als Text in den jeweiligen `SKILL.md`)
| Befehl | Datei |
|---|---|
| `/resume-phase` | `.agents/skills/resume-phase/SKILL.md` |
| `/design-check` | `.agents/skills/design-check/SKILL.md` |
| `/security-check` | `.agents/skills/security-check/SKILL.md` |
| `/scope-check` | `.agents/skills/scope-check/SKILL.md` |
| `/split-phase NN` | `.agents/skills/split-phase/SKILL.md` |
| `/bugfix <Beschreibung>` | `.agents/skills/bugfix/SKILL.md` |

Erkennt dein Antigravity sie nicht, schreibe: „Lies .agents/skills/<name>/SKILL.md und führe die Anweisungen aus. Mein Anliegen: …"

---

## Kurze Korrekturen für unterwegs
- **STOPP übersprungen:** „Stopp. Du hast STOPP-Punkt X übersprungen. Fasse den Stand zusammen und warte auf mein weiter."
- **Zu viele Rückfragen:** „Entscheide pragmatisch, dokumentiere die Annahme in docs/DECISIONS.md und mach weiter."
- **Skill ungewollt gestartet:** „Stopp, ich habe das nicht aufgerufen. Ich möchte: <Befehl>."
- **Neue Unterhaltung nach Abbruch:** `/resume-phase`
