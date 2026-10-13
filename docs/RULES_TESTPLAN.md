# Testplan für Firestore Security Rules (Phasen 01, 02 & 08)

## Ziel
Sicherstellen, dass die implementierten Firestore Security Rules für alle Collections (`users`, Subcollections, `coachLinks`, `activities` und `plannedWorkouts`) robust sind und die geforderten Berechtigungen durchsetzen:
- Default Deny an der Wurzel
- Owner-Only & Authenticated Access
- Schutz unveränderlicher Server- und Identitätsfelder (`athleteId`, `createdBy`, `role`, etc.)
- Granulare Trainer-Freigaben (`coachLinks.permissions.calendar`, `coachLinks.permissions.health`)
- Schutz vor Privilege Escalation, Identitätsfälschung und unbefugter Datenlöschung

## Setup
- Die Tests werden gegen den lokalen **Firebase Emulator** ausgeführt.
- Framework: `@firebase/rules-unit-testing` (JavaScript/TypeScript) in der Firebase Functions Testumgebung oder einem separaten Test-Skript.
- Testdaten (Mocks):
  - `aliceAuth`: Authentifizierter Nutzer mit UID "alice" (Athlet)
  - `bobAuth`: Authentifizierter Nutzer mit UID "coachBob" (Trainer)
  - `eveAuth`: Authentifizierter unbeteiligter Nutzer mit UID "eve" (Fremder)
  - `unauth`: Nicht authentifizierter Zugriff (null)
  - `coachLinks/alice_coachBob`:
    - Status: `ACTIVE`
    - permissions: `{ calendar: true, activities: true, health: false }`
  - `coachLinks/alice_eve`: Existiert nicht oder hat `{ calendar: false }`

## Testfälle

### 1. Default Deny
- **Ziel:** Root-Collection und nicht definierte Collections sind gesperrt.
- **Aktion:** Versuche als `aliceAuth` ein Dokument in `/unknownCollection/doc` zu lesen und zu schreiben.
- **Erwartet:** `PERMISSION_DENIED`

### 2. Collection `users/{uid}`
- **Read (Owner):**
  - **Aktion:** `aliceAuth` liest `/users/alice`.
  - **Erwartet:** Erfolg.
- **Read (Other):**
  - **Aktion:** `bobAuth` liest `/users/alice`.
  - **Erwartet:** `PERMISSION_DENIED` (No Mixed Content / Data Separation).
- **Read (Unauthenticated):**
  - **Aktion:** `unauth` liest `/users/alice`.
  - **Erwartet:** `PERMISSION_DENIED`
- **Create (Valid):**
  - **Aktion:** `aliceAuth` erstellt `/users/alice` mit `role: "ATHLETE"`, `coachId: null`.
  - **Erwartet:** Erfolg.
- **Create (Privilege Escalation):**
  - **Aktion:** `aliceAuth` versucht `/users/alice` mit `role: "TRAINER"` oder `trainerVerified: true` zu erstellen.
  - **Erwartet:** `PERMISSION_DENIED`
- **Update (Valid):**
  - **Aktion:** `aliceAuth` aktualisiert `profile.displayName` in `/users/alice`.
  - **Erwartet:** Erfolg.
- **Update (Privilege Escalation / Immutable Fields):**
  - **Aktion:** `aliceAuth` versucht `/users/alice` zu aktualisieren, indem `role` von `"ATHLETE"` auf `"TRAINER"` geändert wird, oder `coachId` geändert wird.
  - **Erwartet:** `PERMISSION_DENIED`

### 3. Collection `users/{uid}/thresholdHistory/{id}`
- **Read/Write (Owner):**
  - **Aktion:** `aliceAuth` liest und schreibt in `/users/alice/thresholdHistory/123`.
  - **Erwartet:** Erfolg.
- **Read/Write (Other):**
  - **Aktion:** `bobAuth` liest und schreibt in `/users/alice/thresholdHistory/123`.
  - **Erwartet:** `PERMISSION_DENIED`

