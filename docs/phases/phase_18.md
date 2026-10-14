# PHASE 18 — Echte Daten-Pipeline: Garmin Live + History-Backfill, Multi-Format-Upload (.fit/.tcx/.gpx) & Trainer-Kopplung

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH – Externe APIs, OAuth, Art. 9 DSGVO-Consent).
- **Pflicht:** Zwingender STOPP-Punkt vor Live-Tests gegen die Garmin API und vor dem Phasen-Commit.

## Ausgangslage & Ziel
Die Vereins-Testgruppe nutzt Garmin, Wahoo, SRM und Whoop. Die Garmin-App ist bei Garmin Developer bereits registriert und freigegeben (Consumer Key & Secret liegen vor), allerdings verwirft `webhook.ts:51` aktuell eingehende Payloads und historische Daten werden noch nicht geladen. Zudem ist der `AthleteCoachTabScreen` im Frontend ein reiner UI-Mock (nur lokale SnackBars).

## Arbeitspakete

### 18.1 Garmin Connect Live-Integration & Historischer Backfill
1. **Secret Manager Integration:** Richte die Cloud Functions für `GARMIN_CONSUMER_KEY` und `GARMIN_CONSUMER_SECRET` über `defineSecret` (Firebase Functions v2 Secret Manager) ein. Dokumentiere den exakten CLI-Befehl (`firebase functions:secrets:set ...`), damit ich die echten Keys eintragen kann.
2. **Webhook-Verarbeitung implementieren (`functions/src/garmin/webhook.ts`):**
   - Verarbeite eingehende Garmin Push-/Ping-Payloads für `activities`, `activityDetails`, `dailies`, `epochs`, `sleeps`, `bodyComps`, `stressDetails`, `userMetrics` und `hrv`.
   - Antworte Garmin innerhalb von ≤ 3 Sekunden mit `HTTP 200 OK` und verarbeite den Datenabruf/Parsing asynchron (Cloud Tasks / PubSub oder Queue-Dokument), damit Garmin den Endpoint nicht wegen Timeouts sperrt.
   - Mappe die empfangenen Daten verlustfrei in unsere Collections `activities` und `daily_health/{userId}_{YYYY-MM-DD}`.
3. **Historischer Daten-Import (Garmin Backfill API):**
   - Implementiere eine Callable Cloud Function `requestGarminBackfill` (sowie einen automatischen Aufruf direkt nach erfolgreichem OAuth-Token-Austausch).
   - Rufe die offiziellen Garmin Backfill-Endpunkte für die letzten **90 Tage** (in erlaubten Zeitfenstern gemäß Garmin Rate-Limits) für `activities`, `dailies`, `sleeps` und `hrv` auf.
   - Zeige in der App unter *Einstellungen → Verbundene Geräte → Garmin* einen Button **„Historische Daten laden (letzte 90 Tage)“** inkl. Status-Anzeige („Synchronisiere Historie… X Einheiten empfangen“).

### 18.2 Universeller Manueller Datei- & Batch-Upload (Garmin, Wahoo, SRM)
1. Erweitere den Datei-Importer (Backend + App-Upload-Dialog) so, dass neben `.fit` auch **`.tcx`** und **`.gpx`** (sowie `.fit.gz` / `.tcx.gz`) für Wahoo- und SRM-Nutzer sauber geparst werden:
   - Extrahiere Zeitreihen (Sekunden-Streams): Herzfrequenz, Leistung (Watt), Trittfrequenz, Geschwindigkeit/Pace, GPS-Koordinaten, Höhe, Temperatur, Links/Rechts-Balance und Runden/Laps.
   - Erkenne Duplikate zuverlässig über einen Hash aus `(userId, startTime, duration, sportType)`, damit dieselbe Einheit nicht doppelt importiert wird, wenn sie per Garmin-Sync UND manuell hochgeladen wird.
2. **Batch-Upload (Multi-File-Picker):** Erlaube im Upload-Dialog das gleichzeitige Auswählen von bis zu 50 Dateien auf einmal (Web & Android) mit einer Fortschrittsleiste, damit wir unsere 100–200 Referenz-Einheiten bequem importieren können.

### 18.3 Echte Trainer-Athleten-Kopplung (`AthleteCoachTabScreen`)
1. Ersetze alle Mock-SnackBars in `AthleteCoachTabScreen` durch echte Riverpod-Controller und Backend-Calls (`functions/src/coach.ts`):
   - **Einladungscode einlösen:** Athlet gibt den 6-stelligen Code des Trainers ein → Validierung → Anlage/Aktivierung des `coach_athlete_links`-Dokuments.
   - **Art. 9 DSGVO Granulare Einwilligungsschalter:** Echte Schalter für (a) Trainingsaktivitäten & Leistungsdaten, (b) Gesundheits-, Schlaf- & HRV-Daten, (c) Körpergewicht/Notizen. Jede Änderung schreibt sofort einen Audit-Log-Eintrag mit Zeitstempel und aktualisiert die Berechtigung in Echtzeit.
   - **Trainer trennen:** Funktionierender Bestätigungsdialog, der die Trennung ausführt und (über den Fix aus Phase 17.3) dem Trainer sofort jeden Zugriff entzieht.

## STOPP-Punkte & Abnahmekriterien
- **STOPP 1:** Zeige die Implementierung des Garmin-Backfills und des Webhook-Handlers, bevor wir die echten Garmin-Keys im Secret Manager hinterlegen.
- **STOPP 2 (Phasenabschluss):**
  1. Automatisierter Integrationstest im Emulator: Upload je einer echten `.fit`, `.tcx` und `.gpx` Datei erzeugt vollständige `activities`-Dokumente inkl. Streams und löst die Metrik-Berechnung aus.
  2. Automatisierter Test des Trainer-Flows: Code generieren (Coach) → Code einlösen (Athlet) → Consent-Toggle umschalten → Coach sieht Daten → Trennen → Coach bekommt `PERMISSION_DENIED`.
- Nach meiner Freigabe: Commit & Push auf GitHub mit Tag `v0.18.0`.