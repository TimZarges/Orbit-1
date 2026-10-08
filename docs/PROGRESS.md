# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 03
- Branch: feature/phase-02-coach-link

## Fertig
- Phase 00 (Foundation):
  - Komplettes Setup der Ordnerstruktur (`lib/core`, `lib/features`, etc.)
  - Firebase-Konfiguration (`firebase.json`, `.firebaserc`, Emulator-Suite)
  - Cloud Functions (TypeScript-Gerüst in `functions/`)
  - CI-Pipeline (GitHub Actions)
  - Basis-Entscheidungen im ADR-Log (`docs/DECISIONS.md`)
  - Crashlytics-Vorbereitung (`CrashReporter`)
  - Design-System (`AppColors`, `AppSpacing`, `AppTypography`, `AppTheme`)
  - App-Shell (`go_router` in `app_router.dart`, `WidgetGalleryScreen`)
  - Spikes (S1, S2) konzeptuell vorbereitet und Empfehlungen im ADR abgelegt.
- Phase 01 (Auth & Onboarding):
  - Firebase Auth Integration (Login, Auth Provider)
  - Onboarding Flow UI (Rolle, Sportarten, Erfahrung, Wettkampfziel)
  - Firebase Storage & Firestore Rules Entwurf (`firestore.rules`, `storage.rules`)
  - Cloud Functions `setInitialRole`, `deleteAccount`, `exportAccount`
  - `firestore.indexes.json`
  - Platzhalter für `docs/PRIVACY.md`
- Phase 02 (Trainer-Verknüpfung):
  - Firestore Rules für `coachLinks` und `invites` (Denormalisiertes `coachId` Konzept)
  - Cloud Functions für `createInvite`, `redeemInvite`, `updatePermissions`, `revokeLink`
  - Trainer-Tab: Einladung erstellen und Athleten-Liste
  - Athlet-Tab: Empty State und Trainer-Karte inkl. Freigaben
  - `AthleteContextWrapper` zur sicheren Weitergabe der `athleteId` an Kind-Screens

## Offen / in Arbeit
- Phase 03: Trainingsplan-UI (Kalenderansicht)

## Bekannte Probleme
- NPM nicht verfügbar in der Entwicklungsumgebung, daher Rules Emulator Tests für Phase 01 übersprungen. Müssen von Nutzer nachgeholt werden.

## Nächster Schritt
- `/phase-start 02`
