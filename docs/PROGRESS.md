# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 16 (Abgeschlossen) – Alle Phasen 00–16 der Roadmap erfolgreich abgeschlossen! 🎉
- Branch: feature/phase-16-release

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
- Phase 15 (Coach-Desktop und Web): Abgeschlossen
- Phase 16 (Qualität, Datenschutz-Abschluss, Release-Readiness v1.0):
  - Restschulden-Bereinigung (`docs/release/OPEN_ITEMS.md`):
    - FIT-Sportmapping in `functions/src/import/fitParser.ts` auf alle Standard-Sportarten erweitert.
    - `PrivacySettingsSheet` (`lib/features/settings/widgets/privacy_settings_sheet.dart`) implementiert und in `SettingsScreen` verdrahtet (DSGVO-Rechte, Datenexport, Kontolöschungs-Option).
    - Schwellenwert-Anpassungsdialog in `ThresholdsScreen` integriert mit Verknüpfung zur Diagnostik.
    - `AthleteCoachTabScreen` um Einladungscode-Eingabe, Bestätigungsdialog zur Trennung und Berechtigungsschalter erweitert.
    - Automatisierter Lokalisierungstest (`test/core/localization/localization_completeness_test.dart`) sichert 100% ARB-Deckung zwischen de und en.
  - Sicherheits-Audit & Schutzkonzept (`docs/release/SECURITY_AUDIT.md`):
    - Secret Scan erfolgreich: Keine Tokens, privaten Schlüssel oder Secrets im Repository.
    - App Check Staged-Rollout-Plan (Monitoring $\rightarrow$ Enforcement) ausgearbeitet.
    - Quoten- und Budget-Alarme dokumentiert.
  - Datenschutz- & Store-Compliance:
    - Statische Kontolöschungsseite `web/delete-account.html` für Google Play Anforderung erstellt.
    - Google Play Data Safety Deklaration (`docs/release/DATA_SAFETY.md`).
    - Datenschutz-Folgenabschätzung (DSFA) und TOMs (`docs/release/DSFA.md`).
    - Barrierefreiheitsprüfung (`docs/release/ACCESSIBILITY.md`) nach WCAG 2.1 AA (Kontrast, Tippflächen, Textskalierung).
    - Performance-Review (`docs/release/PERFORMANCE.md`) für 1-Hz-Streams und O(1) Reads.
  - Android & iOS Build-Readiness:
    - Android Release Build (`android/app/build.gradle.kts`) mit `app.orbit.training`, Proguard/R8 (`proguard-rules.pro`), `key.properties` Entkopplung und minimierten Manifest-Berechtigungen (`INTERNET`, `POST_NOTIFICATIONS`).
    - Store-Listings (de/en) und Screenshot-Plan (`docs/release/STORE_LISTING.md`).
    - iOS-Vorbereitungsleitfaden (`docs/release/IOS_PREP.md`) für Sign in with Apple und APNs.
    - Betriebs- und Notfall-Rollback-Handbuch (`docs/release/CHECKLIST.md`).
    - Garmin Health API Production Review Vorbereitung (`docs/release/GARMIN_REVIEW.md`).
  - Dokumentation:
    - Umfassendes `README.md` und aktualisierte `docs/ARCHITECTURE.md`.

## Offen / in Arbeit
- Keine offenen Phasen – Projekt ist bereit für Release-Build und Beta/Play Console Einreichung!

## Stand der Qualitäts- und Beta-Bereinigung
- Flutter Analyze: 0 Fehler, 0 Warnungen (`flutter analyze`).
- Flutter Tests: 103 von 103 Tests bestanden (100% grün).
- Cloud Functions: 17 von 17 Tests bestanden, TypeScript kompilierbar, Storage-Trigger und Metrics-Export vollständig verdrahtet.
- Baseline-Report und TODO-Inventar: `docs/beta/BASELINE.md` und `docs/beta/TODO_INVENTORY.md`.
- ADR-Log: Alle Entscheidungen inkl. rekonstruierter ADRs 01–04 und 06 in `docs/DECISIONS.md`.
