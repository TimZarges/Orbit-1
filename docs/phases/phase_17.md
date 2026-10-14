# PHASE 17 — Notfall-Reparatur: Git-Konsolidierung, Backend-Trigger, Security & Grüne Pipeline

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH).
- **Pflicht:** Vor jedem destruktiven Git-Schritt, jeder Änderung an `firestore.rules` / `storage.rules` und am Phasenende gilt ein **zwingender STOPP-Punkt**.
- **Nachweis-Pflicht:** Keine Selbstauskünfte! Jedes erledigte Kriterium muss durch die exakte Terminal-Ausgabe in `CHECKPOINTS.md` belegt werden.

## Ausgangslage (aus BASELINE.md)
1. Phasen 04 bis 16 sind nicht in `main` gemergt (`main` steht bei Phase 03, Commit `fef019b`).
2. `functions/src/metrics.ts` überschattet das Verzeichnis `functions/src/metrics/`, wodurch `index.ts` nur `helloWorld` exportiert und alle Trigger (`activityTrigger`, `diagnostics`, `bests`, `recompute`) tot sind.
3. Der Cloud Storage Trigger `processFitUpload` (`functions/src/import/index.ts`) wurde in Commit `de08c2bb` gelöscht.
4. Bei Trainer-Trennung (`functions/src/coach.ts:125, 164`) bleibt das denormalisierte `coachId`-Feld auf bestehenden Aktivitäten und Plänen erhalten (DSGVO-Verstoß / unberechtigter Lesezugriff).
5. Es existiert kein einziger automatisierter Rules-Test (`@firebase/rules-unit-testing` fehlt), obwohl `docs/RULES_TESTPLAN.md` existiert.
6. `flutter test` schlägt mit 7 Fehlern fehl (`chat_message_test.dart`, `workout_builder`), `flutter analyze` meldet 230 Issues (36 Warnungen).
7. `functions` hat laut `npm audit` 53 Sicherheitslücken (38 High).

## Arbeitspakete

### 17.1 Git-Konsolidierung & Rekonstruktion der ADRs 01–08
1. Prüfe alle lokalen und Remote-Branches. Erstelle vorab ein Sicherungs-Tag `backup-pre-phase17` auf dem aktuell neuesten Arbeits-Branch.
2. Merge den vollständigen Arbeitsstand der Phasen 04–16 sauber in `main` (Fast-Forward oder Merge-Commit ohne Codeverlust) und tagge den Stand als `v0.16.0-baseline`.
3. Übernehme die in `docs/beta/BASELINE.md` rekonstruierten ADRs für die Phasen 01, 02, 03, 04 und 06 in `DECISIONS.md` (klar markiert als `[Rekonstruiert in Phase 17]`) und dokumentiere die Entscheidung für manuelle Dart-Modelle statt `freezed`.

### 17.2 Backend-Trigger reaktivieren (Shadowing & FIT-Import)
1. **Shadowing-Bug beheben:** Löse den Namenskonflikt zwischen `functions/src/metrics.ts` und `functions/src/metrics/` auf. Exportiere alle Trigger (`onActivityCreated`, `onActivityUpdated`, `recomputeMetrics`, `diagnostics`, `bests`) sauber über `functions/src/metrics/index.ts` und registriere sie in `functions/src/index.ts`.
2. **FIT-Storage-Trigger wiederherstellen:** Rekonstruiere `processFitUpload` aus der Git-Historie (vor Commit `de08c2bb`) in `functions/src/import/index.ts` und binde ihn in `functions/src/index.ts` ein. Wenn eine Datei unter `uploads/{userId}/{fileName}` landet, muss sie geparst, als `activities/{activityId}` gespeichert und der Metrik-Trigger ausgelöst werden.
3. **Verifikation:** Prüfe den Kompiliert-Output in `functions/lib/index.js` — alle Funktionen müssen dort als Exporte sichtbar sein.

### 17.3 DSGVO-Fix bei Trainer-Trennung & Entzug (Security Leak)
1. Passe `functions/src/coach.ts` (Entkoppeln & Consent-Widerruf) sowie die zugehörigen Firestore Rules an:
   - Beim Trennen eines Trainers oder beim Widerruf der Art.-9-Einwilligung müssen in einem Batch/Chunked-Write **alle** betroffenen Dokumente in `activities`, `planned_workouts`, `diagnostics` und `daily_health` des Athleten bereinigt werden (`coachId: FieldValue.delete()` bzw. Update der Zugriffsfelder).
   - Zusätzlich in `firestore.rules` absichern: Der Lesezugriff eines Trainers auf Sub-Ressourcen eines Athleten muss gegen ein aktives `coach_athlete_links/{linkId}`-Dokument (`status == 'active'`) geprüft werden, sodass ein bloßes Rest-Feld `coachId` auf einer alten Aktivität niemals allein für den Lesezugriff ausreicht.

### 17.4 Automatisierte Rules-Unit-Tests implementieren
1. Installiere `@firebase/rules-unit-testing` als DevDependency.
2. Implementiere die Kernszenarien aus `docs/RULES_TESTPLAN.md` als echte, ausführbare Tests unter `test/rules/`:
   - Athlet liest/schreibt eigene Daten, darf fremde Daten nicht lesen.
   - Trainer darf Athletendaten NUR bei aktivem Link + passendem Consent-Flag (Art. 9 DSGVO für Gesundheits-/Sensordaten) lesen.
   - Sofortiger Zugriffsverlust nach Trennung oder Consent-Entzug (Test für 17.3!).
   - Manipulation geschützter Server-Felder (`role`, `orbitScore`, berechnete Metriken) durch den Client wird blockiert.

### 17.5 Flutter-Tests, Linter & NPM-Security reparieren
1. Behebe die 7 fehlschlagenden Unit-Tests in `chat_message_test.dart` und `workout_builder`.
2. Beseitige alle 36 Linter-Warnungen (inkl. unzulässiger Zugriffe auf geschützte `StateNotifier`-Members) und reduziere die Analyzer-Issues auf 0 Errors und 0 Warnings.
3. Korrigiere die Hintergrundfarbe des Daily Rings auf das definierte Marken-Navy `#001F47` (statt `#0F172A`).
4. Führe in `functions/` ein Dependency-Update durch (`npm audit fix` / gezielte Upgrades von `node-forge`, `uuid`, `firebase-functions`, `firebase-admin`), bis `npm audit --audit-level=high` **0 High/Critical Vulnerabilities** meldet.

## STOPP-Punkte & Abnahmekriterien
- **STOPP 1:** Zeige vor dem Merge in `main` den Branch-Graphen und die Änderungen an `firestore.rules`.
- **STOPP 2 (Phasenabschluss):** Lege die echten Ausgaben folgender Befehle in `CHECKPOINTS.md` vor:
  1. `git status` & `git log --oneline -n 5 main`
  2. `node -e "console.log(Object.keys(require('./functions/lib/index.js')))"` (Nachweis aller exportierten Cloud Functions)
  3. `npm --prefix functions audit --audit-level=high` (0 High/Critical)
  4. `firebase emulators:exec --only firestore,storage "npm test"` (inkl. Rules-Tests grün)
  5. `flutter analyze` (0 Errors, 0 Warnings) & `flutter test` (100 % grün)
- Erst nach meiner Freigabe: Commit & Push auf GitHub mit Tag `v0.17.0`.