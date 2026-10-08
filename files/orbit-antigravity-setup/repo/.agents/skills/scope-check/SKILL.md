---
name: scope-check
description: "Holt den Agenten zurück in den Rahmen der aktuellen ORBIT-Phase, wenn er über die Phasendatei hinaus Änderungen macht. Nur auf Aufruf /scope-check."
---

# Zurück in den Rahmen

Stopp. Lies die aktuelle Phasendatei in `docs/phases/`, besonders den Abschnitt **Nicht-Ziele**.

1. Liste auf, was du **außerhalb des Phasenumfangs** geändert oder gebaut hast (siehe `git diff` gegen `main`).
2. Mache das rückgängig oder verschiebe es als Notiz in `docs/ROADMAP.md`.
3. Arbeite danach nur an den Aufgaben der Phase weiter und halte die STOPP-Punkte ein.
