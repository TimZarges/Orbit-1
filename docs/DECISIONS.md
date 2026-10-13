# Entscheidungen (ADR-Log)

> Jede nicht triviale Entscheidung bekommt einen Eintrag: Datum, Kontext, Entscheidung, Begründung, Alternativen. Neueste oben.

## Vorlage
### YYYY-MM-DD: Titel
- **Kontext:**
- **Entscheidung:**
- **Begründung:**
- **Alternativen:**

---

## Bereits festgelegt (vor Projektstart)
- **Geplant ≠ absolviert:** getrennte Collections `plannedWorkouts` und `activities`, gegenseitig verknüpft.
- **Navigation:** rollenabhängig, 4 Tabs je Rolle, Profil hinter dem Avatar.
- **Erfahrungsstufen** Einfach/Fortgeschritten/Experte steuern Datendichte und Begriffe.
- **Metriken serverseitig**, Dart nur Vorschau, gemeinsame Testvektoren.
- **Coach-Zugriff** über denormalisiertes `coachId`, gepflegt per Function.
- **Webhook-Verarbeitung** über `webhookEvents` + Firestore-Trigger (kein Cloud Tasks im MVP).
- **Login:** Google + E-Mail/Passwort; Apple mit iOS-Start.
- **Score-Name:** „ORBIT Score" (nicht „MATS Score").
- **Tooling: Antigravity.** Zentrale Regeln in `AGENTS.md`, modulare Regeln in `.agents/rules/` (glob/model_decision), wiederverwendbare Abläufe als **Skills** in `.agents/skills/`. Workflows werden nicht genutzt, weil sie laut Antigravity-Doku am 1. November 2026 abgeschaltet werden.
- **Repo ist privat.** `google-services.json` darf (nach Rückfrage im Audit) committet werden. Service-Account-Schlüssel, Keystores, `.env` und Secrets nie.
- **Autopilot-Modus** (`/phase-run`): STOPP-Punkte werden zu Checkpoints in `docs/CHECKPOINTS.md`, Branches werden gestapelt, harte Stopps nur bei Blockern, Irreversiblem, Regelverstoß, Audit-Befund oder wiederholtem Fehler. Zweck: maximale Selbstständigkeit bei sichtbaren Review-Schulden.

### 2026-10-13: Analyse-Cockpit, Telemetrie-Scrubbing & LTTB-Downsampling (Phase 11)
- **Kontext:** Hochauflösende Zeitreihen (bis zu 36.000 Punkte bei 10h-Aktivitäten) müssen auf mobilen Geräten im Dark Cockpit (`#0F172A`) performant mit Kanalwahl, interaktivem Scrubbing, synchroner GPS-Strecke und Power-Duration-Kurve dargestellt werden.
- **Entscheidung & Begründung:**
  1. **LTTB-Downsampling (`LttbDownsampler`):** Dynamische Reduktion hochfrequenter Zeitreihen auf 400 Datenpunkte mittels Largest-Triangle-Three-Buckets. Garantiert $\le 16\text{ ms}$ Frame-Zeit (60 FPS) bei vollständiger Erhaltung aller physiologischen Belastungsspitzen und Intervalle.
  2. **Interaktives Scrubbing & HUD:** Long-Press-to-Scrub mit vertikaler Leitlinie und HUD über dem Finger (`TelemetryChartWidget`). Verhindert Gestenkonflikte mit vertikalem Page-Scrolling. Synchrone Steuerung des voltfarbenen GPS-Markers auf der Streckenkarte (`TelemetryMapWidget`).
  3. **DSGVO & Vektor-Kartenführung:** Die GPS-Route wird primär als reine Vektorgrafik vollständig offline dargestellt (keine Übertragung von IP-Adressen an Kartenserver). Das Nachladen externer Kacheln erfordert ein ausdrückliches Opt-In (`docs/PRIVACY.md`).
  4. **Power-Duration-Kurve (MMP):** Logarithmische Dauerachse (1s bis 60m), Vergleich mit Saison- und Allzeit-Bestwerten, automatische Auszeichnung neuer Rekorde mit „PR"-Badges in Volt-Fläche mit Navy-Text (Volt-Regel).
  5. **Serverseitige Bestwerte-Pflege:** Cloud Functions pflegen `users/{uid}/bests/{sport}` bei Aktivitätsimporten. Firestore Security Rules gewähren Lesezugriff für Athlet und Trainer mit `permissions.activities == true`.
