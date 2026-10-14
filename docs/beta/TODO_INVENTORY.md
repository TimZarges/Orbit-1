# TODO- und Platzhalter-Inventar (Beta-Planung)

> **Stand:** 2026-10-14  
> **Projekt:** ORBIT  
> **Zweck:** Vollständige Erfassung aller im Code vorhandenen `TODO`, `FIXME`, `TODO(manual)`, „folgt", Platzhalter, Mocks, `UnimplementedError` und Ignore-Kommentare.  
> **Regel:** Jede Aussage ist mit exakter `Datei:Zeile` belegt und in „Blockiert Beta" bzw. „Später" kategorisiert.

---

## 1. Übersicht

| Kategorie | Anzahl Fundstellen |
|---|---|
| **Blockiert Beta (kritisch für Launch/Funktion/Sicherheit)** | 14 |
| **Später (Nice-to-have / nachgelagerte Phasen / Code-Gen)** | 17 |
| **Gesamt** | **31** |

---

## 2. Blockiert Beta (Kritisch)

Diese Punkte verhindern die korrekte Funktion der Beta-Version, führen zu Dateninkonsistenzen, stellen Sicherheits-/DSGVO-Risiken dar oder täuschen Funktionen vor, die nicht angebunden sind.

| Nr. | Datei : Zeile | Typ | Gefundener Text / Code | Grund für Blocker |
|---|---|---|---|---|
| 1 | `lib/features/onboarding/screens/onboarding_screen.dart:40` | Platzhalter | `'firstName': 'Nutzer', // Default/Platzhalter` | Onboarding erfasst weder Vor-/Nachname noch Geschlecht, Geburtsdatum, Gewicht oder Größe. Es werden immer feste Dummy-Werte (`Nutzer Test`, `M`, `1990-01-01`, `75.0 kg`, `180 cm`) an die Cloud Function `setInitialRole` übergeben. |
| 2 | `lib/features/coach_link/screens/athlete_coach_tab_screen.dart:108-114` | Mock | `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code $code wird geprüft und Verknüpfungsanfrage gesendet...')));` | **Mock:** Die Eingabe des Trainer-Einladungscodes ruft weder die Cloud Function `redeemInvite` auf noch schreibt sie in Firestore. Die Verknüpfung kann aus der Athletensicht nicht hergestellt werden. |
| 3 | `lib/features/coach_link/screens/athlete_coach_tab_screen.dart:138-142` | Mock | `ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verknüpfung wurde beendet.')));` | **Mock:** Der Button „Verknüpfung lösen" ruft weder die Cloud Function `revokeLink` auf noch aktualisiert er das `users`- oder `coachLinks`-Dokument. |
| 4 | `lib/features/coach_link/screens/athlete_coach_tab_screen.dart:203-240` | Mock | `setState(() => _shareActivities = val); ScaffoldMessenger...` | **Mock:** Die Schalter für Datenfreigaben (Aktivitäten, Kalender, Gesundheitsdaten Art. 9 DSGVO) rufen nicht `updatePermissions` auf und speichern die Werte nicht in Firestore. |
| 5 | `functions/src/coach.ts:125-127` | TODO | `// Note: If permissions.activities is revoked, we'd need to set coachId to null on all activities. This can be done via batch update, but is omitted for brevity in Phase 02 prototype.` | **DSGVO-/Sicherheitsrisiko:** Beim Entzug der Aktivitäten-Freigabe bleibt das denormalisierte `coachId`-Feld auf bestehenden Aktivitäten stehen. Der Trainer behält dadurch unerlaubten Lesezugriff. |
| 6 | `functions/src/coach.ts:164-165` | TODO | `// Again, would need to run query and batch update all activities/plannedWorkouts here.` | **DSGVO-/Sicherheitsrisiko:** Beim vollständigen Widerruf des Coach-Links (`revokeLink`) wird `coachId` auf Aktivitäten und geplanten Workouts nicht bereinigt. |
| 7 | `functions/src/metrics/activityTrigger.ts:42` | Platzhalter | `'metrics.tss': 50 // Placeholder` | Statt tatsächlicher Normalized Power- und TSS-Berechnung schreibt der Trigger einen hardcodierten Dummy-TSS von 50. |
| 8 | `functions/src/metrics/activityTrigger.ts:51-57` | TODO / Platzhalter | `// TODO: Alle Aktivitäten ab fromDateStr laden und CTL/ATL neu rechnen` & `dailyLoad: 50 // Placeholder` | Der Firestore-Trigger berechnet bei neuen Aktivitäten keine echten CTL/ATL-Werte, sondern setzt lediglich `dailyLoad: 50`. Zudem lauscht der Trigger auf `users/{uid}/activities/{activityId}` statt auf der tatsächlichen Root-Collection `activities/{activityId}`. |
| 9 | `functions/src/metrics/recompute.ts:9` | TODO | `// TODO: Iteriere über alle Aktivitäten ab startDate, filtere ungültige heraus, sortiere nach startTimeUtc` | Die Cloud Function `recomputeMetrics` ist ein unvollständiger Code-Stub ohne Funktionalität. |
| 10 | `functions/src/import/garmin/webhook.ts:51` | TODO | `// TODO: Payload parsen. Garmin sendet z. B. { userAccessToken, startTimeInSeconds, summaryId, fileType }` | Eingehende Webhooks von Garmin werden mit 200 OK quittiert, der Payload wird jedoch nicht ausgewertet oder in `webhookEvents` verarbeitet. |
| 11 | `lib/features/activities/widgets/telemetry_map_widget.dart:34-60, 226-236` | Mock / Täuschung | Dialog: `Beim Laden von Umgebungskarten wird deine IP-Adresse an den Kartenanbieter übertragen...` -> `if (showGrid) { canvas.drawLine(...) }` | **Täuschung:** Der Dialog suggeriert das Laden echter Kartenkacheln eines Drittanbieters. Bei Zustimmung wird jedoch lediglich ein 40-Pixel-Canvas-Gitter gezeichnet. Es existiert keine Kachelanbindung. |
| 12 | `lib/features/workout_builder/screens/workout_template_library_screen.dart:420` | Platzhalter | `plannedDurationSec: 3600, // Platzhalter oder aus Struktur` | Beim Einplanen einer Vorlage in den Kalender wird fest 3600 Sekunden (1 Stunde) hinterlegt, anstatt die Summe der Blockdauern der Struktur zu berechnen. |
| 13 | `lib/features/diagnostics/repositories/diagnostics_repository.dart:174` | Unzulässige Collection | `.collection('recomputeRequests')` | Schreibt in die Subcollection `users/{athleteId}/recomputeRequests`. Diese Collection existiert weder in `docs/DATA_MODEL.md` noch in `firestore.rules` (wird durch `deny all` mit `PERMISSION_DENIED` blockiert) und besitzt keinen Cloud Functions Listener. |
| 14 | `lib/firebase_options_prod.dart:1` | Platzhalter | `// Placeholder for Firebase Options Prod` | Enthält keine Produktionskonfiguration für Firebase; Produktiv-Builds schlagen fehl. |

