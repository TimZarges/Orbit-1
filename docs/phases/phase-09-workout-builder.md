# Phase 09: Workout Builder und Vorlagenbibliothek

**Branch:** `feature/phase-09-workout-builder` · **Voraussetzungen:** Phase 03 (Zonen/Schwellenwerte), 05 (Dart-Vorschau), 08 (Kalender) · **Risiko:** mittel bis hoch (Parser-Qualität, Mobile-Bedienung)

## Ziel
Strukturierte Einheiten schnell und fehlerarm bauen: per **Text-Kurzeingabe** mit Live-Vorschau oder per **Block-Editor**. Vorlagen speichern, durchsuchen, teilen und in den Kalender einplanen. Die Bedienung ist auf dem Handy flüssig.

## Vorher lesen
`AGENTS.md`, **`docs/specs/WORKOUT_SYNTAX.md` (komplett)**, `docs/DESIGN.md` (§3.1, §8), `docs/DATA_MODEL.md` (`plannedWorkouts.structure`, `workoutTemplates`), Phase-08-Kalender.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Domänenmodell (Dart):** Strukturschema v1 aus der Spec als unveränderliche Modelle, JSON-Serialisierung, `schemaVersion`, `migrateStructure`. Validierung (nicht leer, Tiefe ≤ 3, Wiederholungszahl, sportartenfremde Intensität).
2. **STOPP 1 [RISIKO-MITTEL]:** Schema und Textgrammatik inklusive 10 Beispielen und ihrer kanonischen Form zeigen. Ich gebe frei, bevor Parser und UI darauf aufbauen.
3. **Parser und Formatter** (reine Logik, `lib/features/workout_builder/domain/`): gemäß Spec §2–4, mit Fehlerpositionen, mehreren Fehlern, lokalisierten Meldungen, Normalisierung, Round-Trip. **Property-Test** mit zufälligen Strukturen. Eingabegrenzen. Kein UI-Import.
4. **Berechnungen:** Gesamtdauer/-distanz, Zeit je Zone, geschätzte Belastung (Dart-Vorschau aus Phase 05, gleiche Testvektoren), Umrechnung Distanz → Zeit mit hinterlegten Schwellenwerten und **angezeigter Annahme**. Fehlen Schwellenwerte, zeigt die UI einen Hinweis statt falscher Zahlen.
5. **Live-Profilgrafik** (`CustomPainter`): Balken in Zonenfarben (Breite = Dauer, Höhe = Intensität), verschachtelte Wiederholungen sichtbar, Zonennummer als Beschriftung, Semantics-Beschreibung für Screenreader, performant bei 200 Blöcken.
6. **Builder-Screen (mobil):** Oben Texteingabe mit Syntax-Hinweisen und Fehleranzeige an der betroffenen Stelle, darunter die Live-Vorschau und Kennzahlen (Dauer, Distanz, Belastung). Unten Aktionsleiste im Daumenbereich. **Block-Editor** als Bottom Sheet mit Steppern/Segment-Auswahl (Rolle, Dauer oder Distanz, Intensitätsart und -wert, Kadenz, Notiz), Blöcke hinzufügen, duplizieren, löschen, verschieben (Auf/Ab-Schaltflächen, Drag auf größeren Bildschirmen), Wiederholung umschließen/auflösen. **Rückgängig/Wiederholen**. Text und Editor bleiben **synchron** (Änderung an einem aktualisiert das andere).
7. **Sportartspezifisches:** Schwimmen (Bahnlänge, Wiederholungen je Distanz, Pausen, Material optional), Lauf (Pace/Zone), Rad (% FTP/Zone/Kadenz), Kraft (einfache Übungsblöcke mit Wiederholungen/Sätzen, Zonen entfallen).
8. **Bibliothek:** `workoutTemplates` (CRUD, Rules), Suche und Filter (Sportart, Dauer, Zonenfokus), Favoriten, Vorschau mit Profilgrafik. Eigene und **vom Trainer geteilte** Vorlagen (`SHARED_WITH_MY_ATHLETES`, Athlet liest nur Vorlagen seines Trainers, Rules-Tests).
9. **Einplanen:** „Aus Vorlage planen" (Datum wählen, Struktur wird **kopiert**, nicht referenziert) und „Builder → Kalender". Trainer plant für den Athleten im Athleten-Kontext (Freigabe `calendar`).
10. **Startbibliothek (selbst verfasst):** ca. 20 typische Triathlon-Einheiten (de + en) wie CSS-Schwimmsätze, Rad-Schwellenintervalle, Sweet Spot, Grundlage lang, Lauf-Tempoläufe, Brick-Einheiten. Alle **eigene Inhalte**, nichts aus MATS, TrainingPeaks oder anderen Bibliotheken kopieren. Als Seed für neue Nutzer ladbar.
11. **Export-Schnittstelle:** `WorkoutExporter`-Interface (nur Signatur und leere Implementierungen, Platzhalter für Garmin-Workout/FIT), **nicht** umsetzen.
12. **Kalender-Verknüpfung:** Einstiege „Vorlage" und „Builder" aus Phase 08 aktivieren, Mini-Zonenbalken in den Tageskarten aus der Struktur.
13. Lokalisierung, Galerie, Golden Tests (Profilgrafik, Fehlerzustände, Bibliothek).

## STOPP-Punkte
- **STOPP 1 [RISIKO-MITTEL]** nach Aufgabe 1 (Schema und Grammatik)

## Nicht-Ziele
Export zu Garmin/Wahoo/ZWO, Mehrwochenpläne, Massenzuweisung an mehrere Athleten (Phase 15), Teilen von Vorlagen außerhalb Trainer→Athlet.

## Abnahme
### Automatisch prüfbar
- [ ] Alle Parser-Tests und der Round-Trip-Property-Test grün, Berechnungen gegen handgerechnete Werte
- [ ] Rules-Tests für `workoutTemplates` (privat, geteilt, fremd)
- [ ] Widget-Tests: Text ↔ Editor Synchronisation, Undo/Redo, Fehleranzeige an richtiger Position
- [ ] Performance-Test: 200 Blöcke rendern ohne Frame-Einbruch (Benchmark-Harness)
### Manuell (ich)
- [ ] Zehn eigene typische Einheiten in Text und im Editor bauen: schnell und fehlerarm?
- [ ] Bedienung auf dem Handy (Tastatur, Bottom Sheets) angenehm
- [ ] Startbibliothek inhaltlich geprüft (Zonen, Dauer, Schwimmsätze realistisch)

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `docs/specs/WORKOUT_SYNTAX.md` bei Abweichungen, `DATA_MODEL.md`.
