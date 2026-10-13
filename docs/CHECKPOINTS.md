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
