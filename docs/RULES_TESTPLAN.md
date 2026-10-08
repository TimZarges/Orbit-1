# Testplan für Firestore Security Rules (Phase 01)

## Ziel
Sicherstellen, dass die implementierten Firestore Security Rules für die `users`-Collection und deren Subcollections (`thresholdHistory`, `consents`, `private`) robust sind und die geforderten Berechtigungen durchsetzen (Default Deny, Owner-Only Access, Schutz von Server-Feldern).

## Setup
- Die Tests werden gegen den lokalen **Firebase Emulator** ausgeführt.
- Framework: `@firebase/rules-unit-testing` (JavaScript/TypeScript) in der Firebase Functions Testumgebung oder einem separaten Test-Skript.
- Testdaten (Mocks):
  - `aliceAuth`: Authentifizierter Nutzer mit UID "alice"
  - `bobAuth`: Authentifizierter Nutzer mit UID "bob"
  - `unauth`: Nicht authentifizierter Zugriff (null)

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

## Umsetzung
Die Tests werden als `.spec.ts` oder `.test.ts` im Testordner angelegt (z. B. `functions/tests/rules.spec.ts`) und per `npm test` gegen den laufenden Emulator (`firebase emulators:start`) ausgeführt. Dies wird im Rahmen der Phase 01 Implementierung sichergestellt.

### Theoretischer Beweis (Architektur-Check): Trainer-Zugriffsmodell (Phase 02)

**1. Warum das denormalisierte `coachId`-Feld in Listenabfragen funktioniert:**
Firestore Security Rules sind keine Filter (Stichwort: "Rules are not filters"). Wenn ein Trainer eine Abfrage `db.collection('activities').get()` ausführt, wird sie abgewiesen, da er nicht auf alle Aktivitäten global zugreifen darf. 
Führt der Trainer jedoch eine gefilterte Abfrage `db.collection('activities').where('coachId', '==', request.auth.uid).get()` aus, kann Firestore diese statisch analysieren. Da die Rule `allow read: if resource.data.coachId == request.auth.uid;` exakt dieser Filterbedingung entspricht, ist die Abfrage zulässig und extrem performant, da nur ein Index auf `coachId` abgefragt werden muss.

**2. Warum wir für Subcollections wie Health auf `get()` zurückgreifen müssen:**
Die Health-Daten liegen als Subcollection in `users/{uid}/dailyMetrics/{date}`. Wir denormalisieren die `coachId` nicht in jedes einzelne Tagesdokument, da die Berechtigung granular in `coachLinks` verwaltet wird (Feld `permissions.health`). Um bei einem Read auf die Health-Daten zu prüfen, ob der Trainer diese sehen darf, muss die Rule dynamisch das Verknüpfungs-Dokument laden: 
`get(/databases/$(database)/documents/coachLinks/$(uid)_$(request.auth.uid)).data.permissions.health == true`.

**3. Warum `get()` bei Einzelabfragen pro Tag in Ordnung ist:**
Der Aufruf von `get()` in Security Rules kostet einen zusätzlichen Document Read. Da der Trainer in der Regel Health-Daten eines Athleten gezielt (z.B. für die heutige Ansicht oder ausgewählte Tage) abruft, löst dies keine massiven List-Abfragen mit hunderten `get()`-Aufrufen aus. Das Limit von 10 Document Access Calls pro Rule-Auswertung (für Einzel-Dokumente bzw. 20 für Listen) wird hier nicht überschritten, und die Kosten sind minimal. Der große Vorteil ist die absolute Datenkonsistenz: Entzieht der Athlet das Health-Recht, greift die Sperre in derselben Sekunde für alle Tagesdaten rückwirkend.
