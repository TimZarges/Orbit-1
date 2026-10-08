# Phase 00: Audit, Fundament, Design-System, Spikes

**Branch:** `feature/phase-00-foundation` · **Voraussetzungen:** keine (Firebase-Projekte aus `MANUAL_STEPS.md` idealerweise angelegt; sonst Emulator-only starten und melden)

## Ziel
Eine lauffähige, sauber strukturierte Flutter-App mit zentralem Design-System, rollenabhängiger Navigation (Platzhalter-Screens), Dev/Prod-Trennung, CI und belastbaren Entscheidungen zu Charts, Karte, State-Management und Modellen. Der bestehende Code wird verstanden und respektiert, nicht überschrieben.

## Vorher lesen
`AGENTS.md`, `docs/DESIGN.md`, `docs/DATA_MODEL.md` (überfliegen), `docs/REQUIREMENTS.md`, den **gesamten bestehenden Code** (`main.dart`, `training_zones_model.dart`, `telemetry_chart_widget.dart` und alles weitere in `lib/`), `pubspec.yaml`.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Audit:** Bestehenden Code vollständig lesen. Ergebnis in `docs/AUDIT.md`: Struktur, Zustand je Feature (fertig / Platzhalter / kaputt), vorhandene Design-Tokens vs. `docs/DESIGN.md` (Abweichungen!), technische Schulden, Auffälligkeiten (z. B. Secrets im Repo, tote Abhängigkeiten, Zustand von `fit_sdk`).
2. **STOPP 1 [RISIKO-MITTEL]:** Audit-Bericht + Vorschlag für Zielstruktur und Entscheidungen (State-Management, Routing, Modelle). Ich gebe frei.
3. **Projekt lauffähig machen:** `flutter pub get`, `flutter analyze`, Start auf Android-Emulator. `analysis_options.yaml` mit `flutter_lints` + sinnvollen Zusatzregeln. Secrets prüfen (`.gitignore`, keine Keys im Repo; falls doch, mir sofort melden).
4. **Entscheidungen** (jeweils kurz in `docs/DECISIONS.md`):
   - State-Management (Vorschlag `flutter_riverpod`), Routing (Vorschlag `go_router` mit Auth- und Rollen-Guard).
   - Modelle: `freezed`/`json_serializable` **oder** reines Dart 3 (sealed classes, Records). Bewerte Reibung durch `build_runner`.
   - `fit_sdk` im pubspec: ist es gepflegt und nötig? Entscheidung: FIT-Parsing **nur serverseitig** (`@garmin/fitsdk`). Unnötige Abhängigkeit entfernen.
