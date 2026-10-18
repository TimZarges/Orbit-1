# PHASE 35 — Garmin-Datenempfang, Echter `.fit`-Upload & Aktivitäts-Cockpit nach Strava/Garmin/Coros/MATS-Vorbild

## Modus & Zielsetzung
- **Branch:** `feature/phase-35-garmin-fit-cockpit`
- **Ziel-Release:** `v0.35.0`
- **Ziel:** Zuverlässiger Garmin-Datenabruf über aktiven REST-Pull-Sync (`syncGarminActivitiesNow`), multi-format Aktivitäts-Upload (`.fit`, `.tcx`, `.gpx`) mit Hintergrund-Isolate-Parsing auf Android 16 und vollständiges Activity-Cockpit mit synchronisiertem Scrubber, Volt-Streckenlinie, Soll/Ist-Banner und PR-Kurven.
- **Status:** **[x] Abgeschlossen**

---

## Arbeitspakete

### 35.1 Garmin-Datenempfang reparieren & Aktiven REST-Pull-Sync implementieren
- [x] Analyse von `garminAuthCallback`, `requestGarminBackfill` und `garminWebhook` in `functions/src/import/garmin/`.
- [x] Implementierung eines **aktiven REST-Pull-Synchronisations-Endpunkts (`syncGarminActivitiesNow`)**:
  - Abruf historischer Aktivitäten & Gesundheitsdaten direkt nach OAuth-Abschluss.
  - Manuelle Auslösung über „Jetzt synchronisieren“-Button im Client (Einstellungen / Garmin-Card).
  - Speichern der Aktivitäten in Firestore (`users/{uid}/activities`) und Rohdatei-Archivierung in Cloud Storage (`users/{uid}/rawActivities/`).
  - Idempotente Speicherung (keine doppelten Aktivitäten via `garminActivityId` Hash).
- [x] Unit-Tests für `syncGarminActivitiesNow` und Webhook-Fallback.

### 35.2 `.fit` / `.tcx` / `.gpx` Datei-Upload reparieren (SAF & Isolate-Parsing)
- [x] Behebung von Android 16 SAF-Berechtigungs-/Lesefehlern in `file_picker` (`withData: true` bzw. sicherer Stream-Read).
- [x] Multi-Format-Support: `.fit`, `.tcx` und `.gpx` Parser im Hintergrund-Isolate (`Isolate.run` / `compute`).
- [x] Sicheres Archivieren der Original-Rohdatei in Cloud Storage (`users/{uid}/rawActivities/{activityId}.fit`).
- [x] Berechnung aller Leistungs- und Telemetriedaten (Watt, HF, Pace, GPS-Punkte, Höhenprofil, Trittfrequenz, Splits) und Persistierung in Firestore (`users/{uid}/activities/{activityId}`).
- [x] Verifikation: Upload funktioniert zu 100 % sowohl über den `+` FAB auf dem Dashboard als auch im Onboarding.

### 35.3 High-End Aktivitäts-Cockpit (Strava, Garmin Connect, Coros & MATS)
- [x] **Header:** Sportart-Badge, editierbarer Titel, deutsches Datum & 24h-Uhrzeit (`DD.MM.YYYY • HH:mm Uhr`).
- [x] **GPS-Karte:** Leuchtende `#CDFB17` Volt-Streckenlinie mit `#001F47` Navy-Kontur, Hell/Dunkel-Karten-Umschalter und automatische Zentrierung.
- [x] **Soll/Ist-Abgleich-Banner:** Erfüllungs-Ampel (🟢 $\le 15\%$, 🟡 $15\text{–}35\%$, 🔴 $> 35\%$) bei Vorliegen eines geplanten Workouts.
- [x] **2x3 Kern-Metrik-Grid:** Distanz, Dauer, Ø Watt / Ø Pace, Höhenmeter, Ø/Max Puls, ORBIT Load & Intensitäts-Faktor.
- [x] **Synchronisierte Telemetrie-Graphen:** Gestapelte Charts für Leistung (Watt + $W'\text{bal}$), HF, Pace, Höhe und Trittfrequenz mit gemeinsamem Finger-Scrubber.
- [x] **Runden/Splits, Zonen-Verteilung & Leistungskurve:** Splits-Tabelle, Z1–Z5 Zeitbalken und Aktivitäts-Power-Curve im direkten Vergleich zur All-Time PR-Kurve.

### 35.4 Abschluss & Hardware-Verifikation
- [x] `flutter analyze --no-pub` & gezielte Unit-/Widget-Tests fehlerfrei.
- [x] Build & Installation auf Google Pixel 10 Pro via `adb install -r`.
- [x] Screenshot-Nachweis: Echte Aktivität im neuen Cockpit auf dem Pixel 10 Pro (`docs/beta/screenshots/phase35_release_pixel10.png`).
- [x] Merge in `main`, Tag `v0.35.0` setzen und pushen (`git push origin main --tags`).
