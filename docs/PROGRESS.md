# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 06 (Commit & Übergabe) -> Phase 07 (Health-Daten)
- Branch: feature/phase-06-garmin-connector

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

## Offen / in Arbeit
- Phase 07: Gesundheitsdaten & Daily Metrics (Schlaf, Ruhepuls, HRV, Tagesform)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.

