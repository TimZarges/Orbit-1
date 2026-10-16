# ORBIT — Testplan für manuelle Rollen-Abnahme (Closed Beta)

> **Gültig ab:** Version v0.24.0-rc.1  
> **Ziel-Umgebung:** Google Pixel 10 Pro (Android 15), Google Pixel / Galaxy (Android 14+), Chrome / Safari (Web-Coach)  
> **Backend:** Firebase Frankfurt (`europe-west3`) & Garmin Connect API Production

Dieser Testplan definiert die verbindlichen, manuellen Abnahmeschritte für den Beta-Test mit 5–10 Vereinsathleten und Vereinstrainern. Jeder Tester hakt seine Schritte ab. Gefundene Auffälligkeiten werden direkt in `docs/beta/BUGS.md` protokolliert.

---

## Rolle 1: Athlet mit Garmin (Primärgerät: Google Pixel 10 Pro)

**Ziel:** Vollständige Verifikation des automatischen Datenflusses von der Garmin-Uhr / Edge-Radcomputer über die Garmin Connect Cloud in die ORBIT App.

### Schritt 1: Onboarding & Authentifizierung
- [ ] App auf dem Pixel 10 Pro starten (Build v1.0.0+1).
- [ ] Begrüßungs-Screen wird flüssig angezeigt.
- [ ] Registrierung / Login per E-Mail & Passwort durchführen.
- [ ] 4-Schritte-Onboarding-Wizard durchlaufen:
  - Schritt 1: Rolle **Athlet** auswählen.
  - Schritt 2: Schwellenwerte hinterlegen (FTP in Watt, Max-HF, Ruhepuls).
  - Schritt 3: Sportarten auswählen (Rad, Lauf, Schwimmen).
  - Schritt 4: Datenschutzerklärung & Art.-9-DSGVO-Einwilligung (Gesundheitsdaten) explizit bestätigen.
- [ ] Ziel: Startseite („Heute“) wird geladen, Drei-Ringe-Hero-Card auf `#001F47` Navy mit Volt-Leitring `#CDFB17` ist sichtbar.

### Schritt 2: Garmin Connect OAuth-Verknüpfung
- [ ] Profil aufrufen (Avatar oben rechts) -> „Verknüpfte Dienste“ -> **Garmin Connect verbinden**.
- [ ] Chrome Custom Tab öffnet die offizielle Garmin OAuth 1.0a Login-Seite.
- [ ] Mit Garmin-Testkonto einloggen und Berechtigungen für Aktivitäten und Health-Daten erteilen.
- [ ] Automatische Rückkehr zur App über Deep-Link (`/settings`).
- [ ] Statusanzeige wechselt sofort auf **„Garmin verbunden (Aktiv)“** mit grünem Indikator.

### Schritt 3: 90-Tage-Historien-Backfill
- [ ] Button **„90-Tage-Historie importieren“** antippen.
- [ ] Cloud Function `garminBackfill` wird getriggert (3 Chunks à 30 Tage in `europe-west3`).
- [ ] Nach ca. 1–2 Minuten: Kalender und Historie füllen sich mit den Aktivitäten der letzten 3 Monate.
- [ ] PMC-Chart unter „Analyse“ zeigt eine lückenlose 90-Tage-Fitnesskurve (CTL, ATL, TSB).

### Schritt 4: Live-Webhook nach abgeschlossenem Training
- [ ] Auf der Garmin Forerunner / Fenix / Edge ein kurzes Training (oder Test-Aktivität) aufzeichnen und speichern.
- [ ] Garmin synchronisiert via Bluetooth mit der Garmin Connect App.
- [ ] Garmin Webhook sendet Payload an `https://europe-west3-orbit-app-beta.cloudfunctions.net/garminWebhook`.
- [ ] Innerhalb von 5–15 Sekunden:
  - Push-Benachrichtigung auf dem Pixel 10 Pro erscheint: **„Aktivität analysiert: [Titel] • TSS: [X] • NP: [Y] W“**.
  - Statusleisten-Icon: Monochromes ORBIT-Logo (`ic_stat_orbit`), Akzentfarbe `#001F47`.
  - Tippen auf die Push-Mitteilung öffnet direkt die Detailansicht (`/activities/:id`).

