# Testplan für Firestore und Storage Security Rules (Phasen 01, 02, 08, 09, 10, 11, 12 & 13)

## Ziel
Sicherstellen, dass die implementierten Firestore und Storage Security Rules für alle Collections (`users`, Subcollections inkl. `aggregates`, `bests`, `thresholdProposals`, `devices` und `notificationState`, `coachLinks`, `activities`, `plannedWorkouts`, `workoutTemplates` sowie `chats` mit `messages` und `state`) und Storage-Buckets robust sind und die geforderten Berechtigungen durchsetzen:
- Default Deny an der Wurzel
- Owner-Only & Authenticated Access
- Schutz unveränderlicher Server- und Identitätsfelder (`athleteId`, `createdBy`, `ownerId`, `senderId`, `role`, etc.)
- Granulare Trainer-Freigaben (`coachLinks.permissions.calendar`, `coachLinks.permissions.health`, `coachLinks.permissions.activities`, `coachLinks` Trainer-Vorlagen-Sharing)
- Schutz vor Privilege Escalation, Identitätsfälschung, Resource Exhaustion/DoS und unbefugter Datenlöschung
- Striktes Schreibverbot für vorberechnete Aggregate und Bestwerte (nur Cloud Functions)
- Schwellenwert-Vorschläge (Phase 12): Ausschließlich serverseitige Erstellung, Status-Update ('ACCEPTED'/'REJECTED') streng auf den Athleten beschränkt, Unveränderlichkeit diagnostischer Parameter, Lesezugriff für Coach mit `activities`-Freigabe
- Chat & Messaging (Phase 13): Zugriff ausschließlich für Chat-Teilnehmer (`isChatParticipant`), Erstellung neuer Nachrichten nur in aktiven Chats (`isChatActive`), Verbot von Hard-Deletes (`allow delete: if false`), striktes Soft-Delete-Modell ausschließlich durch den Sender, Unveränderlichkeit von Metadaten
- Push-Infrastruktur & FCM (Phase 13): Registrierung von Geräte-Tokens (`users/{uid}/devices`) streng nutzergebunden, Scheduler-Zustand (`users/{uid}/notificationState`) unberührbar für Clients (nur Cloud Functions)
- Cloud Storage Sicherheit (Phase 13): Begrenzung von Bildern (≤ 10 MB, `image/*`) und Dateien (≤ 25 MB), Verbot von Updates (Immutabilität), Berechtigung zum Löschen für Teilnehmer bei Soft-Deletes

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

### 9. Collection `users/{userId}/bests/{sport}` (Phase 11 – Analyse Cockpit: Bestwerte & Power-Kurve)

#### 9.1 Read (Lesen)
- **Athlet liest eigene Bestwerte:**
  - **Aktion:** `aliceAuth` liest `/users/alice/bests/cycling`.
  - **Erwartet:** Erfolg (`isOwner(userId)`).
- **Trainer mit aktiver `activities`-Freigabe liest Bestwerte des Athleten:**
  - **Aktion:** `bobAuth` liest `/users/alice/bests/cycling` (bei existierendem `coachLinks/alice_coachBob` mit `permissions.activities == true`).
  - **Erwartet:** Erfolg (`isAuthenticated() && isCoachForActivities(userId)`).
- **Trainer ohne `activities`-Freigabe versucht Bestwerte zu lesen:**
  - **Aktion:** `charlieAuth` liest `/users/alice/bests/cycling` (bei `coachLinks/alice_coachCharlie` mit `permissions.activities == false`).
  - **Erwartet:** `PERMISSION_DENIED` (`isCoachForActivities` evaluiert zu `false`).
- **Fremder ohne Verknüpfung versucht Bestwerte zu lesen:**
  - **Aktion:** `eveAuth` liest `/users/alice/bests/cycling` (kein `coachLinks/alice_eve` vorhanden).
  - **Erwartet:** `PERMISSION_DENIED`.
- **Unauthentifizierter versucht Bestwerte zu lesen:**
  - **Aktion:** `unauth` liest `/users/alice/bests/cycling`.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 9.2 Write / Create / Update / Delete (Schreiben)
- **Athlet versucht Bestwert-Dokument anzulegen oder zu manipulieren:**
  - **Aktion:** `aliceAuth` versucht `/users/alice/bests/cycling` zu erstellen, zu aktualisieren oder zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow write: if false`).
- **Trainer versucht Bestwert-Dokument anzulegen oder zu manipulieren:**
  - **Aktion:** `bobAuth` versucht `/users/alice/bests/cycling` zu erstellen, zu verändern oder zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow write: if false`).
- **Fremder / Unauthentifizierter versucht Schreibzugriff:**
  - **Aktion:** `eveAuth` oder `unauth` versucht Schreibzugriff auf `/users/alice/bests/cycling`.
  - **Erwartet:** `PERMISSION_DENIED` (`allow write: if false`).

