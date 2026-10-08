---
name: phase-start
description: "Setzt eine freigegebene ORBIT-Phase anhand ihrer Phasendatei um und arbeitet bis zum nächsten STOPP-Punkt. Nur ausführen, wenn der Nutzer ausdrücklich /phase-start NN aufruft."
---

# Phase umsetzen

Die **Phasennummer** steht in der Nachricht des Nutzers hinter dem Befehl (z. B. `/phase-start 00`). Fehlt sie, bestimme die nächste Phase aus `docs/PROGRESS.md` und frage kurz nach Bestätigung.

1. Lies `AGENTS.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md` und die Phasendatei `docs/phases/phase-NN-*.md`. Existiert keine Phasendatei: **abbrechen** und mich auf `/phase-plan NN` hinweisen. **Plan-Check:** Alle Phasen 00–16 sind vorab geplant und können veraltet sein. Vergleiche die Phasendatei mit dem tatsächlichen Code, `docs/DECISIONS.md` und `docs/PROGRESS.md`. Bei Abweichungen (andere Struktur, geänderte Entscheidung, bereits Erledigtes) **zeige mir die nötigen Änderungen an der Phasendatei und warte auf meine Freigabe**, bevor du sie anpasst und startest.
2. Lies vor der Arbeit die in der Phasendatei genannten Dokumente (z. B. `docs/DESIGN.md`, `docs/DATA_MODEL.md`).
3. Erstelle den Branch `feature/phase-NN-<name>` (falls noch nicht vorhanden).
4. Arbeite die Aufgaben der Reihe nach ab: kleine Commits (Conventional Commits), Tests zur neuen Logik, deutsche Kommentare, Konventionen aus `AGENTS.md` und den passenden `.agents/rules/`.
5. **An jedem STOPP-Punkt:** kurz zusammenfassen (Was ist fertig, welche Entscheidungen, welche Risiken) und **auf mein „weiter" warten**. Arbeite nicht selbstständig darüber hinaus, auch nicht, wenn es naheliegt.
6. Dinge, die nur ich tun kann, sofort melden und in `docs/MANUAL_STEPS.md` eintragen.
7. Wenn alle Aufgaben erledigt sind, führe den Ablauf des Skills `phase-finish` aus.
