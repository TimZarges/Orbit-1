# ORBIT V1.0.0 — 360°-Release-Auditbericht (`AUDIT_V1_0_0_REPORT.md`)

**Release:** `v1.0.0` (Build `1`, `version: 1.0.0+1`) · **Release-Branch:** `release/v1.0.0` · **Haupt-Branch:** `main`  
**Audit-Perspektiven:** (1) Senior Principal Developer & CI-Architekt · (2) Erfahrener Athlet · (3) Erfahrener Coach · (4) Fachanwalt für IT- & Datenschutzrecht (DE/EU)  
**Test-Umgebung:** Geöffneter Safari-Browser (`https://orbit-app-mvp.web.app/` & `/app/`) + Google Pixel 10 Pro (`58251FDCR00EQ2`, Android 16) + Firebase `orbit-app-mvp` (`europe-west3`)

---

## 1. Block 1 — GitHub Actions CI-Analyse & Dauerhafte Behebung

### 1.1 Gefundene Fehlerursachen in der GitHub-Pipeline
1. **Hauptursache (`pubspec.yaml` Zeile 40 — Exit-Code 69 in `flutter pub get`):**
   - Im GitHub-Actions-Lauf (`run_id: 44270843956`, Job `flutter-test`, Schritt 4 *„Install dependencies“*) brach `flutter pub get` nach 3 Sekunden ab mit:
     > `Because orbit depends on flutter_web_plugins any which doesn't exist (could not find package flutter_web_plugins at https://pub.dev), version solving failed.`
   - Hintergrund: `flutter_web_plugins` ist ein internes Flutter-SDK-Paket und existiert nicht auf `pub.dev`. Lokal fiel dies bei Läufen mit `--no-pub` nicht auf, blockierte aber jeden frischen CI-Runner.
   - **Behebung:** Ungültigen Eintrag `flutter_web_plugins: any` aus `pubspec.yaml` entfernt (`flutter pub get` läuft nun in 1,9 s fehlerfrei durch).
2. **CI-Workflow-Härtung (`.github/workflows/ci.yml`):**
   - **Branch-Abdeckung:** Trigger auf `branches: [ "main", "release/**" ]` erweitert, sodass sowohl `main` als auch `release/v1.0.0` automatisch geprüft werden.
   - **Node.js-Version:** In `functions-test` von `node-version: '20'` auf **`node-version: '22'`** angehoben (synchron zu `functions/package.json` `"engines": { "node": "22" }`).
   - **Zeitzonen-Determinismus (`TZ: UTC`):** In `flutter-test` `env: TZ: UTC` gesetzt und alle **267/267 Flutter-Tests** unter `TZ=UTC` verifiziert.
   - **Backend-Linting & Unit-Tests in CI:** In `functions-test` zusätzlich zu `npm run build` auch `npm run lint` sowie `npx jest --testPathIgnorePatterns="rules.test.ts|coachLink.test.ts" --runInBand` aktiviert.

---

## 2. Block 2 — Senior Principal Developer Audit (Architektur, Performance & Security)

### 2.1 Speicher- & Laufzeit-Effizienz
- **Controller-Lifecycle & Disposal:**
  - Alle `State`-Klassen (`LoginScreen`, `V1SimpleOnboardingWizard`, `V1SimpleProfileView`, `ProfileScreen`, `V1AthleteCoachConnectionCard`, `EmailVerificationWaitingScreen`) geben ihre `TextEditingController` und `Timer` in `dispose()` frei.
  - **Gefundene & behobene Dialog-Controller-Leaks (inkl. Schutz während der 150-ms-Schließanimation):** In `LoginScreen._showForgotPasswordDialog`, `SettingsScreen._showResetPasswordEmailDialog` und `SettingsScreen._showChangePasswordDialog` wurden die Dialoge in eigenständige `ConsumerStatefulWidget`-Klassen (`_ForgotPasswordDialog`, `_ResetPasswordEmailDialog`, `_ChangePasswordDialog`) gekapselt. Dadurch werden die internen `TextEditingController` exakt in `State.dispose()` freigegeben — erst nachdem die 150-ms-Reverse-Transition der `DialogRoute` vollständig beendet und das `TextFormField` aus dem Widget-Baum entfernt wurde (verifiziert durch Frame-für-Frame-Widget-Tests in `test/phase46_legal_gdpr_deletion_and_release_v1_test.dart`, Gruppe 7).