### 10. Collection `users/{userId}/thresholdProposals/{proposalId}` (Phase 12 – Leistungsdiagnostik: Schwellenwert-Vorschläge)

#### 10.1 Read (Lesen)
- **Athlet liest eigene Schwellenwert-Vorschläge:**
  - **Aktion:** `aliceAuth` liest `/users/alice/thresholdProposals/prop1`.
  - **Erwartet:** Erfolg (`isOwner(userId)`).
- **Trainer mit aktiver `activities`-Freigabe liest Schwellenwert-Vorschläge des Athleten:**
  - **Aktion:** `bobAuth` liest `/users/alice/thresholdProposals/prop1` (bei existierendem `coachLinks/alice_coachBob` mit `permissions.activities == true`).
  - **Erwartet:** Erfolg (`isAuthenticated() && isCoachForActivities(userId)`).
- **Trainer ohne `activities`-Freigabe versucht Schwellenwert-Vorschläge zu lesen:**
  - **Aktion:** `charlieAuth` liest `/users/alice/thresholdProposals/prop1` (bei `coachLinks/alice_coachCharlie` mit `permissions.activities == false`).
  - **Erwartet:** `PERMISSION_DENIED` (`isCoachForActivities` evaluiert zu `false`).
- **Fremder ohne Verknüpfung versucht Schwellenwert-Vorschläge zu lesen:**
  - **Aktion:** `eveAuth` liest `/users/alice/thresholdProposals/prop1` (kein `coachLinks/alice_eve` vorhanden).
  - **Erwartet:** `PERMISSION_DENIED`.
- **Unauthentifizierter versucht Schwellenwert-Vorschläge zu lesen:**
  - **Aktion:** `unauth` liest `/users/alice/thresholdProposals/prop1`.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 10.2 Create (Anlegen)
- **Athlet versucht Schwellenwert-Vorschlag selbst anzulegen:**
  - **Aktion:** `aliceAuth` versucht `/users/alice/thresholdProposals/prop1` anzulegen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow create: if false`, Vorschläge werden ausschließlich serverseitig via Cloud Functions generiert).
- **Trainer versucht Schwellenwert-Vorschlag im Client anzulegen:**
  - **Aktion:** `bobAuth` versucht `/users/alice/thresholdProposals/prop1` anzulegen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow create: if false`).
