# PHASE 24 — Stresstest mit echten Vereinsdaten, Security-Gate & Beta-Release (31.10.)

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH – Produktiv-Deployment & Store-Release).
- **Pflicht:** Keine Phase wird abgehakt, ohne dass die reale Ausführung auf dem echten Gerät (Pixel 10 Pro) und gegen das echte Backend protokolliert ist.

## Arbeitspakete

### 24.1 Stresstest & Performance-Verifikation mit 100–200 echten FIT-Dateien
1. Erstelle ein Import-Validierungsskript (`scripts/verify_fit_corpus.ts`), das einen lokalen Ordner mit meinen 100–200 echten `.fit`/`.tcx`-Dateien (Rad mit Watt, Lauf mit GPS, Pool, Freiwasser, Triathlon, Indoor) durch den exakt gleichen Parser und Metrik-Rechner schickt wie die Cloud Function.
2. **Abnahmekriterium für den Parser:** 100 % der validen Dateien müssen ohne Crash durchlaufen; fehlerhafte/korrupte Dateien müssen sauber abgefangen und mit klarem Grund geloggt werden.
3. **UI-Performance-Messung auf dem Pixel 10 Pro (`flutter run --profile`):**
   - Lade ein Testkonto mit 150 importierten Aktivitäten und 90 Tagen Health-Historie.
   - Prüfe Scroll-Performance in der Aktivitätsliste, das Öffnen einer 4-Stunden-Radausfahrt (14.400 Datenpunkte im Graphen → Downsampling/LTTB-Algorithmus aktivieren, falls Frame-Time > 16 ms!) und das Laden des PMC-Charts.
   - Dokumentiere die echten Messwerte im DevTools Performance-Overlay in `docs/beta/PERFORMANCE_REPORT.md`.

### 24.2 Manuelle Test-Checklisten je Rolle & Bug-Tracker (`docs/beta/`)
Lege zwei strukturierte Dokumente an:
1. `docs/beta/TESTPLAN_ROLES.md`: Schritt-für-Schritt-Abnahmecheckliste für:
   - **Rolle 1: Athlet mit Garmin** (Onboarding, OAuth, 90-Tage-Backfill, neue Aktivität, 3 Ringe, Bug-Report senden).
   - **Rolle 2: Athlet mit Wahoo/SRM** (Manueller `.fit`/`.tcx` Upload, CP/W′bal-Analyse, Wettkampf-Ziel anlegen).
   - **Rolle 3: Vereinstrainer am Smartphone & im Web-Browser** (Athlet einladen, Trainingsplan schreiben, Erholungs-Ampel prüfen, Aktivität kommentieren, Trennung testen).
2. `docs/beta/BUGS.md`: Vorbereitetes Fehlerprotokoll mit Schweregraden (`Blocker`, `Kritisch`, `Mittel`, `Kosmetisch`). **Beta-Gate:** 0 Blocker, 0 Kritisch.

### 24.3 Release-Build, Firebase App Distribution & Google Play Closed Track
1. **Prod-Backend & Backups prüfen:**
   - Stelle sicher, dass Point-in-Time-Recovery (PITR) / geplante Firestore-Backups und ein Kosten-/Budget-Alarm in Google Cloud aktiv sind.
   - Deploye `firestore.rules`, `storage.rules`, `firestore.indexes.json`, Cloud Functions und Hosting (inkl. `/privacy` und `/delete-account`).
2. **Stufe 1 – Sofort-Verteilung via Firebase App Distribution:**
   - Baue die signierte Release-APK / AAB (`flutter build apk --release` & `flutter build appbundle --release`).
   - Verteile den Build über Firebase App Distribution an die 5–10 Vereinsfreunde + Trainer für den ersten 48-Stunden-Showstopper-Test.
3. **Stufe 2 – Google Play Console (Closed Testing Track zum 31.10.):**
   - Erstelle die vollständigen Store-Assets (Feature Graphic, Screenshots vom Pixel 10 Pro + Web-Coach, Kurz- & Langbeschreibung DE/EN, ausgefüllter Data-Safety-Bogen für Gesundheits- und Standortdaten, Link zur Live-Account-Löschseite).
   - Lade das signierte `.aab` in den **Closed Testing Track** hoch und schalte die E-Mail-Liste der Tester frei.

## Finaler STOPP-Punkt (Release-Freigabe durch Tim)
- **WICHTIG:** Der Agent darf die finale Release-Freigabe **NIEMALS** selbst abhaken!
- Lege alle Prüfprotokolle in `CHECKPOINTS.md` vor und halte an, bis ich auf meinem Pixel 10 Pro den Build abgenommen und das finale „GO“ für den Play Store gegeben habe.
- Danach: Finaler Commit & Tag `v0.24.0-beta.1`.