- **Rebuild-Vermeidung & `const`-Disziplin:**
  - Durchgängiger Einsatz von `ref.watch(provider.select(...))` in `OrbitApp`, `DashboardScreen`, `TodayTabScreen`, `CalendarScreen`, `V1SimpleOnboardingWizard`, `V1SimpleProfileView`, `UserAvatarCircle`, `EmailVerificationBanner` und `SettingsScreen`.

### 2.2 Fehler- & Edge-Case-Resilienz
- **`.FIT`-Download (`FitDownloadService`):** Prüft Cloud-Storage-Pfade, überspringt `.json`-Metadatenpfade, nutzt auf Web bei Cross-User-Coach-Zugriffen automatisch die autorisierte Cloud Function `downloadActivityFit` (`europe-west3`) und liefert lokalisierte (DE/EN) Fehlermeldungen.
- **Profilbild-Upload (`ProfileAvatarService`):** Skaliert große Bilder (`> 450 KB`) vor dem Upload auf max. `512px` Breite, lädt nach `users/{uid}/avatars/profile.jpg` hoch, speichert `photoUrl` & `avatarUrl` redundant auf Top-Level und in `profile` und schützt bestehende Bilder beim Speichern von Textfeldern vor dem Überschreiben mit `null`.
- **Garmin-Deregistrierung bei Kontolöschung (`deregisterGarminUserIfConnected` in `functions/src/auth.ts`):** Kapselt den externen OAuth-1.0a-`DELETE`-Aufruf gegen `https://apis.garmin.com/wellness-api/rest/user/registration` in einem `try/catch`-Block (`timeout: 5000`), sodass ein Garmin-API-Ausfall niemals die DSGVO-Kontolöschung nach Art. 17 blockiert.

### 2.3 Security Rules & Backend-Härtung (`firestore.rules` & `storage.rules`)
- **`firestore.rules` (`37/37` Emulator-Tests grün):**
  - Standard `allow read, write: if false;`.
  - `isValidUserCreate` und `isValidUserUpdate` schützen alle 11 privilegierten Felder (`role`, `trainerVerified`, `coachId`, `authorizedCoachIds`, `uid`, `email`, `createdAt`, `metrics`, `metricsVersion`, `notificationState`, `isAdmin`) vor Client-Manipulation und validieren `photoUrl` & `avatarUrl` über `isValidAvatarValue` auf Typ, Schema (`https?://` bzw. Legacy-`data:image/...`) und Länge.
  - Coach-Lesezugriffe auf `users/{userId}` und `activities/{activityId}` setzen zwingend ein aktives `coachLinks/{athleteId}_{coachId}`-Dokument (`status == 'ACTIVE'`) voraus; nach Widerruf (`revokeLink`) oder Kontolöschung (`deleteAccount`) endet der Zugriff sofort.
- **`storage.rules`:**
  - `users/{athleteId}/rawActivities/{allPaths=**}` & `users/{athleteId}/fit/{allPaths=**}`: Nur Athlet selbst oder aktiv verbundener Coach (`status == 'ACTIVE'` & `permissions.activities == true`).
  - `users/{userId}/avatars/{allPaths=**}` & `users/{userId}/profile/{allPaths=**}`: Schreib-/Löschzugriff strikt nur für `request.auth.uid == userId`, max. `5 MB`, Content-Type `image/.*`.

---

## 3. Block 3 — Athleten- & Coach-Praxisaudit (End-to-End Pixel 10 Pro & Safari)

### 3.1 Öffentliche Webseite (`/`) -> ORBIT Web (`/app/`)
- `https://orbit-app-mvp.web.app/` läuft als eigenständige Landingpage (`public/index.html`, `34 KB`), getrennt vom Flutter-Web-Bundle unter `public/app/` (`--base-href /app/`).
- **Behobener Befund auf `/`:** Im unteren Formularbereich von `public/index.html` standen noch 4 veraltete „Closed Beta / 31. Oktober“-Texte; diese wurden auf das V1.0.0 Vereins- & Team-Onboarding-Formular mit direktem Verweis auf `/app/#/register` aktualisiert.
- Header- und Hero-Buttons **Login** (`/app/#/login`) sowie **Registrieren** (`/app/#/register`) navigieren verzögerungsfrei in ORBIT Web.