- **Fremder / Unauthentifizierter versucht Vorschlag anzulegen:**
  - **Aktion:** `eveAuth` oder `unauth` versucht `/users/alice/thresholdProposals/prop1` anzulegen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow create: if false`).

#### 10.3 Update (Ändern / Statusentscheidung)
- **Athlet übernimmt Vorschlag (`status: 'ACCEPTED'`):**
  - **Aktion:** `aliceAuth` aktualisiert `/users/alice/thresholdProposals/prop1` und setzt ausschließlich `status: 'ACCEPTED'`. Alle anderen Felder (`sport`, `type`, `proposedValue`, `confidence`, `basis`, `createdAt`) bleiben identisch.
  - **Erwartet:** Erfolg (`isOwner(userId) && isValidThresholdProposalUpdate()`).
- **Athlet lehnt Vorschlag ab (`status: 'REJECTED'`):**
  - **Aktion:** `aliceAuth` aktualisiert `/users/alice/thresholdProposals/prop1` und setzt ausschließlich `status: 'REJECTED'`. Alle anderen Felder bleiben unverändert.
  - **Erwartet:** Erfolg (`isOwner(userId) && isValidThresholdProposalUpdate()`).
- **Athlet versucht unzulässigen Status zu setzen:**
  - **Aktion:** `aliceAuth` aktualisiert Dokument mit `status: 'PENDING'` oder `status: 'INVALID_STATUS'`.
  - **Erwartet:** `PERMISSION_DENIED` (`status in ['ACCEPTED', 'REJECTED']` schlägt fehl).
- **Athlet versucht diagnostische Daten oder den vorgeschlagenen Wert zu manipulieren:**
  - **Aktion:** `aliceAuth` ändert `proposedValue` (z. B. von 250 auf 350) oder manipuliert `sport`, `type`, `confidence`, `basis` oder `createdAt`.
  - **Erwartet:** `PERMISSION_DENIED` (`affectedKeys().hasOnly(['status'])` und `areImmutableFieldsUnchanged` schlagen fehl).
- **Athlet versucht neue/unbekannte Felder einzuschleusen (Payload-Injektion):**
  - **Aktion:** `aliceAuth` setzt `status: 'ACCEPTED'` und fügt ein zusätzliches Feld `customField: 123` hinzu.
  - **Erwartet:** `PERMISSION_DENIED` (`affectedKeys().hasOnly(['status'])` schlägt fehl).
- **Trainer versucht Status des Athleten zu entscheiden:**
  - **Aktion:** `bobAuth` versucht `status: 'ACCEPTED'` in `/users/alice/thresholdProposals/prop1` zu setzen.
  - **Erwartet:** `PERMISSION_DENIED` (Nur der Athlet `isOwner(userId)` besitzt Entscheidungshoheit).
- **Fremder / Unauthentifizierter versucht Update:**
  - **Aktion:** `eveAuth` oder `unauth` versucht `/users/alice/thresholdProposals/prop1` zu aktualisieren.
  - **Erwartet:** `PERMISSION_DENIED`.

#### 10.4 Delete (Löschen)
- **Athlet löscht eigenen Schwellenwert-Vorschlag:**
  - **Aktion:** `aliceAuth` löscht `/users/alice/thresholdProposals/prop1`.
  - **Erwartet:** Erfolg (`isOwner(userId)`).
- **Trainer versucht Schwellenwert-Vorschlag des Athleten zu löschen:**
  - **Aktion:** `bobAuth` versucht `/users/alice/thresholdProposals/prop1` zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (`isOwner(userId)` schlägt fehl).
- **Fremder / Unauthentifizierter versucht Vorschlag zu löschen:**
  - **Aktion:** `eveAuth` oder `unauth` versucht `/users/alice/thresholdProposals/prop1` zu löschen.
  - **Erwartet:** `PERMISSION_DENIED`.

### 11. Chat & Push-Infrastruktur (Phase 13 – Chat, Push-Benachrichtigungen & Storage)

#### 11.1 Collection `chats/{chatId}`
- **11.1.1 Read (Teilnehmer):**
  - **Aktion:** `aliceAuth` und `bobAuth` lesen `/chats/alice_coachBob`.
  - **Erwartet:** Erfolg (`isChatParticipant(chatId)` ist für beide wahr).
- **11.1.2 Read (Trainer Listenabfrage über Filter):**
  - **Aktion:** `bobAuth` führt `db.collection('chats').where('coachId', '==', 'coachBob').get()` aus.
  - **Erwartet:** Erfolg (Query-Alignment durch `resource.data.coachId == request.auth.uid`).
- **11.1.3 Read (Athlet Listenabfrage über Filter):**
  - **Aktion:** `aliceAuth` führt `db.collection('chats').where('athleteId', '==', 'alice').get()` aus.
  - **Erwartet:** Erfolg (Query-Alignment durch `resource.data.athleteId == request.auth.uid`).
- **11.1.4 Read (Fremder Nutzer):**
  - **Aktion:** `eveAuth` liest `/chats/alice_coachBob`.
  - **Erwartet:** `PERMISSION_DENIED` (`isChatParticipant` schlägt fehl).
- **11.1.5 Read (Unauthentifizierter Zugriff):**
  - **Aktion:** `unauth` liest `/chats/alice_coachBob`.
  - **Erwartet:** `PERMISSION_DENIED`.
- **11.1.6 Write / Create / Update / Delete (Client-Schreibverbot):**
  - **Aktion:** `aliceAuth` oder `bobAuth` versucht `/chats/alice_coachBob` anzulegen, Felder wie `lastMessage` / `unread` zu verändern oder das Chat-Dokument zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow write: if false;`, Lifecycle und Aggregationen laufen strikt über Cloud Functions).

#### 11.2 Subcollection `chats/{chatId}/messages/{messageId}`
- **11.2.1 Read (Teilnehmer):**
  - **Aktion:** `aliceAuth` und `bobAuth` lesen `/chats/alice_coachBob/messages/m1`.
  - **Erwartet:** Erfolg (`isChatParticipant(chatId)`).
- **11.2.2 Read (Fremder / Unauthentifizierter):**
  - **Aktion:** `eveAuth` oder `unauth` liest `/chats/alice_coachBob/messages/m1`.
  - **Erwartet:** `PERMISSION_DENIED`.
- **11.2.3 Create (Gültige Textnachricht durch Sender in aktivem Chat):**
  - **Aktion:** `aliceAuth` erstellt Dokument in `/chats/alice_coachBob/messages/m1` mit:
    `{ senderId: 'alice', type: 'TEXT', status: 'SENT', text: 'Hallo Bob', createdAt: request.time }`.
    Status des Chats ist `ACTIVE`.
  - **Erwartet:** Erfolg (`isChatParticipant && isChatActive && senderId == auth.uid && isValidMessageCreate`).
- **11.2.4 Create (Gültige Anhangs- und Aktivitäts-Nachrichten):**
  - **Aktion:** `bobAuth` erstellt Nachricht mit `senderId: 'coachBob'`, `type: 'IMAGE'`, `status: 'SENT'`, `attachment: { path: 'chats/alice_coachBob/images/pic.jpg', size: 1024 }`.
  - **Erwartet:** Erfolg.
  - **Aktion:** `aliceAuth` erstellt Nachricht mit `senderId: 'alice'`, `type: 'ACTIVITY_SHARE'`, `status: 'SENT'`, `activityShare: { activityId: 'act1', snapshot: { distance: 10000 } }`.
  - **Erwartet:** Erfolg.
