# Phase 44: V1.0.0 Coach-3-Tab-Ansicht, Coach-Athleten-Verbindung & `.FIT`-Download

**Tag:** `v0.44.0` · **Branch:** `feature/phase-44-coach-view-connection-download` · **Status:** `[x] Abgeschlossen`

---

## Ziele & Abnahmekriterien

1. **Nachbesserung „Profil Einfach“ & Athleten-Coach-Verbindung (`V1SimpleProfileView` & `V1AthleteCoachConnectionCard`):**
   - [x] `lib/features/profile/widgets/v1_simple_profile_view.dart`: Stammdaten für Athleten und Coaches editierbar und in Firestore speicherbar (DE & EN, Light & Dark Mode; inkl. `onSaveOverride` für deterministische Widget-Tests).
   - [x] `lib/features/profile/widgets/v1_athlete_coach_connection_card.dart`: Sektion **„Mein Coach / Verbindung mit Coach“** für Athleten (Einladungscode eingeben, eingehende Coach-Anfragen ansehen/bestätigen/ablehnen, nicht vorangekreuzte DSGVO-Checkbox für Kalender- & `.fit`-Freigabe, 1-Klick-Trennen via `revokeLink`).

2. **Coach-Athleten-Service & Cloud Functions (`europe-west3`, Node.js 22):**
   - [x] `lib/features/coach_link/models/v1_coach_athlete_link.dart` & `lib/features/coach_link/providers/v1_coach_connection_provider.dart` erstellt.
   - [x] `functions/src/coach.ts` & `functions/src/index.ts`: `requestAthleteLinkByEmail` und `respondToCoachLinkRequest` ergänzt (inkl. Node.js 22 Runtime-Update in `functions/package.json`) und erfolgreich nach `europe-west3` (`orbit-app-mvp`) deployed.

3. **V1.0.0 Coach-3-Tab-Navigation & Screens (`ReleaseConfig.isV2Enabled == false`):**
   - [x] `lib/features/dashboard/screens/dashboard_screen.dart`: Im V1.0.0-Coach-Modus ausschließlich die 3 Tabs **Athleten**, **Kalender** und **Profil** (DE & EN, Light & Dark Mode) ohne V2/V3-Elemente (Workout-Builder, Analyse, Bibliothek, Chat).
   - [x] Tab 1 (`lib/features/coach_link/screens/v1_coach_athletes_tab.dart`): Einladungscode-Karte (Generieren & Kopieren), E-Mail-Einladungsdialog, offene Anfragen und verbundene Athleten inkl. Triathlon-Badge (`TriathlonCombinedIcon`) und Wohnland-Datum (`dd.mm.yy • 24h`); Klick wechselt direkt mit ausgewähltem Athleten in Tab 2.
   - [x] Tab 2 (`lib/features/coach_link/screens/v1_coach_calendar_tab.dart`): Horizontale Athleten-Auswahlleiste + vollständiger V1.0.0-`CalendarScreen` (Woche, Monat, Liste) im `ProviderScope`-Override auf `viewedAthleteIdProvider` mit `TrainingPreviewCard` und aktivem `.FIT`-Download.
   - [x] Tab 3 (`Profil`): `ProfileScreen` / `V1SimpleProfileView` mit Coach-Stammdaten, Coaching-Schwerpunkt und direktem Einstellungs-Zugang (`v1_coach_profile_settings_button`).

4. **Security Rules (`firestore.rules` & `storage.rules`) & `.FIT`-Download:**
   - [x] `firestore.rules` (über `firestore-rules-author`): `users/{userId}` `allow read` für aktive Coaches/Athleten erweitert; `activities/{activityId}` `allow read` auf `isCoachForActivities(resource.data.athleteId)` umgestellt.
   - [x] `firestore.rules` und `storage.rules` live nach `orbit-app-mvp` deployed.

5. **Tests, Pre-Merge-Gate & Hardware-Verifikation:**
   - [x] `test/phase44_coach_view_connection_and_download_v1_test.dart` mit 8 Tests erstellt und bestanden.
   - [x] `bash scripts/check_phase_ready.sh` erfolgreich (`0 Errors, 0 Warnings, 0 Infos`, 100 % deutsche Kommentare, `247/247` Tests grün).
   - [x] Release-APK (`66.7MB`) auf Google Pixel 10 Pro (`58251FDCR00EQ2`) installiert und verifiziert (`docs/beta/screenshots/phase44_pixel10_athlete_coach_connection.png`).
