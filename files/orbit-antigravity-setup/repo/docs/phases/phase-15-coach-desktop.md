# Phase 15: Coach-Desktop und Web

**Branch:** `feature/phase-15-coach-desktop` · **Voraussetzungen:** Phase 02 (Athletenliste/Kontext), 08–09 (Kalender, Builder), 10–13 · **Risiko:** hoch (Performance bei vielen Athleten, Web-Besonderheiten)

## Ziel
Trainer arbeiten am Rechner effizient mit vielen Athleten: Übersicht mit Status auf einen Blick, Mehrathleten-Wochenraster, Drag & Drop, Massenzuweisung, speicherbare und anpassbare Ansichten, Tastaturbedienung. Die App läuft als Web-App sauber im Browser.

## Vorher lesen
`AGENTS.md`, `docs/DESIGN.md` (§6 Breakpoints, §7), `docs/DATA_MODEL.md` (`coachDashboard`, `preferences`, `thresholdProposals`), Phasen 02, 08, 09, 13.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Web-Grundlagen klären:** Flutter-Web-Build (Renderer-/Build-Optionen laut aktueller Doku), Hosting (z. B. Firebase Hosting), Web-Login (Google), **App Check für Web** (Anbieter laut Firebase-Doku), Storage-CORS, Routing/Deep Links, Ladegröße. Ergebnis in `DECISIONS.md`.
2. **STOPP 1 [RISIKO-MITTEL]:** Funktionsumfang des Coach-Dashboards (MVP), Web-Entscheidungen, Performance-Ziele. Ich gebe frei.
3. **Adaptives Layout:** Breakpoints aus `DESIGN.md` (Compact/Medium/Expanded), NavigationRail, **Mehrspalten** (Master-Detail: Athletenliste links, Detail rechts mit Kalender/Analyse/Chat), Fensterbreiten 600/900/1280/1920 getestet.
4. **Dashboard-Daten (Server):** Functions pflegen `coachDashboard/{coachId}/athletes/{athleteId}` (Name, Foto, Form-Ampel, Soll-Ist-Erfüllung der letzten 7 Tage, Ungelesen, letzte Aktivität, Auffälligkeiten wie „7 Tage ohne Aktivität" oder „starker Belastungsanstieg", Wettkampfziel). Trigger auf Aktivitäten, Plan, Chat, Verknüpfung. Rules: nur der Trainer liest seine Dokumente, nur Functions schreiben. **Ein Dashboard-Aufruf = eine Abfrage**, nicht N pro Athlet. Tests inkl. Widerruf (Athlet verschwindet).
5. **Athletenliste:** Tabelle mit konfigurierbaren **Spalten** (Auswahl, Reihenfolge, Breite), Sortieren, Filtern (Sportart, Status, Stufe, Wettkampfdatum), Suche, Statusampeln mit Text, Mehrfachauswahl. Tastatur: Pfeile, Enter öffnet, `/` oder Strg/Cmd+K Suche.
6. **Speicherbare Ansichten:** `users/{coachId}/preferences/…` (Filter + Sortierung + Spalten, Standardansichten, benennen, löschen). Layout-Einstellungen pro Coach gespeichert, Rules-Tests.
7. **Mehrathleten-Wochenraster:** Zeilen = Athleten, Spalten = Tage, Zellen zeigen Plan/Ist als Chips (Sportfarbe + Icon), Wochenwechsel, Zoom/Dichte einstellbar. Klick öffnet Tag-Sheet.
8. **Drag & Drop:** geplante Einheiten zwischen Tagen und Athleten verschieben, **Alt/Option = kopieren**, Vorlage aus der Bibliothek auf eine Zelle ziehen, Undo für die letzte Aktion. **Zugängliche Alternative** (Menü „Verschieben nach …") bleibt bestehen.
9. **Massenzuweisung:** Vorlage oder Woche auf mehrere ausgewählte Athleten anwenden, **Vorschau vor dem Schreiben** (wer bekommt was, Konflikte), Batch-Writes (≤ 500), Rückgängig-Möglichkeit, Fortschritt. Nur Athleten mit Freigabe `calendar`.
10. **Schwellenwert-Vorschläge vom Trainer:** Trainer erstellt `thresholdProposals` für einen Athleten (Begründung optional), **nur der Athlet übernimmt** (Aufnahme in Phase-12-UI). Rules-Tests.
11. **Web-spezifisch:** saubere URLs je Screen und Athlet, Browser-Zurück/Vorwärts, Reload behält den Zustand, Seitentitel, Hover-States und Tooltips, Kontextmenü (Rechtsklick), Text markierbar, Maus-Scrubbing in Charts (Hover), **Drag-and-Drop-Upload von FIT-Dateien** für Athleten, Favicon/Manifest. Web-Push optional und nur, wenn der Aufwand gering ist, sonst Nicht-Ziel.
12. **Seed für Last-Tests (nur Emulator/Dev, per Umgebungsvariable abgesichert):** Skript erzeugt **25+ Test-Athleten** mit Demo-Daten und Verknüpfung zu einem Trainer-Konto. Messung: Dashboard-Ladezeit, Scroll-Performance, Reads pro Aufruf.
13. **Tests:** Widget-Tests der Tabelle/Raster, Drag-&-Drop-Logik als reine Funktionen, Batch-Zuweisung, Rules-Tests (`coachDashboard`, `preferences`, Massenzuweisung nur mit Freigabe), Golden Tests bei 3 Breiten.
14. Lokalisierung (de + en), Galerie, Tastaturkürzel-Übersicht (`?`).

## STOPP-Punkte
- **STOPP 1 [RISIKO-MITTEL]** nach Aufgabe 1 (Funktionsumfang, Web-Entscheidungen)

## Nicht-Ziele
Organisationen/Teams mit mehreren Trainern, Abrechnung, Mehrwochen-Trainingspläne als eigener Editor, native iOS-/Desktop-Installer, Trainer-Statistik über alle Athleten (Reporting).

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün, Rules-Tests (`coachDashboard`, Ansichten, Massenzuweisung, Trainer-Vorschläge)
- [ ] Functions-Tests: Dashboard-Pflege bei Aktivität/Plan/Chat/Widerruf, Idempotenz
- [ ] Golden Tests bei Breiten 600/900/1280/1920, kein Layout-Überlauf
- [ ] Seed-Skript ist gegen Produktivprojekte abgesichert (Test)
### Manuell (ich)
- [ ] Mit 25+ Test-Athleten: Dashboard lädt zügig, Tabelle und Raster bleiben flüssig
- [ ] Wochenplanung per Drag & Drop und Massenzuweisung fühlen sich effizient an
- [ ] Web-App im Browser (Chrome/Firefox/Safari) und auf dem Handy-Browser prüfen

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `DATA_MODEL.md`, `MANUAL_STEPS.md` (Hosting, Domain, App Check Web).
