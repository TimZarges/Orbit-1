# Phase 07: Health-Daten

**Branch:** `feature/phase-07-health-data` · **Voraussetzungen:** Phase 04–06 (Pipeline, Garmin-Connector, Demo-Modus) · **Risiko:** hoch (Gesundheitsdaten, Formulierungen)

## Ziel
Schlaf, Ruhepuls, HRV und weitere verfügbare Tageswerte werden importiert und als **verständliche Tagesform** dargestellt. Trainer sehen sie nur mit ausdrücklicher Freigabe. Die Darstellung bleibt sachlich, ohne medizinische Aussagen.

## Vorher lesen
`AGENTS.md`, `docs/DATA_MODEL.md` (`dailyMetrics`, `coachLinks.permissions.health`), `docs/specs/GARMIN.md` (Health-Teil), `docs/DESIGN.md` (§7a, §8), `.agents/rules/data-and-security.md`.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Verfügbarkeit klären:** Welche Health-Werte liefert die Garmin-Health-Schnittstelle laut verifizierter Doku (Schlaf, Ruhepuls, HRV, Stress, Body Battery, Schritte)? Nicht Verfügbares wird nicht erfunden, die UI blendet es aus. Ergebnis in `GARMIN.md` und `DECISIONS.md`.
2. **Import:** Health-Payloads → `users/{uid}/dailyMetrics/{localDate}` per Upsert (mehrere Zustellungen pro Tag werden **zusammengeführt**, idempotent). `localDate` über die Zeitzone/Offset des Nutzers. `source` (`GARMIN`/`DEMO`). Webhook-Verarbeitung über denselben `webhookEvents`-Weg wie Aktivitäten.
3. **Demo-Modus erweitern:** realistische Health-Tage (Schlaf mit Schwankung, Ruhepuls-Trend, HRV mit Ausreißern, erholte und müde Phasen), konsistent zu den Demo-Aktivitäten.
4. **Basislinie und Einordnung (reine Funktion, getestet):** persönliche Basislinie aus den letzten 28 Tagen (robuster Mittelwert/Median, Ausreißer behandelt). Abweichung heute vs. Basislinie in drei Stufen (unauffällig / etwas abweichend / deutlich abweichend). **Mindestdatenlage** (z. B. ≥ 14 Tage), sonst „Noch zu wenig Daten".
5. **STOPP 1 [RISIKO-HOCH]:** Wortlaut der Texte (de + en) und Schwellen der Einordnung zeigen. Kriterien: sachlich, **keine** Diagnosen, keine Heilsversprechen, keine Alarmformulierungen, bei deutlicher Abweichung neutraler Hinweis („Erholung beachten, bei Beschwerden ärztlichen Rat einholen") ohne Panik. Ich gebe frei.
6. **Tagesform-Karte** (Baustein, später im Home und in der Analyse): *Einfach* = Ampel + ein Satz, *Fortgeschritten* = Werte (Schlaf, Ruhepuls, HRV) + 7-Tage-Trend, *Experte* = HRV-/Ruhepuls-Verlauf mit Basislinien-Band über 28 Tage. Info-Icons mit Erklärung. Fehlende Werte werden ausgeblendet. Skeleton/Empty State („Noch keine Health-Daten, verbinde dein Garmin-Konto").
7. **Trainer-Zugriff:** nur mit `permissions.health == true` (Rules via `get()` auf `coachLinks/{athleteId}_{coachId}`, Rules-Tests inkl. Widerruf). Ohne Freigabe zeigt die Trainer-UI einen **freundlichen Hinweis** („Der Athlet hat Health-Daten nicht freigegeben"), keinen Fehler.
8. **Datenschutz:** Health-Daten sind in Export und Kontolöschung enthalten (Tests). Widerruf der Health-Freigabe wirkt sofort (Trainer sieht nichts mehr). Keine Health-Werte in Logs oder Push-Texten.
9. Lokalisierung, Galerie-Einträge, Golden Tests (3 Stufen × Zustände: genug Daten, zu wenig Daten, keine Daten).

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 5 (Texte und Schwellen der Tagesform)

## Nicht-Ziele
Manuelle Eingabe von Health-Werten, Schlafphasen-Details, Empfehlungen für Training aus Health-Daten (Phase 10/14 verbinden höchstens die Karte), Verknüpfung mit Medizinprodukten.

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün; Upsert-/Merge-Tests (mehrere Zustellungen je Tag), Zeitzonen-Tests
- [ ] Basislinien-Tests (Ausreißer, zu wenig Daten, Lücken)
- [ ] Rules-Tests: Trainer ohne `health`-Freigabe sieht nichts, mit Freigabe schon, nach Widerruf wieder nichts
- [ ] Export und Löschung enthalten `dailyMetrics`
### Manuell (ich)
- [ ] Mit echtem oder Demo-Datensatz: Karte wirkt verständlich und beruhigend, nicht alarmierend
- [ ] Texte (de/en) von mir geprüft und freigegeben
- [ ] Freigabe für Trainer umschalten und Wirkung beobachten

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `DATA_MODEL.md`, `docs/PRIVACY.md` (Health-Verarbeitung ergänzen).
