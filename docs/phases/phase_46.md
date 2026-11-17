# Phase 46: Gesetzliche Anforderungen DE/EU (DSGVO & DDG § 5), Öffentliche Webseite + Web-App, Finaler Audit & V1.0.0 Release

**Tag:** `v1.0.0` · **Release-Branch:** `release/v1.0.0` · **Feature-Branch:** `feature/phase-46-legal-gdpr-release-v1` · **Status:** `[x] Abgeschlossen`

---

## Ziele & Abnahmekriterien

1. **Öffentliche Webseite (`/`) + Einstieg in ORBIT Web (`/app/`) & HTML-Rechtsseiten:**
   - [x] `public/index.html` bleibt als eigenständige öffentliche Webseite unter `/` erhalten (niemals vom Flutter-Build unter `public/app/` überschrieben), bereinigt von Closed-Beta-Texten (`ORBIT V1.0.0 · RELEASE`), mit klar sichtbaren **Login** (`/app/#/login`) und **Registrieren** (`/app/#/register`) Buttons in Header & Hero (DE & EN).
   - [x] `public/imprint.html` (`public/impressum/index.html`) und `public/privacy.html` (`public/privacy/index.html`) zweisprachig (`DE` & `EN`) sowie Hell-/Dunkel-adaptiv mit verbindlichen Betreiberdaten (`ORBIT Performance / ORBIT Training`, `ORBIT Endurance Technologies`, `Tim Zarges`, `support@orbit-training.app`, `privacy@orbit-training.app`), DSGVO Art. 9/13/14/17, Serverstandort Frankfurt am Main (`europe-west3`), Garmin OAuth & Coach-`.FIT`-Freigabe aktualisiert; `public/delete-account.html` auf ORBIT Web `/app/#/login` aktualisiert.

2. **Rechtliche Integration & 1-Klick-Zugang in App & Web (`DE` & `EN`, Hell & Dunkel):**
   - [x] `lib/core/config/app_config.dart`, `pubspec.yaml` (`version: 1.0.0+1`) & `lib/core/config/contact_config.dart`: Offizielle Paket- und App-Version auf `v1.0.0 (Build 1)` (`versionName = 1.0.0`, `versionCode = 1`, `version.json` `1.0.0+1`, ohne „Closed Beta“) sowie offizielle Marken-, Betreiber- und URL-Konstanten aktualisiert.
   - [x] `lib/core/routing/app_router.dart`: Einstiegsrouten `/register` sowie `?mode=register` ergänzt; Redirect für `/verify-email` korrigiert, sodass unbestätigte Nutzer (`emailVerified == false`) zuverlässig auf den Wartebildschirm gelangen können.
   - [x] `lib/features/auth/widgets/email_verification_banner.dart`, `lib/features/dashboard/screens/dashboard_screen.dart` & `lib/features/auth/screens/email_verification_waiting_screen.dart`: Lokalisiertes E-Mail-Bestätigungs-Banner (`DE`/`EN`, Hell/Dunkel) bei `emailVerified == false` mit 1-Klick-Sprung auf `/verify-email` und „Erneut senden“; doppelten Mail-Trigger in `v1_simple_onboarding_wizard.dart` bereinigt.
   - [x] `lib/features/legal/widgets/legal_documents_sheet.dart`: Modale, zweisprachige und Theme-adaptive 1-Klick-Ansicht für Datenschutzerklärung & Impressum.
   - [x] `lib/features/auth/screens/login_screen.dart`: Sprachumschalter (`DE`/`EN`) sowie 1-Klick-Links zu **Datenschutz**, **Impressum** und **Webseite**.
   - [x] `lib/features/onboarding/widgets/v1_simple_onboarding_wizard.dart`: 1-Klick-Links auf Datenschutz & Impressum in Schritt 3 unter der DSGVO-Checkbox.
   - [x] `lib/features/profile/widgets/v1_simple_profile_view.dart`, `lib/features/settings/screens/settings_screen.dart` & `lib/features/settings/widgets/privacy_settings_sheet.dart`: 1-Klick-Zugang zu Datenschutz, Impressum, `AccountDeletionService` sowie „Daten & Konto löschen“.