- **11.2.5 Create (Gefälschte Sender-ID):**
  - **Aktion:** `aliceAuth` erstellt Nachricht mit `senderId: 'coachBob'`.
  - **Erwartet:** `PERMISSION_DENIED` (`request.resource.data.senderId == request.auth.uid` schlägt fehl).
- **11.2.6 Create in widerrufenem Chat (`REVOKED`):**
  - **Aktion:** Verknüpfung wurde beendet, Chat hat `status: 'REVOKED'`. `aliceAuth` oder `bobAuth` versucht eine neue Nachricht zu erstellen.
  - **Erwartet:** `PERMISSION_DENIED` (`isChatActive` schlägt fehl).
- **11.2.7 Create durch Fremden:**
  - **Aktion:** `eveAuth` versucht Nachricht in `/chats/alice_coachBob/messages/m_eve` anzulegen.
  - **Erwartet:** `PERMISSION_DENIED` (`isChatParticipant` schlägt fehl).
- **11.2.8 Create mit unzulässigem Initial-Status oder Typ:**
  - **Aktion:** `aliceAuth` erstellt Nachricht mit `status: 'DELETED'` oder `type: 'SYSTEM_NOTIFICATION'`.
  - **Erwartet:** `PERMISSION_DENIED` (`isValidMessageCreate` schlägt fehl).
- **11.2.9 Create mit DoS-String (Überlanger Text):**
  - **Aktion:** `aliceAuth` erstellt Nachricht mit Text > 10.000 Zeichen.
  - **Erwartet:** `PERMISSION_DENIED` (`checkStringSize(..., 0, 10000)` schlägt fehl).
- **11.2.10 Update (Gültiges Soft-Delete durch den Sender):**
  - **Aktion:** `aliceAuth` aktualisiert Nachricht `m1` (ursprünglich `senderId: 'alice'`, `status: 'SENT'`):
    setzt `status: 'DELETED'`. `senderId`, `createdAt` und `type` bleiben identisch.
  - **Erwartet:** Erfolg (`isValidMessageUpdate`).
- **11.2.11 Update (Fremdes Soft-Delete durch Empfänger oder Fremden):**
  - **Aktion:** `bobAuth` oder `eveAuth` versucht Alices Nachricht `m1` auf `status: 'DELETED'` zu setzen.
  - **Erwartet:** `PERMISSION_DENIED` (`resource.data.senderId == request.auth.uid` schlägt fehl).
- **11.2.12 Update (Nachträgliches Editieren des Inhalts / Non-Goal):**
  - **Aktion:** `aliceAuth` versucht bei `status: 'SENT'` den Text der Nachricht nachträglich zu editieren.
  - **Erwartet:** `PERMISSION_DENIED` (`isSoftDelete: request.resource.data.status == 'DELETED'` erzwingt, dass Updates ausschließlich Soft-Deletes sind).
- **11.2.13 Update (Wiederherstellung / Undelete gelöschter Nachrichten):**
  - **Aktion:** `aliceAuth` versucht eine bereits mit `status: 'DELETED'` markierte Nachricht auf `status: 'SENT'` zurückzusetzen.
  - **Erwartet:** `PERMISSION_DENIED` (`notAlreadyDeleted` schlägt fehl).
- **11.2.14 Update (Manipulation unveränderlicher Identitätsfelder):**
  - **Aktion:** `aliceAuth` versucht bei einem Soft-Delete `senderId` auf 'coachBob' zu ändern.
  - **Erwartet:** `PERMISSION_DENIED` (`areImmutableFieldsUnchanged(['senderId', 'createdAt', 'type'])` schlägt fehl).
- **11.2.15 Delete (Striktes Hard-Delete Verbot):**
  - **Aktion:** `aliceAuth` oder `bobAuth` ruft `.delete()` auf `/chats/alice_coachBob/messages/m1` auf.
  - **Erwartet:** `PERMISSION_DENIED` (`allow delete: if false;`).

#### 11.3 Subcollection `chats/{chatId}/state/{uid}`
- **11.3.1 Read (Teilnehmer):**
  - **Aktion:** `aliceAuth` und `bobAuth` lesen `/chats/alice_coachBob/state/alice`.
  - **Erwartet:** Erfolg (`isChatParticipant(chatId)`).
- **11.3.2 Read (Fremder):**
  - **Aktion:** `eveAuth` liest `/chats/alice_coachBob/state/alice`.
  - **Erwartet:** `PERMISSION_DENIED`.
- **11.3.3 Write (Eigener Gelesen-Status):**
  - **Aktion:** `aliceAuth` schreibt in `/chats/alice_coachBob/state/alice` mit `{ lastReadAt: request.time }`.
  - **Erwartet:** Erfolg (`isChatParticipant && isOwner(uid) && isValidChatState`).
