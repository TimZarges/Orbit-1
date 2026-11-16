# Phase 43: Schlankes V1.0.0 Onboarding, „Profil Einfach“ & Auth-Flows (Passwort-Reset & E-Mail-Bestätigung)

**Tag:** `v0.43.0` · **Branch:** `feature/phase-43-onboarding-simple-profile-auth` · **Status:** `[x] Abgeschlossen`

---

## Ziele & Abnahmekriterien

1. **Modulares V1.0.0 Onboarding (`V1SimpleOnboardingWizard`):**
   - [x] Auslagerung des V1.0.0-Onboardings in `lib/features/onboarding/widgets/v1_simple_onboarding_wizard.dart` ohne weitere Aufblähung von `onboarding_screen.dart`.
   - [x] Steuerung über `ReleaseConfig.isV2Enabled`: Im V1.0.0-Standardmodus (`false`) ohne V2/V3-Schwellenwert- oder Zonen-Rechner; Bestands-Tests (`phase19`, `phase36`) bleiben über `ReleaseConfig.overrideForTesting(v2: true)` 100 % grün.
   - [x] **Schritt 1 (Rolle & Basis-Einstellungen):** Athlet oder Coach, Sprache (`DE` / `EN`), Design (`Hell` / `Dunkel` / `System`), Wohnland (`DE`, `AT`, `CH`, `EU`, `US`, `GB`) für `CountryDateTimeFormatter` (`dd.mm.yy • 24h`).
   - [x] **Schritt 2 (Stammdaten):** Gemeinsam Vorname/Nachname; Athleten zusätzlich Geburtsdatum, Geschlecht, Körpergröße (cm), Körpergewicht (kg), Hauptsportarten inkl. **Triathlon** (`triathlon`), Radsport, Laufen, Schwimmen, Krafttraining; Coaches Coaching-Schwerpunkt / Kurz-Bio.
   - [x] **Schritt 3 (Datenquellen & DSGVO):** Für Athleten direkter Einstieg für Garmin Connect & manuellen `.fit`-Upload; für beide Rollen verpflichtende, nicht vorangekreuzte DSGVO Art. 9 Einwilligungs-Checkbox.

2. **„Profil Einfach“ (`V1SimpleProfileView` & `ProfileScreen`):**
   - [x] Modulares Widget `lib/features/profile/widgets/v1_simple_profile_view.dart`, eingebunden in `ProfileScreen` bei `!ReleaseConfig.isV2Enabled`.
   - [x] Vollständige Ansicht und Bearbeitung aller Onboarding-Stammdaten (DE & EN, Light & Dark) ohne V2-Leistungsdiagnostik, Zonen-Tabellen oder V3-Saisonziele.
   - [x] Anzeige des Triathlon-Badges (`TriathlonCombinedIcon`), Wohnland mit Live-Formatvorschau (`dd.mm.yy • 24h`), Garmin Connect Status (`garminStatusStreamProvider`) + direkter `.FIT`-Upload.
   - [x] Offizieller App-Footer (`ORBIT v1.0.0 (Build 1) • Closed Beta`, `Server-Region: Deutschland (Frankfurt am Main)`).
   - [x] Konsistenz-Check `.fit`-Upload: `ActivityUploadProvider`, `functions/src/import/activityParser.ts` und `functions/src/import/garmin/webhook.ts` speichern konsistent unter `users/{uid}/rawActivities/{activityId}.fit` und schreiben `rawFilePath`.

3. **Vollständige V1.0.0 Auth-Flows:**
   - [x] `LoginScreen` im Clean Professional Light/Dark Design, komplett lokalisiert (DE/EN), mit Passwort-vergessen-Dialog (`sendPasswordResetEmail`), Validierung, Ladezustand und Fehlerbehandlung.
   - [x] `EmailVerificationWaitingScreen` im Clean Professional Light/Dark Design, DE/EN lokalisiert, mit 60s Resend-Cooldown (`sendEmailVerification`) und Status-Prüfung (`reloadAndCheckEmailVerified`).
   - [x] `SettingsScreen`: Neuer Eintrag **„Passwort zurücksetzen (E-Mail-Link)“** (`settings_reset_password_email_tile`) inkl. `_showResetPasswordEmailDialog`.

4. **Tests, Qualitäts-Gate & Hardware-Verifikation (Pixel 10 Pro):**
   - [x] Neue Testsuite `test/phase43_onboarding_simple_profile_and_auth_v1_test.dart` geschrieben und bestanden.
   - [x] `bash scripts/check_phase_ready.sh` erfolgreich (`0 Errors, 0 Warnings, 0 Infos`, 100 % deutsche Kommentierung, `239/239` Tests grün).
   - [x] Release-APK (`66.5MB`) auf Google Pixel 10 Pro (`58251FDCR00EQ2`) installiert und End-to-End verifiziert.
   - [x] Beweis-Screenshots in `docs/beta/screenshots/` gesichert (`phase43_pixel10_simple_profile_top.png`, `phase43_pixel10_simple_profile_bottom.png`, `phase43_pixel10_auth_reset_dialog.png`).