- **Alternativen:** Rohdaten-Rendering (hätte zu Speicherüberläufen und Frame-Drops geführt) oder unkontrolliertes Laden von Google Maps (DSGVO-Hürden bzgl. Drittland-Datentransfer).

### 2026-10-13: Form-Ampel, Informationsarchitektur & Trainingsanalyse (Phase 10)
- **Kontext:** Der Tab „Analyse" soll in Sekunden verständliche Antworten liefern („Wie fit bin ich, wie belastet war die Woche, liege ich im Plan?") und nahtlos über drei Erfahrungsstufen mitwachsen.
- **Entscheidung & Begründung:**
  1. **Form-Ampel-Formel (`FormCalculator`):** Relatives Verhältnis $R = \frac{\text{TSB}}{\text{CTL}}$ (statt starrer Absolutwerte) mit Mindestdatenlage von $\ge 21$ Tagen und Mindest-CTL $\ge 10.0$. Vier physiologische Zustände: `veryTired` ($R < -0{,}30$), `wellLoaded` ($-0{,}30 \le R < -0{,}10$), `balanced` ($-0{,}10 \le R \le +0{,}15$), `fresh` ($R > +0{,}15$).
  2. **Transparenz & Neutralität:** Ehrliche Angabe der Datenbasis („Basiert auf X Wochen Training"), keinerlei medizinischer Rat, keine Bevormundung („du musst"). Der ORBIT Score bleibt ausgeblendet, bis er separat freigegeben wird.
  3. **Progressive Disclosure:**
     - *Einfach:* Form-Ampel, Wochenbelastung vs. Plan (Balken mit Soll/Ist und Klartext-Abweichung), Konsistenz.
     - *Fortgeschritten:* Zusätzlich Sportverteilung (Stapelbalken statt Torte), Zonenverteilung (Z1–Z7 mit Textlabels und Farbsehschwäche-Schutz), 8-Wochen-Trend.
     - *Experte:* Zusätzlich CTL/ATL/TSB-Linienverlauf, Schwellenwerte und Fachkürzel via `TermResolver`.
  4. **Performance & Datenschutz:** Tab lädt ausschließlich vorberechnete Tagesaggregate (`users/{uid}/aggregates/{date}`), keine speicherintensiven Rohaktivitäten oder Streams. Coach-Lesezugriff wird per Firestore Security Rule über `coachLinks.permissions.activities == true` gesichert.
- **Alternativen:** Absolute TSB-Werte (hätten fälschlicherweise Profis mit hoher CTL und Einsteiger mit niedriger CTL gleichgestellt) oder Tortendiagramme (auf Mobilgeräten ungenau abzulesen).

### 2026-10-13: Workout-Struktur Schema v1 & Builder-Architektur (Phase 09)
- **Kontext:** Schnelles, mobiles und fehlerarmes Erstellen strukturierter Einheiten per Text-Kurzeingabe oder grafischem Block-Editor sowie Speichern und Einplanen von Vorlagen.
- **Entscheidung & Begründung:**
  1. **Schema v1 (`WORKOUT_SYNTAX.md`):** Reine SI-Einheiten intern (Sekunden, Meter), strikt typisierte Sealed Classes (`StepBlock`, `RepeatBlock`), maximale Verschachtelungstiefe von 3, maximal 200 Blöcke nach Expansion. Unbekannte Schema-Versionen werden abgelehnt (`migrateStructure`).
  2. **Bidirektionale Synchronisation:** Vollständige Kopplung zwischen Freitext (`WorkoutParser`) und Block-Editor (`WorkoutBlockEditorSheet`) über `WorkoutBuilderNotifier`. Jede Änderung am Text aktualisiert das Diagramm und den Editor; jede Änderung an Steppern/Blöcken aktualisiert den Text im kanonischen Format (`WorkoutFormatter`).
  3. **Entkoppeltes Einplanen:** Beim Einplanen aus einer Vorlage (`workoutTemplates`) wird die Struktur in das neue Kalender-Dokument (`plannedWorkouts`) tief kopiert und nicht nur referenziert. So bleiben historische Kalenderdaten bei späteren Änderungen der Vorlage unverändert erhalten.
  4. **Granulare Trainer-Sichtbarkeit:** Vorlagen mit `SHARED_WITH_MY_ATHLETES` sind für betreute Athleten lesbar (`exists(/coachLinks/{athleteId}_{ownerId})`), aber nicht schreibbar.
  5. **Live-Profilgrafik:** Eigener performanter `CustomPainter` (`WorkoutProfileChart`) mit garantierter Mindestbalkenbreite (4 px für kurze 15s-Schritte) und Barrierefreiheit via `Semantics`.
