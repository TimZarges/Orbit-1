# PHASE 37 — Kalender-Echtzeit-Sync, Visueller Workout-Builder (Garmin/MATS-Vorbild), Block-Konsistenz, Detail-Aktionen & Triathlon/Wettkampf-Planung

## Modus & Zielsetzung
- **Branch:** `feature/phase-37-calendar-workout-builder`
- **Ziel-Release:** `v0.37.0`
- **Ziel:** Reaktive Echtzeit-Kalendersynchronisation (`snapshots()`), einheitliches Kartendesign über alle Kalenderansichten, konsistente 1:1 Block-Berechnung, interaktive Workout-Aktionen (+1 Tag, Datum wählen, Überspringen), mobiler Klick-Block Builder mit Wiederholungsschleifen (2x–30x), Koppeleinheiten und A/B/C Wettkampf-Planung.
- **Status:** **[ ] In Bearbeitung**

---

## Arbeitspakete

### 37.1 Kalender-Echtzeit-Synchronisation (`snapshots()`) & Einheitliche Karten
- [x] Umstellung aller Kalender- und Dashboard-Provider auf zeitfenster-begrenzte Firestore-Streams (`snapshots()`).
- [x] Jede Änderung (Planung, Verschiebung, Löschung) spiegelt sich sofort reaktiv in der UI wider (ohne Neustart oder Relogin).
- [x] Einheitliches Kartendesign über Wochenansicht, Listenansicht, Monatsansicht und „Heute“-Screen inkl. Blockprofil-Vorschau und Ziel-Leistung/Pace.

### 37.2 Exakte Block-Berechnung & Funktionierendes Trainings-Detail-Sheet
- [x] 1:1 Konsistenz zwischen Titel/Beschreibung und Block-Grafik (z. B. 4x4min Intervalle zeigt exakt 10 Blöcke: Warmup + 4x [Arbeit + Pause] + Cooldown).
- [x] Detaillierte Schritt-für-Schritt Blockliste mit individuellen Watt-, Pace- und HF-Zielwerten des Athleten direkt im `workout_detail_sheet.dart`.
- [x] Reaktive Aktions-Buttons:
  - „Auf morgen verschieben“: `scheduledDate += 1 Tag` in Firestore.
  - „Datum wählen…“: Deutscher DatePicker (`DD.MM.YYYY`) mit sofortiger Verschiebung.
  - „Als übersprungen markieren“: Status auf `SKIPPED` mit visueller Rückmeldung.

### 37.3 Mobiler Klick-Workout-Builder (Garmin/MATS/Coros/Pushing Limits)
- [x] Deutsche Blocktypen mit semantischer Farbkodierung:
  - `Aufwärmen` (Türkis/Blau)
  - `Intervall / Belastung` (Volt/Gelb/Orange/Rot je nach % Intensität)
  - `Erholung / Pause` (Dezentes Slate/Grau)
  - `Ausrollen` (Grün)
  - `Wiederholungs-Serie (Intervall-Schleife)`: Container mit einstellbarer Häufigkeit `2x` bis `30x`.
- [x] Einstellbare Block-Parameter: Dauer (min/sec) oder Distanz (m/km), Intensität in % des Schwellenwerts mit Live-Umrechnung in Watt/Pace.
- [x] Strukturierte Vorlagen-Felder: Fester Titel, allgemeine Beschreibung (Trainerhinweise) und einheitsspezifisches Notizfeld.

### 37.4 Triathlon- & Brick-Sessions sowie Wettkampf-Planung (A / B / C)
- [ ] Planung von Mehrfacheinheiten am selben Tag.
- [ ] Spezifische Sportart „Triathlon / Koppeleinheit“ mit Disziplinwechseln (*Schwimmen ⇄ Rad ⇄ Lauf*).
- [ ] Modus-Umschaltung im Planer: „Training planen“ vs. „Wettkampf / Rennen planen“.
- [ ] Wettkampf-Felder: Name, Datum, Sportart/Distanz, Zielzeit und Priorität (`A-Hauptwettkampf`, `B-Vorbereitungsrennen`, `C-Trainingswettkampf`).

### 37.5 Abschluss & Hardware-Verifikation
- [ ] `flutter analyze --no-pub` & Tests fehlerfrei.
- [ ] Build & Installation auf Google Pixel 10 Pro via `adb install -r`.
- [ ] Screenshot-Nachweise: Neuer Workout-Builder mit Loop, Detail-Sheet mit Blöcken, Wettkampf-Planung.
- [ ] Merge in `main`, Tag `v0.37.0` setzen und pushen.
