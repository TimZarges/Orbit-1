# Phase 46: Gesetzliche Anforderungen DE/EU (DSGVO & DDG § 5), Öffentliche Webseite + Web-App, Finaler Audit & V1.0.0 Release

**Tag:** `v1.0.0` · **Release-Branch:** `release/v1.0.0` · **Feature-Branch:** `feature/phase-46-legal-gdpr-release-v1` · **Status:** `[x] Abgeschlossen`

---

## Ziele & Abnahmekriterien

1. **Öffentliche Webseite (`/`) + Einstieg in ORBIT Web (`/app/`) & HTML-Rechtsseiten:**
   - [x] `public/index.html` bleibt als eigenständige öffentliche Webseite unter `/` erhalten (niemals vom Flutter-Build unter `public/app/` überschrieben), bereinigt von Closed-Beta-Texten (`ORBIT V1.0.0 · RELEASE`), mit klar sichtbaren **Login** (`/app/#/login`) und **Registrieren** (`/app/#/register`) Buttons in Header & Hero (DE & EN).
   - [x] `public/imprint.html` (`public/impressum/index.html`) und `public/privacy.html` (`public/privacy/index.html`) zweisprachig (`DE` & `EN`) sowie Hell-/Dunkel-adaptiv mit verbindlichen Betreiberdaten (`ORBIT Performance / ORBIT Training`, `ORBIT Endurance Technologies`, `Tim Zarges`, `support@orbit-training.app`, `privacy@orbit-training.app`), DSGVO Art. 9/13/14/17, Serverstandort Frankfurt am Main (`europe-west3`), Garmin OAuth & Coach-`.FIT`-Freigabe aktualisiert; `public/delete-account.html` auf ORBIT Web `/app/#/login` aktualisiert.

2. **Rechtliche Integration & 1-Klick-Zugang in App & Web (`DE` & `EN`, Hell & Dunkel):**
   - [x] `lib/core/config/app_config.dart` & `lib/core/config/contact_config.dart`: Version auf `v1.0.0 (Build 1)` (`Release`, ohne „Closed Beta“) sowie offizielle Marken-, Betreiber- und URL-Konstanten aktualisiert.
   - [x] `lib/core/routing/app_router.dart`: Einstiegsrouten `/register` sowie `?mode=register` ergänzt (leitet direkt in das schlanke Onboarding für neue Konten).
   - [x] `lib/features/legal/widgets/legal_documents_sheet.dart`: Modale, zweisprachige und Theme-adaptive 1-Klick-Ansicht für Datenschutzerklärung & Impressum.
   - [x] `lib/features/auth/screens/login_screen.dart`: Sprachumschalter (`DE`/`EN`) sowie 1-Klick-Links zu **Datenschutz**, **Impressum** und **Webseite**.
   - [x] `lib/features/onboarding/widgets/v1_simple_onboarding_wizard.dart`: 1-Klick-Links auf Datenschutz & Impressum in Schritt 3 unter der DSGVO-Checkbox.
   - [x] `lib/features/profile/widgets/v1_simple_profile_view.dart`, `lib/features/settings/screens/settings_screen.dart` & `lib/features/settings/widgets/privacy_settings_sheet.dart`: 1-Klick-Zugang zu Datenschutz, Impressum, `AccountDeletionService` sowie „Daten & Konto löschen“.

3. **Unwiderrufliche DSGVO Art. 17 Konto- & Datenlöschung (Backend + 2-Stufen-Dialog):**
   - [x] `functions/src/auth.ts`: `deleteAccount` in `europe-west3` löscht gebündelt (`deleteQueryInBatches`, 400er Chunks) alle `coachLinks` (`athleteId` & `coachId`), entfernt `authorizedCoachIds` & `coachId` auf verbundenen Athletenprofilen, löscht `coachDashboard`, `invites`, `activities`, `plannedWorkouts`, `garminUsers`, `betaFeedback`, `chats` (`recursiveDelete`), `users/{uid}` (`recursiveDelete`), sämtliche Dateien in Cloud Storage unter `users/{uid}/` (`deleteFiles({ prefix, force: true })`) und schließlich den Firebase-Auth-Benutzer (`deleteUser(uid)`).
   - [x] `lib/features/auth/services/account_deletion_service.dart` & `lib/features/auth/widgets/two_step_account_deletion_dialog.dart`: Zweistufiger Bestätigungsdialog (Schritt 1: vollständige Datenliste -> Schritt 2: explizite Checkbox + „Endgültig löschen“), Weiterleitung zu `/login` nach erfolgreicher Löschung.

4. **Qualitäts-Gate, Live-Verifikation (Safari + Pixel 10 Pro) & Gold-Release `v1.0.0`:**
   - [x] Neue Testsuite `test/phase46_legal_gdpr_deletion_and_release_v1_test.dart` (9 Tests) & Bestandsanpassung in `test/features/phase23_notifications_races_hardening_test.dart` sowie `test/features/settings/settings_logout_test.dart`.
   - [x] `bash scripts/check_phase_ready.sh` (`flutter analyze`: 0 Errors/0 Warnings/0 Infos, TS-Build & ESLint `0 Errors`, 100 % deutsche Doku-Kommentare, **264/264 Flutter-Tests bestanden**) + Firebase-Emulator-Backend/Rules-Suite (**12/12 Suites, 110/110 Tests bestanden**).
   - [x] Produktions-Deployments: Cloud Function `deleteAccount` & Firebase Hosting (`https://orbit-app-mvp.web.app/` + `/app/` + `/privacy` + `/imprint` + `/delete-account` mit HTTP 200) sowie Android Release APK (`67.0MB`) auf Google Pixel 10 Pro (`58251FDCR00EQ2`).
   - [x] Live-Beweis Safari + Pixel 10 Pro: Test-Coach-Konto `coach.p45.e2e@orbit.training` über 2-Stufen-Dialog unwiderruflich gelöscht (Re-Login abgelehnt; Verbindung auf realem Athletenkonto auf Pixel 10 Pro automatisch entfernt; echtes Athletenkonto mit Garmin-Daten vollständig geschützt).
   - [x] Beweis-Screenshots unter `docs/beta/screenshots/`: `phase46_safari_website_hero.png`, `phase46_safari_legal_docs.png`, `phase46_safari_delete_account_dialog.png`, `phase46_pixel10_v1_profile_legal.png`, `phase46_pixel10_legal_sheet.png`, `phase46_pixel10_after_coach_deletion.png`.
   - [x] Fast-Forward-Merge in `main`, annotiertes Tag `v1.0.0` und Release-Branch `release/v1.0.0` angelegt & zu GitHub gepusht.