- **Alternativen:** Reine Formularfelder (auf Mobilgeräten langsam und umständlich) oder JSON-Texteditor (fehleranfällig).

### 2026-10-08: Architektur-Fundament
- **Kontext:** Neuaufsetzen des Projekts von Null.
- **Entscheidung:** Nutzung von `flutter_riverpod` für State-Management, `go_router` für Routing und Dart 3 Records + `freezed`/`json_serializable` für komplexe Modelle.
- **Begründung:** Sauberster Ansatz für Skalierung, Typsicherheit und Wartbarkeit gemäß `DESIGN.md` und `REQUIREMENTS.md`. Compile-Time Safety bei Providern und Immutable Data Models.
- **Alternativen:** BLoC (mehr Boilerplate) oder Provider (weniger typsicher, schwerer zu testen).

### 2026-10-08: FIT-Parsing
- **Kontext:** Umgang mit `.fit`-Dateien (von Garmin etc.) und dem `fit_sdk`.
- **Entscheidung:** FIT-Parsing wird ausschließlich serverseitig (Node.js Cloud Functions mit `@garmin/fitsdk`) durchgeführt.
- **Begründung:** Der Flutter-Client muss nicht die Last des Parsings tragen. Der Client lädt die rohen Dateien nur hoch und zeigt die serverseitig aufbereiteten, gesampelten Metriken an. Das hält die App leichtgewichtig und zentralisiert die Logik.
- **Alternativen:** Client-seitiges Parsing (führt zu hohem RAM-Bedarf und großen App-Binaries).

### 2026-10-08: Karten-Bibliothek (Spike S2)
- **Kontext:** Wahl der Map-Library für GPS-Routen im Cockpit.
- **Entscheidung:** Nutzung von `flutter_map` mit datenschutzkonformen Tiles statt `google_maps_flutter`.
- **Begründung:** Gesundheitsdaten und IP-Übertragungen an Google erfordern hohe DSGVO-Hürden. `flutter_map` bietet ausreichende Performance für unsere Polylines und lässt sich gut in den Dark Mode integrieren.

### 2026-10-08: Chart-Bibliothek (Spike S1)
- **Kontext:** Performance von Telemetrie-Charts bei >7.000 Datenpunkten.
- **Entscheidung:** Nutzung von `fl_chart` in Kombination mit starkem Downsampling (serverseitig oder Client-seitig auf max. 500 Punkte).
- **Begründung:** Ein kompletter CustomPainter für interaktives Chart-Scrubbing ist zu aufwendig. Mit gedownsampleten Daten performt `fl_chart` ausreichend gut und ist deutlich wartbarer.

### 2026-10-08: FIT-Dateiverarbeitung und ESM Import
- **Kontext:** Das Garmin `@garmin/fitsdk` ist ein reines ES-Module, aber Cloud Functions nutzen per Default CommonJS (v20).
- **Entscheidung:** Das `@garmin/fitsdk` wird über dynamische `import()` Aufrufe in der Laufzeit eingebunden, statt die komplette Cloud Function auf ESM umzustellen.
- **Begründung:** Verhindert tiefgreifende Umbauten des Build-Setups für die Cloud Functions, ermöglicht aber dennoch die Nutzung des offiziellen SDKs.
- **Alternativen:** Komplettes TypeScript Setup auf ESM umstellen (komplex mit jest/firebase) oder externe Konverter nutzen.

