# Testplan für Firestore Security Rules (Phasen 01, 02, 08, 09 & 10)

## Ziel
Sicherstellen, dass die implementierten Firestore Security Rules für alle Collections (`users`, Subcollections inkl. `aggregates`, `coachLinks`, `activities`, `plannedWorkouts` und `workoutTemplates`) robust sind und die geforderten Berechtigungen durchsetzen:
- Default Deny an der Wurzel
- Owner-Only & Authenticated Access
- Schutz unveränderlicher Server- und Identitätsfelder (`athleteId`, `createdBy`, `ownerId`, `role`, etc.)
- Granulare Trainer-Freigaben (`coachLinks.permissions.calendar`, `coachLinks.permissions.health`, `coachLinks.permissions.activities`, `coachLinks` Trainer-Vorlagen-Sharing)
- Schutz vor Privilege Escalation, Identitätsfälschung, Resource Exhaustion/DoS und unbefugter Datenlöschung
- Striktes Schreibverbot für vorberechnete Aggregate (nur Cloud Functions)

## Setup
- Die Tests werden gegen den lokalen **Firebase Emulator** ausgeführt.
- Framework: `@firebase/rules-unit-testing` (JavaScript/TypeScript) in der Firebase Functions Testumgebung oder einem separaten Test-Skript.
- Testdaten (Mocks):
  - `aliceAuth`: Authentifizierter Nutzer mit UID "alice" (Athlet)
  - `bobAuth`: Authentifizierter Nutzer mit UID "coachBob" (Trainer)
  - `charlieAuth`: Authentifizierter Nutzer mit UID "coachCharlie" (Trainer mit eingeschränkten Rechten)
  - `eveAuth`: Authentifizierter unbeteiligter Nutzer mit UID "eve" (Fremder)
  - `unauth`: Nicht authentifizierter Zugriff (null)
  - `coachLinks/alice_coachBob`:
    - Status: `ACTIVE`
    - permissions: `{ calendar: true, activities: true, health: false }`
  - `coachLinks/alice_coachCharlie`:
    - Status: `ACTIVE`
    - permissions: `{ calendar: true, activities: false, health: false }`
  - `coachLinks/alice_eve`: Existiert nicht oder hat `{ calendar: false, activities: false }`

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

### 7. Collection `workoutTemplates/{templateId}` (Phase 09 – Workout-Vorlagenbibliothek)

#### 7.1 Read (Lesen)
- **Besitzer liest eigene private Vorlage:**
  - **Aktion:** `aliceAuth` liest `/workoutTemplates/t1` (`ownerId: "alice"`, `visibility: "PRIVATE"`).
  - **Erwartet:** Erfolg.
- **Besitzer liest eigene geteilte Vorlage:**
  - **Aktion:** `bobAuth` liest `/workoutTemplates/t2` (`ownerId: "coachBob"`, `visibility: "SHARED_WITH_MY_ATHLETES"`).
  - **Erwartet:** Erfolg.
- **Beliebiger Nutzer liest öffentliche Vorlage:**
  - **Aktion:** `aliceAuth` liest `/workoutTemplates/t_pub` (`ownerId: "coachBob"`, `visibility: "PUBLIC"`).
  - **Erwartet:** Erfolg.
- **Athlet liest geteilte Vorlage seines verknüpften Trainers:**
  - **Aktion:** `aliceAuth` liest `/workoutTemplates/t2` (`ownerId: "coachBob"`, `visibility: "SHARED_WITH_MY_ATHLETES"`, bei existierendem `coachLinks/alice_coachBob`).
  - **Erwartet:** Erfolg (Zugriff über `exists(coachLinks/$(request.auth.uid + '_' + resource.data.ownerId))`).
- **Athlet versucht geteilte Vorlage eines fremden Trainers zu lesen:**
  - **Aktion:** `eveAuth` liest `/workoutTemplates/t2` (`ownerId: "coachBob"`, `visibility: "SHARED_WITH_MY_ATHLETES"`, ohne Verknüpfung `coachLinks/eve_coachBob`).
  - **Erwartet:** `PERMISSION_DENIED`.
