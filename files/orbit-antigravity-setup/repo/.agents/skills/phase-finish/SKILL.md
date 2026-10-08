---
name: phase-finish
description: "Schließt die aktuelle ORBIT-Phase ab (Formatierung, Analyse, Tests, ehrliche Abnahme, Doku, Zusammenfassung, PR-Text). Nur ausführen am Ende einer Phase oder wenn der Nutzer /phase-finish aufruft."
---

# Phase abschließen

1. Führe aus: `dart format .`, `flutter analyze`, `flutter test`. Bei Änderungen in `functions/`: `npm run build` und `npm test`. Bei Änderungen an Rules: Rules-Tests gegen den Emulator. Behebe alle Fehler und Warnungen.
2. Gehe die Abnahmekriterien der Phasendatei **einzeln** durch. Kennzeichne jedes als *erfüllt*, *nicht erfüllt* oder *nur manuell prüfbar*. Behaupte nichts, was du nicht geprüft hast.
3. Aktualisiere `docs/PROGRESS.md` (Fertig, Offen, Bekannte Probleme, nächster Schritt), `docs/DECISIONS.md` (neue Entscheidungen mit Begründung) und `docs/MANUAL_STEPS.md`.
4. Gib mir eine Zusammenfassung: Was wurde gebaut, was **muss ich manuell testen** (konkrete Schritte auf meinem Android-Gerät), welche Risiken bleiben. Wenn Antigravity ein Walkthrough-Artefakt (Screenshots/Nachweise) erzeugen kann, nutze es zusätzlich.
5. Schlage Titel und Beschreibung für den Pull Request vor. **Merge nicht selbst.** Stopp.
