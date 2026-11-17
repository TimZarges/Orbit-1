# Phase 45: Web-Anwendung (Flutter Web), Responsive Layout, Web-`.FIT`-Handling & Echter E2E Coach-Athlet-Beweis

**Tag:** `v0.45.0` · **Branch:** `feature/phase-45-web-app-responsive-and-e2e-coach-verify` · **Status:** `[x] Abgeschlossen`

---

## Ziele & Abnahmekriterien

1. **Teil A – Kritisches Audit & Nachbesserung Coach-Athleten-Verbindung:**
   - [x] `functions/src/coach.ts`: `redeemInvite` reichert Profilmetadaten (`athleteName`, `athleteEmail`, `coachName`, `coachEmail`, `athleteSports`) an; `redeemInvite`, `updatePermissions`, `revokeLink` und `respondToCoachLinkRequest` pflegen `authorizedCoachIds` serverseitig auf `users/{athleteId}` und synchronisieren sofortigen Widerruf.
   - [x] `firestore.rules` (über `firestore-rules-author`): `authorizedCoachIds` in `isValidUserUpdate()` und `isValidUserCreate()` gegen Client-Manipulation geschützt; Coach-Lesezugriffe auf `users` & `activities` per `coachLinks` (`status == 'ACTIVE'`) verifiziert.
   - [x] `storage.rules`: `users/{athleteId}/rawActivities/{allPaths=**}` & `users/{athleteId}/fit/{allPaths=**}` präzisiert + serverseitige Cloud Function `downloadActivityFit` (`europe-west3`, Node.js 22) als autorisierter Fallback bei Cross-Service-/Browser-CORS-Sperren implementiert und deployed.
   - [x] `lib/features/activities/providers/activities_provider.dart`, `v1_coach_athletes_tab.dart`, `v1_coach_calendar_tab.dart` & `lib/features/activities/models/activity.dart`: Coach-Kalender nutzt strikt die gewählte Athleten-ID (`v1SelectedCoachAthleteIdProvider` / `viewedAthleteIdProvider`) und fällt niemals auf die eigene Coach-UID zurück; `Activity.fromDocument` parst sowohl `Timestamp` als auch ISO-8601-Strings und `storagePath`.

2. **Teil B – Web-Anwendung, Responsive Layout & Plattform-`.FIT`-Handling:**
   - [x] `lib/core/widgets/responsive_content_frame.dart` & `lib/features/dashboard/screens/dashboard_screen.dart`: Responsive Desktop-/Web-Navigation (`NavigationRail` links ab `width >= 900px`, ausgeklappt ab `>= 1160px`, `BottomNavigationBar` `< 900px`) für Coaches (`Athleten`, `Kalender`, `Profil`) und Athleten (`Heute`, `Kalender`, `Coach`, `Profil`) inkl. `ResponsiveContentFrame` (`maxWidth: 1080`).
   - [x] `lib/features/coach_link/screens/athlete_coach_tab_screen.dart`: V1.0.0-Scope-Gating delegiert bei `!ReleaseConfig.isV2Enabled` auf `V1AthleteCoachConnectionCard` in `ResponsiveContentFrame`.
   - [x] `lib/features/activities/services/fit_download_service.dart`, `fit_file_saver_web.dart` & `fit_file_saver_stub.dart`: Bedingte Imports (`dart.library.js_interop` / `package:web`) für direkten Browser-Blob-Download (`<a download="...fit">`) sowie autorisierten `downloadActivityFit`-Server-Fallback; `.json`-Summary-Pfade im `.FIT`-Download sauber übersprungen.
   - [x] `lib/features/activities/providers/activity_upload_provider.dart`: `dart:isolate` / `Isolate.run` und `lengthSync` durch Web-kompatibles `compute(...)` und Byte-Längenprüfung ersetzt; `rawFilePath` konsistent geschrieben.
   - [x] `lib/core/config/app_check_service.dart`, `lib/main.dart`, `firebase.json` & `cors.json`: Web-App-Check sauber übersprungen (`kIsWeb`), Hash-Routing unter `/app/#/` stabilisiert und `no-cache` Header für Web-App-Bundles in `firebase.json` konfiguriert.

3. **Produktions-Deployments, E2E-Live-Verifikation (Safari + Pixel 10 Pro) & Tests:**
   - [x] Flutter Web Release (`flutter build web --release --base-href /app/`) und Release-APK (`66.8MB`) gebaut und auf Firebase Hosting (`https://orbit-app-mvp.web.app/app/`) sowie Google Pixel 10 Pro (`58251FDCR00EQ2`) installiert.
   - [x] Echter E2E-Beweis zwischen geöffnetem Safari (Coach `coach.p45.e2e@orbit.training`) und Pixel 10 Pro (Athlet `ORBIT Athlet`): Einladungscode `129879` per `createInvite` -> `redeemInvite` mit DSGVO-Bestätigung -> Live-Anzeige `Verbundene Athleten (1)` -> Kalender `Lage Rennradfahren` (14.11.26 • 11:39) -> erfolgreicher Real-Download von `20261114_Lage_Rennradfahren.fit` (`127 KB`, `.FIT` Magic Header verifiziert).
   - [x] Beweis-Screenshots unter `docs/beta/screenshots/` gesichert: `phase45_pixel10_coach_connected.png`, `phase45_safari_coach_athletes.png`, `phase45_safari_coach_calendar.png`, `phase45_safari_coach_fit_download.png`.
   - [x] `test/phase45_web_responsive_and_coach_e2e_v1_test.dart` (8 neue Tests) & vollständiger `bash scripts/check_phase_ready.sh`-Durchlauf (`255/255` Tests grün, `0` Analyzer/Lint/Comment-Issues).