### Schritt 5: Drei Ringe & Tagessteuerung („Heute“)
- [ ] Startseite prüfen:
  - **Erholungs-Ring (0–100 %)**: Berechnet aus HRV-Baseline und Schlafqualität.
  - **Tagesbelastungs-Ring (0–100 %)**: Zeigt den dynamischen Zielkorridor und die heutige Ist-Belastung.
  - **Schlaf-Ring (0–100 %)**: Zeigt Schlafdauer vs. Schlafbedarf inkl. Schlafschuld.
  - **ORBIT Gesamt-Score (0–100)**: Zentrales Volt-Badge `#CDFB17`.
  - Datenbasierte Tages-Empfehlung (DE/EN) wird angezeigt.
- [ ] Health-Cockpit (`/health`) öffnen: 30-Tage-Normband ($\mu \pm 1\sigma$) für HRV und Ruhepuls ist eingezeichnet.

### Schritt 6: Push-Test & Quiet Time
- [ ] Im Einstellungsmenü den Button **„Test-Push senden“** antippen (`sendTestPushNotification`).
- [ ] Benachrichtigung trifft mit Ton/Vibration und ORBIT-Icon ein.
- [ ] Test bei aktiver Quiet Time (22:00–07:00 Uhr): Nicht-kritische Benachrichtigungen werden stummgeschaltet und erst um 07:30 Uhr mit dem Morgen-Briefing zugestellt.

### Schritt 7: In-App-Bug-Reporter mit Screenshot
- [ ] Schwebenden Käfer-Button (unten rechts) antippen.
- [ ] Dialog öffnet sich mit automatischem Screenshot und Diagnose-Logs.
- [ ] Kategorie wählen (z. B. `DESIGN_SUGGESTION`), Beschreibung eingeben und absenden.
- [ ] Firestore-Eintrag wird unter `betaFeedback/{reportId}` angelegt.

---

## Rolle 2: Athlet mit Wahoo / SRM (Manueller Multi-File-Upload & Wettkampf)

**Ziel:** Verifikation für Ausdauersportler ohne Garmin, die Wahoo ELEMNT, SRM PowerControl oder Zwift nutzen.

### Schritt 1: Manueller Multi-File-Upload (`.fit`, `.tcx`, `.gpx`)
- [ ] App auf Android-Gerät oder im Web-Browser öffnen.
- [ ] Im Tab „Aktivitäten“ auf das „+“-Symbol tippen / „Datei hochladen“ wählen.
- [ ] Mehrere Dateien gleichzeitig auswählen (z. B. 3 Dateien: `.fit`, `.tcx`, `.gpx` oder komprimiert `.fit.gz`).
- [ ] Upload-Fortschrittsbalken visualisiert die Verarbeitung.
- [ ] Alle Dateien werden durch die Storage-Function `processFitUpload` fehlerfrei geparst.
- [ ] Duplikat-Schutz: Dieselbe Datei erneut hochladen -> App meldet neutral: *„Aktivität bereits vorhanden (Duplikat übersprungen)“*.