- **11.3.4 Write (Fremder Gelesen-Status / Manipulation des Gegenübers):**
  - **Aktion:** `bobAuth` versucht in `/chats/alice_coachBob/state/alice` zu schreiben.
  - **Erwartet:** `PERMISSION_DENIED` (`isOwner(uid)` schlägt fehl).
- **11.3.5 Write (Ungültiges Schema / Payload-Injektion):**
  - **Aktion:** `aliceAuth` schreibt ein Dokument ohne `lastReadAt` oder mit mehr als 5 Feldern.
  - **Erwartet:** `PERMISSION_DENIED` (`isValidChatState` schlägt fehl).
- **11.3.6 Delete (Löschverbot):**
  - **Aktion:** `aliceAuth` versucht `/chats/alice_coachBob/state/alice` zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow delete: if false;`).

#### 11.4 Subcollection `users/{uid}/devices/{deviceId}`
- **11.4.1 Read/Write (Owner registriert eigenes Gerät):**
  - **Aktion:** `aliceAuth` erstellt/aktualisiert `/users/alice/devices/dev1` mit:
    `{ fcmToken: 'valid_token_xyz', platform: 'android', appVersion: '1.0.0', language: 'de' }`.
  - **Erwartet:** Erfolg (`isOwner(userId) && isValidDeviceDoc`).
- **11.4.2 Read/Write (Fremder oder Trainer):**
  - **Aktion:** `bobAuth` oder `eveAuth` versucht `/users/alice/devices/dev1` zu lesen oder zu schreiben.
  - **Erwartet:** `PERMISSION_DENIED` (`isOwner(userId)` schlägt fehl).
- **11.4.3 Delete (Owner entfernt Gerät bei Logout):**
  - **Aktion:** `aliceAuth` löscht `/users/alice/devices/dev1`.
  - **Erwartet:** Erfolg (`isOwner(userId)`).
- **11.4.4 Validation (DoS-Schutz bei überlangen Feldern):**
  - **Aktion:** `aliceAuth` versucht ein Dokument mit `fcmToken` > 1.000 Zeichen anzulegen.
  - **Erwartet:** `PERMISSION_DENIED` (`checkStringSize(..., 1, 1000)` schlägt fehl).

#### 11.5 Subcollection `users/{uid}/notificationState/{docId}`
- **11.5.1 Read (Owner):**
  - **Aktion:** `aliceAuth` liest `/users/alice/notificationState/current`.
  - **Erwartet:** Erfolg (`isOwner(userId)`).
- **11.5.2 Read (Fremder / Coach):**
  - **Aktion:** `bobAuth` oder `eveAuth` versucht `/users/alice/notificationState/current` zu lesen.
  - **Erwartet:** `PERMISSION_DENIED`.
- **11.5.3 Write (Striktes Client-Schreibverbot):**
  - **Aktion:** `aliceAuth`, `bobAuth` oder `eveAuth` versucht `/users/alice/notificationState/current` zu schreiben oder zu löschen.
  - **Erwartet:** `PERMISSION_DENIED` (`allow write: if false;`).

#### 11.6 Cloud Storage: `chats/{chatId}` Medien & Anhänge
- **11.6.1 Read (Teilnehmer für Bilder und Dateien):**
  - **Aktion:** `aliceAuth` und `bobAuth` lesen aus `/chats/alice_coachBob/images/pic.jpg` und `/chats/alice_coachBob/files/plan.fit`.
  - **Erwartet:** Erfolg (`isChatParticipant(chatId)`).
- **11.6.2 Read (Fremder / Unauthentifizierter):**
  - **Aktion:** `eveAuth` oder `unauth` liest aus `/chats/alice_coachBob/images/pic.jpg`.
  - **Erwartet:** `PERMISSION_DENIED`.
- **11.6.3 Create Bild (Teilnehmer, <= 10MB, Content-Type image/*):**
  - **Aktion:** `aliceAuth` lädt 4 MB Bild mit `contentType: 'image/jpeg'` nach `/chats/alice_coachBob/images/photo.jpg` hoch.
  - **Erwartet:** Erfolg.
- **11.6.4 Create Bild (Limit überschritten oder falscher Dateityp):**
  - **Aktion:** `aliceAuth` lädt 12 MB Bild nach `/chats/alice_coachBob/images/huge.jpg` hoch.
  - **Erwartet:** `PERMISSION_DENIED` (`size <= 10 * 1024 * 1024` schlägt fehl).
  - **Aktion:** `aliceAuth` lädt PDF nach `/chats/alice_coachBob/images/doc.pdf` mit `contentType: 'application/pdf'` hoch.
  - **Erwartet:** `PERMISSION_DENIED` (`contentType.matches('image/.*')` schlägt fehl).
- **11.6.5 Create Datei (Teilnehmer, <= 25MB):**
  - **Aktion:** `bobAuth` lädt 15 MB FIT- oder PDF-Datei nach `/chats/alice_coachBob/files/plan.fit` hoch.
  - **Erwartet:** Erfolg.
  - **Aktion:** `bobAuth` lädt 28 MB Datei nach `/chats/alice_coachBob/files/big.fit` hoch.
  - **Erwartet:** `PERMISSION_DENIED` (`size <= 25 * 1024 * 1024` schlägt fehl).
- **11.6.6 Update (Strikte Immutabilität):**
  - **Aktion:** `aliceAuth` oder `bobAuth` versucht eine existierende Datei oder ein Bild zu überschreiben.
  - **Erwartet:** `PERMISSION_DENIED` (`allow update: if false;`).
- **11.6.7 Delete (Anhangsbereinigung bei Soft-Delete):**
  - **Aktion:** `aliceAuth` löscht `/chats/alice_coachBob/images/photo.jpg` nach Soft-Delete der Nachricht.
  - **Erwartet:** Erfolg (`allow delete: if isChatParticipant(chatId);`).
- **11.6.8 Delete durch Fremden:**
  - **Aktion:** `eveAuth` versucht `/chats/alice_coachBob/images/photo.jpg` zu löschen.
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

### Theoretischer Beweis (Architektur-Check): Bestwerte & Power-Dauer-Kurve (Phase 11)

**1. Ausschließliche serverseitige Pflege (Schutz vor Rekord-Manipulation):**
In Phase 11 visualisiert das Analyse-Cockpit Bestwerte wie die Power-Dauer-Kurve (Mean-Maximal-Power für 1s bis 4h) und Bestzeiten je Distanz (Allzeit und aktuelle Saison). Da diese Kennzahlen als Grundlage für Trainingsentscheidungen, Schwellenwert-Vorschläge und Leistungsvergleiche dienen, dürfen sie keinesfalls durch Clients manipuliert oder gefälscht werden können. Die Regel `allow write: if false;` stellt sicher, dass Schreibzugriffe strikt dem vertrauenswürdigen Backend (Cloud Functions mit Firebase Admin SDK, das die Sicherheitsregeln umgeht) vorbehalten sind.

**2. Granulare Autorisierung über `coachLinks.permissions.activities`:**
Bestwerte aggregieren die Spitzenleistungen aus den absolvierten Aktivitäten des Athleten. Im DSGVO-konformen Berechtigungsmodell von ORBIT (`coachLinks/{athleteId}_{coachId}`) schützt das Flag `permissions.activities` die Einsicht in Aktivitäts- und Trainingsdaten. Die Hilfsfunktion `isCoachForActivities(athleteId)` liest per `get()` das Verknüpfungsdokument `/coachLinks/$(athleteId + '_' + request.auth.uid)` und prüft `linkDoc.data.permissions.activities == true`.
- Hat der Athlet dem Trainer das Recht erteilt, kann der Trainer die Bestwerte einsehen (`isAuthenticated() && isCoachForActivities(userId)`).
- Ohne Freigabe oder bei getrennter Verbindung wird der Lesezugriff sofort abgewiesen.
- Ein Entzug der Berechtigung durch den Athleten wird in Echtzeit ohne Cache-Verzögerung wirksam.

**3. Performanter Lesezugriff ohne "Rules are not filters"-Konflikt:**
Bestwerte sind nach Sportart modularisiert (`users/{userId}/bests/{sport}`). Sowohl gezielte Einzeldokument-Abfragen (z. B. `doc('users/alice/bests/cycling').get()`) als auch Collection-Abfragen über alle Sportarten des Athleten (`collection('users/alice/bests').get()`) sind uneingeschränkt möglich. Da die Autorisierungsbedingung ausschließlich an den Pfadparameter `{userId}` und den statisch prüfbaren `coachLinks`-Pfad gebunden ist und keine dokumenteninternen Felder voraussetzt, evaluiert Firestore die Leseerlaubnis konsistent auf Collection-Ebene.

### Theoretischer Beweis (Architektur-Check): Schwellenwert-Vorschläge & Athleten-Entscheidungshoheit (Phase 12)

**1. Ausschließliche serverseitige Erstellung (`allow create: if false`):**
In Phase 12 ermittelt das Backend über wissenschaftliche Schätzmethoden (Critical Power, MMP-Muster, CSS, Schwellen-Pace/HF) relevante Leistungsveränderungen und speichert diese als Vorschläge unter `users/{userId}/thresholdProposals/{proposalId}` ab.
Da fehlerhafte oder manipulierte Schwellenwerte die Berechnung aller Trainingsmetriken (TSS, IF, Zonen, CTL/ATL/TSB) verfälschen würden, ist das Anlegen neuer Vorschläge für alle Clients ausnahmslos gesperrt. Vorschläge können ausschließlich über vertrauenswürdige Cloud Functions (Firebase Admin SDK) erzeugt werden.

**2. Granulare Coach-Einsicht über `coachLinks.permissions.activities`:**
Trainer benötigen zur Trainingssteuerung und Beurteilung des Leistungsstandes Einblick in die Schwellenwert-Historie und aktuelle Vorschläge ihrer Athleten. Da Schwellenwert-Vorschläge auf den Trainingsaktivitäten des Athleten basieren, ist der Lesezugriff an das DSGVO-Berechtigungsflag `permissions.activities` gekoppelt:
`allow read: if isOwner(userId) || (isAuthenticated() && isCoachForActivities(userId));`
- Besitzt der verknüpfte Trainer die Aktivitätsfreigabe, kann er die Vorschläge einsehen (`isCoachForActivities` evaluiert via `get()` auf `/coachLinks/$(userId)_$(auth.uid)` zu `true`).
- Fehlt die Freigabe oder existiert keine aktive Verbindung, wird der Lesezugriff sofort abgewiesen.
- Entzieht der Athlet die Berechtigung, verliert der Coach im selben Moment die Leserechte.

**3. Strikte Athleten-Souveränität bei Entscheidungen (`isOwner(userId)`):**
Gemäß der Produktphilosophie von ORBIT und den Vorgaben für Phase 12 („Nur der Athlet entscheidet") ist ein Update ausschließlich dem Athleten selbst erlaubt (`isOwner(userId)`). Ein Coach kann den Vorschlag zwar sehen, hat jedoch keinerlei Schreib- oder Entscheidungsrechte über den Status (`bobAuth` -> `PERMISSION_DENIED`).

**4. Validator Function Pattern & mathematische Feldintegrität bei Updates:**
Die Hilfsfunktion `isValidThresholdProposalUpdate()` erzwingt drei komplementäre Sicherheitsprüfungen bei Statusänderungen:
- **Exklusive Feldmutation:** `request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status'])` stellt sicher, dass der Diff des Dokuments maximal das Feld `status` umfasst. Es ist unmöglich, andere Felder zu aktualisieren, zu entfernen oder neue Felder (z. B. Payload-Injektionen oder Privilegien-Flags) hinzuzufügen.
- **Zustandsraum-Validierung:** `request.resource.data.status in ['ACCEPTED', 'REJECTED']` beschränkt die Statusaktualisierung strikt auf die beiden fachlich gültigen Endzustände. Ein Rücksetzen auf `PENDING` oder beliebige Freitexte wird abgewiesen.
- **Explizite Immutabilität diagnostischer Daten:** `areImmutableFieldsUnchanged(['sport', 'type', 'proposedValue', 'confidence', 'basis', 'createdAt'])` schützt die wissenschaftlichen Kernparameter (insb. den berechneten Schwellenwert `proposedValue` und dessen Datenbasis `basis`) redundant vor jeder Modifikation.