---

## 3. Später (Nachgelagert / Nicht blockierend für Beta)

Diese Punkte betreffen spätere Phasen (z. B. Export-Features, Bild-Upload), unschädliche Code-Generierungs-Marker oder Doku-Hinweise.

| Nr. | Datei : Zeile | Typ | Gefundener Text / Code | Begründung für Zurückstellung |
|---|---|---|---|---|
| 15 | `lib/features/onboarding/screens/onboarding_screen.dart:265` | folgt | `child: const Text('Garmin verbinden (folgt)'),` | Direkte Garmin-Verknüpfung im Onboarding ist optional; Verknüpfung ist über Einstellungen möglich. |
| 16 | `lib/features/onboarding/screens/onboarding_screen.dart:270` | folgt | `child: const Text('FIT importieren (folgt)'),` | FIT-Import im Onboarding ist optional; Import ist im Tab „Heute" über FAB erreichbar. |
| 17 | `lib/features/profile/screens/profile_screen.dart:32` | TODO | `// TODO: Implement image upload` | Avatar-Upload für das Nutzerprofil; Default-Avatar reicht für Beta. |
| 18 | `lib/features/workout_builder/domain/workout_exporter.dart:20` | UnimplementedError | `throw UnimplementedError('FIT-Export wird in einer späteren Phase umgesetzt.');` | Export strukturierter Workouts auf Garmin-Geräte war für Phase 17+ geplant. |
| 19 | `lib/features/workout_builder/domain/workout_exporter.dart:25` | UnimplementedError | `throw UnimplementedError('ZWO-Export wird in einer späteren Phase umgesetzt.');` | Zwift (ZWO) Export ist nicht Bestandteil des MVP-Scopes. |
| 20 | `lib/features/workout_builder/domain/workout_exporter.dart:3, 14` | Platzhalter | `/// Platzhalter-Interface... /// Dummy-Implementierung als Platzhalter für zukünftige Phasen.` | Interface-Definition für zukünftige Exporter. |
| 21 | `lib/features/chat/widgets/chat_bubble.dart:308` | Platzhalter | `subtitle: const Text('Wird durch einen Platzhalter ersetzt.'),` | UI-Text für serverseitig gelöschte Nachrichten (Soft Delete). |
| 22 | `lib/features/analysis/widgets/analysis_info_sheet.dart:148` | folgt | `return 'Erklärung für diesen Wert folgt in Kürze.';` | Fallback-Text im Glossar für selten abgefragte Metriken. |
| 23 | `functions/src/import/fitParser.ts:49` | Hinweis | `const utcOffsetMinutes = 0; // Better: extract from device settings or profile timezone` | UTC-Offset-Fallback bei FIT-Dateien ohne Zeitzoneneintrag. |
| 24 | `functions/src/import/garmin/backfill.ts:7` | eslint-disable | `// eslint-disable-next-line @typescript-eslint/no-var-requires` | Linter-Pragma für `oauth-1.0a` CommonJS-Import. |
| 25 | `functions/src/import/garmin/auth.ts:7` | eslint-disable | `// eslint-disable-next-line @typescript-eslint/no-var-requires` | Linter-Pragma für `oauth-1.0a` CommonJS-Import. |
| 26 | `lib/l10n/app_localizations.dart:11` | ignore_for_file | `// ignore_for_file: type=lint` | Automatisch generierte Lokalisierungsdatei von Flutter. |
| 27 | `lib/l10n/app_localizations_de.dart:1, 5` | ignore / ignore_for_file | `// ignore: unused_import`, `// ignore_for_file: type=lint` | Automatisch generierte Lokalisierungsdatei von Flutter. |
| 28 | `lib/l10n/app_localizations_en.dart:1, 5` | ignore / ignore_for_file | `// ignore: unused_import`, `// ignore_for_file: type=lint` | Automatisch generierte Lokalisierungsdatei von Flutter. |
| 29 | `lib/firebase_options_prod 2.dart:1` | Dateiduplikat | `// Placeholder for Firebase Options Prod` | Verwaistes Dateiduplikat im Dateisystem. |
| 30 | `functions/src/seeds/seed_coach_athletes.ts:9` | Testcode | `export async function seedCoachAthletes(...)` | Nur für Staging/Dev-Tests; ist durch Umgebungscheck gegen Prod abgesichert. |
| 31 | `lib/features/calendar/services/calendar_demo_seeder.dart:6` | Demo-Code | `/// Seeder für realistische geplante Trainingseinheiten im Demo-Modus.` | Gewollte Demo-Funktionalität für Erstnutzer ohne Trainingsdaten. |
