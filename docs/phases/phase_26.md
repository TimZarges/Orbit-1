# PHASE 26 — Backend-Regionen-Fix (europe-west3), Package-Konsistenz, App Check & Onboarding-Reparatur

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH — Firebase-Regionen, Authentifizierung, App Check & Onboarding-Flow).
- **Pflicht (DSGVO & Architektur):** Alle Cloud Functions laufen ausnahmslos in `europe-west3` (Frankfurt). Sämtliche Client-Aufrufe (`FirebaseFunctions.instanceFor(region: 'europe-west3')`) müssen konsistent konfiguriert sein. Keine stillen Fallbacks auf `us-central1`.
- **Sofortiges USB-Update:** Jeder Fix wird sofort neu gebaut und per `adb install -r` auf das Pixel 10 Pro aufgespielt und verifiziert.

---

## Arbeitspakete

### 26.1 Konsistente Backend-Region `europe-west3` im Client
1. Audit aller Dart-Dateien im Client: Aufspüren von `FirebaseFunctions.instance` ohne explizite Regionenangabe.
2. Sicherstellen, dass überall ein zentraler Provider oder `FirebaseFunctions.instanceFor(region: 'europe-west3')` verwendet wird (insbesondere in Auth-, Garmin-, Metrics-, Coach- und Diagnostics-Providern).
3. Verifikation gegen das Live-Backend: Aufrufe wie `setInitialRole` oder `createInvite` müssen direkt Frankfurt (`europe-west3`) ansteuern und HTTP 200 liefern.

### 26.2 Package- & Signing-Konsistenz (`app.orbit.training`)
1. Android-Konsistenz sicherstellen:
   - `namespace = "com.example.orbit"` für internen Java/R-Code.
   - `applicationId = "app.orbit.training"` als externe App-Identität.
   - `google-services.json` mit beiden Paketnamen synchronisiert.
   - `MainActivity.java` sauber in den Java-Sources verankert.
2. App Check & Play Integrity:
   - Konfiguration von `AppCheckService` für Release- und Sideload-Builds mit sicherem Fallback ohne Crash.

### 26.3 Onboarding-Reparatur & Erstinitialisierung
1. Fehlerfreie Registrierung / Login auf dem Pixel 10 Pro.
2. Durchlaufen aller 4 Schritte ohne UI-Überlappung oder Ausblenden der Tastatur.
3. Erfolgreiches Abspeichern des Nutzerdokuments mit `role`, `profile`, `experienceLevel` und erstem `thresholdHistory`-Eintrag.

---

## STOPP-Punkt 1 (Abnahme Phase 26)
- Nachweis der erfolgreichen Registrierung und Onboarding auf dem Pixel 10 Pro mit Screenshot und Logcat.
- Nachweis `0 Errors, 0 Warnings` im Analyzer und grüne Tests.
- Freigabe durch Tim -> Commit & Tag `v0.26.0`.
