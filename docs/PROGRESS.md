# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 11 (Abgeschlossen) -> Phase 12 (Leistungsdiagnostik & Schwellenwert-Erkennung)
- Branch: feature/phase-11-analysis-cockpit

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
- Phase 11 (Analyse Cockpit – Telemetrie, Karte, Power-Kurve):
  - Dark Cockpit Theme (`#0F172A`) mit hoher Datendichte und Signal-Tokens gemäß `DESIGN.md` §3.2.
  - LTTB-Downsampling Engine (`LttbDownsampler`): Reduziert 1-Hz-Streams von bis zu 36.000 Datenpunkten (10h-Aktivität) auf 400 Punkte für 60 FPS bei voller Erhaltung markanter Spitzen und Intervalle.
  - Interaktives Scrubbing: Long-Press-to-Scrub (`TelemetryChartWidget`) mit haptischem Klick, vertikaler Leitlinie und über dem Finger schwebendem HUD. Umschalter Zeit- vs. Distanzachse sowie Querformat-Vollbildmodus.
  - Synchrone GPS-Streckenkarte (`TelemetryMapWidget`): Reine Offline-Vektorgrafik der Route mit Start-/Ziel-Pins und synchron wanderndem voltfarbenen Scrubbing-Marker.
  - DSGVO-Kartenkonzept: Reines Offline-Vektorrendering standardmäßig, Opt-In-Einwilligung mit Hinweistext vor dem Laden externer Kacheln (`docs/PRIVACY.md`).
  - Power-Duration-Kurve (`PowerDurationCurveWidget`): Logarithmisch skalierte Mean-Maximal-Power (1s bis 60m), Vergleich mit Saison- und Allzeit-Bestwerten, automatische Auszeichnung neuer Rekorde mit „PR"-Badges in Volt-Fläche mit Navy-Text.
  - Backend Bestwerte (`users/{uid}/bests/{sport}`): Serverseitige Berechnung in Cloud Functions Trigger (`functions/src/metrics/bests.ts`).
  - Firestore Security Rules: Autorisierter Lesezugriff auf `bests` für Athleten und berechtigte Trainer (`permissions.activities == true`) durch den Spezialisten `firestore-rules-author` erstellt und im Testplan dokumentiert.
  - Asynchroner Isolate-Decoder (`StreamDecoder`) zur Entlastung des UI-Threads bei großen JSON-/GZIP-Payloads.
  - Integration in `ActivityDetailScreen` („Analyse-Cockpit öffnen") und Erweiterung der Widget-Galerie (`/gallery`).

## Offen / in Arbeit
- Phase 12: Leistungsdiagnostik & Schwellenwert-Erkennung (FTP-, LTHR- & CSS-Schätzung aus Aktivitäten, Konfidenz-Modell, Übernahme-Workflow)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.