**5. Souveräne Datenbereinigung (`allow delete: if isOwner(userId)`):**
Der Athlet behält die volle Souveränität über seinen Speicherplatz und seine Historie: Abgelehnte oder veraltete Vorschläge dürfen vom Athleten gelöscht werden (`isOwner(userId)`). Für Coaches oder Fremde ist das Löschen strikt unterbunden.

### Theoretischer Beweis (Architektur-Check): Chat, Push-Infrastruktur & Storage (Phase 13)

**1. Teilnehmer-Bindung ohne Firestore Document-Read-Overhead (`chatId.split('_')` und statisches Query-Matching):**
- Durch die deterministische Namenskonvention `chatId = "{athleteId}_{coachId}"` kann die Autorisierung für Subcollections (`messages/{messageId}`, `state/{uid}`) und Storage-Pfade (`chats/{chatId}/*`) direkt anhand des Pfadnamens via `request.auth.uid in chatId.split('_')` erfolgen.
- Es ist **kein** zusätzlicher `get()`-Aufruf auf das übergeordnete Chat-Dokument erforderlich. Dies spart Firestore Document Reads bei jedem Nachrichten- oder Attachment-Abruf und verhindert Read-Quota-Bottlenecks.
- Für Root-Chat-Abfragen (`collection('chats')`) kombiniert die Regel `isChatParticipant(chatId) || (resource != null && (resource.data.athleteId == request.auth.uid || resource.data.coachId == request.auth.uid))` die Pfadauswertung mit denormalisierten Dokumentfeldern: So kann der Coach `collection('chats').where('coachId', '==', request.auth.uid)` und der Athlet `where('athleteId', '==', request.auth.uid)` performant und indexbasiert abfragen, ohne dass Firestore die Abfrage wegen Unentscheidbarkeit ("Rules are not filters") abweist.

