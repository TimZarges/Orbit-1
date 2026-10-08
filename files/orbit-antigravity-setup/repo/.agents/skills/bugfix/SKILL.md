---
name: bugfix
description: "Strukturierter Bugfix für ORBIT: Ursache finden, fehlschlagenden Test schreiben, minimal beheben. Nur auf Aufruf /bugfix mit Fehlerbeschreibung."
---

# Bugfix

Die Fehlerbeschreibung steht in der Nachricht des Nutzers (was gesehen, was erwartet, Gerät/Flavor). Fehlen Angaben, frage gezielt nach.

1. Finde zuerst die **Ursache**: relevanten Code lesen, wenn möglich per Test reproduzieren.
2. Schreibe einen **fehlschlagenden Test**.
3. Behebe den Fehler **minimal**, halte dich an `AGENTS.md` und die passenden `.agents/rules/`.
4. Branch: `fix/<kurzname>`. Kleine Commits.
5. Erkläre mir die Ursache in höchstens 3 Sätzen und nenne, was ich manuell prüfen soll.