### 4. Collection `users/{uid}/consents/{id}`
- **Read/Write (Owner):**
  - **Aktion:** `aliceAuth` liest und schreibt `/users/alice/consents/health`.
  - **Erwartet:** Erfolg.
- **Read/Write (Other):**
  - **Aktion:** `bobAuth` liest und schreibt `/users/alice/consents/health`.
  - **Erwartet:** `PERMISSION_DENIED`

### 5. Collection `users/{uid}/private/*`
- **Read/Write (Owner):**
  - **Aktion:** `aliceAuth` versucht, `/users/alice/private/integrations` zu lesen oder zu schreiben.
  - **Erwartet:** `PERMISSION_DENIED` (Nur vom Backend/Server per Admin SDK lesbar/schreibbar).
- **Read/Write (Other):**
  - **Aktion:** `bobAuth` versucht, `/users/alice/private/integrations` zu lesen oder zu schreiben.
  - **Erwartet:** `PERMISSION_DENIED`

### 6. Collection `plannedWorkouts/{workoutId}` (Phase 08 – Kalender & Planung)

#### 6.1 Read (Lesen)
- **Athlet liest eigenes Workout:**
  - **Aktion:** `aliceAuth` liest `/plannedWorkouts/w1` (mit `athleteId: "alice"`).
  - **Erwartet:** Erfolg.
- **Trainer liest über denormalisiertes `coachId`:**
  - **Aktion:** `bobAuth` liest `/plannedWorkouts/w1` (mit `athleteId: "alice"`, `coachId: "coachBob"`).
  - **Erwartet:** Erfolg (ermöglicht performante Listenabfragen `where coachId == uid`).
- **Trainer liest über aktive Kalender-Freigabe:**
  - **Aktion:** `bobAuth` liest `/plannedWorkouts/w1` (mit `athleteId: "alice"`, `coachId: null`, Freigabe `coachLinks/alice_coachBob.permissions.calendar == true`).
  - **Erwartet:** Erfolg (via `isCoachForCalendar`).
- **Trainer ohne Kalender-Freigabe liest:**
  - **Aktion:** `bobAuth` liest `/plannedWorkouts/w1` nachdem `permissions.calendar` auf `false` gesetzt wurde.
  - **Erwartet:** `PERMISSION_DENIED`.
- **Fremder liest Workout:**
  - **Aktion:** `eveAuth` liest `/plannedWorkouts/w1` von Alice.
  - **Erwartet:** `PERMISSION_DENIED`.
- **Unauthentifizierter liest Workout:**
  - **Aktion:** `unauth` liest `/plannedWorkouts/w1`.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 6.2 Create (Anlegen)
- **Athlet legt eigene Einheit an:**
  - **Aktion:** `aliceAuth` erstellt Dokument mit `athleteId: "alice"`, `createdBy: "alice"`.
  - **Erwartet:** Erfolg.
- **Athlet versucht Einheit für Fremden anzulegen:**
  - **Aktion:** `aliceAuth` erstellt Dokument mit `athleteId: "eve"`, `createdBy: "alice"`.
  - **Erwartet:** `PERMISSION_DENIED`.
- **Athlet fälscht `createdBy`:**
  - **Aktion:** `aliceAuth` erstellt Dokument mit `athleteId: "alice"`, `createdBy: "coachBob"`.
  - **Erwartet:** `PERMISSION_DENIED` (Schutz vor Identitätsfälschung).
- **Trainer mit Kalender-Freigabe legt Einheit für Athlet an:**
  - **Aktion:** `bobAuth` erstellt Dokument mit `athleteId: "alice"`, `createdBy: "coachBob"` (bei `coachLinks/alice_coachBob.permissions.calendar == true`).
  - **Erwartet:** Erfolg.
- **Trainer fälscht `createdBy` als Athlet:**
  - **Aktion:** `bobAuth` erstellt Dokument für Alice mit `athleteId: "alice"`, `createdBy: "alice"`.
  - **Erwartet:** `PERMISSION_DENIED` (`createdBy` muss exakt `request.auth.uid` entsprechen).
