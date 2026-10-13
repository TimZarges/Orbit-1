# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 08 (Abgeschlossen) -> Phase 09 (Workout Builder & Bibliothek)
- Branch: feature/phase-08-calendar

## Fertig
- Phase 00 (Foundation): Abgeschlossen
- Phase 01 (Auth & Onboarding): Abgeschlossen
- Phase 02 (Trainer-Verknüpfung): Abgeschlossen
- Phase 03 (Profil, Einstellungen, Schwellenwerte): Abgeschlossen
- Phase 04 (Aktivitäts-Import): Abgeschlossen
- Phase 05 (Metrik-Kern): Abgeschlossen
- Phase 06 (Garmin-Connector):
  - OAuth 1.0a Flow mit CSRF-State & Webhook-Architektur implementiert und auf Firebase Cloud Functions (Gen 2, europe-west3) bereitgestellt.
  - Landing Page, Datenschutz, Impressum und Callback-Portal auf Firebase Hosting (`orbit-app-mvp.web.app`) live geschaltet.
  - UI in Flutter (Einstellungen -> Verbindungen -> Garmin) mit Token-Handling, Disconnect-Modal und WCAG AA Kontrasten integriert.
  - Backfill-Logik vorbereitet (Warten auf Freischaltung `HISTORICAL_DATA_EXPORT` durch Garmin-Support).
- Phase 07 (Gesundheitsdaten & Daily Metrics):
  - Garmin Health API Webhook-Verarbeitung für Dailies, Sleeps und HRV rMSSD per idempotentem Upsert (`merge: true`) in `functions/src/import/garmin/webhook.ts` integriert.
  - Datenmodell `DailyMetrics`, statistische 28-Tage-Basislinie `HealthBaseline` (Median, StdDev, Mindestdatenlage 14 Tage) und `ReadinessEvaluator` implementiert.
  - Sachliche, nicht-medizinische Einordnung und Freigabe von Texten (de + en) und Schwellenwerten (STOPP 1 freigegeben).
  - Progressive Disclosure `ReadinessCard` (Einfach, Fortgeschritten, Experte) mit Statusanzeige, Metrik-Deltas, Expertendetails und Info-Sheet gebaut und im Heute-Tab verankert.
  - Granularer Trainer-Schutz (`permissions.health == true`) in Rules und UI-Banner abgebildet.
  - DSGVO-Export und -Löschung (`recursiveDelete`) um `dailyMetrics` erweitert; `docs/PRIVACY.md` aktualisiert.
  - 30-Tage `HealthDemoSeeder` für sofortiges Testen und Demo-Modus bereitgestellt.
- Phase 08 (Kalender und Soll-Ist-Abgleich):
  - Datenmodell `PlannedWorkout` und Repository `PlannedWorkoutRepository` (CRUD, Verschieben, Bereichsabfragen, Status-Verwaltung) implementiert.
  - Firestore Security Rules für `plannedWorkouts` durch den Spezialisten `firestore-rules-author` aktualisiert (Athleten-Rechte, Trainer-Berechtigungen über `permissions.calendar`, Identitätsbindung, atomarer Schutz gegen Fälschung).
  - Cloud Function Trigger `onPlannedWorkoutWritten` zum automatischen Pflegen des denormalisierten `coachId`-Feldes bereitgestellt.
  - Soll-Ist-Zuordnungsalgorithmus `MatchingEngine` (`matchActivityToPlan`) mit Sport-Match, Dauerplausibilität und Konfidenz-Scoring umgesetzt.
  - Kalender-UI mit Wochen-, Monats- und Listenansicht (`CalendarScreen`), Tageskarten (`WorkoutCard`), Soll-Ist-Wochenzusammenfassung und „Training planen“-Dialog (`CreateWorkoutDialog`) gebaut.
  - Interaktives `WorkoutDetailSheet` mit Aktionen (Auf morgen verschieben, Datum wählen, Erledigt/Übersprungen markieren, Verknüpfung mit Aktivität herstellen/lösen) integriert.
  - Vollständiger Athleten-Kontext für Trainer (Öffnen des Kalenders eines Athleten im Coach-Modus).
  - `CalendarDemoSeeder` für realistische Test- und Demo-Wochenpläne bereitgestellt.

## Offen / in Arbeit
- Phase 09: Workout Builder und Bibliothek (Text-Kurzeingabe, grafischer Struktur-Editor, Vorlagen)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.