- **Fremder liest private Vorlage:**
  - **Aktion:** `eveAuth` liest `/workoutTemplates/t1` (`ownerId: "alice"`, `visibility: "PRIVATE"`).
  - **Erwartet:** `PERMISSION_DENIED`.
- **Trainer versucht private Vorlage seines Athleten zu lesen:**
  - **Aktion:** `bobAuth` liest `/workoutTemplates/t1` (`ownerId: "alice"`, `visibility: "PRIVATE"`).
  - **Erwartet:** `PERMISSION_DENIED` (Vorlagen des Athleten bleiben strikt privat, es sei denn `PUBLIC`).
- **Unauthentifizierter liest Vorlage:**
  - **Aktion:** `unauth` liest `/workoutTemplates/t_pub` (oder `t1`).
  - **Erwartet:** `PERMISSION_DENIED` (Kein unauthentifizierter Zugriff, `isAuthenticated()` erforderlich).

#### 7.2 Create (Anlegen)
- **Nutzer legt eigene Vorlage mit gültiger Sichtbarkeit an:**
  - **Aktion:** `aliceAuth` erstellt Vorlage mit `ownerId: "alice"`, `visibility: "PRIVATE"`, `sport: "RUN"`, `title: "5x1000m Intervalle"`.
  - **Erwartet:** Erfolg.
- **Trainer legt eigene Vorlage für Athleten geteilt an:**
  - **Aktion:** `bobAuth` erstellt Vorlage mit `ownerId: "coachBob"`, `visibility: "SHARED_WITH_MY_ATHLETES"`, `sport: "BIKE"`, `title: "FTP Test"`.
  - **Erwartet:** Erfolg.
- **Nutzer versucht Vorlage mit fremder `ownerId` anzulegen:**
  - **Aktion:** `aliceAuth` erstellt Vorlage mit `ownerId: "coachBob"`, `visibility: "PRIVATE"`.
  - **Erwartet:** `PERMISSION_DENIED` (`request.resource.data.ownerId == request.auth.uid`).
- **Nutzer versucht ungültigen Sichtbarkeits-Enum zu setzen:**
  - **Aktion:** `aliceAuth` erstellt Vorlage mit `visibility: "CONFIDENTIAL"` oder `visibility: "FRIENDS_ONLY"`.
  - **Erwartet:** `PERMISSION_DENIED` (`visibility in ['PRIVATE', 'SHARED_WITH_MY_ATHLETES', 'PUBLIC']`).
- **Nutzer versucht DoS-Angriff über überlange Strings:**
  - **Aktion:** `aliceAuth` erstellt Vorlage mit einem Titel > 200 Zeichen oder einer Beschreibung > 5000 Zeichen.
  - **Erwartet:** `PERMISSION_DENIED` (Durchgesetzt via `isValidWorkoutTemplate` / `checkStringSize`).
- **Unauthentifizierter versucht Vorlage anzulegen:**
  - **Aktion:** `unauth` erstellt Vorlage.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 7.3 Update (Ändern)
- **Besitzer aktualisiert eigene Vorlage:**
  - **Aktion:** `aliceAuth` ändert `title`, `description`, `tags` oder schaltet `isFavorite` um. `ownerId` bleibt `"alice"`.
  - **Erwartet:** Erfolg.
- **Besitzer versucht Eigentümer (`ownerId`) zu manipulieren:**
  - **Aktion:** `aliceAuth` versucht bei einem Update `ownerId` von `"alice"` auf `"coachBob"` zu ändern.
  - **Erwartet:** `PERMISSION_DENIED` (`request.resource.data.ownerId == resource.data.ownerId`).
- **Fremder versucht Vorlage zu aktualisieren:**
  - **Aktion:** `bobAuth` oder `eveAuth` versucht Vorlage von `alice` zu aktualisieren.
  - **Erwartet:** `PERMISSION_DENIED` (`resource.data.ownerId == request.auth.uid`).