**2. Chat-Dokument-Lifecycle & Schreibschutz (`allow write: if false`):**
- Das Chat-Dokument entsteht strikt serverseitig über Cloud Functions bei Annahme eines Einladungscodes bzw. Aktivierung der Trainer-Athleten-Verknüpfung (`coachLinks/{athleteId}_{coachId}`).
- Metadaten wie `lastMessage`, `updatedAt` und ungelesene Nachrichten (`unread: { uid: count }`) werden transaktional von Functions verwaltet.
- Das strikte Schreibverbot für Clients (`allow write: if false;`) verhindert, dass Nutzer unberechtigt Zähler manipulieren, Teilnehmer austauschen oder fremde Chats überschreiben.

**3. Schutz nach Verknüpfungswiderruf (`REVOKED`) bei Erhalt des Lesezugriffs:**
- Wird eine Verknüpfung zwischen Athlet und Trainer aufgelöst, setzt die Cloud Function den Status des Chats auf `status: 'REVOKED'`.
- Beim Erstellen neuer Nachrichten verlangt die Hilfsfunktion `isChatActive(chatId)`:
  `exists(chatPath) && (!('status' in get(chatPath).data) || get(chatPath).data.status != 'REVOKED')`.
- Sobald der Status `REVOKED` ist, schlägt `isChatActive` fehl, sodass keine neuen Nachrichten mehr gepostet werden können.
- Der Lesezugriff auf historische Nachrichten bleibt über `isChatParticipant(chatId)` intakt. Dies erfüllt die DSGVO- und Produktdokumentations-Anforderung (Aufbewahrung der Trainingskommunikation bei gleichzeitigem Stopp neuer Interaktionen).