- **Trainer ohne Kalender-Freigabe versucht Einheit anzulegen:**
  - **Aktion:** `bobAuth` erstellt Dokument für Alice, während `permissions.calendar == false` oder Link fehlt.
  - **Erwartet:** `PERMISSION_DENIED`.
- **Fremder versucht Einheit anzulegen:**
  - **Aktion:** `eveAuth` erstellt Dokument mit `athleteId: "alice"`, `createdBy: "eve"`.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 6.3 Update (Ändern)
- **Athlet aktualisiert eigene Einheit:**
  - **Aktion:** `aliceAuth` ändert `title` oder `plannedDurationSec` in Einheit mit `athleteId: "alice"`. `athleteId` und `createdBy` bleiben unverändert.
  - **Erwartet:** Erfolg.
- **Athlet versucht `athleteId` oder `createdBy` zu ändern:**
  - **Aktion:** `aliceAuth` sendet Update und ändert `athleteId` auf "eve" oder `createdBy` auf "coachBob".
  - **Erwartet:** `PERMISSION_DENIED` (Immutable Fields).
- **Trainer mit Kalender-Freigabe aktualisiert Einheit:**
  - **Aktion:** `bobAuth` ändert `title` in Einheit von Alice bei aktiver `permissions.calendar == true`. Unveränderliche Felder intakt.
  - **Erwartet:** Erfolg.
- **Trainer versucht `athleteId` oder `createdBy` zu manipulieren:**
  - **Aktion:** `bobAuth` ändert `athleteId` oder `createdBy` bei einem Update.
  - **Erwartet:** `PERMISSION_DENIED`.
- **Trainer nach Freigabeentzug versucht Update:**
  - **Aktion:** `bobAuth` versucht Update, nachdem `permissions.calendar == false` gesetzt wurde.
  - **Erwartet:** `PERMISSION_DENIED`.
- **Fremder versucht Update:**
  - **Aktion:** `eveAuth` versucht Update an Dokument von Alice.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 6.4 Delete (Löschen)
- **Athlet löscht eigene, selbst erstellte Einheit:**
  - **Aktion:** `aliceAuth` löscht Dokument mit `athleteId: "alice"`, `createdBy: "alice"`.
  - **Erwartet:** Erfolg.
- **Athlet löscht vom Trainer erstellte Einheit im eigenen Kalender:**
  - **Aktion:** `aliceAuth` löscht Dokument mit `athleteId: "alice"`, `createdBy: "coachBob"`.
  - **Erwartet:** Erfolg (Athleten-Souveränität über den persönlichen Trainingsplan).
- **Trainer löscht vom Trainer erstellte Einheit bei aktiver Freigabe:**
  - **Aktion:** `bobAuth` löscht Dokument mit `athleteId: "alice"`, `createdBy: "coachBob"` bei `permissions.calendar == true`.
  - **Erwartet:** Erfolg.
- **Trainer versucht vom Athleten erstellte Einheit zu löschen:**
  - **Aktion:** `bobAuth` versucht Dokument mit `athleteId: "alice"`, `createdBy: "alice"` zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (Trainer dürfen vom Athleten geplante Einheiten nicht eigenmächtig entfernen).
- **Trainer nach Freigabeentzug versucht eigene Einheit zu löschen:**
  - **Aktion:** `bobAuth` versucht Dokument mit `createdBy: "coachBob"` zu löschen, nachdem `permissions.calendar` entzogen wurde.
  - **Erwartet:** `PERMISSION_DENIED`.
- **Fremder versucht Löschen:**
  - **Aktion:** `eveAuth` versucht Dokument von Alice zu löschen.
  - **Erwartet:** `PERMISSION_DENIED`.

---

## Umsetzung
Die Tests werden als `.spec.ts` oder `.test.ts` im Testordner angelegt (z. B. `functions/tests/rules.spec.ts`) und per `npm test` gegen den laufenden Emulator (`firebase emulators:start`) ausgeführt. Dies wird im Rahmen der Phasen-Implementierung sichergestellt.

### Theoretischer Beweis (Architektur-Check): Trainer-Zugriffsmodell (Phase 02)

