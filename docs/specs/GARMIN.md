# Spec: Garmin-Anbindung (Verifizierte Fakten)

> **Datum:** 2026-10-09
> **Quelle:** Offizielles Garmin Connect Developer Program & Developer Portal (zusammengefasst)

## Programm-Status & Zugang
- Der produktive Zugang zur Health und Activity API ist **nicht** rein Self-Service. Er erfordert ein formalisiertes Partnership-Agreement ("Application Approval").
- Ohne dieses Approval (oder im Rahmen einer Evaluierung) läuft die Anwendung im Development-Modus mit simulierten User-Daten oder beschränkt auf Test-Accounts.
- **Konsequenz für ORBIT:** Da aktuell keine Freigabe vorliegt, wird die Integration vollständig als Mock/Simulation über interne Test-Webhooks umgesetzt (Phase 06 "Mock-Modus").

## Authentifizierung (OAuth)
- **Standard:** Garmin nutzt aktuell **OAuth 2.0** (oft mit PKCE für mobile Apps) oder OAuth 1.0a in älteren Legacy-Schnittstellen. Wir implementieren OAuth 2.0.
- **Tokens:** Access-Tokens und Refresh-Tokens (bei OAuth 2.0) müssen sicher serverseitig gespeichert werden (`users/{uid}/private/integrations/garmin`).

## Webhooks (Push-Architektur)
- **Architektur:** Push-basiert. Sobald der Nutzer synchronisiert, pusht Garmin JSON-Daten an unsere registrierte Callback-URL.
- **Antwortzeit:** Unser Webhook muss **sofort mit HTTP 200 (OK)** oder 202 (Accepted) antworten. Längeres Blockieren führt zu Timeouts und Retries seitens Garmin.
- **Ping/Pong:** Webhook-URL muss auf Validierungsanfragen (Pings) von Garmin reagieren können, um die Endpunkt-Gesundheit zu bestätigen.
- **Deregistrierung:** De-Authorization Events werden über Webhooks gesendet. Wir müssen daraufhin die lokalen Garmin-Tokens löschen und den Verbindungsstatus auf "Getrennt" setzen.

## Backfill
- **Mechanik:** Abruf historischer Daten ist über einen asynchronen Backfill-Request möglich. Der Endpunkt liefert typischerweise ein `HTTP 202 (Accepted)`. Die eigentlichen historischen Daten kommen dann häppchenweise über den Webhook rein.
- **Limitationen:** Nicht beliebig weit in die Vergangenheit möglich (oft auf wenige Wochen oder Monate nach Genehmigung beschränkt).

## Zusammenfassung für Phase 06
Da kein Entwickler-Secret vorhanden ist, implementieren wir einen **simulierten ProviderConnector** (`mockGarminConnector`) und eine simulierte Webhook-Verarbeitung, die exakt das Verhalten der Garmin-Architektur spiegelt:
- Asynchroner Verbindungsfluss.
- Empfang von Webhooks (JSON-Payload nach `webhookEvents`).
- Firestore-Trigger verarbeitet die Daten.