**4. Soft-Delete-Integrität & Verbot von Edit/Hard-Delete:**
- **Identitätsbindung:** Eine Nachricht darf nur mit `senderId == request.auth.uid` erstellt werden.
- **Kein Hard-Delete:** Hard-Deletes sind kategorisch gesperrt (`allow delete: if false;`).
- **Ausschließliches Soft-Delete:** Ein Update ist ausschließlich dem ursprünglichen Absender gestattet (`resource.data.senderId == request.auth.uid`) und darf ausschließlich ein Soft-Delete ausführen: `request.resource.data.status == 'DELETED'`.
- **Kein Nachträgliches Editieren:** Da `status == 'DELETED'` erzwungen wird, ist das Verfälschen von Nachrichtentexten bei bestehendem `SENT`-Status unmöglich (wichtiger Beweis für die Anforderung "Nachricht bearbeiten ist Non-Goal").
- **Schutz vor Undelete:** Durch `resource.data.status != 'DELETED'` kann eine gelöschte Nachricht nicht reaktiviert werden.
- **Unveränderliche Felder:** `areImmutableFieldsUnchanged(['senderId', 'createdAt', 'type'])` stellt sicher, dass Urheber und Erstellungszeitpunkt auch beim Soft-Delete revisionssicher erhalten bleiben.

**5. Isolierter FCM-Token-Speicher & Schutz des Scheduler-Zustands:**
- Geräte-Tokens liegen unter `users/{userId}/devices/{deviceId}`. Durch `isOwner(userId)` können sie ausschließlich vom authentifizierten Besitzer gelesen, angelegt, aktualisiert und bei Logout gelöscht werden. Dritte (Coaches, Fremde) haben keinerlei Einblick in fremde Geräte-Tokens (Schutz der Privatsphäre und Verhinderung von Push-Spoofing).
- Der Scheduler-Status unter `users/{userId}/notificationState/{docId}` speichert vorberechnete Zeitpunkte (`nextReminderAtUtc`, `nextWeeklySummaryAtUtc`). Durch `allow read: if isOwner(userId); allow write: if false;` kann der Nutzer diesen einsehen, aber zu keinem Zeitpunkt manipulieren.

**6. Cloud Storage Sicherheit (Anhänge, Dateitypen & Größenlimits):**
- Chat-Medien sind strikt in `chats/{chatId}/images` und `chats/{chatId}/files` separiert.
- Bilder sind auf `request.resource.size <= 10 * 1024 * 1024` (10 MB) und `request.resource.contentType.matches('image/.*')` beschränkt.
- Dateien sind auf `request.resource.size <= 25 * 1024 * 1024` (25 MB) beschränkt.
- **Immutabilität:** `allow update: if false;` verhindert das heimliche Überschreiben von hochgeladenen Dokumenten durch schädliche Payloads.
- **Getrennte Delete-Erlaubnis:** Da `request.resource` bei Storage-Deletes `null` ist, führt eine kombinierte `write`-Regel mit Größenprüfung bei Löschungen zu Runtime-Errors. Durch die explizite Trennung in `allow create` und `allow delete: if isChatParticipant(chatId);` kann der Nutzer beim Soft-Delete einer Nachricht den Anhang in Storage sauber entfernen, ohne dass Sicherheitsprüfungen fehlschlagen.



