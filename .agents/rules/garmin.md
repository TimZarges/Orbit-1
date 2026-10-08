---
trigger: model_decision
description: "Anwenden bei Arbeit an Garmin-Anbindung, Aktivitäts-Import, FIT-Dateien, Webhooks, OAuth, Provider-Connectoren und Health-Daten-Sync."
---

# Import- und Garmin-Regeln

**Vollständig lesen:** @docs/specs/GARMIN.md

1. **Aktuelle Garmin-Doku zuerst lesen** (OAuth, Endpunkte, Webhooks, Pflichten) und mir zusammenfassen (STOPP). Nicht aus dem Gedächtnis implementieren.
2. Anbieterneutral über `ProviderConnector`. FIT-Parsing **nur serverseitig** (`@garmin/fitsdk`).
3. Webhook: sofort `200`, Roh-Payload nach `webhookEvents`, Verarbeitung per Firestore-Trigger mit Retry. Idempotenz über `(source, externalId)`.
4. Tokens und Secrets **nur serverseitig** (Secret Manager, `users/{uid}/private/integrations`), nie im Client, nie im Log, nie im Repo.
5. FIT-Upload und Demo-Daten nutzen **dieselbe Pipeline** wie Garmin und sind der Weg, solange kein Garmin-Zugang vorliegt.
6. Multisport/Triathlon als `MULTISPORT` mit `segments[]`; Pool und Freiwasser unterscheiden; unbekannte Typen → `OTHER`.
