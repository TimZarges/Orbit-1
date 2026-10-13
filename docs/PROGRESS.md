# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 14 (Abgeschlossen) -> Phase 15 (Coach Desktop & Dashboard)
- Branch: feature/phase-14-home

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
- Phase 14 (Home-Dashboard „Heute"):
  - Inhalts- und Prioritätskonzept (`HomeCardResolver`):
    - Dynamische Priorisierung (Action-Banner, Hero Daily Ring, Saisonziel-Countdown, Form-Ampel / Readiness, Letzte Aktivität).
    - Maximal 4 Karten oberhalb der Falz für einen ruhigen Startscreen ohne Überforderung.
  - Volt Hero-Karte (`HomeHeroCard` & `DailyRingWidget`):
    - Strikte Einhaltung der Volt-Regel (`docs/DESIGN.md` §2): Volt (`#CDFB17`) auf Deep Navy (`#0F172A`).
    - Visualisierung des Verhältnisses von Ist-Belastung zu Planbelastung (oder Ruhetag) mit vollem Semantics-/Screenreader-Textäquivalent.
    - Heutiges Training mit Sportfarbe, Dauer, TSS und Schnellzugriff auf Detailsheet (`WorkoutDetailSheet`).
  - Saisonziel-Countdown (`RaceGoal`, `RaceCountdownCard`, `EditRaceGoalSheet`):
    - Countdown in Tagen/Wochen mit 1-Klick-Bearbeitung direkt aus der Karte ins Profil.
  - Action-Banner (`HomeActionBanner`):
    - Kontextsensitive Anzeige für neue Schwellenwerte (Phase 12), ungelesene Trainer-Nachrichten (Phase 13) und nicht zugeordnete Einheiten (Phase 08).
  - Gebündelter Datenzugriff & Quota-Schutz (`homeDashboardProvider`):
    - Maximal 4 Firestore-Reads pro Öffnung, Riverpod-Caching und Pull-to-Refresh (`RefreshIndicator`).
  - Responsives Layout:
    - Einspaltig auf Mobile, Zweispalten-Raster ab Tablet-Breite ($\ge 600\text{ px}$).
    - Gestalteter Onboarding Empty-State für Neunutzer mit FIT-Upload und Garmin-Connect.
  - Unit-Tests: `test/features/home/domain/home_card_resolver_test.dart`.
  - Integration in Widget-Galerie (`/gallery`).

## Offen / in Arbeit
- Phase 15: Coach Desktop & Dashboard (Kaderübersicht, Schnellfilter, Compliance, Feedback)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.



