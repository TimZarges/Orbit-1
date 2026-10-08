# ORBIT Datenmodell (Ausgangsbasis)

> Erweiterungen sind erlaubt. Änderungen an bestehenden Feldern nur mit Eintrag in `docs/DECISIONS.md`.
> Jede Struktur-Entscheidung zu Rules/Zugriff wird per **Emulator-Test bewiesen**. Region: `europe-west3`.

## Grundprinzipien
1. **Geplant ≠ absolviert.** Zwei Collections: `plannedWorkouts` (Plan) und `activities` (importierte/hochgeladene Realität), gegenseitig verknüpft. Ein Import überschreibt nie einen Plan.
2. **Zeit:** immer `startTimeUtc` (Timestamp) + `utcOffsetMinutes` (int) + `localDate` (`yyyy-MM-dd`, Tag am Ort des Athleten). Aggregation (Tages-/Wochenwerte, CTL/ATL) läuft über `localDate`.
3. **Zeitreihen nicht im Dokument:** Streams (Sekunden-Daten) liegen heruntergesampelt, komprimiert in Storage. Das Dokument enthält nur Zusammenfassung und Pfad.
4. **Schwellenwerte mit Historie.** Berechnete Kennzahlen speichern den verwendeten Schwellenwert-Snapshot und eine `metricsVersion`. Eine FTP-Änderung verändert die Vergangenheit nicht stillschweigend. Neuberechnung nur explizit (Function `recomputeMetrics`).
5. **Coach-Zugriff über denormalisiertes `coachId`.** Firestore-Rules filtern nicht. Für Abfragen wie „alle Aktivitäten meiner Athleten" trägt jedes freigegebene Dokument das Feld `coachId` = Trainer **mit aktivem Leserecht**. Eine Cloud Function pflegt es bei Änderungen der Verknüpfung (Freigabe entfernt → `coachId` auf `null`). Trainer fragen mit `where coachId == uid`.
6. **Serverseitige Felder** (nie vom Client schreibbar): `role`, `coachId`, `trainerVerified`, `metrics`, `metricsVersion`, Verknüpfungsstatus.

## Collections

### `users/{uid}`
```
uid, email, createdAt
role: "ATHLETE" | "TRAINER"            // nur Function
trainerVerified: bool                    // nur Function, Standard false
coachId: string | null                   // aktuell zugeordneter Trainer des Athleten, nur Function
profile: {
  displayName, photoURL,
  sportTypes: ["TRIATHLON","BIKE","RUN","SWIM","STRENGTH"],
  experienceLevel: "SIMPLE" | "ADVANCED" | "EXPERT",
  raceGoal?: { name, date, type },       // z. B. "Ironman 70.3", Datum
  birthYear?, weightKg?, heightCm?, timezone    // IANA, z. B. "Europe/Berlin"
}
settings: {
  units: "metric"|"imperial", language: "de"|"en", themeMode: "system"|"light"|"dark",
  notifications: { chat, newPlannedWorkout, dailyReminder, newActivity, weeklySummary },
  quietHours?: { from, to }
}
consents: { healthData: {at, version}, coachSharing?: {at, version}, privacyVersion }
plan: null                               // reserviert, ungenutzt (kein Bezahlmodell)
```

### `users/{uid}/thresholdHistory/{id}`
`effectiveFrom (localDate), ftpW?, thresholdHrBpm?, maxHrBpm?, restingHrBpm?, runThresholdPaceSecPerKm?, swimCssSecPer100m?, source: "MANUAL"|"ESTIMATED"|"IMPORTED", createdAt`

### `users/{uid}/private/integrations` (nur serverseitig lesbar)
`garmin: { accessToken, tokenSecret|refresh…, garminUserId, connectedAt, lastSyncAt }` (Struktur gemäß aktueller Garmin-Doku). Rules: **für Clients komplett gesperrt**.

### `users/{uid}/dailyMetrics/{localDate}` (Health)
`sleepSeconds, sleepScore?, restingHrBpm?, hrvMs?, stress?, steps?, bodyBattery?, source, updatedAt`
Zugriff Trainer: nur mit Freigabe `health` (Rules via `get()` auf `coachLinks/{athleteId}_{coachId}`).

### `users/{uid}/aggregates/{localDate}`
`dailyLoad, ctl, atl, tsb, orbitScore, metricsVersion` (Vorberechnet, spart Reads und Rechenzeit).

### `activities/{activityId}` (absolviert)
```
athleteId, coachId|null (denormalisiert, s. o.)
startTimeUtc, utcOffsetMinutes, localDate
sport: "SWIM"|"BIKE"|"RUN"|"STRENGTH"|"MULTISPORT"|"OTHER"
subSport?: "POOL"|"OPEN_WATER"|"INDOOR"|"TRAIL"|…
title, source: "GARMIN"|"FIT_UPLOAD"|"MANUAL"|"DEMO", externalId?       // (source, externalId) = Idempotenz-Schlüssel
durationSec, distanceM, movingTimeSec?
summary: { avgHr?, maxHr?, avgPowerW?, maxPowerW?, avgCadence?, elevationGainM?, avgPaceSecPerKm?, poolLengthM?, swolf?, … }
segments?: [ { sport, startOffsetSec, durationSec, distanceM, isTransition } ]   // Multisport/Wettkampf
metrics?: { tss?, intensityFactor?, normalizedPowerW?, variabilityIndex?, … }    // nur Function
metricsVersion, thresholdsSnapshot
streamsPath?, fitPath?                    // Storage
plannedWorkoutId?, matchStatus: "UNMATCHED"|"AUTO"|"MANUAL"
createdAt
```
Garmin-Aktivitätstypen werden auf diese Enums gemappt, unbekannte auf `OTHER`.