### 3.2 Athleten-Erlebnis (Pixel 10 Pro `58251FDCR00EQ2` & Web)
- **Topbar-Bugmeldung ohne Floating-Overlay:** Der schwebende `GlobalFloatingBugBeetle` ist in V1.0.0 (`!isV2Enabled`) vollständig deaktiviert; das Bug-Icon (`BetaBugReportIconButton`) sitzt sauber in der Topbar (`AppBar`) von `Heute`, `Kalender`, `Coach`, `Profil`, `Onboarding` und `E-Mail bestätigen` (`phase46_pixel10_no_floating_bug.png`, `phase46_pixel10_calendar_topbar_bug.png`, `phase46_safari_no_floating_bug.png`).
- **Profilbild-Persistenz:** Das gespeicherte Radfahrer-Profilbild wird auf dem Pixel 10 Pro dauerhaft sowohl im großen Avatar von `Profil Einfach` als auch oben rechts im Topbar-Avatar (`UserAvatarCircle`) gerendert (`phase46_pixel10_profile_avatar_persisted.png`).
- **Heute & Kalender (Woche, Monat, Liste):** `Heute` zeigt strikt nur am heutigen Kalendertag absolvierte Einheiten + Garmin-Sync & `.FIT`-Upload; `Kalender` zeigt alle absolvierten Einheiten als `TrainingPreviewCard` (in V1.0.0 nicht klickbar, rechts direkter `.FIT`-Download-Button).

### 3.3 Coach-Erlebnis (Web & Mobile)
- Aufgeräumte 3-Tab-Navigation (`Athleten`, `Kalender`, `Profil`) mit responsiver `NavigationRail` ab `900px` Breite im Web.
- E2E-Kette (Code-Generierung -> Athleten-DSGVO-Freigabe -> Kalender-Einsicht -> echter `.FIT`-Download `20261114_Lage_Rennradfahren.fit` mit `127 KB` -> 1-Klick-Trennung bzw. vollständige Coach-Kontolöschung mit automatischer Bereinigung beim Athleten) vollständig gegen `orbit-app-mvp` verifiziert.

---

## 4. Block 4 — Rechtssicherheits- & Formalitäten-Audit (Anwalts-Prüfung DE/EU)

1. **DDG § 5 (Impressumspflicht) & MStV § 18 Abs. 2:**
   - Vollständige, widerspruchsfreie Betreiberangaben (`ORBIT Performance / ORBIT Training`, `ORBIT Endurance Technologies`, Verantwortlich: `Tim Zarges`, `support@orbit-training.app`, `privacy@orbit-training.app`, Standort Deutschland/EU) zweisprachig (DE/EN) in `public/imprint.html` (`/impressum`), `public/privacy.html` (`/privacy`), `public/delete-account.html` und `LegalDocumentsSheet`.
   - **Behobener Befund (2-Klick-Erreichbarkeit auf Unterseiten):** In `public/delete-account.html` (`web/delete-account.html`) und `public/help.html` wurden direkte Footer-Links auf `/imprint.html`, `/privacy.html`, `/` und `/app/#/login` sowie die vollständige Verantwortlichen-Angabe ergänzt.
2. **DSGVO Art. 9 Abs. 2 lit. a & Art. 7 (Gesundheitsdaten-Einwilligung):**
   - Einwilligungs-Checkboxen im Onboarding (`v1_onboarding_gdpr_checkbox`) und bei der Coach-Freigabe sind niemals vorangekreuzt (`_gdprConsent = false`, `_gdprAcceptedForCode = false`) und jederzeit mit 1 Klick widerrufbar.
3. **DSGVO Art. 13, 14, 15–21, 28 & 77 (Datenschutzerklärung Web & In-App):**
   - **Behobener Befund:** `public/privacy.html` (`public/privacy/index.html`) und `LegalDocumentsSheet` wurden auf Deutsch und Englisch explizit ergänzt um:
     - **Auftragsverarbeiter nach Art. 28 DSGVO:** Google Cloud EMEA Limited / Google Ireland Limited (ausschließlich Region `europe-west3` Frankfurt am Main, EU-DPA).
     - **Speicherdauer nach Art. 13 Abs. 2 lit. a DSGVO:** Speicherung nur während der aktiven Kontolaufzeit; sofortige Produktivlöschung + rollierende Backup-Überschreibung innerhalb von max. 30 Tagen.
     - **Vollständige Betroffenenrechte:** Auskunft (Art. 15), Berichtigung (Art. 16), Löschung (Art. 17), Einschränkung (Art. 18), Datenübertragbarkeit via `.FIT`-Download & JSON-Export (Art. 20), Widerruf (Art. 7 Abs. 3) und **Beschwerderecht bei einer Datenschutz-Aufsichtsbehörde (Art. 77 DSGVO)**.
4. **DSGVO Art. 17 & Google Play Data Deletion Requirement:**
   - Sowohl der zweistufige In-App-/Web-Löschdialog (`TwoStepAccountDeletionDialog` -> `deleteAccount` in `europe-west3`) als auch die eigenständige öffentliche Web-Löschseite `/delete-account.html` sind live aktiv und verifiziert.
