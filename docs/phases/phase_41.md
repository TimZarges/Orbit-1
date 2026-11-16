# PHASE 41 — V1.0.0 Scope-Steuerung (`ReleaseConfig`), Clean Professional Design System (Hell & Dunkel), Vollständige Zweisprachigkeit (`DE` & `EN`) & Wohnland-Formatierer (`dd.mm.yy` / `24h`)

## Modus & Zielsetzung
- **Branch:** `feature/phase-41-v1-scope-design-l10n` (gemergt in `main`)
- **Ziel-Release:** `v0.41.0`
- **Ziel:** Saubere Kapselung des fokussierten V1.0.0-Funktionsumfangs über `ReleaseConfig` (ohne Bruch der 218 Bestands-Tests), Einführung des Clean Professional Design Systems für Dark Mode (`#0D0F12` Carbon / `#16181D` Anthrazit / `8 %` Weiß-Opazität Rahmen) und Light Mode (`#F4F6F9` Alabaster / `#FFFFFF` Karten / `#E2E8F0` Rahmen / `#0F172A` Typografie), vollständige Zweisprachigkeit (`de` & `en`), Erstellung des `CountryDateTimeFormatter` (`dd.mm.yy` & `24h` nach Wohnland) sowie Live-Hardware-Verifikation auf dem Google Pixel 10 Pro (`58251FDCR00EQ2`).
- **Status:** **[x] Abgeschlossen**

---

## Arbeitspakete

### 41.1 `.gitignore` & Dokumentations-Konsistenz
- [x] `.gitignore` verifiziert: Nur große Research-Screenshots (`docs/research/screenshots/`) werden ignoriert; offizielle Phasen-Beweis-Screenshots (`docs/beta/screenshots/`) werden sauber versioniert.
- [x] Redundanz zwischen `docs/ROADMAP.md` und `docs/ROADMAP_V1_TO_V4.md` bereinigt (`docs/ROADMAP.md` verweist eindeutig auf die verbindliche Single Source of Truth `docs/ROADMAP_V1_TO_V4.md`).
- [x] `PROGRESS.md` und `docs/PROGRESS.md` synchron gehalten.

### 41.2 Intelligente Feature-Steuerung (`lib/core/config/release_config.dart`)
- [x] `ReleaseConfig` und `ReleaseScopeState` (`releaseConfigProvider`) implementiert:
  - Produktiv-Standard (V1.0.0): `isV2Enabled = false` (blendet Trainings-Detail-Weiterleitung, Zonen-Rechner, Leistungsdiagnostik, Workout-Builder und Chat aus) und `isV3Enabled = false` (blendet 3 Daily Health Ringe, Readiness-Score, Morgen-Check-in und ML-Analysen aus).
  - Test-Override `ReleaseConfig.overrideForTesting({bool? v2, bool? v3})` + `resetTestingOverrides()` implementiert, sodass alle 218 Bestands-Tests + 9 neue Phase-41-Tests (**227/227 Tests**) zu 100 % grün durchlaufen.
- [x] `TodayTabScreen`, `DashboardScreen`, `HomeRecentActivityCard` und `SettingsScreen` mit granularen Selektoren (`ref.watch(releaseConfigProvider.select(...))`) an `ReleaseConfig` gekoppelt.

### 41.3 Clean Professional Design System – Hell & Dunkel (`lib/core/theme/orbit_professional_theme.dart`)
- [x] **Dark Mode:** Tiefer Carbon-Hintergrund (`#0D0F12`), abgesetzte Anthrazit-Karten (`#16181D`), dezente 1px-Rahmen mit 8 % Weiß-Opazität (`0x14FFFFFF`), gestochen scharfe Typografie (`#F8FAFC`).
- [x] **Light Mode:** Klarer Alabaster-Hintergrund (`#F4F6F9`), reinweiße Karten (`#FFFFFF`), feine Schiefergrau-Rahmen (`#E2E8F0`), kontrastreiche dunkle Typografie (`#0F172A`).
- [x] Sofortiger, ruckelfreier und persistenter Wechsel zwischen **Hell**, **Dunkel** und **System** über `SettingsController.setThemeMode(...)`.

### 41.4 Vollständige Zweisprachigkeit (`DE` & `EN`) & `CountryDateTimeFormatter` (`dd.mm.yy` & `24h`)
- [x] `AppStrings` (`lib/core/localization/app_strings.dart`) um sämtliche V1.0.0-Texte, Navigations-Labels, Einstellungs-Titel und Aktionen auf Deutsch (`de`) und Englisch (`en`) erweitert.
- [x] `CountryDateTimeFormatter` (`lib/core/utils/country_date_time_formatter.dart`) erstellt: Formatiert gekoppelt an das im Profil/Settings gespeicherte Wohnland (`DE`, `AT`, `CH` und weitere EU-Länder) jedes Datum strikt als `dd.mm.yy` (z. B. `21.10.26`) und jede Uhrzeit im `24h`-Format (`19:54`).

### 41.5 Qualitäts-Gate, Pixel 10 Pro Hardware-Abnahme & GitHub-Push
- [x] `bash scripts/check_phase_ready.sh` erfolgreich ausgeführt (`0 Errors, 0 Warnings, 0 Infos` in `flutter analyze` und ESLint, 100 % deutsche Doc-Kommentare, **227/227 Tests bestanden**).
- [x] Release-APK (`app-release.apk`) gebaut, via `adb -s 58251FDCR00EQ2 install -r` auf dem Google Pixel 10 Pro installiert und Light/Dark-Mode sowie DE/EN live auf dem Gerät verifiziert.
- [x] Fast-Forward-Merge in `main`, annotiertes Git-Tag `v0.41.0` gesetzt und auf `origin/main` gepusht.
