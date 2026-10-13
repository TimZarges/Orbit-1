# Checkpoints (Autopilot-Protokoll)

> Hier hält der Agent im Autopilot (`/phase-run`) alle Entscheidungen fest, die sonst ein STOPP gewesen wären.
> **Neueste Einträge oben.** Lies nach jeder Phase zuerst alle Einträge mit `RISIKO-HOCH`.

## Legende
- **RISIKO-HOCH:** Security-Rules, Auth/Functions, Datenmodell, Formeln/ORBIT Score, Datenschutz. Bitte vor dem Merge prüfen.
- **RISIKO-MITTEL:** UX-Grundentscheidungen, Architektur, Abhängigkeiten.
- **RISIKO-NIEDRIG:** Details, die sich leicht ändern lassen.

## Eintragsformat
```
### [Phase NN] Kurztitel · RISIKO-…
- **STOPP-Punkt/Anlass:** (z. B. „STOPP 1 aus Phasendatei" oder „Plan selbst freigegeben")
- **Entscheidung:** was getan wurde
- **Alternative:** was die Option gewesen wäre
- **Begründung:**
- **Bitte prüfen:** konkret, womit (Datei/Test/Gerät)
- **Rückholen:** wie man es rückgängig macht (Commit/Branch)
```

## Branch-Reihenfolge (zum Mergen von unten nach oben)
| Reihenfolge | Branch | Basis | Status |
|---|---|---|---|
| – | – | – | – |

## Einträge

### [Phase 11] Analyse Cockpit (Telemetrie, Karte, Power-Kurve) · RISIKO-MITTEL
- **STOPP-Punkt/Anlass:** STOPP 1 (Technik, Karte, Einwilligung, Performance-Ziele) & STOPP 2 (Performance-Nachweis vor Feinschliff).
- **Entscheidung:**
  1. **Chart-Technik & LTTB-Downsampling (`LttbDownsampler`):**
     - Reduktion hochauflösender Zeitreihen (bis zu 36.000 Punkte bei 10h-Aktivitäten) auf 400 Anzeigepunkte für flüssige 60 FPS ($\le 16\text{ ms}$ Frame-Zeit) bei voller Erhaltung markanter Spitzen und Intervalle.
  2. **Interaktives Scrubbing & Kartensynchronisation:**
     - Long-Press-to-Scrub mit vertikaler Leitlinie und HUD über dem Finger (`TelemetryChartWidget`). Verhindert Konflikte mit vertikalem Page-Scroll.
     - Synchrone Positionierung des voltfarbenen Markers auf der GPS-Streckenkarte (`TelemetryMapWidget`).
     - Umschaltung zwischen Zeit- und Distanzachse sowie Vollbildmodus im Querformat.
  3. **DSGVO & Karten-Kacheln (`docs/PRIVACY.md`):**
     - Die GPS-Routenführung wird primär als reine Vektorgrafik offline gerendert (keine Weitergabe von IP-Adressen an externe Server).
     - Das Laden externer Kacheln erfordert ein ausdrückliches Opt-In über einen Einwilligungsdialog.
  4. **Power-Duration-Kurve & Bestwerte (`users/{uid}/bests/{sport}`):**
     - Logarithmisch skalierte Kurve der aktuellen Einheit im Vergleich zu Saison- und Allzeit-Bestwerten (`PowerDurationCurveWidget`).
     - Neue Bestleistungen werden mit „PR"-Badges in Volt-Fläche mit Navy-Text hervorgehoben (Volt-Regel).
     - Cloud Functions pflegen `allTimeMmp` und `seasonMmp` (1s bis 60m) serverseitig; Firestore Rules gewähren Lesezugriff für Athlet und berechtigte Trainer (`permissions.activities == true`).
  5. **Isolate-Dekodierung & Lazy Loading:**
     - `StreamDecoder` dekodiert und entpackt GZIP-Streams in einem Hintergrund-Isolate, um den UI-Thread frei von JSON-Parsing-Last zu halten.
