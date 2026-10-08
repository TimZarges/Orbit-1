# Phase 06: Garmin-Connector

**Branch:** `feature/phase-06-garmin-connector` · **Voraussetzungen:** Phase 04 (Pipeline), Phase 05 (Metriken). Idealerweise Garmin-Entwicklerzugang freigegeben, sonst Mock-Modus · **Risiko:** hoch (Fremd-API, OAuth, Webhooks, Secrets)

## Ziel
Ein Nutzer verbindet sein Garmin-Konto, seine Aktivitäten kommen automatisch in ORBIT an (inklusive Nachladen der Historie). Verbindung, Fortschritt und Fehler sind sichtbar, das Trennen funktioniert sauber. Ohne Garmin-Zugang läuft alles vollständig gegen Mocks und ist dort getestet.

## Vorher lesen
`AGENTS.md`, `.agents/rules/garmin.md`, `docs/specs/GARMIN.md`, `docs/DATA_MODEL.md` (`private/integrations`, `integrationStatus`, `webhookEvents`), Pipeline aus Phase 04.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Garmin-Doku lesen** (offizielle Dokumentation des Garmin Connect Developer Program, `developer.garmin.com`): OAuth-Verfahren, Endpunkte, Push-/Ping-Mechanik, Payload-Formate, Rate-Limits, Pflichtfunktionen (z. B. Deregistrierung, Berechtigungsänderungen, Löschanfragen), Backfill-Regeln, Branding- und Review-Anforderungen. Ergebnis als verifizierte Fakten in `docs/specs/GARMIN.md` einarbeiten (mit Quellenangabe, Datum). Nichts aus dem Gedächtnis annehmen. Ist die Seite nicht erreichbar oder der Zugang nicht freigegeben: Stand vermerken und mit Mock-Modus fortfahren.
2. **STOPP 1 [RISIKO-HOCH]:** Zusammenfassung der verifizierten Garmin-Fakten und der geplanten Umsetzung (Flows, Endpunkte, Datenspeicherung). Ich gebe frei.
3. **`ProviderConnector`-Schnittstelle** (TypeScript): `connect`, `disconnect`, `backfill`, `handleWebhook`, `mapActivity`. Garmin = erste Implementierung. Die Verarbeitung einer Aktivität ruft **dieselbe Pipeline** wie der FIT-Upload (`source: "GARMIN"`, `externalId` = Garmin-ID).
4. **Secrets:** Consumer-Key/Secret nur im Secret Manager (`defineSecret`), nie im Repo. Tokens ausschließlich in `users/{uid}/private/integrations` (für Clients gesperrt, Rules-Test).
5. **OAuth-Flow:** Callable startet den Flow, App öffnet Custom Tab, Callback als HTTPS-Function, Rücksprung in die App (Android App Link, Voraussetzung `assetlinks.json` siehe `MANUAL_STEPS.md`). Zustandsparameter (CSRF-Schutz), Ablauf, Fehlerfälle (Abbruch, Ablehnung, Zeitüberschreitung).
6. **Webhook-Endpunkte:** prüfen, **sofort mit 200 antworten**, Roh-Payload nach `webhookEvents` (Status `RECEIVED`). Verarbeitung per **Firestore-Trigger** (Status `PROCESSED`/`FAILED`, Retry mit Obergrenze, Dead-Letter-Markierung). Idempotenz über `(source, externalId)`. Behandle neue, geänderte und gelöschte Aktivitäten sowie Deregistrierung/Berechtigungsentzug (Verbindung auf `DISCONNECTED`, Tokens löschen).
7. **Backfill:** Callable `garminBackfill` mit Zeitraum innerhalb der Garmin-Grenzen, Fortschritt in `users/{uid}/integrationStatus/garmin` (`state`, `progress`, `from`, `to`, `errorCode`). Wiederaufnahme nach Fehler, keine Doppelimporte.
8. **Typ-Mapping:** Garmin-Aktivitätstypen → ORBIT-`sport`/`subSport` (Triathlon/Multisport → `MULTISPORT` mit `segments[]`, Pool vs. Freiwasser), unbekannt → `OTHER`. Tabelle als Test.
9. **Client-UI (Einstellungen → Verbindungen → Garmin):** Zustände (nicht verbunden, verbindet, verbunden, Fehler, Backfill läuft mit Fortschritt), Verbinden, Trennen (mit Frage „importierte Daten behalten oder löschen?"), verständliche Fehlermeldungen. First-Run-Option „Garmin verbinden" aus Phase 04 **aktivieren**.
10. **Mock-/Simulationsmodus:** Skript `functions/scripts/simulate-garmin` (nur Emulator/Dev, per Umgebungsvariable abgesichert, nie in Prod) sendet aufgezeichnete bzw. aus der Doku abgeleitete Payloads an den Webhook. Fixtures in `functions/test/fixtures/garmin/`.
11. **Tests:** Webhook-Verarbeitung (neu, geändert, gelöscht, doppelt, kaputt), OAuth-Zustandslogik, Backfill (Fortschritt, Wiederaufnahme), Mapping-Tabelle, Rules (Tokens nie lesbar, `integrationStatus` nur lesbar).
12. **STOPP 2 [RISIKO-HOCH]:** Sicherheits-Review der Endpunkte (öffentlich erreichbar: Eingabevalidierung, Größenlimit, Missbrauchsschutz, Logging ohne personenbezogene Daten, Geheimnisse) und `/security-check`, bevor irgendetwas gegen die echte Garmin-API geschaltet wird.

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 1 (Garmin-Fakten und Umsetzungsplan)
- **STOPP 2 [RISIKO-HOCH]** nach Aufgabe 11 (Sicherheits-Review)

## Nicht-Ziele
Strava/Wahoo/Polar u. a., Workout-Export zu Garmin (nur Schnittstelle, Phase 09), Health-Daten (Phase 07), Live-Betrieb ohne Freigabe.

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün (Functions, Flutter), Rules-Tests grün
- [ ] Mock-Durchlauf: simulierter Webhook → Aktivität in der Liste, Doppelzustellung erzeugt kein Duplikat
- [ ] Keine Secrets im Repo oder Log (Stichprobe per Suche), Tokens nur serverseitig
- [ ] Trennen widerruft/entfernt Tokens, Rückfrage-Pfad „Daten löschen" getestet
### Manuell (ich)
- [ ] Garmin-Zugang freigegeben, Secrets im Secret Manager, Webhook-URLs im Garmin-Portal eingetragen
- [ ] Eigenes Garmin-Konto verbinden, eine echte Aktivität erscheint in ORBIT, Werte stimmen
- [ ] Backfill der letzten Wochen funktioniert, Trennen und erneutes Verbinden funktioniert

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `MANUAL_STEPS.md`, `docs/specs/GARMIN.md` (verifizierter Stand), `DATA_MODEL.md`.
