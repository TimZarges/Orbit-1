# Spec: Workout-Struktur und Text-Kurzeingabe

Gilt für Phase 09 (Builder) und alles, was Workouts anzeigt oder berechnet. Die Textsyntax ist **reine Logik** (Parser und Formatter, Dart), vollständig getestet, ohne UI-Abhängigkeit.

## 1. Strukturschema v1 (`plannedWorkouts.structure`, `workoutTemplates.structure`)
```
{ "schemaVersion": 1, "sport": "BIKE"|"RUN"|"SWIM"|"STRENGTH", "blocks": [ Block ] }

Block = STEP | REPEAT
STEP   = { "type":"STEP", "role":"WARMUP"|"WORK"|"REST"|"COOLDOWN"|"MAIN",
           "target": { "durationSec": int } | { "distanceM": int },
           "intensity": Intensity,
           "cadence"?: { "low": int, "high": int },
           "note"?: string }
REPEAT = { "type":"REPEAT", "count": 2..99, "blocks": [ Block ] }      // max. Tiefe 3

Intensity =
    { "kind":"ZONE",        "low": 1..7, "high": 1..7 }
  | { "kind":"PCT_FTP",     "low": int,  "high": int }            // Rad
  | { "kind":"PCT_LTHR",    "low": int,  "high": int }            // Schwellen-HF
  | { "kind":"PACE",        "secPerKm": int }                      // Lauf
  | { "kind":"SWIM_PACE",   "secPer100m": int }                    // Schwimmen absolut
  | { "kind":"CSS_OFFSET",  "offsetSecPer100m": int }              // Schwimmen relativ zur CSS (0 = CSS)
  | { "kind":"FREE" }
```
Regeln: `blocks` nie leer. Einheiten intern immer SI/Sekunden/Meter (Imperial nur in der Anzeige). Unbekannte `schemaVersion` wird abgelehnt, nicht geraten. Migration über eine Funktion `migrateStructure(vOld → vNew)`.

## 2. Textsyntax (Eingabe mit Live-Vorschau)
**Beispiele**
```
10' Z1, 4x(4' Z4 / 2' Z1), 10' Z1                     (Rad/Lauf, Zonen)
15' 55%FTP, 3x(8' 95-100%FTP / 4' locker), 10' Z1     (Rad, % FTP)
2km Z1, 5x1000m @4:30/km / 90", 1km Z1                (Lauf, Pace)
400m Z1, 8x100m CSS / 20", 4x(4x50m Z5 / 15") / 2', 200m Z1      (Schwimmen)
```
**Bausteine**
- Dauer: `10'` (Minuten), `30"` (Sekunden), `1h`, `1h30'`, `90'`. Distanz: `400m`, `2km`.
- Intensität: `Z1`…`Z7`, Bereiche `Z2-Z3`, `85%FTP`, `90-95%FTP`, `88%LTHR`, `@4:30/km`, `@1:45/100m`, `CSS`, `CSS+5"`, `CSS-3"`, `locker` (= Z1), `frei`.
- Wiederholung: `4x(…)` verschachtelt bis Tiefe 3. Kurzform `8x100m CSS / 20"` = 8 × (100 m CSS, 20 s Pause).
- Trenner: `,` trennt Blöcke. `/` trennt innerhalb einer Wiederholung **Belastung** und **Pause**.
- Rollen: Der erste Block ohne Wiederholung ist `WARMUP`, der letzte `COOLDOWN`, falls keine Rolle genannt ist (`WU`, `CD`, `Pause` können explizit gesetzt werden). Das Verhalten ist per Test festgeschrieben.
- Notiz: Text in `[eckigen Klammern]` am Blockende.
- Groß-/Kleinschreibung egal, Leerzeichen tolerant, `'`/`’` und `"`/`”` werden normalisiert.

## 3. Anforderungen an den Parser
- Liefert `Result<Structure, List<ParseError>>`. Jeder Fehler hat **Position** (Zeichenindex von/bis), **Code** und lokalisierbaren Text (de/en). Mehrere Fehler werden gesammelt, nicht beim ersten abgebrochen.
- **Round-Trip:** `format(parse(text))` ergibt kanonischen Text, und `parse(format(structure)) == structure` für jede gültige Struktur (Property-Test mit zufällig erzeugten Strukturen).
- Grenzen: max. Länge 500 Zeichen, max. 200 Blöcke nach Expansion, Wiederholungszahl 2–99, Tiefe ≤ 3.
- Sportspezifische Validierung: `CSS`/`/100m` nur Schwimmen, `FTP` nur Rad, `/km` nur Lauf, `LTHR` Rad/Lauf. Falsche Kombination ist ein Fehler mit Hinweis.
- Berechnungen aus der Struktur (reine Funktionen): Gesamtdauer, Gesamtdistanz, Zeit je Zone, geschätzte Belastung. Distanzziele werden mit hinterlegten Schwellenwerten in Zeit umgerechnet, die **Annahme wird angezeigt** („geschätzt mit deiner CSS von 1:45/100 m").

## 4. Tests (Pflicht)
Beispiele aus §2, Randfälle (leere Eingabe, offene Klammer, `0x(…)`, Tiefe 4, gemischte Einheiten), Normalisierung der Anführungszeichen, Fehlerpositionen, Round-Trip-Property-Test, sportartenfremde Intensität, Berechnungen gegen handgerechnete Werte.
