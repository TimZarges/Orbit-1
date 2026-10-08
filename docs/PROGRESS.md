# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 04
- Branch: feature/phase-03-profile-settings

## Fertig
- Phase 00 (Foundation): Abgeschlossen
- Phase 01 (Auth & Onboarding): Abgeschlossen
- Phase 02 (Trainer-Verknüpfung): Abgeschlossen
- Phase 03 (Profil, Einstellungen, Schwellenwerte):
  - Berechnungsmodelle (`training_zones_model.dart`, `estimations.dart`) inkl. Tests
  - Terminology-Layer (`TermResolver`) für Erfahrungsstufen inkl. Tests
  - Lokalisierung (`app_localizations.dart` / `.arb` Dateien)
  - `MeasurementFormatter` für Einheiten inkl. Tests
  - UI-Screens: `ProfileScreen`, `SettingsScreen`, `ThresholdsScreen` und `InfoTerm`-Widget
  - Einbindung ins Dashboard / Router

## Offen / in Arbeit
- Phase 04: Aktivitäts-Import (FIT-Dateien, Garmin-Webhook)

## Bekannte Probleme
- `build_runner` (freezed/json_serializable) wirft aktuell wegen `analyzer`-Konflikten (SDK 3.13 / analyzer 3.9) Exceptions. Modelle für `AppSettings` wurden temporär manuell implementiert, bis die Packages kompatibel aufgerüstet sind.
