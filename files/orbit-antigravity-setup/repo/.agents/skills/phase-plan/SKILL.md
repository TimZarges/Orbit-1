---
name: phase-plan
description: "Erstellt den detaillierten Plan (Phasendatei) für eine ORBIT-Phase aus der ROADMAP, ohne Code zu schreiben. Nur ausführen, wenn der Nutzer ausdrücklich /phase-plan NN aufruft oder darum bittet, eine Phase zu planen."
---

# Phase planen

Die **Phasennummer** steht in der Nachricht des Nutzers hinter dem Befehl (z. B. `/phase-plan 03`). Fehlt sie, bestimme die nächste Phase aus `docs/PROGRESS.md` und frage kurz nach Bestätigung.

Schreibe in diesem Schritt **keinen Anwendungscode**.

**Existiert die Phasendatei bereits** (alle Phasen 00–16 sind vorab geschrieben): Schreibe sie **nicht neu**, sondern führe einen **Plan-Check** durch. Vergleiche sie mit dem tatsächlichen Code, `docs/DECISIONS.md`, `docs/PROGRESS.md` und `docs/CHECKPOINTS.md`, liste Abweichungen und veraltete Annahmen auf, schlage konkrete Änderungen an der Datei vor und warte auf meine Freigabe. Die Schritte unten gelten für **neue** Phasen.

1. Lies `AGENTS.md`, `docs/ROADMAP.md` (Epic dieser Phase), `docs/PROGRESS.md`, `docs/DECISIONS.md` und die relevanten Dokumente (`docs/DESIGN.md`, `docs/DATA_MODEL.md`, `docs/specs/*`).
2. Lies den **tatsächlichen Code-Stand**, auf dem die Phase aufbaut. Verlass dich nicht nur auf die Doku.
3. Erstelle die Datei `docs/phases/phase-NN-<kurzer-name>.md` nach der Vorlage `docs/phases/_TEMPLATE.md`. Sie muss enthalten:
   - konkrete Aufgaben in sinnvoller Reihenfolge,
   - **STOPP-Punkte** dort, wo ein Fehler teuer würde (Datenmodell, Rules, Formeln, Fremd-APIs, UX-Grundentscheidungen),
   - Abnahmekriterien getrennt in **automatisch prüfbar** (du verifizierst selbst) und **manuell** (nur ich, z. B. Gerät, Konsole),
   - Nicht-Ziele, damit die Phase klein bleibt. Ist die Phase zu groß, schlage eine Aufteilung vor (siehe Skill `split-phase`).
4. Prüfe, ob neue Einträge in `docs/MANUAL_STEPS.md` nötig sind.
5. Stelle offene Rückfragen an mich (nur echte, gern als kurzes Interview mit Auswahloptionen).
6. Falls Antigravity ein Implementation-Plan-Artefakt erzeugt: Die **maßgebliche Fassung ist die Datei in `docs/phases/`**. Halte beide konsistent.
7. **Stopp.** Warte auf meine Freigabe. Beginne nicht mit der Umsetzung.
