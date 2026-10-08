# Phase 12: Leistungsdiagnostik

**Branch:** `feature/phase-12-diagnostics` · **Voraussetzungen:** Phase 03 (Schwellenwerte), 05 (Neuberechnung), 11 (Bestwerte) · **Risiko:** hoch (Schätzmethoden, Auswirkungen auf alle Zahlen)

## Ziel
ORBIT erkennt anhand der Daten, wann sich FTP, Laufschwelle oder CSS verändert haben könnten, und **schlägt** neue Werte transparent vor. Der Athlet entscheidet, die Vergangenheit wird nur auf Wunsch neu berechnet. Geführte Tests helfen, sauber zu messen.

## Vorher lesen
`AGENTS.md`, `docs/specs/METRICS.md` (Schwellenwerte, **Ergänzung B**), `docs/DATA_MODEL.md` (`thresholdHistory`, `thresholdProposals`, `bests`), `docs/DESIGN.md` (§7a, §8), Phase-05-`recomputeMetrics`.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Schätzmethoden festlegen** (je Sportart): Datenbasis, Zeitfenster, Faktoren, Mindestanzahl und -qualität der Einheiten, Konfidenzstufen, Ausschlüsse (z. B. Indoor-Besonderheiten, Intervalle zu kurz). Quelle/Begründung je Methode, Grenzen offen benennen.
2. **STOPP 1 [RISIKO-HOCH]:** Methodenpapier (kurz) zeigen. Ich gebe frei, weil Vorschläge direkt alle Belastungszahlen beeinflussen.
3. **Schätzfunktionen (reine Logik, Functions + Tests):** FTP (aus MMP-Bestwerten oder Critical-Power-Modell), Lauf-Schwellen-HF und -Pace, CSS. Rückgabe: `{value, deltaToCurrent, confidence, basis[], explanationKey}`. Bei zu dünner Datenlage **kein** Vorschlag. Testvektoren mit synthetischen Verläufen (klarer Anstieg, Plateau, Ausreißer, zu wenig Daten).
4. **Vorschlagslogik:** Trigger/Scheduler erzeugt `users/{uid}/thresholdProposals/{id}` nur bei **relevanter** Änderung (Mindestdifferenz, nicht bei jeder Kleinigkeit), keine Dubletten, Ablauf alter Vorschläge. Rules: Athlet liest/entscheidet, Trainer liest mit Freigabe, schreiben nur Functions.
5. **Diagnostik-Screen:** Tabs *Rad / Lauf / Schwimmen*. Je Sportart: aktueller Wert mit Datum und Quelle, Verlauf (`thresholdHistory`) als Chart, **Vorschlagskarte** („Vorschlag: 262 W (+4 %), Konfidenz mittel, basiert auf deiner besten 20-Minuten-Leistung vom 12.09.") mit **Übernehmen**, **Ignorieren**, **Warum?** (Erklärung und Datenbasis). Wording je Erfahrungsstufe, keine Garantien.
6. **Übernehmen:** erzeugt einen neuen `thresholdHistory`-Eintrag mit `effectiveFrom = heute`, danach Frage **„Vergangene Einheiten neu berechnen?"** mit Hinweis auf Umfang und Wirkung (geschätzte Dauer, Änderung von Form-/Belastungszahlen) und Aufruf von `recomputeMetrics` mit Fortschrittsanzeige. Standard ist **nicht** neu berechnen.
7. **Geführte Tests:** Informationsseiten zu 20-Minuten-FTP-Test, 400 m/200 m CSS-Test, 30-Minuten-Lauftest mit Hinweisen zu Aufwärmen, Bedingungen und Sicherheit (kein medizinischer Rat, „bei Beschwerden nicht durchführen"). Button „Test in meinen Kalender einplanen" erzeugt ein Workout aus einer **Vorlage der Startbibliothek** (Phase 09).
8. **Datenqualität:** Hinweise, wenn Leistung fehlt, nur Indoor-Daten vorliegen oder lange keine harte Einheit vorkam („Für einen Vorschlag fehlt …"). Keine Zahlen erfinden.
9. **Schwellen-Fortschrittskarte** für den Analyse-Tab (Platzhalter aus Phase 10 ersetzen) und Verknüpfung zum Home (Phase 14, Hinweis „Neuer Vorschlag verfügbar", nur Datenvertrag, noch keine Push-Benachrichtigung).
10. **Athleten-Kontext:** Trainer sieht Verlauf und Vorschläge mit Freigabe. **Übernehmen nur durch den Athleten** (Trainer-Vorschläge folgen in Phase 15).
11. Lokalisierung, Galerie, Golden Tests (Vorschlagskarte je Konfidenz, kein Vorschlag, Verlauf).

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 1 (Methoden)

## Nicht-Ziele
Automatisches Übernehmen, Trainer-Vorschläge (Phase 15), Leistungsprofile/Fahrertypen, Push (13), Laktat-/Spiroergometrie-Import.

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün, Schätzfunktionen gegen Testvektoren (inkl. „kein Vorschlag" bei dünner Datenlage)
- [ ] Rules-Tests für `thresholdProposals`
- [ ] Übernehmen schreibt `effectiveFrom = heute`, ändert die Vergangenheit **nicht**, Neuberechnung nur auf Wunsch
- [ ] Widget-Tests der Vorschlagskarte (Übernehmen/Ignorieren/Warum)
### Manuell (ich)
- [ ] Vorschläge mit eigenen Daten gegen mein Gefühl und frühere Tests prüfen
- [ ] Texte, Warnhinweise und Testbeschreibungen (de/en) geprüft
- [ ] Neuberechnung einer Beispielzeitspanne beobachten

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `docs/specs/METRICS.md` (finale Methoden), `DATA_MODEL.md`.
