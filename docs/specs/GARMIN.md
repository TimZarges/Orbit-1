# Spec: Garmin-Anbindung

> **Prüfe die aktuelle offizielle Garmin-Dokumentation** (Garmin Connect Developer Program), bevor du implementierst: OAuth-Version, Endpunkte, Webhook-/Ping-Verfahren, Rate-Limits, Pflichtfunktionen. Verlass dich nicht auf Gedächtnis. Diese Datei beschreibt nur unsere Architektur und Randbedingungen.

## Randbedingungen
- Zugriff auf Activity-/Health-API nur nach **Freigabe des Entwicklerkontos** (Antrag durch mich, siehe `MANUAL_STEPS.md`). Bis dahin: **FIT-Upload + Demo-Daten** (Phase 04) sind der vollwertige Weg, die Pipeline ist identisch.
- Garmin arbeitet **push-basiert**: Nach Nutzerautorisierung ruft Garmin unseren Webhook auf. Der Endpunkt ist eine HTTPS Cloud Function, die **sofort mit 200 antwortet**.
- Nach der Freigabe gelten Garmin-Vorgaben zu Branding/Quellenangabe und ein Review mit Testzugang (→ Demo-Modus, Phase 04).
- Garmin verlangt typischerweise die Verarbeitung von Deregistrierungs-/Berechtigungs-Änderungen. Gegen aktuelle Doku prüfen und umsetzen.

## Architektur
1. **Connector-Schnittstelle** `ProviderConnector` (anbieterneutral): `connect`, `disconnect`, `backfill`, `handleWebhook`. Garmin = erste Implementierung. Strava u. a. später ohne Umbau.
2. **OAuth:** Start in der App (Custom Tab), Callback über Cloud Function, Rücksprung in die App per **Android App Link** (`assetlinks.json` → `MANUAL_STEPS.md`). Tokens und Consumer-Secret **nur serverseitig** (Secret Manager, `users/{uid}/private/integrations`).
3. **Webhook → `webhookEvents`:** Der Endpunkt schreibt nur den Roh-Payload nach `webhookEvents` (Status `RECEIVED`) und antwortet. Eine **Firestore-getriggerte Function** verarbeitet ihn asynchron (Retry bei Fehlern, Status `PROCESSED|FAILED`). Kein Cloud Tasks/Pub/Sub im MVP.
4. **Aktivität verarbeiten:** FIT laden → mit `@garmin/fitsdk` serverseitig parsen → `activities`-Dokument (Idempotenz über `(source, externalId)`) → Streams downsampled nach Storage → Metriken (Spec `METRICS.md`) → Matching mit `plannedWorkouts` (Phase 08).
5. **Typ-Mapping:** Garmin-Aktivitätstypen → ORBIT-`sport`/`subSport`, unbekannt → `OTHER`. Multisport/Triathlon → `MULTISPORT` mit `segments[]` (inkl. Wechsel). Pool vs. Freiwasser unterscheiden.
6. **Health:** Schlaf, Ruhepuls, HRV, Stress/Body Battery (soweit verfügbar) → `dailyMetrics/{localDate}`.
7. **Backfill** nach dem Verbinden (Zeitraum gemäß Garmin-Vorgaben), Fortschritt in der UI.
8. **Trennen:** Tokens widerrufen, Garmin-Deregistrierung anstoßen, auf Wunsch importierte Daten löschen.

## Tests
Webhook-Verarbeitung gegen aufgezeichnete/mocked Payloads, Idempotenz (doppelter Aufruf), Fehlerfall (kaputtes FIT), Rules (Tokens nie lesbar).
