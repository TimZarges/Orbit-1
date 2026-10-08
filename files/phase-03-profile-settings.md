# Phase 03: Profil, Einstellungen, Schwellenwerte

**Branch:** `feature/phase-03-profile-settings` · **Voraussetzungen:** Phase 01 und 02 abgeschlossen · **Risiko:** mittel

## Ziel
Nutzer pflegen Profil und Schwellenwerte, stellen Sprache (DE/EN), Einheiten, Darstellung und Erfahrungsstufe ein, sehen und widerrufen ihre Einwilligungen. Die Begriffs-Mechanik der Erfahrungsstufen und die Info-Icons mit Erklärtexten stehen als wiederverwendbare Bausteine bereit.

## Vorher lesen
`AGENTS.md`, `docs/DESIGN.md` (§4, §7a, §8), `docs/DATA_MODEL.md` (`users`, `thresholdHistory`, `consents`), `docs/specs/METRICS.md` (Schwellenwerte, Zonen), bestehendes `training_zones_model.dart`.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Zonenmodell festlegen:** Lies `training_zones_model.dart` und dokumentiere in `docs/DECISIONS.md`, welche Modelle bereits existieren (Leistung Z1–Z7, Herzfrequenz, Lauf-Pace, Schwimm-CSS). Fehlende Modelle ergänzen. **Vorschlag zum Prüfen:** Leistungszonen nach dem gängigen 7-Zonen-Standard in % FTP, HF-Zonen aus Schwellen-HF, Pace-Zonen aus Schwellenpace, Schwimmzonen aus CSS. Jede Zone hat Nummer, Name, Grenzen, Farbe aus `DESIGN.md`. Reine Funktionen mit Unit-Tests (Grenzwerte inklusive/exklusive festschreiben).
2. **STOPP 1 [RISIKO-HOCH]:** Zonenmodell und Schätzhilfen (Aufgabe 3) mit Formeln und Quellenhinweis zeigen. Ich gebe frei, weil sie später in jede Belastungsrechnung eingehen.
3. **Schätzhilfen** (nur als Vorschlag, nie automatisch): grobe Max-HF-Schätzung, FTP aus einem 20-Minuten-Test, CSS aus 400-m/200-m-Test, Laufschwelle aus einem 30-Minuten-Test. Jeweils mit Formel im Kommentar, Hinweis „grobe Schätzung" und Unit-Tests.
4. **Profil-Screen:** Name, Foto (Upload nach Storage mit Typ-/Größenlimit und clientseitiger Verkleinerung), Sportart(en), Wettkampfziel (Name, Datum, Typ, bearbeiten/löschen), Geburtsjahr, Gewicht, Größe, Zeitzone. Validierung, Lade-/Fehlerzustände, Speichern mit Bestätigung. Alles im **Athlete-Kontext**: Ein Trainer darf Profildaten des Athleten nur lesen (je nach Freigabe), nicht ändern.
5. **Schwellenwerte-Screen:** je Sportart aktueller Wert, Verlauf aus `thresholdHistory` (Liste), neuen Wert mit **Gültig-ab-Datum** erfassen (Standard heute), „Weiß ich nicht" mit Schätzhilfe-Einstieg, Zonen-Vorschau mit Farben. Änderungen wirken **nur zukünftig** (Hinweis im UI, Neuberechnung folgt in Phase 05/12). Repository + Rules-Tests (nur Eigentümer schreibt, Trainer liest nur mit Freigabe).
6. **Einstellungen:**
   - Sprache DE/EN (wirkt **sofort** in der ganzen App, wird in `settings.language` gespeichert),
   - Einheiten metrisch/imperial über **eine zentrale** Formatter-Schicht (Distanz, Pace km/mi, Schwimm-Pace 100 m/100 yd, Gewicht, Höhe), mit Tests,
   - Darstellung Hell/Dunkel/Auto (Cockpit-Bereiche bleiben dunkel),
   - **Erfahrungsstufe** ändern,
   - Benachrichtigungen: Schalter je Kategorie und Ruhezeiten (nur Speicherung, die Pushes selbst kommen in Phase 13),
   - Datenschutz: Einwilligungen mit Datum/Version anzeigen, **Widerruf** der Gesundheitsdaten-Einwilligung mit klarer Folge (Nutzung eingeschränkt, Angebot „Daten löschen/exportieren"), Datenexport und Konto löschen (Screens aus Phase 01 verdrahten und testen),
   - Verbindungen: Platzhalter-Karte „Garmin" (Aktivierung in Phase 06).
7. **Erfahrungsstufen-Mechanik:** `TermResolver` liefert Begriff und Kurzform je Stufe (Tabelle in `DESIGN.md` §7a), lokalisiert, mit Tests für alle Begriffe × 3 Stufen × 2 Sprachen.
8. **Info-Icon-Baustein:** `InfoTerm`-Widget (Icon → Bottom Sheet mit kurzer verständlicher Erklärung, optional „Mehr erfahren"). Erklärtexte zentral in den ARB-Dateien (de + en). Erste Einträge: FTP, Schwellen-HF, CSS, Zonen, Max-HF, Ruhepuls. Galerie-Eintrag + Golden Test.
9. Lokalisierung vollständig (de + en), Widget-Galerie und Golden Tests für neue Komponenten.

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 1 (Zonenmodell und Schätzformeln)

## Nicht-Ziele
Automatische Schwellenwert-Vorschläge aus Trainingsdaten (Phase 12), Push-Versand (13), Garmin-Verbindung (06), Neuberechnung bestehender Aktivitäten (05/12).

## Abnahme
### Automatisch prüfbar
- [ ] `flutter analyze`, `flutter test` grün (inkl. Golden Tests), Rules-Tests für `thresholdHistory` und Profilfelder grün
- [ ] Unit-Tests: Zonengrenzen, Schätzhilfen, Einheiten-Formatter, `TermResolver` (alle Kombinationen)
- [ ] Sprachwechsel zur Laufzeit: Widget-Test zeigt Texte beider Sprachen ohne Neustart
- [ ] Keine hartkodierten Strings in den neuen Screens (Stichprobe per Suche)
### Manuell (ich)
- [ ] Profil und Foto auf dem Gerät ändern, Sprache umschalten, imperiale Einheiten prüfen
- [ ] Erklärtexte sind für Laien verständlich (de und en), Zonen stimmen mit meiner Erwartung überein
- [ ] Einwilligung widerrufen und Konsequenz verständlich erklärt

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `MANUAL_STEPS.md`.
