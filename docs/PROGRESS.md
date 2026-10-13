# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 07 (Abgeschlossen) -> Phase 08 (Kalender und Soll-Ist)
- Branch: feature/phase-07-health-data

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

## Offen / in Arbeit
- Phase 08: Kalender und Soll-Ist (Planung, Zuordnung, Wochen-/Monats-/Listenansicht)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.