- **Athlet versucht vom Trainer geteilte Vorlage zu aktualisieren:**
  - **Aktion:** `aliceAuth` versucht `/workoutTemplates/t2` (`ownerId: "coachBob"`) zu bearbeiten.
  - **Erwartet:** `PERMISSION_DENIED` (Nur der besitzende Trainer darf seine geteilten Vorlagen editieren).
- **Update mit ungültiger Sichtbarkeit oder DoS-String:**
  - **Aktion:** `aliceAuth` ändert `visibility` auf `"INVALID"` oder bläht `description` auf > 5000 Zeichen auf.
  - **Erwartet:** `PERMISSION_DENIED` (Validierung greift auch bei `update`).
- **Unauthentifizierter versucht Update:**
  - **Aktion:** `unauth` versucht Update.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 7.4 Delete (Löschen)
- **Besitzer löscht eigene Vorlage:**
  - **Aktion:** `aliceAuth` löscht Dokument `/workoutTemplates/t1`.
  - **Erwartet:** Erfolg.
- **Fremder versucht Vorlage zu löschen:**
  - **Aktion:** `eveAuth` versucht Vorlage von `alice` zu löschen.
  - **Erwartet:** `PERMISSION_DENIED`.
- **Athlet versucht vom Trainer geteilte Vorlage zu löschen:**
  - **Aktion:** `aliceAuth` versucht `/workoutTemplates/t2` (`ownerId: "coachBob"`) zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (Athlet darf fremde geteilte Vorlagen nicht aus der Bibliothek entfernen).
- **Unauthentifizierter versucht Vorlage zu löschen:**
  - **Aktion:** `unauth` versucht Vorlage zu löschen.
  - **Erwartet:** `PERMISSION_DENIED`.

### 8. Collection `users/{userId}/aggregates/{date}` (Phase 10 – Auswertungen & Trainingsanalyse)

#### 8.1 Read (Lesen)
- **Athlet liest eigene vorberechnete Tagesaggregate:**
  - **Aktion:** `aliceAuth` liest `/users/alice/aggregates/2026-10-13`.
  - **Erwartet:** Erfolg (`isOwner(userId)`).
- **Trainer mit aktiver `activities`-Freigabe liest Tagesaggregate des Athleten:**
  - **Aktion:** `bobAuth` liest `/users/alice/aggregates/2026-10-13` (bei existierendem `coachLinks/alice_coachBob` mit `permissions.activities == true`).
  - **Erwartet:** Erfolg (`isAuthenticated() && isCoachForActivities(userId)`).
- **Trainer ohne `activities`-Freigabe versucht Tagesaggregate zu lesen:**
  - **Aktion:** `charlieAuth` liest `/users/alice/aggregates/2026-10-13` (bei `coachLinks/alice_coachCharlie` mit `permissions.activities == false`).
  - **Erwartet:** `PERMISSION_DENIED` (`isCoachForActivities` evaluiert zu `false`).
- **Fremder ohne Verknüpfung versucht Tagesaggregate zu lesen:**
  - **Aktion:** `eveAuth` liest `/users/alice/aggregates/2026-10-13` (kein `coachLinks/alice_eve` vorhanden).
  - **Erwartet:** `PERMISSION_DENIED`.
- **Unauthentifizierter versucht Tagesaggregate zu lesen:**
  - **Aktion:** `unauth` liest `/users/alice/aggregates/2026-10-13`.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 8.2 Write / Create / Update / Delete (Schreiben)
- **Athlet versucht Aggregat-Dokument anzulegen oder zu manipulieren:**
  - **Aktion:** `aliceAuth` versucht `/users/alice/aggregates/2026-10-13` zu erstellen, zu aktualisieren oder zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow write: if false`).
- **Trainer versucht Aggregat-Dokument anzulegen oder zu manipulieren:**
  - **Aktion:** `bobAuth` versucht `/users/alice/aggregates/2026-10-13` zu erstellen, zu verändern oder zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow write: if false`).
