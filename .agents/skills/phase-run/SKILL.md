---
name: phase-run
description: "Autopilot: Führt eine ORBIT-Phase möglichst vollständig und ohne Rückfragepausen aus. Plant bei Bedarf selbst, wandelt STOPP-Punkte in Protokolleinträge (docs/CHECKPOINTS.md) um und hält nur bei harten Blockern an. Nur auf Aufruf /phase-run NN."
---

# Autopilot: Phase ausführen

Die **Phasennummer** steht in der Nachricht des Nutzers (z. B. `/phase-run 02`). Ein Bereich wie `00-02` ist erlaubt, dann arbeitest du die Phasen nacheinander ab. Empfohlen ist eine Phase pro Unterhaltung. Fehlt die Nummer, bestimme die nächste Phase aus `docs/PROGRESS.md` und fahre fort.

**Autopilot heißt weniger Pausen, nicht weniger Sorgfalt.** Alle Regeln aus `AGENTS.md`, den `.agents/rules/` und dem Skill `phase-start` gelten weiter (Tests, Kommentare, kleine Commits, Konventionen, Sicherheit).

## Ablauf
1. **Lesen:** `AGENTS.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/CHECKPOINTS.md`, die Phasendatei `docs/phases/phase-NN-*.md` und die dort genannten Docs.
2. **Plan-Check:** Alle Phasen 00–16 sind vorab geplant und können veraltet sein. Vergleiche die Phasendatei mit dem tatsächlichen Code, `docs/DECISIONS.md` und `docs/PROGRESS.md`. Bei Abweichungen **passe die Phasendatei selbst an**, vermerke jede Änderung in `docs/CHECKPOINTS.md` (Anlass, Änderung, Risiko) und mache weiter.
   **Fehlt die Phasendatei** (z. B. nach `/split-phase` oder bei einer neuen Phase): Erstelle sie selbst nach den Regeln des Skills `phase-plan` (Aufgaben, STOPP-Punkte, Abnahme automatisch/manuell, Nicht-Ziele), lege sie in `docs/phases/` ab, vermerke in `docs/CHECKPOINTS.md`, dass du den Plan **selbst freigegeben** hast, und mache weiter.
3. **Branches stapeln:** Erstelle `feature/phase-NN-<name>` vom Branch der **vorherigen Phase**, falls dieser noch nicht in `main` gemergt ist, sonst von `main`. Notiere die Basis in `docs/CHECKPOINTS.md`, damit ich die Branches in der richtigen Reihenfolge mergen kann. **Nicht pushen, nicht mergen.** Lokale Commits genügen.
4. **STOPP-Punkte werden zu Checkpoints:** Statt zu warten, schreibe einen Eintrag in `docs/CHECKPOINTS.md` (Format siehe dort: Was, Entscheidung, Alternative, Risiko, was ich prüfen soll), übernimm das **Risiko-Tag** des STOPP-Punkts (`[RISIKO-HOCH|MITTEL|NIEDRIG]`) in den Eintrag, triff die **konservativste vernünftige** Entscheidung und arbeite weiter.
5. **Platzhalter statt Erfindung:** Fehlt etwas, das nur ich bereitstellen kann (Firebase-Projekt, `google-services.json`, SHA-Fingerprints, Garmin-Zugang, Gerät), erfinde nichts. Baue gegen **Emulator, Mock oder Interface**, markiere die Stelle mit `TODO(manual)`, trage sie in `docs/MANUAL_STEPS.md` ein und arbeite an unabhängigen Aufgaben weiter.
6. **Review-Schulden sichtbar machen:** Kennzeichne in `docs/CHECKPOINTS.md` jeden Eintrag zu **Security-Rules, Auth/Functions, Datenmodell, Formeln/ORBIT Score, Datenschutz-Texten** mit `RISIKO-HOCH`. Der ORBIT Score bleibt bis zu meiner Freigabe ausdrücklich **„VORLÄUFIG"**.
7. **Abschluss:** Führe den Ablauf des Skills `phase-finish` aus (Checks, ehrliche Abnahme, Doku) und gib den **Abschlussbericht** aus:
   - **„Bitte zuerst prüfen"** (maximal 5 Punkte, nach Risiko sortiert),
   - manuelle Tests für mein Android-Gerät,
   - **blockierte oder offene** Aufgaben mit Grund,
   - PR-Text und der Befehl für den nächsten Schritt (`/phase-run NN+1` in einer **neuen Unterhaltung**).

## Harte Stopps (hier anhalten und melden)
- **A. Blocker, der nur mich betrifft** (Zugangsdaten, Konsole, Konto, Antrag, Gerät), und es gibt **keinen** Weg per Emulator/Mock weiterzumachen. Erledige zuerst alles Unabhängige der Phase, stoppe erst, wenn nichts mehr übrig ist.
- **B. Irreversible oder kostenpflichtige Aktion:** bestehenden Nutzer-Code ohne Git-Rückweg löschen, Git-Verlauf umschreiben, Deploy auf Firebase (jede Umgebung), Aktionen auf Produktivdaten.
- **C. Verstoß gegen `AGENTS.md` nötig:** Secrets ins Repo, Rules lockern, fremde Marken/Texte/Code übernehmen.
- **D. Audit-Befund:** Geheimnisse im Repo oder Git-Verlauf, oder das Projekt ist nicht wie beschrieben (z. B. kein Flutter-Projekt).
- **E. Derselbe Fehler besteht nach 3 ernsthaften Lösungsversuchen.** Dokumentiere ihn, markiere die Aufgabe als offen und arbeite an unabhängigen Aufgaben weiter. Stoppe erst, wenn nichts Unabhängiges mehr übrig ist.

## Im Autopilot nie
`firebase login` oder `firebase deploy`, `git push`, `git merge`, Änderungen an `AGENTS.md`, `.agents/rules/` oder `.agents/skills/` (nur **Vorschläge** in `docs/CHECKPOINTS.md`), `/goal` oder `/teamwork-preview` selbst starten, Daten in der Cloud löschen.

Antworte im Zweifel zugunsten der **Rückholbarkeit**: lieber kleiner, getesteter Fortschritt als große ungeprüfte Sprünge.
