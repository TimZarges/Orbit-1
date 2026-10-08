# Phase 10: Analyse einfach (Ampel, Wochenbelastung, Erfahrungsstufen)

**Branch:** `feature/phase-10-analysis-simple` · **Voraussetzungen:** Phase 05 (Metriken, Aggregate), 07 (Tagesform-Karte), 08 (Plan) · **Risiko:** hoch (Aussagen an Nutzer, Wortlaut)

## Ziel
Der Tab **Analyse** beantwortet in Sekunden: *Wie fit bin ich, wie belastet war die Woche, liege ich im Plan?* Er ist für Einsteiger verständlich und wächst über die Erfahrungsstufen mit. Die Detailanalyse einer Aktivität zeigt die einfache Ebene, die Tiefe folgt in Phase 11.

## Vorher lesen
`AGENTS.md`, `docs/DESIGN.md` (komplett, besonders §7a, §8), `docs/specs/METRICS.md` (Ergänzung A: Form-Ampel), `docs/ORBIT_SCORE.md` (vorläufig), `.agents/rules/design.md`.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Informationsarchitektur** des Tabs (Skizze in `docs/DECISIONS.md` oder Galerie-Prototyp): Zeitraumwahl (Woche/Monat/Saison), Reihenfolge der Karten je Stufe, was *Einfach*, *Fortgeschritten*, *Experte* jeweils zeigen. **Vorschlag:** Einfach = Form-Ampel, Wochenbelastung vs. Plan, Konsistenz. Fortgeschritten = zusätzlich Sportverteilung, Zonenverteilung, 8-Wochen-Verlauf. Experte = zusätzlich CTL/ATL/TSB-Verlauf und Fachkürzel.
2. **Form-Ampel-Logik** (reine Funktion, getestet): Zustand aus TSB relativ zur individuellen CTL, Schwellen als **Konfiguration**, Mindestdatenlage, Datenbasis-Text („basiert auf 6 Wochen Training"). Zustände und Texte gemäß METRICS Ergänzung A.
3. **STOPP 1 [RISIKO-HOCH]:** Wortlaut aller Texte (de + en), Schwellen, Mindestdatenlage und der Karten-Prototyp zeigen. Kriterien: neutral, nachvollziehbar, **kein** medizinischer Rat, keine Anweisungen, ehrliche Unsicherheit. Der **ORBIT Score** wird nur angezeigt, wenn ich ihn freigegeben habe (sonst weglassen).
4. **Karten (Bausteine, wiederverwendbar im Home):** Form-Ampel, Wochenbelastung vs. Plan (Balken Ist/Soll, Abweichung als Klartext), Konsistenz (Trainingstage), Sportverteilung (Dauer je Sport, Balken statt Torte), Schwellen-Fortschritt als Platzhalter-Karte (Phase 12). Jede Kennzahl mit **Info-Icon** (Glossar aus Phase 03). Begriffe über `TermResolver`.
5. **Verläufe:** 8-Wochen-Belastung und CTL/ATL/TSB-Linie (leichtgewichtig, aus `aggregates`, **nicht** aus Rohaktivitäten). Chart-Technik gemäß Phase-00-Entscheidung. Zugängliche Textzusammenfassung zu jedem Chart („Belastung in den letzten 8 Wochen gestiegen").
6. **Aktivitätsdetail, einfache Ebene:** Kennzahlen je Sportart, Zonenverteilung als beschrifteter Balken, Soll-Ist-Hinweis (falls geplant), Segmente (Multisport). Button „Mehr Details" führt später ins Cockpit (jetzt deaktiviert mit Hinweis).
7. **Zustände:** Skeleton-Loader, Empty State („Noch keine Daten, verbinde Garmin / importiere / Demo"), **zu wenig Daten** (erklärt, was fehlt), Fehler mit Wiederholen. Demo-Daten müssen sinnvolle Aussagen ergeben.
8. **Athleten-Kontext:** Der Trainer sieht dieselben Karten für den Athleten (Rules über Freigabe `activities`, Health-Anteile nur mit `health`). Kopfbereich nennt den Athleten.
9. **Performance:** Nur Aggregate und begrenzte Zeiträume laden, Paginierung der Aktivitäten, Streams werden hier **nicht** geladen.
10. **Barrierefreiheit:** Zonen nie nur über Farbe, Textalternativen für Charts, Kontrast, Textskalierung 1,3, Tippflächen ≥ 48 dp.
11. Lokalisierung, Galerie, **Golden Tests je Stufe** (Einfach/Fortgeschritten/Experte) und Zustände (genug Daten, zu wenig, leer, Fehler).

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 2 (Texte, Schwellen, Prototyp)

## Nicht-Ziele
Telemetrie-Charts, Karte, Power-Duration-Kurve (Phase 11), Schwellenwert-Vorschläge (12), Push (13), Trainingsempfehlungen für Einheiten („heute lieber locker") als Anweisung.

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün, Ampel-Logik inkl. Grenz- und Mindestdatenfälle, `TermResolver`-Abdeckung
- [ ] Golden Tests für 3 Stufen × Zustände
- [ ] Widget-Tests: Stufenwechsel zur Laufzeit ändert Begriffe und Kartenmenge
- [ ] Keine Rohaktivitäten-Abfragen im Analyse-Tab (Code-Review per Suche), Reads pro Öffnung dokumentiert
### Manuell (ich)
- [ ] Mit Demo und eigenen Daten: Aussagen stimmen mit meinem Gefühl überein, verstehen Einsteiger sie?
- [ ] Texte (de/en) von mir freigegeben
- [ ] Gerätetest: Scrollen, Zeitraumwechsel, Info-Sheets fühlen sich flüssig an

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `docs/specs/METRICS.md` (finale Ampel-Schwellen).