3. **Unwiderrufliche DSGVO Art. 17 Konto- & Datenlöschung (Backend + Garmin-Deregistrierung + 2-Stufen-Dialog):**
   - [x] `functions/src/auth.ts`: `deleteAccount` (`europe-west3`) deregistriert bei aktiver Garmin-Verknüpfung über `deregisterGarminUserIfConnected` (`DELETE https://apis.garmin.com/wellness-api/rest/user/registration` im fehlertoleranten `try/catch`-Block), löscht `garminUsers`, `users/{uid}/integrations/garmin` & `integrationStatus/garmin`, bereinigt gebündelt `coachLinks` (`athleteId` & `coachId`), `authorizedCoachIds` & `coachId` auf verbundenen Athletenprofilen, `coachDashboard`, `invites`, `activities`, `plannedWorkouts`, `betaFeedback`, `chats` (`recursiveDelete`), `users/{uid}` (`recursiveDelete`), Cloud Storage `users/{uid}/` (`deleteFiles({ prefix, force: true })`) und `admin.auth().deleteUser(uid)`.
   - [x] `lib/features/auth/services/account_deletion_service.dart` & `lib/features/auth/widgets/two_step_account_deletion_dialog.dart`: Zweistufiger Bestätigungsdialog (Schritt 1: vollständige Datenliste -> Schritt 2: explizite Checkbox + „Endgültig löschen“), Weiterleitung zu `/login` nach erfolgreicher Löschung.

4. **Qualitäts-Gate, Synchroner Release-Build, Live-Verifikation & Gold-Release `v1.0.0`:**
   - [x] Neue Testsuite `test/phase46_legal_gdpr_deletion_and_release_v1_test.dart` (10 Tests inkl. `EmailVerificationBanner`) & Bestandsanpassung in `test/features/phase23_notifications_races_hardening_test.dart` und `test/features/settings/settings_logout_test.dart`; Backend-Unit-Tests für `deregisterGarminUserIfConnected` in `functions/src/__tests__/auth.test.ts` (`4/4` Tests).
   - [x] Nach dem allerletzten Code-Edit ausgeführt: `bash scripts/check_phase_ready.sh` (`flutter analyze`: 0 Errors/0 Warnings/0 Infos, TS-Build & ESLint `0 Errors`, 100 % deutsche Doku-Kommentare, **265/265 Flutter-Tests bestanden**) + Firebase-Emulator-Backend/Rules-Suite (**12/12 Suites, 112/112 Tests bestanden**).
   - [x] Synchrone Produktions-Deployments nach finaler Code-Prüfung: Cloud Function `deleteAccount` (`europe-west3` inkl. Secret-Manager-Zugriff auf `GARMIN_CONSUMER_KEY`/`GARMIN_CONSUMER_SECRET`), Flutter Web Release (`flutter build web --release --base-href /app/` mit `version.json` `1.0.0`/`1`) nach `public/app/` -> Firebase Hosting (`https://orbit-app-mvp.web.app/` + `/app/` + `/privacy` + `/imprint` + `/delete-account` HTTP 200) sowie Android Release APK (`67.0MB`, `versionCode=1`, `versionName=1.0.0`) auf Google Pixel 10 Pro (`58251FDCR00EQ2`).
   - [x] Live-Beweis Safari + Pixel 10 Pro: Test-Coach-Konto `coach.p45.e2e@orbit.training` über 2-Stufen-Dialog unwiderruflich gelöscht (Re-Login abgelehnt; Verbindung auf realem Athletenkonto auf Pixel 10 Pro automatisch entfernt; echtes Athletenkonto mit Garmin-Daten vollständig geschützt).
   - [x] Beweis-Screenshots unter `docs/beta/screenshots/`: `phase46_safari_website_hero.png`, `phase46_safari_legal_docs.png`, `phase46_safari_delete_account_dialog.png`, `phase46_pixel10_v1_profile_legal.png`, `phase46_pixel10_legal_sheet.png`, `phase46_pixel10_after_coach_deletion.png`.
   - [x] Fast-Forward-Merge in `main`, annotiertes Tag `v1.0.0` und Release-Branch `release/v1.0.0` angelegt & zu GitHub gepusht.