- **Alternative:** Rendering aller Rohdatenpunkte mit `fl_chart` oder Google Maps SDK (hohe Latenzen, Memory-Spikes und IP-Tracking).
- **Begründung:** Höchste Performance auf Mittelklasse-Android-Geräten, intuitive Bedienbarkeit und vollständige DSGVO-Konformität.
- **Bitte prüfen:** Aktivitätsdetailansicht -> „Analyse-Cockpit öffnen" sowie Widget-Galerie (`/gallery`).
- **Rückholen:** Branch `feature/phase-11-analysis-cockpit` verwerfen.

### [Phase 10] Analyse einfach (Ampel, Wochenbelastung, Erfahrungsstufen) · RISIKO-HOCH
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Wortlaut aller Texte, Schwellenwerte, Mindestdatenlage und Kartenprototyp).
- **Entscheidung:**
  1. **Form-Ampel-Logik (`FormCalculator`):**
     - Relatives Verhältnis $R = \frac{\text{TSB}}{\text{CTL}}$ (unter Beachtung von $\text{CTL} \ge 10.0$).
     - Mindestdatenlage: $\ge 21$ kontinuierliche Tage erforderlich, sonst Status `insufficientData` („Noch zu wenig Daten").
     - Wenn $\text{CTL} < 10.0$: Status `lowBaseline` („Geringe Grundbelastung").
     - Vier physiologische Zustände:
       - `veryTired` ($R < -0{,}30$): „Sehr müde" / „High fatigue" (Warmes Bernstein/Orange, neutral ohne Alarmismus).
       - `wellLoaded` ($-0{,}30 \le R < -0{,}10$): „Gut belastet" / „Productive" (Performance-Volt / Grün).
       - `balanced` ($-0{,}10 \le R \le +0{,}15$): „Ausgeglichen" / „Balanced" (Deep Navy / Neutral Slate).
       - `fresh` ($R > +0{,}15$): „Frisch" / „Fresh" (Cyan).
     - Fußnote zur Datenbasis: Immer transparent ausgewiesen („Basiert auf X Wochen Training (Y Tagen)").
     - Strikt sachlich: Keine zwingenden Handlungsanweisungen („du musst"), kein medizinischer Rat.
     - Der ORBIT Score (0–100) wird in dieser Stufe noch nicht aktiv in der Ampel geschaltet, sondern nur TSB/CTL-Zustand und Datenbasis.
  2. **Erfahrungsstufen-Architektur (§7a DESIGN.md):**
     - *Einfach:* Form-Ampel, Wochenbelastung vs. Plan, Konsistenz (Alltagsbegriffe).
     - *Fortgeschritten:* Zusätzlich Sportverteilung (horizontaler Stapelbalken statt Torte), Zonenverteilung (Z1–Z7), 8-Wochen-Trend.
     - *Experte:* Zusätzlich CTL/ATL/TSB-Linienchart und Schwellenwert-Übersicht (Fachbegriffe: CTL, ATL, TSB, TSS).
  3. **Wiederverwendbare Karten & Info-Icons:**
     - Jede Kennzahl mit barrierefreiem Info-Icon und Bottom Sheet (`AnalysisInfoSheet`) für Begriffserklärungen und Formeln.
     - Barrierefreiheit: Rot-Grün-Schwäche beachtet (Zonen Z1–Z7 immer mit Textlabels und Prozenten), Semantics-Labels für alle Charts.
  4. **Firestore Security Rules:**
     - Durch den Spezialisten `firestore-rules-author` erweitert: Verknüpfte Trainer mit `coachLinks.permissions.activities == true` dürfen vorberechnete Aggregate (`users/{userId}/aggregates/{date}`) lesen. Client-Schreibzugriff bleibt strikt verboten.
  5. **Aktivitätsdetail (`ActivityDetailScreen`):**
     - Sportartspezifische Kennzahlen über `TermResolver`, Zonenstreifen, Plan-Match-Badge und Hinweis auf das Cockpit in Phase 11.
- **Alternative:** Absolute TSB-Schwellenwerte wie bei Fremdplattformen (hätte bei Athleten mit unterschiedlicher Fitness zu falschen Einschätzungen geführt).
- **Begründung:** Maximale physiologische Validität bei individueller Anpassung und Schutz der Privatsphäre.
- **Bitte prüfen:** Tab „Analyse" in der App-Navigation sowie Galerie (`/gallery`).
- **Rückholen:** Branch `feature/phase-10-analysis-simple` verwerfen.

### [Phase 09] Workout Builder & Vorlagenbibliothek · RISIKO-MITTEL
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Schema v1 und Textgrammatik freigegeben)
- **Entscheidung:**
  - Domänenmodell (`WorkoutStructure`, `StepBlock`, `RepeatBlock`, `WorkoutTarget`, `WorkoutIntensity`, `WorkoutCadence`) mit SI-Einheiten und `schemaVersion: 1`.
  - Reiner Dart-Parser (`WorkoutParser`) und Formatter (`WorkoutFormatter`) mit exakter Fehlerlokalisierung, Round-Trip-Konsistenz und Kurzformen.
  - Berechnungen (`WorkoutCalculator`) für Zeit, Distanz, Zonen und Belastungsschätzung (TSS / ORBIT Score) mit Annahmen-Dokumentation.
  - Live-Profilchart (`WorkoutProfileChart`) mit `CustomPainter`, Mindestbalkenbreite für ultrakurze Schritte und `Semantics`.
  - Mobile UI (`WorkoutBuilderScreen`, `WorkoutBlockEditorSheet`, `WorkoutTemplateLibraryScreen`) mit bidirektionaler Synchronisation, Undo/Redo und Kalender-Einplanung (Struktur kopieren).
  - Firestore Security Rules für `workoutTemplates` durch `firestore-rules-author` mit `SHARED_WITH_MY_ATHLETES`-Prüfung über `coachLinks`.
  - 20 triathlon-spezifische Original-Vorlagen in `TemplateSeedData`.
- **Alternative:** Reine Formularfelder ohne Freitext-Kurzeingabe oder referenziertes Einplanen (hätte historische Pläne bei Vorlagen-Updates verfälscht).
- **Begründung:** Maximale mobile Geschwindigkeit bei gleichzeitig voller mathematischer Typsicherheit und Barrierefreiheit.
- **Bitte prüfen:** Text-Kurzeingabe im Workout Builder (`/workout-builder`) und Vorlagenbibliothek (`/templates`).
- **Rückholen:** Branch `feature/phase-09-workout-builder` verwerfen.

### [Phase 00] Initiales Audit & Architektur · RISIKO-MITTEL
- **STOPP-Punkt/Anlass:** STOPP 1 aus Phasendatei (Audit-Bericht + Vorschlag Zielstruktur)
- **Entscheidung:** Audit-Bericht in `docs/AUDIT.md` erstellt. Da das Repo komplett neu ist, gibt es keinen Legacy-Code. Entscheidungen: `flutter_riverpod` (State), `go_router` (Routing), Dart 3 Records/Sealed Classes + `freezed` (Modelle), Backend-only FIT-Parsing.
- **Alternative:** Andere State/Routing-Lösungen (z.B. BLoC).
- **Begründung:** Sauberster Ansatz für Skalierung, Typsicherheit und Wartbarkeit gemäß `DESIGN.md` und `REQUIREMENTS.md`.
- **Bitte prüfen:** Vorschläge im `docs/AUDIT.md`.
- **Rückholen:** Branch `feature/phase-00-foundation` verwerfen.

### Phase 00 - STOPP 2 (Design-System & App-Shell)
- **Status:** Erledigt
- **Datum:** 2026-10-08
- **Details:** 
  - Basisstruktur, `pubspec.yaml`, `analysis_options.yaml` erstellt.
  - `firebase.json` und `functions/`-Gerüst aufgesetzt (TypeScript, europe-west3).
  - CI-Pipeline (`.github/workflows/ci.yml`) hinzugefügt.
  - Design-System (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart`) gemäß `docs/DESIGN.md` implementiert.
  - App-Router (`go_router`) und `WidgetGalleryScreen` als Platzhalter erstellt.
  - `spikes/`-Verzeichnis für künftige Experimente vorbereitet.
  - `docs/ARCHITECTURE.md` angelegt.