### 2026-10-09: Metrik-Methoden (Phase 05)
- **Kontext:** Berechnung von Belastungswerten (TSS, CTL, ATL, etc.) für Rad, Lauf und Schwimmen.
- **Entscheidung & Begründung:**
  1. **Lauf-Belastung:** Primär **rTSS** (basierend auf Pace & Threshold Pace), da es die mechanische Belastung besser abbildet. Fallback auf **hrTSS** (basierend auf HF & Schwellen-HF), falls GPS/Pace unzuverlässig (z.B. Indoor) aber HF vorhanden ist.
  2. **sTSS (Schwimmen):** `sTSS = (Dauer_in_h) * (IF^3) * 100`, wobei `IF = Normalized Pace / Critical Swim Speed (CSS)`. Da Wasserwiderstand kubisch wächst, ist die dritte Potenz fachlich korrekt.
  3. **Behandlung fehlender Daten:** 
     - Keine FTP/Schwellenwerte: Berechnung mit Standard-Schätzwerten (z.B. HF-Max-Formel), Metrik-Qualität wird als `INSUFFICIENT` markiert.
     - Indoor ohne Leistung/Pace: Fallback auf hrTSS. Wenn auch keine HF, dann `TSS = 0` (oder manuelle RPE-Eingabe in Phase 09).
  4. **CTL/ATL-Modell:** Exponentieller gleitender Durchschnitt (EMA). CTL-Konstante = 42 Tage, ATL = 7 Tage. Startwert bei neuen Athleten ist 0 (baut sich über 6 Wochen auf, Option zur manuellen Vorgabe in Profil-Einstellungen).
  5. **NP (Glättung & Nullwerte):** 30-Sekunden gleitender Durchschnitt. Datenlücken < 30s werden als 0-Watt gewertet (verhindert das künstliche "Schönrechnen" bei Tretpausen).
  6. **Umgang mit langen Pausen:** Pausen > 30s (z.B. Ampel, Kaffeepause) setzen das 30s-Fenster zurück (verhindern Verzerrung durch extrem lange Null-Phasen im Moving Average).
- **Alternativen:** TRIMP statt hrTSS (weniger vergleichbar mit Rad-TSS), simple Durchschnitts-Pace statt rTSS.

### 2026-10-13: Health-Daten & Tagesform-Aggregation (Phase 07)
- **Kontext:** Garmin Health Webhooks pushen Dailies (Ruhepuls, Schritte), Sleeps (Dauer, Schlaf-Score) und HRV (rMSSD) asynchron und zu unterschiedlichen Zeitpunkten.
- **Entscheidung:**
  1. **Schema & Zusammenführung:** `users/{uid}/dailyMetrics/{localDate}` wird per Firestore-Upsert (`merge: true`) befüllt. Fehlende Felder (z. B. wenn der Nutzer kein Garmin mit Schlaf-Tracking oder HRV trägt) bleiben `null`/weggelassen und werden von der UI tolerant ausgeblendet.
  2. **Basislinie:** 28-Tage-Mittelwert/Median für Ruhepuls und HRV mit Mindestdatenlage von 14 Tagen. Liegen weniger als 14 Tage vor, zeigt ORBIT den Status „Aufbau der Basislinie" statt einer möglicherweise irreführenden Ampelbewertung.
  3. **Wortwahl & Neutralität:** Streng sachliche, sportwissenschaftliche Begriffe (Tagesform: Normalbereich, leichte Abweichung, deutliche Abweichung). Keine Heilsversprechen oder Diagnosen.
  4. **Trainer-Berechtigung:** Trainer-Lesezugriff auf `dailyMetrics` erfolgt strikt unter Prüfung von `coachLinks.permissions.health == true`.
- **Begründung:** Verhindert Datenverlust bei sequentiellen Webhook-Zustellungen, wahrt höchste DSGVO-Standards (Art. 9) und erfüllt das Leitprinzip „einfach zuerst, sachlich und verlässlich".