- **Fremder / Unauthentifizierter versucht Schreibzugriff:**
  - **Aktion:** `eveAuth` oder `unauth` versucht Schreibzugriff auf `/users/alice/aggregates/2026-10-13`.
  - **Erwartet:** `PERMISSION_DENIED` (`allow write: if false`).

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

### Theoretischer Beweis (Architektur-Check): Workout-Vorlagenbibliothek (Phase 09)

**1. Granulare Sichtbarkeits-Hierarchie ohne Datenlecks:**
Die Vorlagenbibliothek unterstützt drei Sichtbarkeitsstufen: `PRIVATE`, `SHARED_WITH_MY_ATHLETES` und `PUBLIC`.
- `PUBLIC`: Für alle authentifizierten Nutzer lesbar (z. B. vordefinierte System-Vorlagen oder kuratierte Community-Vorlagen).
- `PRIVATE`: Streng auf den Besitzer beschränkt (`resource.data.ownerId == request.auth.uid`). Weder andere Athleten noch verknüpfte Trainer können private Vorlagen eines Nutzers einsehen.
- `SHARED_WITH_MY_ATHLETES`: Erlaubt Trainern, ihre Vorlagen exklusiv für ihre eigenen aktiven Athleten freizugeben. Die Auswertung über `exists(/databases/$(database)/documents/coachLinks/$(request.auth.uid + '_' + resource.data.ownerId))` prüft exakt, ob eine aktive Verbindung existiert, bei der der anfragende Nutzer der Athlet (`athleteId == request.auth.uid`) und der Besitzer der Vorlage der Coach (`coachId == resource.data.ownerId`) ist. Da fremde Athleten keine entsprechende Verknüpfung in `coachLinks` besitzen, schlägt `exists()` für sie fehl.

**2. Listenabfragen und Firestore "Rules are not filters"-Konformität:**
In Firestore muss jede Listenabfrage mit den Security Rules mathematisch beweisbar übereinstimmen:
- Abfrage der eigenen Vorlagen: `collection('workoutTemplates').where('ownerId', '==', currentUserId).get()`. Da `currentUserId == request.auth.uid`, matcht dies exakt den Zweig `resource.data.ownerId == request.auth.uid`. Die Abfrage ist zulässig und performant indexiert.
- Abfrage der Trainer-Vorlagen durch den Athleten: `collection('workoutTemplates').where('ownerId', '==', coachId).where('visibility', '==', 'SHARED_WITH_MY_ATHLETES').get()`. Firestore bindet `resource.data.ownerId` an die Konstante `coachId` und `visibility` an `'SHARED_WITH_MY_ATHLETES'`. Dadurch kann der Pfad `coachLinks/$(request.auth.uid + '_' + coachId)` statisch ausgewertet werden: Existiert der Link, ist die Bedingung für alle Treffer erfüllt, und die Abfrage wird ausgeführt.
- Ein unzulässiger globaler Scan (`collection('workoutTemplates').get()`) wird vom Regelwerk automatisch abgewiesen, wodurch ein versehentliches Auslesen privater Vorlagen dritter Nutzer unmöglich ist.

**3. Unveränderlichkeit des Besitzers (`ownerId`) und Schutz vor Eigentumsübertragung:**
Beim Anlegen (`create`) erzwingt `request.resource.data.ownerId == request.auth.uid`, dass der Ersteller immer die Identität des angemeldeten Nutzers trägt. Beim Ändern (`update`) wird verlangt:
`resource.data.ownerId == request.auth.uid && request.resource.data.ownerId == resource.data.ownerId`.
Dies garantiert:
- Nur der rechtmäßige Besitzer kann ein Update initiieren.
- Der Besitzer kann die Vorlage nicht heimlich einem anderen Nutzer unterjubeln oder die Urheberschaft fälschen.

