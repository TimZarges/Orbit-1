# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 04
- Branch: feature/phase-04-activity-import

## Fertig
- Phase 00 (Foundation): Abgeschlossen
- Phase 01 (Auth & Onboarding): Abgeschlossen
- Phase 02 (Trainer-Verknüpfung): Abgeschlossen
- Phase 03 (Profil, Einstellungen, Schwellenwerte): Abgeschlossen
- Phase 04 (Aktivitäts-Import):
  - FIT-Dateiverarbeitung im Backend über Cloud Function (inkl. Dynamischem `@garmin/fitsdk` Import, 1Hz Downsampling, GZIP Streaming).
  - `Activity` und `ActivitySummary` Models.
  - Upload-Flow mit Storage-Regeln (25MB Limit) und Riverpod-State (`activity_upload_provider.dart`).
  - Listenansicht im `TodayTabScreen` mit Empty-State.
  - Detailansicht mit Summary-Werten (`ActivityDetailScreen`), Multisport-Segmenten und Lösch-Funktion (`deleteActivity` Callable).
  - Vollständiger Frontend-Backend-Workflow.

## Offen / in Arbeit
- Phase 05: Metriken & Belastung (TSS, Normalized Power, Zonenverteilung)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.
