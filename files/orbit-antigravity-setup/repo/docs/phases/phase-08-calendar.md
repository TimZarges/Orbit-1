# Phase 08: Kalender und Soll-Ist-Abgleich

**Branch:** `feature/phase-08-calendar` · **Voraussetzungen:** Phase 02 (Athleten-Kontext), 04 (Aktivitäten), 05 (Belastung) · **Risiko:** hoch (Datenmodell Planung, Zuordnungslogik, Rules)

## Ziel
Athleten und Trainer planen Einheiten in einem übersichtlichen Kalender, importierte Aktivitäten werden dem Plan zugeordnet, die Abweichung ist auf einen Blick verständlich. Der Trainer arbeitet im Kalender **jedes seiner Athleten** mit denselben Screens.

## Vorher lesen
`AGENTS.md`, `docs/DATA_MODEL.md` (`plannedWorkouts`, `activities`, Grundprinzip 1 und 5), `docs/DESIGN.md` (§3.3 Sport-Identität, §7, §8), `docs/specs/METRICS.md`, Phase-02-Athleten-Kontext.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **`plannedWorkouts` finalisieren** (Felder, Status `PLANNED/COMPLETED/SKIPPED`, `activityId`, `templateId`, `createdBy`, `coachId`) und Zuordnungsalgorithmus als Spezifikation in `DECISIONS.md`: Kandidaten = gleicher `localDate` und kompatible Sportart (Multisport ↔ Brick-Einheiten beachten), Dauerplausibilität (Verhältnis grob 0,5–2,0), Bewertung (Punktzahl) und Konfidenzschwelle.
2. **STOPP 1 [RISIKO-HOCH]:** Datenmodell Planung, Zuordnungsregeln und Rules-Konzept zeigen (wer darf anlegen/ändern: Athlet eigene, Trainer für verknüpfte Athleten mit Freigabe `calendar`; `coachId` setzt eine Function). Ich gebe frei.
3. **Repository und Rules:** `PlannedWorkoutRepository` (CRUD, Bereichsabfragen nach Athlet und `localDate`, Indizes), Rules inkl. Trainer-Anlage über `get()` auf `coachLinks`, Trigger `onPlannedWorkoutCreated` setzt `coachId`. Rules-Tests (Athlet, Trainer mit/ohne Freigabe, Fremde, Widerruf).
4. **Kalender-UI (mobil zuerst):** **Wochenansicht** als Standard, **Monatsansicht** (`table_calendar`) mit Belegungsmarkern, **Listenansicht** (nächste Einträge, Paginierung). „Heute"-Button, Wechsel per Segment-Umschalter, Tag-Detail als **Bottom Sheet**. Tageskarten: Sport-Icon + Sportfarbe, Titel, Dauer, Status, Mini-Zonenbalken (wenn Struktur vorhanden). Skeleton und Empty State.
5. **Einheit anlegen/bearbeiten (einfach, ohne Builder):** Sportart, Titel, Dauer/Distanz, grobe Intensität, Beschreibung. Der Weg „Training planen" bietet bereits die Einstiege „Schnell", „Vorlage" (Phase 09) und „Builder" (Phase 09), diese beiden sind zunächst als „folgt" markiert.
6. **Verschieben:** Aktion im Bottom Sheet mit Schnellauswahl „Morgen", „Nächster Montag", „Datum wählen". Nur `localDate` ändert sich. (Drag & Drop folgt in Phase 15.)
7. **Zuordnung (Soll-Ist):** Reine Funktion `matchActivityToPlan` mit Tests. Trigger bei neuer Aktivität: eindeutiger Treffer → automatisch verknüpfen (`status = COMPLETED`, `activityId`/`plannedWorkoutId`, `matchStatus = AUTO`), uneindeutig → `UNMATCHED` und im UI „Zuordnen?"-Hinweis. **Manuelles** Zuordnen und Lösen. Aktivitäten ohne Plan erscheinen als „Zusatzeinheit". Vergangene, nicht erledigte Einheiten zeigen „Offen" mit Aktionen „Übersprungen" oder „Zuordnen", **nie** automatisch auf „übersprungen" setzen.
8. **Abweichung verständlich:** z. B. „95 % der geplanten Dauer", „Belastung 110 % vom Plan", Wording je Erfahrungsstufe, Info-Icon. Farbliche Hinweise nie allein über Farbe.
9. **Wochensummen:** Dauer und Distanz je Sportart, geplante vs. tatsächliche Belastung (aus `aggregates`/Metriken), Anzahl Trainingstage.
10. **Athleten-Kontext:** Der Trainer öffnet den Kalender eines Athleten über dessen `athleteId`. Kopfbereich zeigt klar, wessen Kalender es ist. Trainer-Einheiten sind für den Athleten als „vom Trainer geplant" erkennbar. Änderungen des Trainers sind für den Athleten sichtbar (einfacher Änderungsvermerk, Push folgt in Phase 13).
11. **Demo-Modus erweitern:** passende geplante Workouts zu den Demo-Aktivitäten (teils erfüllt, teils offen, teils abweichend).
12. **Performance und Zeit:** Monatsabfragen mit Limits/Indizes, Wochenwechsel ohne Ruckeln, korrekte Behandlung von Zeitzonen und Sommerzeitwechsel (Tests).
13. Lokalisierung, Galerie-Einträge, Golden Tests (Woche/Monat/Liste, leere/volle Tage, Abweichungsdarstellung).

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 1 (Planungsmodell, Zuordnungsregeln, Rules-Konzept)

## Nicht-Ziele
Workout Builder und Vorlagen (Phase 09), Drag & Drop und Mehrathleten-Raster (15), Push-Benachrichtigungen (13), Trainingspläne über mehrere Wochen/Blöcke (nach MVP).

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün, Rules-Tests (Anlage/Änderung/Lesen) für Athlet, Trainer, Fremde, Widerruf
- [ ] `matchActivityToPlan`: Tests für eindeutig, mehrdeutig, kein Treffer, Brick/Multisport, Dauerausreißer
- [ ] Trigger: Idempotenz, kein Überschreiben manueller Zuordnungen
- [ ] Zeitzonen-/Sommerzeit-Tests, Index-Warnungen im Emulator = 0
### Manuell (ich)
- [ ] Woche planen, Aktivität importieren, Zuordnung und Abweichungstext prüfen (Demo + eigene Daten)
- [ ] Als Trainer-Testkonto im Kalender eines Athleten planen, Athlet sieht es
- [ ] Bedienung der Bottom Sheets mit dem Daumen auf dem Gerät fühlt sich gut an

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `DATA_MODEL.md`, `MANUAL_STEPS.md`.
