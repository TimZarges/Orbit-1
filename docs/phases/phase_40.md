# PHASE 40 — Verankerung Projekt-Roadmap (V1.0.0–V4.0.0), Phasenplan (40–46) & Verschärfte Code-Qualitäts-Gesetze

## Modus & Zielsetzung
- **Branch:** `feature/phase-40-login-onboarding-email-fix` (gemergt in `main`)
- **Ziel-Release:** `v0.40.0`
- **Ziel:** Verbindliche Verankerung der gesamten Produkt-Roadmap (`V1.0.0` bis `V4.0.0`), des detaillierten Phasenplans (`Phase 40` bis `Phase 46` bis zum V1.0.0 Release), der Wettbewerbs-Benchmark-Analyse (`MATS.coach`, `TrainingPeaks`, `Garmin Connect`) sowie der verschärften Regeln für Effizienz, Clean Code und 100 % deutsche Code-Kommentierung in `AGENTS.md`, `scripts/check_phase_ready.sh` und auf GitHub (`origin/main`).
- **Status:** **[x] Abgeschlossen**

---

## Arbeitspakete

### 40.1 Verschärfung von `AGENTS.md` & `.cursorrules` (Effizienz, Clean Code & 100 % Kommentierung)
- [x] **EFFIZIENZ-GEBOT:** Konsequenter Einsatz von `const`-Konstruktoren, `RepaintBoundary` bei Grafiken, `ListView.builder` für Listen und granularen Riverpod-Selektoren (`ref.watch(provider.select(...))`). Keine Berechnungen oder Objekt-Instanziierungen in `build()`. Sparsame Firestore-Abfragen mit Limits, Streaming bei `.FIT`-Downloads und saubere Speicherfreigabe.
- [x] **CLEAN-CODE-GEBOT:** Strikte Schichten-Trennung (Präsentation, Geschäftslogik, Datenhaltung), selbsterklärende Bezeichner, Verbot von totem/auskommentiertem Code und Verbot hartcodierter UI-Strings (Lokalisierung DE/EN).
- [x] **100 % DEUTSCHE KOMMENTIERUNG AM GESAMTEN CODE:** Deutscher Datei-Header-Kommentar in jeder Datei, deutsche Dokumentations-Kommentare (`///` bzw. `/** ... */`) an jeder Klasse, jedem Interface, Enum, Provider, Widget und jeder Methode (öffentlich & privat, Was/Warum/Parameter/Rückgabewert) sowie deutsche Inline-Kommentare (`//`) für jeden logischen Abschnitt.

### 40.2 Erweiterung des Pre-Merge-Gates (`scripts/check_phase_ready.sh`)
- [x] Prüfung a): `flutter analyze` mit **0 Errors, 0 Warnings, 0 Infos** (vollständige Bereinigung aller 989 Info-Lints im gesamten Projekt).
- [x] Prüfung b): TypeScript-Build (`npm --prefix functions run build`) & ESLint (`npm --prefix functions run lint`) in `functions/` mit **0 Errors & 0 Warnings**.
- [x] Prüfung c): Automatisierte Prüfung, dass **alle bestehenden und geänderten** `.dart`- und `.ts`-Produktionsdateien über deutsche Dokumentations-Kommentare verfügen.
- [x] Prüfung d): Vollständiger, fehlerfreier Durchlauf aller Unit- und Widget-Tests (`flutter test`).

### 40.3 Verbindliche Ablage der Roadmap (`docs/ROADMAP_V1_TO_V4.md`) & Checkpoints (`docs/CHECKPOINTS.md`)
- [x] Erstellung von `docs/ROADMAP_V1_TO_V4.md` mit:
  - Versions-Matrix für `V1.0.0`, `V2.0.0`, `V3.0.0` und `V3.1.0 / V4.0.0` (Allgemein, Athleten, Coach, Design von Key-Features).
  - Allen 6 Detail-Entscheidungen für `V1.0.0` (COROS-Vorschaukarte nicht klickbar + `.FIT`-Download rechts statt GPX; Heute-Ansicht nur absolviertes Training + Garmin Sync & Datei-Upload; Kalender in Woche/Monat/Liste; Onboarding & Profil Einfach für Athlet & Coach inkl. Triathlon, Hell/Dunkel, DE/EN, `dd.mm.yy` & 24h nach Wohnland; Coach-Navigation & `.FIT`-Download; Gesetzliche Anforderungen DSGVO Art. 9, Art. 17, Art. 13/14 & DDG § 5 Impressum).
  - Detailliertem Phasenplan von **Phase 40 bis Phase 46 (`v1.0.0`)** sowie Übernahme der MATS.coach- und TrainingPeaks-Highlights für `V2.0.0` und `V3.0.0`.
- [x] Aktualisierung von `docs/CHECKPOINTS.md`, `PROGRESS.md` und `docs/PROGRESS.md` mit dem kompletten Fahrplan bis `v1.0.0`.

### 40.4 Git-Merge, Pre-Merge-Gate, Tagging (`v0.40.0`) & GitHub-Push
- [x] Saubere Integration von `feature/phase-40-login-onboarding-email-fix`, `docs/research/BENCHMARK_MATS_TRAININGPEAKS_GARMIN.md` und aller Roadmap-/Regel-Dokumente in `main`.
- [x] Erfolgreicher Lauf von `bash scripts/check_phase_ready.sh`.
- [x] Annotiertes Git-Tag `v0.40.0` erstellt und `main` inkl. aller Tags nach `origin/main` gepusht.
