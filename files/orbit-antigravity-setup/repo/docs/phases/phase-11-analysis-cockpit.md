# Phase 11: Analyse Cockpit (Telemetrie, Karte, Power-Kurve)

**Branch:** `feature/phase-11-analysis-cockpit` · **Voraussetzungen:** Phase 04 (Streams), 05 (Metriken), 10 (einfache Ebene), Entscheidungen aus Phase-00-Spikes (Chart, Karte) · **Risiko:** hoch (Performance, Datenschutz Karte)

## Ziel
Die Tiefenansicht einer Aktivität im dunklen Cockpit: Telemetrie mit Kanalwahl, Scrubbing und synchroner Karte, Zonenverteilung, Power-Duration-Kurve und Belastungsverlauf. Sie läuft flüssig auf einem Mittelklasse-Android-Gerät und respektiert den Datenschutz bei Karten.

## Vorher lesen
`AGENTS.md`, `docs/DESIGN.md` (§1, §3.2, §8), `docs/DECISIONS.md` (Chart- und Karten-Entscheidung aus Phase 00), `docs/DATA_MODEL.md` (Streams, `bests`), `docs/specs/METRICS.md` (MMP).

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Technik-Check:** Lies das Ergebnis der Spikes S1/S2. Wurde die Chart-Performance noch **nicht** auf einem Gerät gemessen, entscheide vorläufig anhand des Benchmark-Harness, dokumentiere es in `docs/CHECKPOINTS.md` und plane die Gerätemessung als manuellen Schritt ein.
2. **STOPP 1 [RISIKO-MITTEL]:** Bestätigung der Chart-Technik, des Kartenanbieters (DSGVO: IP-Weitergabe, Nutzungsbedingungen, Kosten), der Performance-Ziele (z. B. Ziel-Framezeit bei 2-h-Aktivität) und des Einwilligungsablaufs für externe Kartenkacheln.
3. **Stream-Ladung:** `streams.json.gz` laden, in einem **Isolate** dekodieren, Ergebnis je Aktivität im Speicher halten (Größenbegrenzung, Freigabe beim Verlassen). Fehlende Kanäle sind normal (kein Leistungsmesser, kein GPS), die UI blendet sie ohne Fehler aus. Sehr lange Aktivitäten (10 h) getestet.
4. **Aufbereitung:** gemeinsame Zeitachse, optional **Distanzachse** (monoton, Pausen behandelt), Downsampling (z. B. LTTB) passend zur Bildschirmbreite, Zoom/Auswahlbereich erzeugt Neuberechnung im Isolate. Reine Funktionen mit Tests.
5. **Telemetrie-Chart:** Kanal-Chips (Leistung, HF, Pace/Speed, Kadenz, Höhe als Backdrop, Temperatur), Farben aus `DESIGN.md` §3.2, Umschalter „Nach Zeit / Nach Distanz", Zonen als **dezentes Hintergrundband (≤ 15 % Deckkraft)**, Schwimm-Pace mit umgekehrter Achse (kleiner = schneller). Runden/Segmente als Markierungen, Antippen hebt den Abschnitt hervor.
6. **Scrubbing:** **Long-Press-to-Scrub** (kein Konflikt mit Seiten-Scrollen), **Vollbild im Querformat** als zweite Option, HUD **über** dem Finger mit Live-Werten aller sichtbaren Kanäle, Haptik bei Zonenwechsel, Marker synchron zur Karte (und umgekehrt).
7. **Karte:** Anbieter gemäß STOPP 1, Polyline der Aktivität (optional nach Kanal eingefärbt), Marker synchron, Start/Ziel. **Einwilligungsabfrage vor dem ersten Laden externer Kacheln** („Beim Laden der Karte werden Daten an <Anbieter> übertragen", merken/widerrufen in den Einstellungen). Ohne Einwilligung oder ohne GPS: Platzhalter mit Erklärung.
8. **Zonenverteilung (Detail):** Zeit in Zonen für HF, Leistung, Pace (je nach Stufe und verfügbaren Daten), beschriftete Balken.
9. **Bestwerte (Backend):** Trigger pflegt `users/{uid}/bests/{sport}`: Rad-Mean-Maximal-Power für definierte Dauern (z. B. 1 s … 60 min) für Saison und Allzeit, Lauf-Bestzeiten für definierte Distanzen. Tests mit Testvektoren, Rules (Athlet, Trainer mit Freigabe).
10. **Power-Duration-Kurve:** Kurve der aktuellen Aktivität im Vergleich zu Saison- und Allzeit-Bestwerten (Logarithmische Dauerachse), Highlights neuer Bestwerte als „PR"-Badge in Volt-Fläche mit Navy-Text.
11. **Belastungsverlauf (Cockpit):** CTL/ATL/TSB über die Saison, Wettkampfziel als Marker, optional Projektion mit geplanter Belastung (klar als Projektion gekennzeichnet).
12. **Lazy Loading:** Chart- und Kartenwidgets werden nur gebaut, wenn sichtbar, die Seite bleibt sofort bedienbar. Skeleton während der Dekodierung.
13. **Performance-Nachweis:** Benchmark-Harness (Debug) mit synthetischer 2-h- und 10-h-Aktivität, Frame-Zeiten im Profile-Mode, Ergebnis in `DECISIONS.md`. Gerätemessung durch mich als manueller Schritt.
14. **Athleten-Kontext:** Trainer öffnet dieselbe Ansicht (Freigabe `activities`), Kopfbereich zeigt den Athleten.
15. Lokalisierung, Galerie, Golden Tests (Cockpit-Zustände: volle Daten, ohne GPS, ohne Leistung, Fehler), Zugänglichkeit (Tabellenalternative zum Chart für Screenreader).

## STOPP-Punkte
- **STOPP 1 [RISIKO-MITTEL]** nach Aufgabe 1 (Technik, Karte, Einwilligung, Performance-Ziele)
- **STOPP 2 [RISIKO-MITTEL]** nach Aufgabe 13 (Performance-Bericht vor dem Feinschliff)

## Nicht-Ziele
Datenschutzzonen für Start/Ziel, Segment-Vergleiche, Live-Tracking, Schwimm-Bestwerte, Schwellenwert-Vorschläge (Phase 12).

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün, Aufbereitungs-/Downsampling-/Bestwerte-Tests, Rules-Tests für `bests`
- [ ] Widget-Tests: fehlende Kanäle, fehlendes GPS, Einwilligung verweigert, 10-h-Aktivität
- [ ] Golden Tests der Cockpit-Zustände
- [ ] Benchmark-Harness vorhanden, Messprotokoll im Repo
### Manuell (ich)
- [ ] Gerätemessung (Profile-Mode, Mittelklasse-Android): flüssig bei 2-h-Aktivität, kein Jank beim Scrubbing
- [ ] Scrubbing per Long-Press und im Querformat fühlt sich gut an, HUD verdeckt nichts
- [ ] Karten-Einwilligungstext geprüft

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `DATA_MODEL.md`, `docs/PRIVACY.md` (Kartenanbieter ergänzen), `MANUAL_STEPS.md`.