5. **Struktur** feature-first einführen: `lib/core/{design,l10n,routing,widgets,utils,errors}`, `lib/data/{repositories,models,services}`, `lib/features/<feature>/`. Bestehenden Code **verschieben statt neu schreiben**.
6. **Dev/Prod:** Android-Flavors `dev` und `prod`, getrennte Firebase-Konfiguration (`firebase_options_*.dart` bzw. FlutterFire-Konfiguration je Flavor), App-Name/Icon-Badge je Flavor erkennbar. `firebase.json`, `.firebaserc`, Emulator-Suite (Auth, Firestore, Storage, Functions) konfigurieren. Functions-Gerüst (`functions/`, TypeScript, 2nd Gen, Region `europe-west3`) inkl. Test-Setup.
7. **CI:** GitHub Actions: `flutter analyze` + `flutter test`, Functions `npm ci && npm run build && npm test`. Läuft auf Pull Requests.
8. **Crashlytics und App Distribution** im Code vorbereiten (Initialisierung, Opt-in/Consent-Hook, nur im Release-Flavor aktiv), damit ich früh auf dem echten Gerät teste. Konsolenschritte in `MANUAL_STEPS.md`.
9. **Design-System** nach `docs/DESIGN.md` in `lib/core/design/` umsetzen: Farben (Brand, Zonen, Kanäle, Sport-Identität), Typografie-Skala, Spacing, Motion, Theme (hell/dunkel/Cockpit) als ThemeExtensions. Inter + Playfair als **gebündelte Assets**. Werte aus dem bestehenden Code **übernehmen** und Abweichungen zu `DESIGN.md` dokumentieren. Kontrast-/Farbsehschwäche-Check der Zonen- und Kanalfarben (kurz in `docs/DECISIONS.md`).
10. **Widget-Galerie** (Debug-Route) mit Kernkomponenten (Card, Button/Volt-CTA, Chip, Metric-Anzeige mit Einheit, Zonenbalken, Ampel, Empty State, Skeleton) in hell/dunkel/Cockpit und Textskalierung 1,0/1,3. **Golden Tests** für diese Komponenten.
11. **App-Shell:** `go_router` mit rollenabhängiger Navigation laut `docs/DESIGN.md` §7 (Athlet: Heute/Plan/Analyse/Coach, Trainer: Athleten/Kalender/Nachrichten/Bibliothek, Avatar oben rechts → Profil), Responsive-Breakpoints (BottomNav/Rail), Lokalisierung (`gen_l10n`, de + en, de ist Standard), alles mit **Platzhalter-Screens** im gestalteten Empty-State. Rolle vorerst über Debug-Schalter umschaltbar.
12. **Spikes** (Ergebnisse als Entscheidung in `docs/DECISIONS.md`):
    - **S1 Chart-Performance:** synthetischer 2-h-Datensatz (ca. 7.200 Punkte, 4 Kanäle). Vergleich `fl_chart` vs. `CustomPainter` (mit Downsampling). Baue ein kleines Benchmark-Screen (Debug) mit Frame-Zeit-Anzeige. **Ich messe auf dem Gerät im Profile-Mode** (Schritt in `MANUAL_STEPS.md`). Empfehlung ableiten.
    - **S2 Karte:** Optionen vergleichen (z. B. `flutter_map` mit EU-/selbst gehostetem Tile-Anbieter vs. Google Maps). Kriterien: DSGVO (IP-Weitergabe), Nutzungsbedingungen/Kosten, Android-Performance, Polyline mit synchronem Marker. Empfehlung + Begründung, noch nicht integrieren.
13. **STOPP 2 [RISIKO-MITTEL]:** Zwischenbericht zu Spikes, Design-System und Shell. Ich gebe frei (insbesondere Chart- und Kartenentscheidung).
14. Doku: `docs/ARCHITECTURE.md` (Überblick Struktur, Datenfluss, Konventionen), `docs/PROGRESS.md`, `docs/MANUAL_STEPS.md` aktualisieren.

## STOPP-Punkte
- **STOPP 1 [RISIKO-MITTEL]** nach Aufgabe 1 (Audit + Entscheidungsvorschlag)
- **STOPP 2 [RISIKO-MITTEL]** nach Aufgabe 12 (Spikes, Design-System, Shell)

## Nicht-Ziele
Kein Login, keine echten Daten, keine Firestore-Features, keine Garmin-Anbindung, keine Inhalte der Screens über Empty States hinaus.

## Abnahme
### Automatisch prüfbar
- [ ] `flutter analyze` ohne Warnungen, `flutter test` grün (inkl. Golden Tests)
- [ ] CI-Workflow vorhanden und lokal nachvollziehbar (Befehle laufen)
- [ ] Functions bauen und Testlauf grün
- [ ] Keine hartkodierten Farben/Schriften/Strings in `lib/features/` (Stichprobe per Suche)
- [ ] `docs/AUDIT.md`, `DECISIONS.md`, `ARCHITECTURE.md` vorhanden
### Manuell (ich)
- [ ] App startet als `dev`-Flavor auf meinem Android-Gerät, Navigation in beiden Rollen funktioniert
- [ ] Design wirkt wie das bisherige (Navy/Volt, Inter), Galerie sieht gut aus
- [ ] Chart-Spike auf dem Gerät gemessen (Profile-Mode) und Ergebnis gemeldet

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `MANUAL_STEPS.md` aktualisiert.
