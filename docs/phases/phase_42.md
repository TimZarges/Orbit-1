# PHASE 42 — Einheitliche COROS-Vorschaukarte (`TrainingPreviewCard`), Echter `.FIT`-Download-Service, Strikte V1.0.0 Heute-Ansicht & Kalender (Woche, Monat, Liste)

## Modus & Zielsetzung
- **Branch:** `feature/phase-42-training-preview-today-calendar` (gemergt in `main`)
- **Ziel-Release:** `v0.42.0`
- **Ziel:** Vereinheitlichung der COROS-Trainings-Vorschaukarte (`TrainingPreviewCard` / `HomeRecentActivityCard`) für Heute & Kalender, Implementierung eines speicherschonenden `.FIT`-Download-Services (`FitDownloadService`), strikte Fokussierung der Heute-Ansicht auf am aktuellen Tag absolvierte Trainings sowie Überarbeitung des Kalenders (Woche, Monat, Liste) ohne V2-Planungsfunktionen im V1.0.0-Modus.
- **Status:** **[x] Abgeschlossen**

---

## Arbeitspakete

### 42.1 Einheitliche COROS-Vorschaukarte (`TrainingPreviewCard` / `HomeRecentActivityCard`)
- [x] Vereinheitlichtes Layout in `lib/features/home/widgets/home_recent_activity_card.dart`:
  - Linke Spalte (~68 % Breite): Sportart-Icon in definierter Sport-Akzentfarbe (Triathlon, Radfahren, Laufen, Schwimmen, Kraft, Sonstige) + Hauptmetrik groß & fett (`km`/`m` bei Outdoor/Ausdauer, `hh:mm:ss` bei Indoor/Kraft), Sekundärmetriken kompakt (Dauer, Pace `/km` bzw. Ø-Leistung `W`, Ø-Puls `bpm`, `kcal`), Titel + lokalisiertes Datum & Uhrzeit via `CountryDateTimeFormatter` (`dd.mm.yy • 24h`).
  - Rechte Spalte (~32 % Breite): Interaktiver `.FIT`-Download-Button (Icon + `.FIT` Label) statt GPX-Grafik mit kompaktem Ladeindikator pro Karte.
  - Klick-Verhalten: Bei `ReleaseConfig.isV2Enabled == false` ist der Kartenkörper nicht klickbar (`onTap: null`, kein Ripple, keine Weiterleitung ins `ActivityCockpitScreen`).
- [x] `ActivitySummary` (`lib/features/activities/models/activity.dart`) um optionales Feld `calories` (`kcal`) erweitert.

### 42.2 Echter, speicherschonender `.FIT`-Download-Service (`FitDownloadService`)
- [x] `lib/features/activities/services/fit_download_service.dart` implementiert:
  - Lädt Originaldateien (`activity.rawFilePath` bzw. `users/{athleteId}/rawActivities/{activityId}.fit`) mit 25-MB-Limit aus Firebase Cloud Storage.
  - Exportiert die Binärdaten plattformübergreifend über `FilePicker.saveFile` (Android SAF, iOS, Desktop & Web-Download).
  - Liefert bei fehlender Rohdatei eine lokalisierte (DE/EN), nutzerfreundliche Meldung (`FitDownloadStatus.notFound`).

### 42.3 Strikte V1.0.0 Heute-Ansicht (`TodayTabScreen`)
- [x] `TodayTabScreen` (`lib/features/activities/screens/today_tab_screen.dart`) filtert im V1.0.0-Modus strikt auf am heutigen Kalendertag absolvierte Trainings (`localDate == todayIsoKey`).
- [x] Header und aufgeräumter Empty-State bieten direkten Zugriff auf **Garmin Sync** und **Datei-Upload (`.fit`)** auf Deutsch (`DE`) und Englisch (`EN`).

### 42.4 Kalender für V1.0.0 (`CalendarScreen` – Woche, Monat & Liste)
- [x] `CalendarScreen` (`lib/features/calendar/screens/calendar_screen.dart`) mit Clean Professional Design (Hell & Dunkel) und DE/EN-Lokalisierung.
- [x] Bei `ReleaseConfig.isV2Enabled == false` werden alle V2-Planungsfunktionen (Wochensoll-Karte, geplante Workouts, „Training planen“-FAB, „+ Einheit planen“-Karten) ausgeblendet.
- [x] **Woche**, **Monat** (mit Sportart-Farbpunkten) und **Liste** (`ListView.builder`) nutzen einheitlich die `TrainingPreviewCard` inkl. `.FIT`-Download-Button.

### 42.5 Tests, Qualitäts-Gate, Pixel 10 Pro Hardware-Abnahme & GitHub-Push
- [x] Neue Testsuite `test/phase42_training_preview_and_calendar_v1_test.dart` erstellt (7 neue Unit-/Widget-Tests).
- [x] `bash scripts/check_phase_ready.sh` erfolgreich bestanden (`0 Errors, 0 Warnings, 0 Infos`, 100 % deutsche Kommentare, **234/234 Tests grün**).
- [x] Release-APK (`66.2 MB`) auf Google Pixel 10 Pro (`58251FDCR00EQ2`) installiert und 4 Live-Screenshots (Heute, Kalender Woche, Monat, Liste) unter `docs/beta/screenshots/` gesichert.
- [x] Fast-Forward-Merge in `main`, Tag `v0.42.0` gesetzt und auf `origin/main` gepusht.