**4. Validator Function Pattern & DoS-/Payload-Schutz:**
Durch `isValidWorkoutTemplate(request.resource.data)` in `create` UND `update` wird sichergestellt:
- Kein "Update Bypass": Ein Nutzer kann nicht ein minimales gültiges Dokument anlegen und es anschließend per Update mit einem 1-MB-String oder bösartigen Daten überschreiben.
- Begrenzung der Feldgrößen: `title` (max. 200 Zeichen), `sport` (max. 50 Zeichen), `description` (max. 5000 Zeichen), `tags` (max. 50 Elemente).
- Strikt typisierte Enums: `visibility in ['PRIVATE', 'SHARED_WITH_MY_ATHLETES', 'PUBLIC']`. Unbekannte oder fehlerhafte Sichtbarkeitsstufen werden abgewiesen.

### Theoretischer Beweis (Architektur-Check): Aggregat-Lesezugriff & Trainingsanalyse (Phase 10)

**1. Vorberechnete Tagesaggregate statt massiver Client-Aggregation:**
In Phase 10 beantwortet der Tab "Analyse" Fragestellungen wie Trainingszustand (Form-Ampel), wöchentliche Belastung vs. Plan, Sportverteilung und längerfristige Verläufe (CTL, ATL, TSB über 8 Wochen). Statt dass Endgeräte hunderte Einzelaktivitäten und hochfrequente Telemetriedaten herunterladen und on-device berechnen müssen, berechnet das Backend (Cloud Functions) die Werte deterministisch und speichert sie als kompakte Tagesdokumente unter `users/{userId}/aggregates/{localDate}`. Dies spart massiv Lese-Bandbreite, schont Mobilfunk-Datenvolumen und garantiert identische Kennzahlen auf allen Clients.

**2. Granulare Berechtigungsprüfung über `coachLinks.permissions.activities`:**
Die Aggregat-Daten leiten sich direkt aus den absolvierten Aktivitäten des Athleten ab. Im Berechtigungsmodell von ORBIT (`coachLinks/{athleteId}_{coachId}`) steuert das Feld `permissions.activities` die Einsicht in Aktivitäts- und Trainingsdaten. 
Die Hilfsfunktion `isCoachForActivities(athleteId)` liest per `get()` das Verknüpfungsdokument `/coachLinks/$(athleteId + '_' + request.auth.uid)` und prüft `linkDoc.data.permissions.activities == true`.
- Besitzt der Trainer die Freigabe, darf er die Aggregate lesen.
- Fehlt die Freigabe (`activities == false`) oder existiert keine Verbindung, wird der Lesezugriff sofort verweigert.
- Entzieht der Athlet dem Trainer das Recht, wirkt der Entzug im selben Moment für sämtliche historischen und zukünftigen Aggregate.

**3. Striktes clientseitiges Schreibverbot (`allow write: if false`):**
Metriken wie `dailyLoad`, `ctl`, `atl`, `tsb` und der Belastungsindex (`orbitScore`) dürfen keinesfalls durch Clients manipuliert werden (Schutz vor Verfälschung von Trainingsstatistiken oder fehlerhaften Berechnungsständen). Die Regel `allow write: if false;` stellt sicher, dass Schreibzugriffe exklusiv dem vertrauenswürdigen Backend vorbehalten sind (Cloud Functions mit Firebase Admin SDK, das die Sicherheitsregeln umgeht).

**4. Performante Bereichsabfragen (Range Queries) in Subcollections:**
Der Analyse-Tab fragt Aggregate über Zeitintervalle ab (z. B. `.where(FieldPath.documentId(), '>=', '2026-08-01')`). Da die Regel `allow read: if isOwner(userId) || (isAuthenticated() && isCoachForActivities(userId));` nur an die Pfadvariable `{userId}` und den statisch prüfbaren `coachLinks`-Dokumentpfad gekoppelt ist und keine dokumentenindividuellen Felder filtert, evaluiert Firestore die Autorisierung einheitlich für den gesamten Query-Pfad. Es entsteht kein "Rules are not filters"-Konflikt, und Trainer können die 8-Wochen-Verläufe ihrer Athleten in einer einzigen schnellen Subcollection-Abfrage laden.
