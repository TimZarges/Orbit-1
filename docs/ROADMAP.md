# ORBIT Roadmap

> **Alle 17 Phasen (00–16) sind vorab als Phasendateien ausgearbeitet** (`docs/phases/`). Pläne können veralten, deshalb beginnt jede Phase mit einem **Plan-Check** gegen den tatsächlichen Code. Abweichungen werden in der Phasendatei nachgezogen und in `docs/CHECKPOINTS.md` vermerkt. Ist eine Phase zu groß, teile sie mit `/split-phase NN`.

| Nr | Phase | Datei | Baut auf | Risiko | Kernergebnis |
|---|---|---|---|---|---|
| 00 | Fundament | `phase-00-foundation.md` | – | mittel | Audit, Struktur, Design-System, Shell, Dev/Prod, CI, Spikes (Chart, Karte) |
| 01 | Auth, Onboarding, Rollen, Rules | `phase-01-auth-onboarding.md` | 00 | hoch | Login, Rollen sicher, Rules + Tests, Einwilligung, Löschen/Export |
| 02 | Trainer-Verknüpfung | `phase-02-coach-link.md` | 01 | hoch | Einladung, Freigaben, `coachId`-Modell, Athleten-Kontext |
| 03 | Profil, Einstellungen, Schwellenwerte | `phase-03-profile-settings.md` | 01, 02 | mittel | Profil, Zonen, Einheiten, Sprache, Erfahrungsstufen, Info-Icons |
| 04 | Aktivitäts-Import (FIT, Demo) | `phase-04-activity-import.md` | 01–03 | hoch | Upload → Parser → Aktivität + Streams, Demo-Modus, Liste/Detail |
| 05 | Metrik-Kern | `phase-05-metrics-core.md` | 03, 04 | hoch | NP/TSS/CTL/ATL, Aggregate, Testvektoren, ORBIT Score (vorläufig) |
| 06 | Garmin-Connector | `phase-06-garmin-connector.md` | 04, 05 | hoch | OAuth, Webhook, Backfill, Mock-Modus |
| 07 | Health-Daten | `phase-07-health-data.md` | 04–06 | hoch | Schlaf/Ruhepuls/HRV, Tagesform, Freigabe-Logik |
| 08 | Kalender und Soll-Ist | `phase-08-calendar.md` | 02, 04, 05 | hoch | Planung, Zuordnung, Wochen-/Monats-/Listenansicht |
| 09 | Workout Builder, Bibliothek | `phase-09-workout-builder.md` | 03, 05, 08 | mittel–hoch | Text-Kurzeingabe + Editor, Profilgrafik, Vorlagen |
| 10 | Analyse einfach | `phase-10-analysis-simple.md` | 05, 07, 08 | hoch | Ampel, Wochenbelastung, Stufen-Darstellung |
| 11 | Analyse Cockpit | `phase-11-analysis-cockpit.md` | 04, 05, 10 | hoch | Telemetrie, Scrubbing, Karte, Power-Kurve |
| 12 | Leistungsdiagnostik | `phase-12-diagnostics.md` | 03, 05, 11 | hoch | Schwellenwert-Vorschläge, geführte Tests, Neuberechnung |
| 13 | Chat und Push | `phase-13-chat-push.md` | 02, 04 | hoch | Echtzeit-Chat, Anhänge, FCM, geplante Pushes |
| 14 | Home („Heute") | `phase-14-home.md` | 07, 08, 10, 12, 13 | mittel | Daily Ring, Karten, Prioritätslogik |
| 15 | Coach-Desktop und Web | `phase-15-coach-desktop.md` | 02, 08–13 | hoch | Dashboard, Raster, Drag & Drop, Massenzuweisung, Web |
| 16 | Qualität, Datenschutz, Release | `phase-16-release.md` | 00–14 | hoch | Tests, Sicherheit, Datenschutz-Doku, Android-Release |

## Reihenfolge-Logik
Fundament (00) → Identität und Sicherheit (01) → **Trainer-Beziehung früh** (02), damit alles `athleteId`-fähig ist → Profil/Schwellenwerte (03) → **Daten rein** (04–07) → Planung (08–09) → Analyse (10–12) → Kommunikation (13) → Veredelung (14–16).

## Zulässige Umstellungen
- **Chat (13) früher:** braucht nur 02 und 04. Sinnvoll, wenn Athlet-Trainer-Kommunikation Priorität bekommt. Dann Push-Teile für „neues Workout" und „neue Aktivität" später nachziehen.
- **Garmin (06) später:** Ohne Freigabe laufen 04, 05, 08, 09, 10 und 11 vollständig mit FIT-Upload und Demo-Daten. 06 kann nach hinten wandern, ohne etwas zu blockieren.
- **Health (07) später:** nur 10 (Tagesform-Karte) und 14 (Home) hängen leicht daran.
- **Nicht umstellen:** 01 → 02 vor allem anderen, 04 → 05 vor 08/10/11, 05 vor 12.

## Parallelisierbar (nur mit getrennten Branches und bewusstem Merge)
Nicht empfohlen im Autopilot. Möglich für dich manuell: 06 (Garmin-Antrag und Wartezeit) parallel zu 08/09 vorbereiten.

## Was vor welcher Phase von dir kommen muss
| Vor Phase | Von dir |
|---|---|
| 00 | Package-ID, Firebase dev/prod (Region `europe-west3`) oder bewusst Emulator-only, Emulator/Gerät, Berechtigungen |
| 01 | Auth-Anbieter, SHA-Fingerprints, App Check, AV-Vertrag mit Google |
| 04 | 2–3 eigene, anonymisierte FIT-Dateien |
| 06 | Garmin-Entwicklerzugang, Secrets, Webhook-URLs, `assetlinks.json` |
| 11 | Mittelklasse-Android-Gerät für Performance-Messung, ggf. Kartenanbieter-Konto |
| 13 | FCM aktiv, zwei echte Geräte, ggf. Cloud Scheduler |
| 15 | Hosting/Domain (optional), Desktop-Browser |
| 16 | Play-Console, Upload-Key, Datenschutz-Fachperson, Impressum, Domain für Löschseite |

## Plan ändern
1. Änderung in `docs/DECISIONS.md` begründen.
2. Betroffene Phasendatei anpassen (oder `/split-phase NN`).
3. Diese Tabelle aktualisieren.
4. Nie stillschweigend: Abweichungen immer in `docs/CHECKPOINTS.md` vermerken.