### Schritt 2: Profi-Telemetrie & Skiba $W'\text{bal}$-Analyse
- [ ] Eine Radfahrt mit Powermeter öffnen (`/activities/:id`).
- [ ] Umschalten der synchronisierten Kanäle (Leistung `#CDFB17` Volt, W'bal `#FF0055`, HF `#FF3B30`, Trittfrequenz, Höhe).
- [ ] Finger über den Graphen scrubben: Der Cursor gleitet butterweich (≤ 16 ms) ohne Ruckeln über die 500 LTTB-Stützpunkte.
- [ ] Überprüfen, ob $W'\text{bal}$ bei Intervallen über CP entleert wird und in Rollphasen exponentiell nachlädt.
- [ ] Automatische Intervall-Tabelle prüfen: Erkannte Intervalle zeigen Dauer, Durchschnitts-Watt, NP und aerobe Entkopplung.

### Schritt 3: Saison-Ziele & A/B/C-Wettkampf-Planung
- [ ] Auf der Startseite in der `RaceCountdownCard` auf „Ziel bearbeiten“ tippen.
- [ ] Neuen A-Wettkampf anlegen (z. B. *DATEV Challenge Roth*, Datum in 10 Wochen, Sportart *Triathlon*, Zielzeit *9:15:00*, Ziel-Leistung *240 W*).
- [ ] Zusätzlichen B-Wettkampf (Vorbereitungs-Halbmarathon) und C-Wettkampf anlegen.
- [ ] Startseite zeigt den dynamischen Countdown mit Volt-Badge `#CDFB17` für das A-Rennen.
- [ ] Tab „Analyse“ (PMC-Chart) öffnen:
  - Vertikale Wettkampf-Flaggen werden am Renntag gerendert (A=Volt, B=Cyan, C=Weiß).
  - Die letzten 14 Tage vor dem A-Rennen zeigen den gestrichelten Taper-Zielkorridor (TSB $+10$ bis $+25$).

---

## Rolle 3: Vereinstrainer (Smartphone & Web `/app`)

**Ziel:** Verifikation der Trainer-Cockpits, DSGVO-konformen Freigaben und Trainingssteuerung für Vereinsgruppen.

### Schritt 1: Trainer-Rolle & Einladungscode generieren
- [ ] Registrierung / Login als Trainer.
- [ ] Im Coach-Dashboard auf **„Athleten einladen“** tippen.
- [ ] Ein 6-stelliger Einladungscode (z. B. `ORB-7429`) wird generiert und in die Zwischenablage kopiert.
- [ ] Code läuft nach 48 Stunden automatisch ab.

### Schritt 2: Athleten-Kopplung
- [ ] Athlet öffnet Tab „Coach“ -> Einladungscode eingeben -> „Verbinden“.
- [ ] Verknüpfung wird sofort aktiv. Trainer sieht den Athleten in seiner Athletenliste.

### Schritt 3: Art.-9-DSGVO-Gesundheitsdaten-Schalter live prüfen
- [ ] **Test A (Berechtigung erteilt):**
  - Athlet aktiviert in seinen Freigaben: *„Gesundheitsdaten (HRV, Schlaf, Erholung) für Trainer freigeben: AN“*.
  - Trainer öffnet den Athleten im Web-Coach `/app`: Die Erholungs-Ampel (Grün/Gelb/Rot) und der 3-Ringe-Score sind sichtbar.
- [ ] **Test B (Berechtigung widerrufen):**
  - Athlet schaltet im Profil den Schalter für Gesundheitsdaten auf **AUS**.
  - Trainer aktualisiert die Ansicht: Gesundheitsdaten und Ampel sind sofort gesperrt. Trainer sieht nur noch sportliche Leistungswerte (Watt, Pace, Trainingsdauer).
  - Security Rules blockieren jeglichen unberechtigten Lesezugriff mit `PERMISSION_DENIED`.

### Schritt 4: Trainingsplanung & Intervall-Feedback
- [ ] Trainer plant im Kalender ein Intervall-Training für morgen (z. B. *4x 8min EB @ 290 W*).
- [ ] Athlet erhält sofort eine Push-Benachrichtigung: **„Neues Training von Coach: 4x 8min EB“**.
- [ ] Nach dem Training: Trainer hinterlässt einen Feedback-Kommentar an der absolvierten Einheit.
- [ ] Athlet sieht die schwebende Trainer-Feedback-Bubble auf seinem Home-Dashboard.

### Schritt 5: Trainer-Trennung (`revokeLink`)
- [ ] Athlet oder Trainer tippt auf **„Verknüpfung trennen“**.
- [ ] Bestätigungs-Dialog akzeptieren.
- [ ] Verknüpfung wird aufgelöst.
- [ ] Verifikation: `coachId` wird von allen privaten Dokumenten entfernt. Trainer hat mit sofortiger Wirkung keinerlei Zugriff mehr auf historische oder neue Einheiten des Athleten.
