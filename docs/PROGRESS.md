# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 15 (Abgeschlossen) -> Phase 16 (Release-Vorbereitung, Polish & Store-Readiness)
- Branch: feature/phase-15-coach-desktop

## Fertig
- Phase 00 (Foundation): Abgeschlossen
- Phase 01 (Auth & Onboarding): Abgeschlossen
- Phase 02 (Trainer-Verknüpfung): Abgeschlossen
- Phase 03 (Profil, Einstellungen, Schwellenwerte): Abgeschlossen
- Phase 04 (Aktivitäts-Import): Abgeschlossen
- Phase 05 (Metrik-Kern): Abgeschlossen
- Phase 06 (Garmin-Connector): Abgeschlossen
- Phase 07 (Gesundheitsdaten & Daily Metrics): Abgeschlossen
- Phase 08 (Kalender und Soll-Ist-Abgleich): Abgeschlossen
- Phase 09 (Workout Builder und Vorlagenbibliothek): Abgeschlossen
- Phase 10 (Analyse einfach – Ampel, Wochenbelastung, Erfahrungsstufen): Abgeschlossen
- Phase 11 (Analyse Cockpit – Telemetrie, Karte, Power-Kurve): Abgeschlossen
- Phase 12 (Leistungsdiagnostik & Schwellenwert-Erkennung): Abgeschlossen
- Phase 13 (Chat und Push-Benachrichtigungen): Abgeschlossen
- Phase 14 (Home-Dashboard „Heute"): Abgeschlossen
- Phase 15 (Coach-Desktop und Web):
  - O(1) Dashboard-Aggregation (`coachDashboard/{coachId}/athletes/{athleteId}`):
    - Cloud Functions berechnen aggregierte Statusdokumente (Form-Ampel, CTL/ATL/TSB, 7d-Soll-Ist-Erfüllung, unread chat messages, letzte Aktivität, Alerts, Wettkampfziel).
    - Coach lädt das gesamte Dashboard mit einer einzigen Abfrage statt $N$ Abfragen.
    - Automatischer Trigger bei Beendigung/Widerruf von Trainer-Verknüpfungen.
  - Firestore Security Rules (via `firestore-rules-author`):
    - `coachDashboard`: Nur Trainer liest (`coachId == auth.uid`), Client-Schreibverbot.
    - `preferences`: Vollständige Trennung & Lese-/Schreibzugriff nur durch Besitzer (`isOwner(userId)`).
    - `thresholdProposals`: Trainer mit Aktivitäts-Freigabe darf Vorschläge mit Status `PENDING` anlegen; Statusänderung (`ACCEPTED`/`REJECTED`) obliegt ausschließlich dem Athleten.
  - UI & Adaptiver Coach-Arbeitsbereich (`TrainerAthletesTabScreen`):
    - Responsives Layout mit Schnellumschaltung zwischen Kader-Tabelle (`CoachAthletesTable`) und Wochenraster (`MultiAthleteWeekGrid`).
    - Filterchips nach Sportart, Statusampeln, Warnungen und Volltextsuche.
    - Tastaturkürzel (`/` oder `Cmd+K` für Fokus auf Suche, `?` für Tastenkürzel-Übersicht).
  - Mehrathleten-Wochenraster mit Drag & Drop und Undo (`MultiAthleteGridController`):
    - Funktionale Domain-Logik für Verschieben und Kopieren (Alt/Option-Taste).
    - Vollständiger Undo-Stack zur sicheren Rücknahme von Planungsaktionen.
    - Zugängliche Alternative über Kontextmenü.
  - Massenzuweisung (`BatchAssignService`, `BatchAssignDialog`):
    - Sichere Zuweisung an mehrere Athleten via Firestore `WriteBatch` ($\le 500$ Ops) unter Beachtung der Kalender-Berechtigung.
  - Web & Storage Konfiguration:
    - `cors.json` für Cloud Storage, Titel/PWA-Konfiguration in `web/index.html`.
    - Detaillierte Hosting-, Domain- und App-Check-Web-Anleitung in `docs/MANUAL_STEPS.md`.
  - Last-Test Seed-Skript (`functions/src/seeds/seed_coach_athletes.ts`):
    - Erzeugt 28 Test-Athleten für Lade- und Scrolltests, abgesichert gegen Ausführung in Produktivumgebungen.
  - Unit-Tests: `test/features/coach_link/domain/multi_athlete_grid_controller_test.dart`, `test/features/coach_link/models/coach_dashboard_models_test.dart`.
  - Showcase in `widget_gallery.dart`.

## Offen / in Arbeit
- Phase 16: Release-Vorbereitung, Polish & Store-Readiness

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.