### 2026-10-13: Planungsmodell, Zuordnungslogik und Kalender-Rules (Phase 08)
- **Kontext:** Geplante Einheiten (`plannedWorkouts`) werden von Athleten und Trainern erstellt und müssen mit absolvierten Aktivitäten (`activities`) abgeglichen werden.
- **Entscheidung:**
  1. **Planungsdatenmodell (`plannedWorkouts/{workoutId}`):** Enthält `athleteId`, `coachId` (denormalisiert), `createdBy`, `localDate`, `sport`, `title`, `plannedDurationSec`, `plannedDistanceM`, `plannedLoad`, `status` (`PLANNED` | `COMPLETED` | `SKIPPED`), `activityId`.
  2. **Zuordnungsalgorithmus (`matchActivityToPlan`):**
     - Kandidatenfilter: Gleicher `localDate`, kompatible Sportart, Dauerplausibilität ($0{,}5 \le \text{Dauer-Verhältnis} \le 2{,}0$).
     - Scoring: Sport-Match (40 Pkt) + Dauernähe (bis 40 Pkt) + Titel/Distanz (bis 20 Pkt).
     - Automatischer Match (`AUTO`): Genau ein Kandidat mit Score $\ge 70$.
     - Uneindeutig: Verbleibt als `UNMATCHED`, UI bietet manuelle 1-Klick-Zuordnung.
  3. **Rules-Architektur:** Athleten dürfen eigene Einheiten erstellen, Trainer dürfen für verknüpfte Athleten planen, wenn `coachLinks.permissions.calendar == true`.
- **Begründung:** Gewährleistet klare Trennung von Plan und Realität (Grundprinzip 1), vermeidet fehlerhafte automatische Zuordnungen und ermöglicht kollaborative Trainingssteuerung für Trainer und Athleten.

### 2026-10-13: Leistungsdiagnostik & Schwellenwert-Vorschläge (Phase 12)
- **Kontext:** Erkennung veränderter Schwellenwerte (FTP, LTHR, Schwellenpace, CSS) aus regulären Trainingsdaten oder geführten Feldtests.
- **Entscheidung:**
  1. **Schätzmethoden je Sportart:**
     - **Rad-FTP:** $0.95 \times \text{MMP}_{20\text{m}}$. Variabilitätsindex (VI) dient als Konfidenz-Gate ($\text{VI} \le 1.05 \rightarrow \text{HIGH}$, $1.05 < \text{VI} \le 1.12 \rightarrow \text{MEDIUM}$, $> 1.15 \rightarrow$ verworfen wegen ungleichmäßiger Pacing-Struktur). Min-Delta $\ge 3\text{ W}$ oder $\ge 1.5\%$.
     - **Lauf (LTHR & Schwellenpace):** 30-Minuten-Dauerlauftest (Friel). LTHR = Durchschnittspuls der letzten 20 Minuten, Schwellenpace = 30-Minuten-Durchschnittstempo. HF-Plateau-Prüfung über Standardabweichung ($\text{StdDev} \le 4.0\text{ bpm} \rightarrow \text{HIGH}$, $> 8.0\text{ bpm} \rightarrow$ verworfen). Min-Delta $\ge 2\text{ bpm}$ bzw. $\ge 5\text{ s/km}$.
     - **Schwimmen (CSS):** 400m / 200m Zeitschwimmen. $\text{CSS} = (400 - 200) / (T_{400} - T_{200})$, $\text{Pace}_{\text{CSS}} = (T_{400} - T_{200}) / 2\text{ s/100m}$. Min-Delta $\ge 1.0\text{ s/100m}$.
  2. **Athleten-Souveränität & Berechtigungsmodell:**
     - Nur der Athlet selbst darf Schwellenwert-Vorschläge annehmen oder ablehnen (`status in ['ACCEPTED', 'REJECTED']`).
     - In der Trainer-Ansicht sind Vorschläge und Historie bei vorhandener Aktivitäten-Freigabe (`coachLinks.permissions.activities == true`) lesbar, aber nicht übernehmbar.
     - Schreibzugriff auf `thresholdProposals` durch Clients ist ausschließlich auf das Feld `status` beschränkt (`affectedKeys().hasOnly(['status'])`). Alle physiologischen Berechnungsfelder sind unveränderlich.
  3. **Wirkung & Vergangenheitsneuberechnung:**
     - Die Übernahme eines Vorschlags schreibt einen neuen Eintrag in `thresholdHistory` mit `effectiveFrom = heute`. Bisherige Historie und Kennzahlen bleiben standardmäßig unverändert.
     - Eine Neuberechnung vergangener Einheiten (`recomputeMetrics`) erfolgt ausschließlich nach ausdrücklicher Bestätigung im Bestätigungsdialog mit transparentem Hinweis auf Tragweite und Dauer.