5. **TDDDG § 25 Abs. 2 Nr. 2 (Keine externen Google Fonts / Keine unzulässigen Drittanbieter-Requests):**
   - Alle statischen HTML-Seiten (`public/index.html`, `imprint.html`, `privacy.html`, `delete-account.html`, `help.html`) nutzen ausschließlich lokale System-UI-Font-Stacks (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`) ohne `<link href="https://fonts.googleapis.com/...">`.
   - Der Flutter-Web-Build unter `public/app/` wird mit **`--no-web-resources-cdn`** gebaut, sodass CanvasKit lokal aus `/app/canvaskit/` geladen wird.

---

## 5. Block 5 — 360°-Webseiten-, Hilfe- & Roadmap-Audit (`public/index.html` & `public/help.html`)

### 5.1 Inhaltliche & UWG-§-5-konforme Trennung von V1.0.0 Live vs. Roadmap (V2.0.0–V4.0.0)
- **Sektion „Jetzt live in ORBIT Version 1.0.0“ (`#v1-live` in `public/index.html`):**
  - **Allgemein (V1.0.0):** Nutzung auf Android & Web (`/app/`), direkt erreichbar über „Login“ (`/app/#/login`) und „Registrieren“ (`/app/#/register`); schnelles Onboarding für Athlet & Coach, Login/Logout, Passwort zurücksetzen & E-Mail-Bestätigung; Clean Professional Design (Hell & Dunkel), vollständige Sprachumschaltung (`DE & EN`), automatische Datums- (`dd.mm.yy`) und `24h`-Uhrzeitformatierung gekoppelt an das Wohnland; volle EU-Datenhoheit (`europe-west3` Frankfurt am Main, 2-Stufen-Funktion „Daten & Konto löschen“ sowie Topbar-Bugmeldung).
  - **Für Athleten (V1.0.0):** „Profil Einfach“ mit allen Stammdaten, dauerhaftem Profilbild und Unterstützung für Triathlon, Radfahren, Laufen, Schwimmen & Krafttraining; automatischer Garmin Sync & manueller `.fit`-Upload; Heute-Ansicht & Kalender (Woche, Monat, Liste); Training Preview angelehnt an COROS mit direktem `.FIT`-Download-Button rechts.
  - **Für Coaches (V1.0.0):** „Profil Einfach“ & sichere Verbindung mit Athleten (Einladungscode oder E-Mail-Anfrage mit expliziter DSGVO-Freigabe); 3-Tab-Navigationsleiste (`Athleten`, `Kalender`, `Profil`); direkter `.FIT`-Originaldatei-Download mit 1 Klick.
- **Sektion „Roadmap & Kommende Updates (V2.0.0 bis V4.0.0)“ (`#roadmap` in `public/index.html`):**
  - Glasklar als kommende Ausbaustufen (*„NICHT BESTANDTEIL VON V1.0.0“*) nach § 5 UWG gekennzeichnet:
    - **Version 2.0.0 (Nächster Meilenstein):** Leistungsdiagnostik, Zonen berechnen & einstellen (inkl. LIT/MIT/HIT), Chat, Kommentare (+ Einheit im Chat) & Mitteilungen; Athlet: Profil Fortgeschritten, History Garmin Sync, History Bulk-Upload (300+ Dateien), Training Details (1-Hz-Cockpit & 2D-RPE-Quadrant) & Trainingsplanung empfangen; Coach: Profil Fortgeschritten, Trainings-Datenbank, Workout-Builder im Web (farbige Zonen-Blöcke & Ernährungsfeld) und Planung pro Athlet.
    - **Version 3.0.0 (Readiness, Health & Machine Learning):** Saison-Ziele, Workout-Builder Mobil, Zeitplanung/Verfügbarkeitsprofile & Aufenthaltsort; Profil Expert, Daily Health (3 Ringe), Morgen-Check (Journal), Gesamtanalyse & Machine-Learning-Analyse.
    - **Version 3.1.0 / 4.0.0 (Zukunft & KI):** Sync zu weiteren Anbietern, erweitertes Machine Learning & interaktiver KI-Trainer.
- **Bereinigung von `public/help.html`:**
  - Zweigeteilt in **Teil 1 (V1.0.0 Bedienungsanleitung & FAQ — Jetzt Live)** und **Teil 2 (Sportwissenschaftliches Lexikon — Geplante Module für V2.0.0 bis V4.0.0)**, vollständig zweisprachig (`DE & EN`) und im Hell-/Dunkel-Modus umschaltbar.
- **Technische & Rechtliche Prüfung aller öffentlichen Routen (`HTTP 200` & `0` Drittanbieter-Requests):**
  - `/`, `/help`, `/imprint`, `/impressum`, `/privacy`, `/delete-account`, `/app/`, `/app/canvaskit/canvaskit.js`, `/app/assets/fonts/MaterialIcons-Regular.otf`, `/app/assets/FontManifest.json` liefern alle **HTTP 200** (`ext_refs=[]`, `anchors_missing=[]`).

---

## 6. Block 6 — Finale Verifikation, Live-Screenshots & Release-Synchronisation (`v1.0.0`)

- **`bash scripts/check_phase_ready.sh`:**
  - `flutter analyze`: `0 Errors, 0 Warnings, 0 Infos`
  - `npm --prefix functions run build && npm --prefix functions run lint`: `0 Errors`
  - Deutsche Dokumentations-Kommentare: `100 %`
  - `flutter test` (inkl. `TZ=UTC` & Dialog-Controller-Lifecycle-Tests): **`269/269` Tests bestanden**
- **Emulator-Suite (`firestore` & `storage`):** **`12/12` Test-Suites (`113/113` Tests) bestanden**
- **Live-Beweis-Screenshots (`docs/beta/screenshots/`):**
  - `docs/beta/screenshots/audit_safari_website_v1_features.png` (Sektion „Jetzt live in ORBIT Version 1.0.0“ im geöffneten Safari-Browser)
  - `docs/beta/screenshots/audit_safari_website_roadmap_v2_v4.png` (Neue Roadmap-Sektion V2.0.0 bis V4.0.0 im geöffneten Safari-Browser)
  - `docs/beta/screenshots/audit_safari_orbit_web_app_icons_verify.png` (ORBIT Web unter `/app/` mit lokalem CanvasKit & `MaterialIcons-Regular.otf` ohne Tofu-Icons)
  - `docs/beta/screenshots/audit_pixel10_v1_final.png` (ORBIT V1.0.0 Release-APK `1.0.0+1` auf dem Google Pixel 10 Pro `58251FDCR00EQ2` mit Topbar-Bugbutton und gespeichertem Profilbild)
- **Produktions-Deployments:** Firebase Hosting (`/`, `/app/`, `/imprint.html`, `/privacy.html`, `/delete-account.html`, `/help.html`), Firestore Rules, Storage Rules, Cloud Functions (`europe-west3`) sowie Android Release-APK (`1.0.0+1`) auf Pixel 10 Pro (`58251FDCR00EQ2`).

---

## 7. Block 7 — Launch-Update `v1.0.1` (Reaktive E-Mail-Verifizierung, Coach-Invite-Fix, Heute-Entschlackung & Web-Bereinigung)

- **Reaktive E-Mail-Bestätigung ohne Relogin (`auth_provider.dart`, `email_verification_banner.dart`, `email_verification_waiting_screen.dart`):**
  - `EmailVerificationController` kombiniert `userChanges()`, `idTokenChanges()` sowie `reload()` + `getIdToken(true)`; beide Oberflächen beobachten zusätzlich `AppLifecycleState.resumed` und bieten den Button `„Bereits bestätigt? Status prüfen“` / `„Already verified? Check status“`.
- **End-to-End-Reparatur der Coach-E-Mail-Einladung (`functions/src/coach.ts`, `auth.ts`, `firestore.rules`, `v1_coach_athletes_tab.dart`):**
  - `requestAthleteLinkByEmail` sucht sowohl in Firestore (`users`) als auch via Firebase Auth (`getUserByEmail`), legt für noch nicht registrierte E-Mail-Adressen persistente `coachInvites` + `mail`-Queue-Einträge an, gibt den 6-stelligen Coach-Code für den ehrlichen Rückmelde-Dialog zurück und überträgt offene Einladungen bei Signup (`setInitialRole`) bzw. über `claimPendingCoachInvites` in eine DSGVO-pflichtige `PENDING`-Anfrage (`coachLinks`). `coachInvites` & `mail` sind durch neue `firestore.rules` + Emulator-Tests abgesichert.
- **Radikal aufgeräumter Heute-Tab in V1.0.0 (`today_tab_screen.dart`):**
  - Im strikten V1.0.0-Modus werden alle Garmin-Sync- und `.fit`-Upload-Karten, Buttons und der FAB ausgeblendet; ohne heutiges Training erscheint ausschließlich die ruhige Hinweiskarte (`„Heute noch kein absolviertes Training“` / `„Sobald heute ein Training synchronisiert wird, erscheint es hier.“`).
- **Bereinigung von Mitbewerber-Marken, `europe-west3` in Nutzertexten & Vereins-Onboarding (`public/`, `lib/`):**
  - Entfernt aus allen HTML-Seiten (`public/index.html`, `help.html`, `privacy.html`, `delete-account.html`, `privacy/index.html`, `impressum/index.html`; `brand-showcase.html` gelöscht) und App-Texten; `ContactConfig.serverRegion` & `AppInfo.region` vereinheitlicht auf `Frankfurt am Main (Deutschland / EU)`. Live-Prüfung auf `/`, `/privacy/`, `/impressum/`, `/help`, `/delete-account`, `/app/`: überall `HTTP 200` und `0` Treffer (`forbidden_hits=0`).
- **Verifikation (`v1.0.1`):**
  - `bash scripts/check_phase_ready.sh`: `flutter analyze` `0 Errors / 0 Warnings / 0 Infos`, `functions` Build & Lint `0 Errors`, `100 %` deutsche Kommentare, **`271/271` Flutter-Tests bestanden**.
  - Emulator-Suite (`npx -y firebase-tools emulators:exec --only firestore,storage "npm --prefix functions test" --project orbit-app-mvp`): **`12/12` Test-Suites (`117/117` Tests) bestanden**.
  - Live-Screenshots: `docs/beta/screenshots/audit_pixel10_v1_0_1_today_clean.png`, `docs/beta/screenshots/audit_safari_v1_0_1_website_clean.png`, `docs/beta/screenshots/audit_safari_v1_0_1_web_app.png`.

---

## 8. Block 8 — Verankertes ORBIT Farbsystem (`COLOR_SYSTEM_V1`) & Index-/Stream-Reparatur Coach-E-Mail-Einladung (`v1.0.1`)

- **Verankerte Single Source of Truth (`docs/design/COLOR_SYSTEM_V1.md`, `app_colors.dart`, `orbit_professional_theme.dart`, `theme_tokens.dart`):**
  - **Light Mode:** Ruhiger Hintergrund `#F6F8FB`, Karten & Leisten `#FFFFFF`, Sekundärfläche `#EEF2F7`, Haupttext `#0F172A`, Akzent `#001F47` / `#003B82`, Sekundärtext `#64748B`, Rahmen `#DCE3EC`, Erfolg `#059669`, Warnung `#D97706`, Fehler `#DC2626`. **Kein Logo-Volt (`#CDFB17`)** auf Text oder Standard-UI-Flächen im Light Mode (ausschließlich als zukünftige GPX-Spur reserviert).
  - **Dark Mode:** Ruhiger Hintergrund `#0B0E14`, Karten & Leisten `#141923`, Erhöhte Fläche `#1B2230`, Subtile Fläche `#222B3A`, Haupttext `#F8FAFC`, Sekundärtext `#94A3B8`, Rahmen `0x24FFFFFF`, Primär-Akzent `#CDFB17`, Erfolg `#10B981`, Warnung `#F59E0B`, Fehler `#EF4444`.
  - **Unabhängige Sportarten- & Zonen-/V2–V4-Tokens:** Triathlon `#0284C7`/`#38BDF8`, Rad `#D97706`/`#F59E0B`, Lauf `#059669`/`#10B981`, Schwimmen `#2563EB`/`#60A5FA`, Kraft `#475569`/`#94A3B8`, Zonen `Z1–Z7` & V2–V4 ohne Verwendung von `#001F47` oder `#CDFB17`.
  - **Web-Angleichung (`public/index.html`, `help.html`, `imprint.html`, `privacy.html`, `delete-account.html`, `privacy/index.html`, `impressum/index.html`, `web/delete-account.html`):** CSS-Variablen in Light & Dark vollständig angeglichen (`#F6F8FB`/`#FFFFFF`/`#EEF2F7`/`#001F47`/`#003B82` bzw. `#0B0E14`/`#141923`/`#1B2230`/`#CDFB17`).
- **Vollständige Reparatur der Coach-E-Mail-Einladung (`firestore.indexes.json`, `v1_coach_connection_provider.dart`, `v1_coach_athletes_tab.dart`, `v1_athlete_coach_connection_card.dart`, `dashboard_screen.dart`, `functions/src/coach.ts`):**
  - **Root-Cause-Analyse auf Live-Firestore:** `npx firebase-tools firestore:indexes --project orbit-app-mvp` belegte das Fehlen der Composite Indexes für `coachLinks(athleteId, status)` und `coachInvites(coachId, status)` — wodurch beide Live-Streams (`v1AthleteCoachLinksStreamProvider`, `v1CoachPendingEmailInvitesStreamProvider`) `FAILED_PRECONDITION` warfen und über `.valueOrNull ?? const []` stillschweigend verschluckt wurden.
  - **Behebung:** `firestore.indexes.json` um `coachLinks(athleteId, status)` sowie `coachInvites(coachId, status)` / `(athleteEmail, status)` ergänzt und live deployed; alle drei Client-Streams sowie `claimCoachInvitesForAthlete` auf indexfreie Einzel-Feld-Queries mit lokaler Statusfilterung umgestellt; Stream-Fehler werden in UI explizit mit Retry-Button angezeigt (`AGENTS.md` Regel 0); Coach erhält sowohl bei vorhandenem als auch bei neuem Konto den klaren Rückmelde-Dialog inkl. Mail-Status & 6-stelligem Code; Athleten überführen offene Einladungen automatisch via `v1AutoClaimCoachInvitesProvider` (`DashboardScreen` & `V1AthleteCoachConnectionCard`) sowie manuell über `athlete_check_email_invites_btn`.
- **Verifikation:**
  - `bash scripts/check_phase_ready.sh`: `0 Errors / 0 Warnings / 0 Infos`, `100 %` deutsche Kommentare, **`272/272` Flutter-Tests bestanden**.
  - Emulator-Suite: **`12/12` Test-Suites (`117/117` Tests) bestanden**.
  - Live-Screenshots: `docs/beta/screenshots/color_system_pixel10_dark.png`, `docs/beta/screenshots/color_system_pixel10_coach_tab.png`, `docs/beta/screenshots/color_system_safari_website_light.png`, `docs/beta/screenshots/color_system_safari_web_app.png`.

---

## 9. Block 9 — Re-Invite / Re-Link & Fehlerformatierung (`v1.0.2`)

- **Ursachenbehebung für Re-Invite / Re-Link bereits verknüpfter oder getrennter Konten:**
  - `functions/src/coach.ts`:
    - `requestAthleteLinkByEmail` löst den Athleten-Account primär über die maßgebliche Firebase-Auth-Identität (`admin.auth().getUserByEmail(normalizedEmail)`) statt zuerst über `users` auf (verhindert Treffer auf verwaiste Alt-Dokumente nach Kontowechsel/-löschung), bereinigt Duplikat-/Alt-ID-Dokumente in `coachLinks`, überschreibt `coachLinks` und `coachInvites` sauber ohne `{ merge: true }`-Altlasten (`REVOKED`/alte Permissions) und meldet `reactivated` / `alreadyPending` explizit an das UI zurück.
    - `revokeLink` bereinigt zusätzlich `invites/{code}.usedBy` per `arrayRemove(athleteId)` sowie Alt-Link-Dokumente; `redeemInvite` erlaubt das erneute Einlösen desselben Coach-Codes nach Trennung (`status !== 'ACTIVE'`); `respondToCoachLinkRequest` synchronisiert zugehörige `coachInvites` und blockiert veraltete Annahmen zurückgezogener Anfragen.
  - `functions/src/coach/dashboard.ts`:
    - Behebt den im Live-Log aufgetretenen `FAILED_PRECONDITION`-Indexfehler in `onCoachLinkChanged` über eine indexfreie Bereichsabfrage (`FieldPath.documentId() >= thirtyDaysAgoStr`) auf `users/{athleteId}/aggregates`.
  - **Flutter-UI & Provider (`v1_coach_connection_provider.dart`, `v1_coach_athletes_tab.dart`, `v1_athlete_coach_connection_card.dart`):**
    - Zentrale Fehlerübersetzung `V1CoachConnectionService.formatError` für Coach-Dialog & Athletenkarte, Doppelklick-Sperre (`_busyActionIds` / `_isBusy`) beim Zurückziehen/Beantworten, sofortige Stream-Invalidierung und klares Rückmelde-UI für reaktivierte und aktualisierte Anfragen.
- **Verifikation (`v1.0.2`):**
  - `bash scripts/check_phase_ready.sh`: `flutter analyze` `0 Errors / 0 Warnings / 0 Infos`, `functions` Build & Lint `0 Errors`, `100 %` deutsche Kommentare, **`273/273` Flutter-Tests bestanden**.
  - Emulator-Suite (`npx -y firebase-tools emulators:exec --only firestore,storage "npm --prefix functions test"`): **`12/12` Test-Suites (`118/118` Tests) bestanden** (inklusive neuem Re-Invite-, Ablehnungs- & Code-Wiederverwendungs-Test in `coachLink.test.ts`).
  - **Live-End-to-End-Verifikation gegen `orbit-app-mvp`** (mit 3 Wegwerf-Testkonten inkl. anschließender restloser Kontolöschung via `deleteAccount`, reales Athletenkonto unberührt): E-Mail-Einladung (`accountExists: true`, `PENDING`) -> DSGVO-Annahme (`ACTIVE`) -> `ALREADY_EXISTS`-Schutz -> `revokeLink` -> erneute E-Mail-Einladung (`reactivated: true`, `PENDING`) -> Ablehnung + erneutes Re-Invite -> `ACTIVE` -> Trennung & Wiederverwendung des 6-stelligen Coach-Codes -> Pre-Registration-Invite + Onboarding-Claim + Annahme (`100 %` bestanden).
  - Live-Screenshots: `docs/beta/screenshots/v1_0_2_safari_live.png`, `docs/beta/screenshots/v1_0_2_pixel10_live.png`.

---

## 10. Block 10 — Finaler V1.0.0-Abschluss: Coach trennt Athleten-Verbindung, Export-Hardening & Code-Qualität (`v1.0.2`)

- **Coach-seitig initiiertes Trennen (`functions/src/coach.ts`, `v1_coach_connection_provider.dart`, `v1_coach_athletes_tab.dart`):**
  - `revokeLink` akzeptiert `linkId` oder `athleteId` (Coach-Fallback), setzt `status: 'REVOKED'`, `revokedAt` und `revokedBy: 'COACH' | 'ATHLETE'` (`revokedByUid`), entfernt sofort `coachId` & `authorizedCoachIds` vom Athleten-Dokument sowie offene `coachInvites`, `invites.usedBy` und `coachDashboard`-Einträge; Firestore Rules, Storage Rules und `downloadActivityFit` entziehen dem ehemaligen Coach unmittelbar jeden Lese- und `.FIT`-Download-Zugriff.
  - `V1CoachConnectionService.disconnectAthlete(athleteId)` ruft `revokeLink` auf, setzt eine aktive Kalender-Auswahl (`v1SelectedCoachAthleteIdProvider`, `viewedAthleteIdProvider`) zurück und invalidiert die Coach-Streams.
  - Jede Karte verbundener Athleten (`_ConnectedAthleteCard`) zeigt in `V1CoachAthletesTab` den Button **„Verbindung trennen“** / **„Disconnect athlete“** (`#DC2626` Light / `#EF4444` Dark) inklusive DE/EN-Bestätigungsdialog (`coach_disconnect_confirm_dialog`) und Hinweis auf bereits lokal gespeicherte `.FIT`-Dateien.
- **Rechtssicherheits-Nachkontrolle & Modularität (`functions/src/auth.ts`, `privacy_settings_sheet.dart`):**
  - `exportAccount` (Art. 20 DSGVO) filtert alle Ausgabedaten rekursiv über `sanitizeExportValue(...)`, sodass garantiert keine Server-/OAuth-Secrets (`oauthTokenSecret`, `accessTokenSecret`, `refreshToken` etc.) geleakt werden und Firestore-Timestamps als ISO-8601 serialisieren; `_GdprExportResultDialog` wurde sauber ausgelagert.
- **Offener Store-Hinweis:**
  - ORBIT V1.0.0 ist technisch vollständig und funktional abgeschlossen; für den breiten öffentlichen Google Play Store Launch muss organisatorisch noch die echte **ladungsfähige Postanschrift** gemäß § 5 Abs. 1 Nr. 1 DDG im Impressum ergänzt werden (`docs/audit/LEGAL_COMPLIANCE_REPORT_V1.md`).
- **Verifikation (`v1.0.2` Feature Complete):**
  - `bash scripts/check_phase_ready.sh`: `0 Errors / 0 Warnings / 0 Infos`, `functions` Build & Lint `0 Errors`, `100 %` deutsche Kommentare, **`276/276` Flutter-Tests bestanden**.
  - Emulator-Suite (`npx -y firebase-tools emulators:exec --only firestore,storage "npm --prefix functions test"`): **`12/12` Test-Suites (`120/120` Tests) bestanden** (inkl. `coachLink.test.ts` Coach-Trennung + `.fit`-Sperre & `auth.test.ts` `sanitizeExportValue`).
  - Live-E2E-Prüfung auf `orbit-app-mvp` (Wegwerf-Konten) + Live-Screenshots: `docs/beta/screenshots/v1_coach_disconnect_dialog.png`, `docs/beta/screenshots/v1_0_0_final_pixel10.png`.
