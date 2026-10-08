# Phase 04: Aktivitäts-Import (FIT-Upload, Parser, Demo-Modus)

**Branch:** `feature/phase-04-activity-import` · **Voraussetzungen:** Phase 01–03 · **Risiko:** hoch (Datenmodell, Pipeline, Storage-Rules)

## Ziel
Eine FIT-Datei hochladen und als Aktivität (inkl. Zeitreihen) in ORBIT sehen. Ein **Demo-Modus** liefert realistische Beispieldaten über **dieselbe Pipeline**. Die Pipeline ist anbieterneutral, damit Garmin (Phase 06) nur noch eine zweite Eingangstür ist. Das ist der Boden für Kalender, Analyse und Chat.

## Vorher lesen
`AGENTS.md`, `.agents/rules/garmin.md`, `docs/DATA_MODEL.md` (`activities`, Storage-Pfade, Grundprinzipien 2–3), `docs/specs/GARMIN.md` (Architektur), `docs/DESIGN.md` (Empty State, First-Run).

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben

### Teil A: Pipeline (Backend)
1. **Datenmodell finalisieren** (`activities`, `summary`, `segments`, Streams-Format, `processing`-Status) und `docs/DATA_MODEL.md` anpassen.
2. **STOPP 1 [RISIKO-HOCH]:** Finales Aktivitäts-Modell und Streams-Format (Kanäle, Einheiten, Abtastrate, Kompression, maximale Punktzahl) zeigen. Es ist die Grundlage für Phase 05, 08, 11.
3. **FIT-Bibliothek wählen:** Prüfe `@garmin/fitsdk` (Funktionsumfang, Pflege, Encoder vorhanden?) und halte die Entscheidung in `DECISIONS.md` fest. FIT wird **nur serverseitig** geparst. Entferne die Abhängigkeit `fit_sdk` im Flutter-Projekt, falls Phase 00 sie nicht schon entfernt hat.
4. **Upload-Weg:** Client lädt nach `users/{uid}/fit/{activityId}.fit` (Storage-Rules: nur eigener Pfad, Größenlimit z. B. 25 MB, Dateityp). Function (Storage-Trigger oder Callable `importFit`) startet die Verarbeitung. Ein `activities`-Dokument mit `processing.state` gibt der UI Feedback.
5. **Parser und Mapping** (`functions/src/import/`): Sport/Subsport aus FIT auf ORBIT-Enums (unbekannt → `OTHER`), Pool vs. Freiwasser, Multisport/Triathlon als `MULTISPORT` mit `segments[]` inkl. Wechselzonen, Runden/Längen (Schwimmen). Summary (Dauer, Distanz, Ø/Max HF, Leistung, Kadenz, Höhenmeter, Pace, SWOLF, Bahnlänge).
6. **Zeiten:** FIT-Zeitstempel in UTC → `startTimeUtc`; `utcOffsetMinutes` aus den lokalen Zeitangaben der Datei, Fallback `profile.timezone`; `localDate` daraus ableiten. Tests mit Zeitzonenwechsel und Mitternachts-Einheit.
7. **Streams:** Datensätze (Zeit, HF, Leistung, Kadenz, Geschwindigkeit, Höhe, Position in Grad aus Semicircles, Schwimm-Längen) auf eine feste Abtastung heruntersamplen, als komprimierte Datei `users/{uid}/streams/{activityId}.json.gz` speichern, `streamsPath` ins Dokument. Lücken/Pausen sauber behandeln (keine Interpolation über Pausen).
8. **Idempotenz und Duplikate:** `(source, externalId)` mit stabiler `externalId` (z. B. Hash aus Datei-ID/Startzeit/Seriennummer oder Datei-Hash). Gleiche Datei zweimal → kein Duplikat, verständliche Rückmeldung. Fehlerfälle: beschädigte/leere Datei, Nicht-FIT, zu groß → `processing.state = FAILED` mit `errorCode` und lokalisierter Meldung, keine halbfertigen Dokumente.
9. **Rules:** Clients können `activities` **nicht** anlegen oder ändern (nur Functions). Löschen über Callable `deleteActivity` (löscht Dokument, FIT und Streams). Trainerzugriff über `coachId` wie in Phase 02. Rules-Tests für alle Fälle.
10. **Tests:** Parser mit **synthetischen FIT-Dateien** (per Encoder erzeugt, falls verfügbar) für Rad mit Leistung, Lauf mit GPS, Pool-Schwimmen, Triathlon-Multisport, Datei ohne Leistung, beschädigte Datei. Zusätzlich Platz für **echte, anonymisierte** FIT-Dateien in `testvectors/fit/` (Eintrag in `MANUAL_STEPS.md`: ich liefere 2–3 eigene Dateien, GPS-Start/Ziel vorher unkenntlich machen).
11. **STOPP 2 [RISIKO-MITTEL]:** Kurzbericht zur Pipeline (Testergebnisse, bekannte Grenzen). Danach Teil B.

### Teil B: Client
12. **Import-UI:** FIT-Datei wählen (Dateiauswahl), Upload-Fortschritt, Verarbeitungsstatus live (Firestore-Stream), Fehlerzustände mit Hilfetext. Alles im **Athlete-Kontext**.
13. **Aktivitätsliste und Detail (nur Zusammenfassung):** Liste nach `localDate` absteigend mit Paginierung, Sport-Icon + Sportfarbe, Titel, Datum (lokal), Dauer, Distanz. Detail mit Kennzahlen je Sportart, Segmenten (Multisport), „Mehr Details" als deaktivierter Platzhalter (Phase 11). Aktivität löschen mit Bestätigung. Skeleton-Loader und Empty State.
14. **First-Run-Screen** (Tab „Heute" bzw. Aktivitätsliste leer): zwei Optionen „Garmin verbinden (folgt in Phase 06, deaktiviert mit Hinweis)" und „FIT-Datei importieren". Gestalteter Empty State nach `DESIGN.md`.
15. Lokalisierung (de + en), Galerie-Einträge, Golden Tests (Liste, Detail, Empty State, Fehlerzustand).

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 1 (finales Aktivitäts-Modell, Streams-Format)
- **STOPP 2 [RISIKO-MITTEL]** nach Aufgabe 10 (Pipeline fertig)

## Nicht-Ziele
Metrik-Berechnung (Phase 05), Charts und Karte (11), Garmin-Anbindung (06), Zuordnung zu geplanten Workouts (08), Health-Daten (07). Demo-Daten werden explizit vom Nutzer abgelehnt, stattdessen werden echte FIT-Dateien zur Verfügung gestellt.

## Abnahme
### Automatisch prüfbar
- [ ] `flutter analyze`, `flutter test`, Functions-Build und -Tests grün
- [ ] Parser-Tests für alle genannten Dateitypen und Fehlerfälle grün, Idempotenz (doppelter Upload) getestet
- [ ] Rules-Tests: Client kann `activities` nicht schreiben, fremde Dateien nicht lesen, Größenlimit greift
- [ ] Zeitzonen-Tests (Mitternacht, Zeitzonenwechsel) grün
### Manuell (ich)
- [ ] Vom Nutzer bereitgestellte FIT-Dateien (Rad/Lauf/Schwimmen) hochladen: Werte stimmen überein
- [ ] Listen- und Detailansicht fühlen sich gut an
- [ ] Fehlerfall (kaputte Datei) ist verständlich erklärt

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `MANUAL_STEPS.md` (eigene FIT-Dateien), `DATA_MODEL.md`.