- **Begründung:** Verhindert verfälschte Kennzahlen durch unzureichende Daten oder Pacing-Brüche, garantiert DSGVO-konforme Datenintegrität und schützt die Athleten-Autonomie.

### 2026-10-13: Chat-Architektur, Aktivitäts-Share und Push-Infrastruktur (Phase 13)
- **Kontext:** Echtzeit-Interaktion zwischen Athlet und Trainer, Versenden von Medien/Dateien, Teilen absolvierter Einheiten und FCM-Push-Benachrichtigungen.
- **Entscheidung:**
  1. **Chat-Datenmodell & Beendigungsverhalten:**
     - Struktur: `chats/{athleteId}_{coachId}` mit Subcollection `messages`.
     - Nach Beendigung/Widerruf der Verknüpfung (`status: "REVOKED"`): Der Chatverlauf bleibt für beide Parteien lesbar (Nachvollziehbarkeit des bisherigen Trainings), jedoch wird das Erstellen neuer Nachrichten per Firestore Security Rules (`isChatActive(chatId)`) strikt blockiert.
  2. **Aktivitäts-Sharing als Momentaufnahme:**
     - Beim Teilen einer Einheit im Chat (`type: "ACTIVITY_SHARE"`) wird ein statischer Snapshot (`ActivityShareSnapshot`) der Eckdaten (Titel, Sport, Datum, Dauer, Distanz, Ø Watt, Ø HF) in der Nachricht gespeichert.
     - Das Teilen gewährt **keinen** zusätzlichen Datenzugriff auf die Rohdaten/Streams der Aktivität. Der Klick auf die Karte öffnet die Detailanalyse nur dann, wenn der Trainer ohnehin die Berechtigung `permissions.activities == true` besitzt.
  3. **Nachrichtenlöschung (Soft-Delete):**
     - Ein Absender kann eigene Nachrichten löschen. Die Nachricht wird auf `status: "DELETED"` gesetzt, Text und Anhänge werden unwiderruflich gelöscht und durch den Platzhalter „Diese Nachricht wurde gelöscht." ersetzt. Zugehörige Dateien in Cloud Storage werden freigegeben/gelöscht.
  4. **Datensparsame Push-Benachrichtigungen & Ruhezeiten:**
     - FCM-Pushs enthalten standardmäßig **keinen** Nachrichtentext und keine Gesundheitsdaten („Neue Nachricht von <Name>"). Eine Vorschau ist nur bei bewusster Aktivierung in den Einstellungen möglich.
     - Während konfigurierter Ruhezeiten (`settings.quietHours`) werden Pushes serverseitig unterdrückt (Nachrichten verbleiben im Chat und im Unread-Badge). Ungültige oder abgemeldete Geräte-Tokens werden nach jedem Multicast-Versand automatisch bereinigt.
- **Begründung:** Wahrung strenger DSGVO-Standards, Schutz vor unbefugtem Datenabfluss und störungsfreie Erholungsphasen für Athleten.

### 2026-10-13: Home-Dashboard („Heute"), Daily Ring und Read-Budget (Phase 14)
- **Kontext:** Der Tab „Heute" ist der zentrale Einstiegspunkt der App für Athleten. Er muss auf einen Blick Orientierung bieten, darf Nutzer nicht überfordern und muss ressourceneffizient (Firestore Quotas) bleiben.
- **Entscheidung:**
  1. **Inhalts- und Prioritätskonzept (`HomeCardResolver`):**
     - Maximal 4 Karten oberhalb der Falz.
     - Reihenfolge:
       1. `HomeActionBanner`: Dringende Handlungsbedarfe (ungelesene Trainer-Nachrichten, neue Schwellenwert-Vorschläge, nicht zugeordnete Einheiten).
       2. `HomeHeroCard`: Visuelles Zentrum mit Volt Daily Ring (`#CDFB17`) auf Deep Navy (`#0F172A`) und heutigem Training / Ruhetag.
       3. `RaceCountdownCard`: Saisonziel-Countdown in Tagen/Wochen mit 1-Klick-Bearbeitung.
       4. `FormTrafficLightCard` / `ReadinessCard`: Physiologischer Kontext (Belastungszustand & Erholung).
       5. `HomeRecentActivityCard`: Zuletzt absolvierte Einheit mit Direktlink ins Cockpit.
     - Neuer Nutzer ohne Daten sieht einen fokussierten, gestalteten Onboarding-State mit Schnellstart-Aktionen (FIT-Upload, Garmin verbinden, Saisonziel).
  2. **Strikte Einhaltung der Volt-Regel (`docs/DESIGN.md` §2):**
     - Performance-Volt (`#CDFB17`) wird niemals als Schrift auf hellen Flächen verwendet, sondern ausschließlich auf Deep Navy (`#0F172A`) oder als Schaltflächen-/Badge-Hintergrund mit Navy-Schrift.
     - Barrierefreiheit: Ring besitzt Semantics und volles Textäquivalent („Ist: 45 / Plan: 68 TSS" bzw. „Ruhetag"), funktioniert auch ohne Farbwahrnehmung.
  3. **Read-Budget ($\le 4$ Firestore-Reads pro Öffnung):**
     - Ein gebündelter Provider (`homeDashboardProvider`) führt maximal 4 Reads durch (Tagesaggregat, 1 geplantes Workout, 1 letzte Aktivität, User-Profil & Pending Proposals).
     - Kein unkoordiniertes Einzel-Laden pro Karte. Caching via Riverpod FutureProvider mit Pull-to-Refresh (`RefreshIndicator`).
  4. **Kein Home-Tab für Trainer:**
     - Für Trainer ist der Starttab „Athleten" (`TrainerAthletesTabScreen`), da deren Arbeitsfokus auf der Betreuung des Kaders liegt.
- **Begründung:** Ruhige Mobile-First-Trainingsplattform, Vermeidung von Quota-Erschöpfung und strikte Design-Konsistenz.

### 2026-10-13: Coach-Desktop & Web-Architektur, O(1) Aggregation und Drag & Drop (Phase 15)
- **Kontext:** Trainer müssen am großen Bildschirm (Web und Desktop) effizient und ohne Ladehemmungen mit Dutzenden Athleten arbeiten (Statusübersicht, Wochenplanung, Massenzuweisung).
- **Entscheidung:**
  1. **O(1) Dashboard-Aggregation (`coachDashboard/{coachId}/athletes/{athleteId}`):**
     - Statt beim Öffnen des Trainer-Dashboards für $N$ Athleten jeweils separate Subcollections (Profile, Aggregates, Workouts, Activities, Unread-Counts) abzufragen ($> 100$ Reads), pflegen server-seitige Cloud Functions ein aggregiertes Dashboard-Dokument pro Athlet.
     - Der Trainer liest sein gesamtes Dashboard mit einer einzigen Abfrage (`coachDashboard/{coachId}/athletes`).
     - Trigger auf Aktivitäten, Links, Pläne und Chats halten die Kennzahlen (Form, CTL/ATL/TSB, 7d-Compliance, Alerts, ungelesene Nachrichten) konsistent.
  2. **Multi-Athlete Week Grid mit Drag & Drop und Undo (`MultiAthleteGridController`):**
     - Reine funktionale Domain-Logik ohne Seiteneffekte: Verschieben, Tauschen und Kopieren (mittels Alt/Option-Taste).
     - Jeder Drag-Vorgang speichert einen `GridActionHistoryEntry` im Undo-Stack, sodass versehentliche Planungsänderungen mit einem Klick rückgängig gemacht werden können.
     - Für Tastatur- und Screenreader-Nutzung steht ein zugängliches Kontextmenü („Verschieben nach ...") zur Verfügung.
  3. **Massenzuweisung (`BatchAssignService`):**
     - Zuweisung von Workouts oder Wochenstrukturen an mehrere ausgewählte Athleten erfolgt atomar über Firestore `WriteBatch`.
     - Validierung der Berechtigungen (`permissions.calendar == true`) im Frontend und Backend.
  4. **Persönliche Arbeitsplatzansichten (`users/{userId}/preferences/{prefId}`):**
     - Trainer können Tabellenspalten (Auswahl, Sortierung, Reihenfolge) und Filterpresets konfigurieren und in Firestore speichern.
  5. **Web-Grundlagen & Hosting:**
     - Flutter Web mit CanvasKit/HTML-Autoselektion.
     - Konfiguration von `cors.json` für Cloud Storage.
     - Detaillierte Dokumentation für Firebase Hosting, Custom Domains und App Check Web (reCAPTCHA Enterprise) in `docs/MANUAL_STEPS.md`.
- **Begründung:** Maximale Performance bei professionellen Trainerkadern ($\ge 25$ Athleten), ergonomische Tastatur- und Mausbedienung am Desktop und Schutz vor DoS/Quota-Limits.

### 2026-10-13: Qualität, Datenschutz-Abschluss & Release-Readiness v1.0 (Phase 16)
- **Kontext:** Vorbereitung der App auf den Store-Launch (Google Play Store), Bereinigung aller offenen Restschulden, Nachweis der Barrierefreiheit und Erfüllung aller DSGVO- und Store-Richtlinien.
- **Entscheidung:**
  1. **Restschulden-Bereinigung & Code-Integrität:**
     - FIT-Sportmapping in Cloud Functions auf standardisierte Profile erweitert (`RUN`, `BIKE`, `SWIM`, `STRENGTH`, `OTHER`).
     - Vollständige Datenschutz-Verdrahtung in `SettingsScreen` mit `PrivacySettingsSheet` (Art. 9, Art. 17 Kontolöschung, Art. 20 JSON-Export).
     - Interaktiver Dialog für Schwellenwert-Anpassungen in `ThresholdsScreen` und Verknüpfung zum Diagnose-Cockpit.
     - Vollständige Interaktion in `AthleteCoachTabScreen` (Invite-Code Dialog, Bestätigungsdialog für Widerruf, Berechtigungs-Toggles).
     - Automatisierter Vollständigkeitstest für Lokalisierung (`localization_completeness_test.dart`) stellt sicher, dass kein Schlüssel in DE oder EN fehlt.
  2. **Android Release-Konfiguration & Sicherheit:**
     - `applicationId`: `app.orbit.training`.
     - Entkopplung des Signaturschlüssels via `key.properties` (wird nicht in Git eingecheckt).
     - R8/Proguard Minification aktiviert mit `proguard-rules.pro`.
     - Berechtigungsaudit im Manifest: Strikte Beschränkung auf `INTERNET` und `POST_NOTIFICATIONS`.
  3. **Datenschutz- und Store-Compliance:**
     - Statische Löschseite `web/delete-account.html` zur Erfüllung der Google Play Anforderung für Kontolöschung.
     - Detaillierte Google Play Data Safety Deklaration (`docs/release/DATA_SAFETY.md`).
     - Datenschutz-Folgenabschätzung (DSFA) und TOMs (`docs/release/DSFA.md`).
     - Betriebs- und Notfall-Rollback-Handbuch (`docs/release/CHECKLIST.md`).
     - Garmin-Produktionsantragsvorbereitung (`docs/release/GARMIN_REVIEW.md`).
- **Begründung:** Gewährleistung der Store-Konformität, juristische Absicherung im Umgang mit Gesundheitsdaten und reibungsloser Produktionsbetrieb.



