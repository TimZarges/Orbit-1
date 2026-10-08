# Phase 05: Metrik-Kern (Berechnung, Aggregation, ORBIT Score)

**Branch:** `feature/phase-05-metrics-core` · **Voraussetzungen:** Phase 03 (Schwellenwerte), Phase 04 (Aktivitäten) · **Risiko:** hoch (Formeln, Wahrheit der Zahlen)

## Ziel
Aus jeder Aktivität entstehen korrekte, nachvollziehbare Kennzahlen. Tages- und Wochenbelastung (CTL/ATL/TSB) werden pro `localDate` aggregiert. Die Zahlen sind durch gemeinsame Testvektoren abgesichert, ihre Methoden dokumentiert. Der ORBIT Score ist als **vorläufige** Definition vorbereitet.

## Vorher lesen
`AGENTS.md`, `.agents/rules/metrics.md`, `docs/specs/METRICS.md` (komplett), `docs/DATA_MODEL.md` (`metrics`, `thresholdHistory`, `aggregates`), Aktivitäts-Pipeline aus Phase 04.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Methodenwahl dokumentieren:** rTSS vs. hrTSS (Lauf), sTSS-Formel (Schwimmen), Behandlung fehlender Daten (kein FTP, keine HF, Indoor ohne Leistung), CTL/ATL-Konstanten und Startwert, Glättung/Nullwerte bei NP, Umgang mit Pausen. Pro Methode: Formel, Quelle/Begründung, Grenzen.
2. **STOPP 1 [RISIKO-HOCH]:** Methodenpapier zeigen (kurz, `DECISIONS.md`). Ich gebe frei, bevor die Berechnung gebaut wird.
3. **Testvektoren zuerst:** `testvectors/<metrik>.json` (Format `{id, description, input, expected, tolerance}`). Mindestens: konstante Leistung (NP = Ø, IF = Leistung/FTP, TSS bei 1 h am FTP = 100), variable Leistung (handgerechnet), Pausen/Lücken, NP bei < 30 s Daten, CTL/ATL für eine bekannte Tagesfolge, Zonenverteilung, Schwimm-Pace/SWOLF, leere und kaputte Eingaben. Erwartete Werte **unabhängig** herleiten (handgerechnet oder aus der Formel in einem separaten Skript), nicht aus der eigenen Implementierung.
4. **Metriken in TypeScript** (`functions/src/metrics/`): NP, IF, TSS, VI, Zonenverteilung (HF/Leistung/Pace), Lauf-Belastung, Schwimm-Belastung (sTSS), Aerobic Decoupling, Qualität `metrics.quality` (`COMPLETE`/`ESTIMATED`/`INSUFFICIENT`) je nach vorhandenen Schwellenwerten. Reine Funktionen, **deutsch kommentierte Formeln**, keine Firebase-Abhängigkeit im Kern.
5. **Dart-Vorschau** (klein, nur für den Workout Builder in Phase 09): geschätzte Belastung aus Dauer und Intensität. Testet gegen **dieselben** Testvektoren-Dateien.
6. **Trigger `onActivityWritten`:** Schwellenwerte zum `localDate` aus `thresholdHistory` laden (jüngster Eintrag mit `effectiveFrom ≤ localDate`), `thresholdsSnapshot`, `metrics`, `metricsVersion` schreiben. **Schleifenschutz:** Der Trigger darf nicht von seinem eigenen Schreiben erneut feuern (Vergleich `metricsVersion`/Eingabe-Hash, Early Return). Idempotent.
7. **Aggregation:** `users/{uid}/aggregates/{localDate}` mit `dailyLoad`, `ctl`, `atl`, `tsb`. Änderung an einem Tag aktualisiert alle Folgetage (begrenzt, z. B. max. 365 Tage, Batch-Writes ≤ 500). Löschen einer Aktivität aktualisiert ebenfalls. Konsistenztest: Neuberechnung von vorn ergibt dieselben Werte wie inkrementelle Updates.
8. **`recomputeMetrics` (Callable):** Zeitraum wählbar, Schutz vor Missbrauch (nur eigener Athlet, Rate-Limit, Maximalspanne), Fortschrittsstatus, idempotent. Dient Phase 12 („Vergangene Einheiten neu berechnen").
9. **Zugriff:** Rules-Tests für `aggregates` (Athlet, Trainer mit Freigabe `activities`, Fremde nicht).
10. **ORBIT Score:** Entwurf in `docs/ORBIT_SCORE.md`, deutlich als **„VORLÄUFIG – nicht freigegeben"** gekennzeichnet (Definition, Formel, Annahmen, Grenzen, „keine medizinische Aussage", Verhalten bei dünner Datenlage). Reine Funktion mit Tests, **noch nicht in der UI**.
11. **STOPP 2 [RISIKO-HOCH]:** ORBIT-Score-Definition zur Freigabe. Im Autopilot bleibt sie vorläufig und wird in Phase 10 nicht angezeigt, bis ich freigebe.
12. **Performance-Check:** Verarbeitung einer 6-Stunden-Aktivität (ca. 21.600 Punkte) und einer Rückrechnung über 1 Jahr: Laufzeit und Reads/Writes messen und in `DECISIONS.md` festhalten.

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 1 (Methodenpapier)
- **STOPP 2 [RISIKO-HOCH]** nach Aufgabe 10 (ORBIT Score, vorläufig)

## Nicht-Ziele
UI für Kennzahlen (Phase 10–12), Power-Duration-Kurve und Bestwerte (11), Schwellenwert-Schätzung (12), Health-Metriken (07).

## Abnahme
### Automatisch prüfbar
- [ ] Alle Testvektoren grün in **TypeScript und Dart**, beide Seiten lesen dieselben Dateien
- [ ] `functions` Build und Tests grün, `flutter analyze`/`test` grün
- [ ] Trigger-Tests: kein Schleifen-Feuern, Idempotenz, Lösch- und Update-Fälle, Schwellenwert-Wechsel am Stichtag
- [ ] Inkrementelle Aggregation == vollständige Neuberechnung (Property-/Vergleichstest)
- [ ] Rules-Tests für `aggregates`
### Manuell (ich)
- [ ] Stichprobe: Werte einer meiner echten Einheiten (NP/TSS) mit Garmin Connect/Trainings-Software vergleichen, Abweichungen verstehen
- [ ] Methodenpapier gelesen und freigegeben, ORBIT-Score-Entwurf bewertet

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `docs/ORBIT_SCORE.md` (vorläufig), `docs/specs/METRICS.md` bei Bedarf.