**1. Warum das denormalisierte `coachId`-Feld in Listenabfragen funktioniert:**
Firestore Security Rules sind keine Filter (Stichwort: "Rules are not filters"). Wenn ein Trainer eine Abfrage `db.collection('activities').get()` ausführt, wird sie abgewiesen, da er nicht auf alle Aktivitäten global zugreifen darf. 
Führt der Trainer jedoch eine gefilterte Abfrage `db.collection('activities').where('coachId', '==', request.auth.uid).get()` aus, kann Firestore diese statisch analysieren. Da die Rule `allow read: if resource.data.coachId == request.auth.uid;` exakt dieser Filterbedingung entspricht, ist die Abfrage zulässig und extrem performant, da nur ein Index auf `coachId` abgefragt werden muss.

**2. Warum wir für Subcollections wie Health auf `get()` zurückgreifen müssen:**
Die Health-Daten liegen als Subcollection in `users/{uid}/dailyMetrics/{date}`. Wir denormalisieren die `coachId` nicht in jedes einzelne Tagesdokument, da die Berechtigung granular in `coachLinks` verwaltet wird (Feld `permissions.health`). Um bei einem Read auf die Health-Daten zu prüfen, ob der Trainer diese sehen darf, muss die Rule dynamisch das Verknüpfungs-Dokument laden: 
`get(/databases/$(database)/documents/coachLinks/$(uid)_$(request.auth.uid)).data.permissions.health == true`.

**3. Warum `get()` bei Einzelabfragen pro Tag in Ordnung ist:**
Der Aufruf von `get()` in Security Rules kostet einen zusätzlichen Document Read. Da der Trainer in der Regel Health-Daten eines Athleten gezielt (z.B. für die heutige Ansicht oder ausgewählte Tage) abruft, löst dies keine massiven List-Abfragen mit hunderten `get()`-Aufrufen aus. Das Limit von 10 Document Access Calls pro Rule-Auswertung (für Einzel-Dokumente bzw. 20 für Listen) wird hier nicht überschritten, und die Kosten sind minimal. Der große Vorteil ist die absolute Datenkonsistenz: Entzieht der Athlet das Health-Recht, greift die Sperre in derselben Sekunde für alle Tagesdaten rückwirkend.

### Theoretischer Beweis (Architektur-Check): Kalender-Zugriffsmodell (Phase 08)

**1. Symmetrische Erstellung mit Identitätsbindung:**
Durch die Bedingung `request.resource.data.createdBy == request.auth.uid` ist garantiert, dass der Ersteller immer wahrheitsgemäß festgehalten wird. Weder Athlet noch Trainer können im Namen des jeweils anderen Einheiten vortäuschen.

**2. Rollenspezifische Löschrechte (Athleten-Souveränität):**
Der Athlet darf jede Einheit in seinem Kalender löschen (`resource.data.athleteId == request.auth.uid`), unabhängig davon, wer sie erstellt hat. Ein Trainer darf hingegen nur Einheiten löschen, die er selbst angelegt hat (`resource.data.createdBy == request.auth.uid`) UND für die er weiterhin eine gültige Kalender-Freigabe besitzt (`isCoachForCalendar(resource.data.athleteId)`). Dies verhindert, dass ein Trainer eigenmächtige Notizen oder Einheiten des Athleten zerstört.

**3. Schutz vor unbefugter Zuordnungs- oder Eigentümerübertragung:**
Bei jedem `update` erzwingen die Rules `request.resource.data.athleteId == resource.data.athleteId && request.resource.data.createdBy == resource.data.createdBy`. Ein Angreifer kann weder eine Einheit in einen fremden Kalender transferieren noch die Urheberschaft fälschen.

**4. Dynamischer Rechteentzug via `coachLinks`:**
Sobald ein Athlet die Kalender-Berechtigung entzieht (`permissions.calendar = false`) oder die Verknüpfung auflöst, schlägt `isCoachForCalendar()` sofort fehl. Der Trainer verliert unmittelbar den schreibenden Zugriff sowie den Detail-Lesezugriff auf Einheiten ohne denormalisierte `coachId`.