### `plannedWorkouts/{id}` (Plan)
```
athleteId, coachId|null, createdBy (uid), localDate, sport, title, description?
structure?: { blocks: [ … ] }              // siehe Phase „Workout Builder"
plannedDurationSec?, plannedLoad?
status: "PLANNED"|"COMPLETED"|"SKIPPED", activityId?, templateId?
createdAt, updatedAt
```

### `workoutTemplates/{id}` (Bibliothek)
`ownerId, visibility: "PRIVATE"|"SHARED_WITH_MY_ATHLETES", sport, title, structure, createdAt`

### `coachLinks/{athleteId}_{coachId}`
`athleteId, coachId, status: "INVITED"|"ACTIVE"|"REVOKED", permissions: { calendar: bool, activities: bool, health: bool }, createdAt, updatedAt`
Standard-Freigaben bei Annahme: `calendar: true, activities: true, health: false`.

### `invites/{code}`
`coachId, expiresAt, maxUses, usedBy[]` (Einladung per Code, Link oder QR). Annahme **immer** aktiv durch den Athleten.

### `chats/{chatId}` (`chatId = "{athleteId}_{coachId}"`)
`participants[2], athleteId, coachId, lastMessage, updatedAt, unread: { uid: count }`

### `chats/{chatId}/messages/{messageId}`
`senderId, text, timestamp, attachment?: { path, type, name }, readBy?`
Anhänge zusätzlich als verlinkte Aktivität (`activityId`) möglich. Zugriff auf die Aktivität richtet sich nach den Freigaben, nicht nach dem Chat.

### `webhookEvents/{id}` (nur Server)
Roh-Payloads von Anbietern. Eine Firestore-getriggerte Function verarbeitet sie (inkl. Retry). Status: `RECEIVED|PROCESSED|FAILED`.

## Storage-Pfade
- `users/{uid}/fit/{activityId}.fit`
- `users/{uid}/streams/{activityId}.json.gz`
- `chats/{chatId}/attachments/{file}` (Größen- und Typlimit in Rules)

## Indizes
Composite-Indizes in `firestore.indexes.json`, z. B. `activities (athleteId, localDate desc)`, `activities (coachId, localDate desc)`, `plannedWorkouts (athleteId, localDate)`, `plannedWorkouts (coachId, localDate)`.

---

## Ergänzungen (geplant, werden in der jeweiligen Phase finalisiert und hier nachgetragen)

| Struktur | Phase | Zweck |
|---|---|---|
| `users/{uid}.demo: { enabled, seededAt }` | 04 | Demo-Modus aktiv. Demo-Aktivitäten haben `source: "DEMO"` |
| `activities.processing: { state: "UPLOADED"\|"PROCESSING"\|"READY"\|"FAILED", errorCode? }` | 04 | Importstatus für die UI |
| `activities.metrics.quality: "COMPLETE"\|"ESTIMATED"\|"INSUFFICIENT"` | 05 | Datenqualität der Kennzahlen (z. B. kein FTP hinterlegt) |
| `users/{uid}/integrationStatus/{provider}` | 06 | Nicht geheimer Verbindungsstatus: `state`, `lastSyncAt`, `backfill{state,progress,from,to}`, `errorCode`. Vom Nutzer lesbar, nur von Functions beschreibbar. **Getrennt** von `private/integrations` (Tokens) |
| `users/{uid}/bests/{sport}` | 11 | Bestwerte: Rad Mean-Maximal-Power je Dauer (Saison, Allzeit), Lauf Bestzeiten je Distanz. Von Functions gepflegt |
| `users/{uid}/thresholdProposals/{id}` | 12/15 | Schwellenwert-Vorschlag (vom System in 12, vom Trainer in 15). Nur der Athlet übernimmt |
| `chats/{chatId}/state/{uid}.lastReadAt` | 13 | Gelesen-Status ohne Schreibzugriff je Nachricht |
| `messages.type: "TEXT"\|"IMAGE"\|"FILE"\|"ACTIVITY_SHARE"` + `activityShare: {activityId, snapshot}` | 13 | Geteilte Aktivität als Momentaufnahme. Das Teilen gewährt **keinen** zusätzlichen Datenzugriff |
| `users/{uid}/devices/{deviceId}`: `fcmToken, platform, appVersion, language, updatedAt` | 13 | Push-Ziele. Vom Nutzer schreibbar (nur eigene Geräte) |
| `users/{uid}/notificationState`: `nextReminderAtUtc, nextWeeklySummaryAtUtc` | 13 | Vorberechnete Zeitpunkte für geplante Pushes. Nur Functions |
| `coachDashboard/{coachId}/athletes/{athleteId}` | 15 | Serverseitig gepflegte Kurzfassung je Athlet (Form-Ampel, Soll-Ist-Quote 7 Tage, Ungelesen, letzte Aktivität, Auffälligkeiten, Wettkampfziel). Verhindert Dutzende Reads pro Dashboard-Aufruf |
| `users/{coachId}/preferences/{key}` | 15 | Coach-Ansichten, Spaltenkonfiguration, Layout |
| `plannedWorkouts.structure` (Schema v1) | 09 | Siehe `docs/specs/WORKOUT_SYNTAX.md` |

**Regel:** Jede dieser Strukturen bekommt beim Anlegen Rules, Rules-Tests, Indizes und einen Eintrag in `docs/DECISIONS.md`.
