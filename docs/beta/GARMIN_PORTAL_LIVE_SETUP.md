# ORBIT — Garmin Developer Portal Live Setup & Webhook-Konfiguration

> **Gültig ab:** Phase 24 (Live-Setup für Production & Beta)  
> **GCP-Projekt-ID:** `orbit-app-mvp`  
> **Server-Region:** `europe-west3` (Frankfurt am Main, Deutschland)  
> **Basis-URL Cloud Functions:** `https://europe-west3-orbit-app-mvp.cloudfunctions.net`

Diese Anleitung führt Schritt für Schritt durch das **Garmin Developer Portal** ([developer.garmin.com](https://developer.garmin.com)), um die OAuth 1.0a Authentifizierung und alle 9 Echtzeit-Webhooks für Aktivitäten und Health-Daten mit unserem Backend in Frankfurt zu verbinden.

---

## 1. Voraussetzungen & Secret Manager
Stelle sicher, dass im Google Cloud Secret Manager für das Projekt `orbit-app-mvp` in `europe-west3` die beiden folgenden Secrets hinterlegt sind:
- `GARMIN_CONSUMER_KEY` (Consumer Key aus dem Garmin Portal)
- `GARMIN_CONSUMER_SECRET` (Consumer Secret aus dem Garmin Portal)

*Hinweis:* Der ORBIT-Quellcode liest Secrets niemals aus `.env` oder dem Repository, sondern bindet sie über `defineSecret` zur Laufzeit der Cloud Function ein.

---

## 2. OAuth 1.0a Authentifizierungs-Endpunkte

Im Garmin Developer Portal unter **Apps** -> **Deine App auswählen** -> **OAuth Configuration**:

| Einstellung | Wert im Garmin Developer Portal |
| :--- | :--- |
| **OAuth Version** | `OAuth 1.0a` |
| **Request Token URL** | *Wird vom Client über Garmin API aufgerufen* |
| **User Authorization URL** | *Offizielle Garmin Login-Seite* |
| **Callback URL (Redirect)** | **`https://europe-west3-orbit-app-mvp.cloudfunctions.net/garminAuthCallback`** |

### Funktionsweise:
1. Athlet tippt in der App auf *„Garmin Connect verbinden“* -> ruft `garminAuthStart` auf.
2. Der Nutzer wird zur Garmin-Webseite weitergeleitet und autorisiert die Datenfreigabe.
3. Garmin leitet mit `oauth_token` und `oauth_verifier` zurück an `garminAuthCallback`.
4. Die Cloud Function tauscht den Verifier gegen den permanenten `User Access Token` + `Token Secret` und speichert diese verschlüsselt unter `users/{uid}/private/garminAuth` in Frankfurt ab.

---

## 3. Webhook-Endpunkte (Push- & Ping-Notifications)

Im Garmin Developer Portal unter **Webhooks** / **Push Notifications**:

Alle Event-Typen können auf unseren zentralen Ingestion-Endpunkt gerichtet werden:
**`https://europe-west3-orbit-app-mvp.cloudfunctions.net/garminWebhook`**

### Unterstützte Event-Typen im ORBIT-Backend:

| Garmin Event-Typ | Payloads / Feldname | Was das ORBIT-Backend tut |
| :--- | :--- | :--- |
| **1. Activities** | `activities` | Erstellt Basis-Aktivität und triggert Metrik-Berechnung (TSS, NP, IF). |
| **2. Activity Details** | `activityDetails` | Extrahiert sekundengenaue 1Hz-Streams (Watt, HF, GPS, Höhe, Kadenz, L/R-Balance) und speichert LTTB-Downsampling. |
| **3. Dailies** | `dailies` | Synchronisiert tägliche Ruhepuls-, Aktivitäts-Kalorien- und Schrittwerte für die 3 Ringe. |
| **4. Sleeps** | `sleeps` | Berechnet Tief-, REM- und Leichtschlaf-Dauer, Schlafqualität und Schlafschuld. |
| **5. HRV Summary** | `hrv` | Ermittelt nächtliche Herzfrequenzvariabilität (rMSSD in ms) und gleicht sie mit dem 30-Tage-Normband ($\mu \pm 1\sigma$) ab. |
| **6. Stress Details** | `stressDetails` | Aggregiert Tages-Stresslevel und Rest-Stress-Score. |
| **7. Body Composition** | `bodyComps` | Gewicht und Körperfettanteil zur automatischen Aktualisierung von W/kg. |
| **8. User Metrics** | `userMetrics` | Aktualisierte Schwellenwerte (VO2max, Laktatschwelle) von der Uhr. |
| **9. Deregistration** | `deregistrations` | Wird aufgerufen, wenn der Nutzer die Berechtigung in Garmin Connect widerruft. Löscht Tokens und trennt die Verknüpfung sofort. |

---

## 4. Wichtige Konfigurations-Details für Garmin

### A. HTTP-Methode & Antwortzeiten
- Garmin sendet Webhook-Payloads per **HTTP POST** mit JSON-Body.
- **Antwortzeit-Anforderung:** Garmin verlangt eine Antwort mit HTTP `200 OK` (oder `202 Accepted`) innerhalb von **5 Sekunden**.
- **Unsere Architektur:** Die Cloud Function `garminWebhook` speichert den unverarbeiteten Payload sofort in Firestore (`webhookEvents`) und antwortet in unter 200 Millisekunden mit `200 OK`. Die rechenintensive Extraktion und Metrik-Berechnung erfolgt komplett asynchron im Hintergrund über den Trigger `processGarminWebhook`.

### B. Ping- vs. Push-Payloads (`callbackURL`)
- Bei großen Einheiten (z. B. 4h–6h Ausfahrten mit hochauflösenden Streams) sendet Garmin oft nur einen Ping mit einer `callbackURL`.
- Unser Backend prüft automatisch auf `callbackURL`, signiert die Anfrage mit OAuth 1.0a und lädt die vollständigen Streams komprimiert herunter.

---

## 5. Testen der Anbindung
1. **Ping-Test im Garmin Portal:**
   Im Developer Portal gibt es eine Schaltfläche **„Test Endpoint“**. Sende einen Test-Ping an `https://europe-west3-orbit-app-mvp.cloudfunctions.net/garminWebhook`.
   - Erwartetes Ergebnis: HTTP 200 OK.
2. **End-to-End-Test auf dem Pixel 10 Pro:**
   Schritte gemäß `docs/beta/TESTPLAN_ROLES.md` (Rolle 1) durchführen.
