# PHASE 27 — Garmin Connect Live-OAuth, Android 11–16 `<queries>`, Deep-Link-Callback & 90-Tage-Backfill

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH — Garmin API, OAuth 1.0a, Android Intent-Filter, Secret Manager & Live-Sync).
- **Leitplanke:** Striktes Einhalten der Garmin Developer Vorgaben. Keine Klartext-Secrets im Client. Sicheres Öffnen des mobilen Garmin Connect Login-Browsers und Rücksprung in die App.

---

## Arbeitspakete

### 27.1 Android Package Visibility (`<queries>`) & Browser-Handshake
1. Ergänzung von `android/app/src/main/AndroidManifest.xml` um die notwendigen `<queries>`-Einträge für `https://`, Custom-Tabs und Garmin Connect Browser-Intents gemäß Android 11–16 Richtlinien.
2. `url_launcher` Konfiguration im Client mit sicherem Fallback (`mode: LaunchMode.externalApplication`).

### 27.2 Garmin OAuth 1.0a Flow & Deep-Link-Rücksprung
1. Prüfung und Korrektur von `garminAuthStart`:
   - Anfordern des Request-Tokens über die Cloud Function in `europe-west3`.
   - Generierung der korrekten Autorisierungs-URL (`connect.garmin.com/oauthConfirm`).
2. Deep-Link & Callback-Handling:
   - Konfiguration des Callback-Schemas (`app.orbit.training://oauth-callback` bzw. HTTPS-Universal-Link auf `orbit-app-mvp.web.app/garmin-callback`).
   - Austausch des Verifier-Tokens gegen Access-Tokens in `garminAuthCallback`.
   - Speicherung der Tokens im geschützten `garminTokens`-Dokument unter strikter Einhaltung von `firestore.rules`.

### 27.3 Automatischer 90-Tage-Backfill & Live-Status
1. Unmittelbares Triggern von `executeGarminBackfill(uid, 90)` in 3×30-Tage-Chunks nach erfolgreicher Kopplung.
2. Live-Statusanzeige im `GarminConnectionScreen` auf dem Pixel 10 Pro:
   - Statuswechsel von `DISCONNECTED` -> `CONNECTING` -> `CONNECTED`.
   - Rückmeldung über synchronisierte Aktivitäten und Vitaldaten.

---

## STOPP-Punkt 1 (Abnahme Phase 27)
- Nachweis der erfolgreichen Garmin-Kopplung auf dem Pixel 10 Pro (Screenshot + Logcat + Cloud Functions Log).
- Nachweis des eintreffenden Backfills oder Webhook-Empfangs.
- Freigabe durch Tim -> Commit & Tag `v0.27.0`.
