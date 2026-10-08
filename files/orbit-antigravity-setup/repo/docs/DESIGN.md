# ORBIT Design-System

> **Quelle der Wahrheit ist der bestehende Code** (`ThemeData` in `main.dart`, `training_zones_model.dart`, `telemetry_chart_widget.dart`).
> Weichen Werte hier vom Code ab, gilt der Code. Abweichung in `docs/DECISIONS.md` notieren und mich fragen, wenn sie das Erscheinungsbild merklich ändert.
> Alle Werte werden zentral in `lib/core/design/` abgelegt (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_motion.dart`, `app_theme.dart`, ThemeExtensions). **Nie** Farben, Größen oder Texte in Widgets hartkodieren.

## 1. Leitbild
**„Precision Performance & Dark-Cockpit Data Density"**, zwei Welten:
- **Helle Welt:** Heute, Plan, Coach, Chat, Profil, Workout Builder. Aufgeräumt, gut lesbar, Hintergrund `#FFFFFF` / `#F8FAFC`.
- **Dunkle Welt („Cockpit"):** Analyse-Details, Telemetrie, Karte, Power-Kurve. Hintergrund `#0F172A`. Hier leuchten Signalfarben.
- Cockpit-Bereiche sind **immer** dunkel. Die App bietet zusätzlich Hell/Dunkel/Auto (Einstellungen). Das dunkle App-Theme nutzt die Cockpit-Tokens als Basis.

## 2. Farben
| Rolle | Wert |
|---|---|
| Brand / Typografie / Navigation | Deep Navy `#001F47` (Variante `#00357A`) |
| Akzent / CTA / aktiver Zustand / PR | Performance Volt `#CDFB17` |
| Flächen | `#FFFFFF`, `#F8FAFC` (alt: Tech Grey `#F2F3F4`) |
| Cockpit | `#0F172A` (alt. `#001F47`) |
| Card-Border | `#E2E8F0` |

**Volt-Regel:** Volt hat auf Weiß zu wenig Kontrast. Volt nur als **Fläche mit Navy-Text** (Buttons, Badges) oder **auf dunklem Grund** (Ringe, Linien). Nie als Textfarbe auf Weiß. Kontraste nach WCAG AA prüfen.

**Daily Ring:** liegt auf einer **Navy-Hero-Card**, Ring in Volt, Track in Navy-Hell (z. B. 20 % Weiß). Nicht auf weißem Grund.

## 3. Drei getrennte Farbsysteme (nie vermischen)

### 3.1 Zonen Z1–Z7 (Belastungsintensität)
Z1 `#A0AEC0` · Z2 `#3182CE` · Z3 `#38A169` · Z4 `#DD6B20` · Z5 `#E53E3E` · Z6 `#9F7AEA` · Z7 `#D53F8C`
- Zonen erscheinen als **Balken mit Beschriftung (Z1…Z7)** oder in Charts als **dezentes Hintergrundband (≤ 15 % Deckkraft)**.
- Rot-Grün-Schwäche: Z3/Z4/Z5 dürfen **nie allein über Farbe** unterscheidbar sein. Immer Zonennummer oder Label dazu. Mit Farbsehschwäche-Simulation prüfen.

### 3.2 Telemetrie-Kanäle (nur Linien im Cockpit)
**Problem im alten Entwurf:** Kadenz (`#38A169`), Temperatur (`#DD6B20`) und HF (`#E53E3E`) hatten dieselben Hex-Werte wie Zonen. Deshalb eigene, hellere Varianten (auf `#0F172A` kontrastreich). **Vorschlag, gegen den Code und die Kontraste in Phase 0 prüfen:**

| Kanal | Wert |
|---|---|
| Leistung (Watt) | `#F6C453` |
| Herzfrequenz | `#FF6B6B` |
| Pace/Speed (Lauf/Rad) | `#22D3EE` |
| Schwimm-Pace/SWOLF | `#818CF8` (neu, klar von Pace-Cyan getrennt) |
| Kadenz | `#4ADE80` |
| Höhe | `#94A3B8` (als weiches Backdrop-Band) |
| Kerntemperatur | `#FB923C` |

### 3.3 Sport-Identität (Kalender, Listen, Icons; helle Welt)
Schwimmen `#0EA5E9` · Rad `#F59E0B` · Lauf `#10B981` · Kraft `#64748B` · Multisport Navy `#001F47`.
Immer **Icon + Farbe** zusammen, nie nur Farbe. (Vorschlag, in Phase 0 gegen vorhandene Werte prüfen.)

## 4. Typografie
- Schriften: **Inter** (Variable Font, eine Datei) und **Playfair Display Italic**, beide als **Assets gebündelt** (kein Laufzeit-Abruf bei Google, DSGVO).
- **Skala** (sp, Mindestgröße 12):

| Stil | Größe | Gewicht |
|---|---|---|
| `display` | 32 | Inter Black |
| `headline` | 24 | Inter Black |
| `title` | 18 | Inter SemiBold |
| `body` | 16 | Inter Regular |
| `bodySmall` | 14 | Inter Regular |
| `label` | 12 | Inter Medium |
| `metric` | 28–40 | Inter Bold, **tabular figures** |
| `quote` | 18–20 | Playfair Display Italic (sparsam) |

- **Inter Black erst ab ca. 24 sp**, darunter wirkt es auf dem Handy zu wuchtig.
- Metriken: fette Zahl + kleine, dezente Einheit („285 **W**", „142 **bpm**"). Immer `FontFeature.tabularFigures()`.
- Textskalierung bis 1,3× darf kein Layout brechen.

## 5. Spacing, Form, Elevation, Motion
- Raster **4 dp** (Abstände: 4, 8, 12, 16, 24, 32). Seitenrand mobil 16.
- Cards: Radius 16, Border 1 px `#E2E8F0`, dezenter Schatten. Buttons/Inputs: Radius 12. Chips: voll gerundet.
- Elevation nur 3 Stufen (flach, Card, Sheet/Dialog).
- Motion: 150 ms (Mikro), 250 ms (Standard), 400 ms (Übergänge). Kurve `easeOutCubic`. Respektiere „Animationen reduzieren" des Systems. Haptik (Selection Click) bei Zonenwechsel/Scrubbing.
- Alles als `ThemeExtension`/Token, keine Zahlen im Widget-Code.

## 6. Mobile-First-Regeln
- Basis-Layout **360×800 dp**, dann hochskalieren. Tippflächen ≥ 48×48 dp. Primäre Aktionen im Daumenbereich (unten).
- Breakpoints: **Compact < 600** (BottomNav), **Medium 600–1024** (NavigationRail), **Expanded > 1024** (Rail + Mehrspalten, Fokus Coach).
- System-Insets (Notch, Gestennavigation), Tastaturverhalten (Chat, Formulare), sicherer Bereich beachten.
- Listen mit `ListView.builder`. `const`-Konstruktoren. Charts lazy laden. Große Zeitreihen vor dem Rendern downsamplen (z. B. LTTB). Schwere Berechnungen nicht im UI-Thread.
- Semantics-Labels für Screenreader. Kontrast AA.

## 7. Navigation (rollenabhängig)
**Athlet (4 Tabs):** `Heute` · `Plan` · `Analyse` · `Coach`
**Trainer (4 Tabs):** `Athleten` · `Kalender` · `Nachrichten` · `Bibliothek`
- **Profil/Einstellungen** liegen hinter dem **Avatar oben rechts**, kein eigener Tab.
- **Tab „Coach" ohne Trainer:** Einladungs-Screen („Trainer einladen / Einladungscode eingeben"), nie ein toter Chat.
- Workout Builder und Vorlagenbibliothek werden aus `Plan` heraus erreicht („Training planen").
- Trainer öffnen für einen Athleten dieselben Screens wie der Athlet (Kalender, Analyse) im **Athlete-Kontext** (`athleteId`). Ein klar sichtbarer Kopfbereich zeigt, wessen Daten man gerade sieht.

## 7a. Erfahrungsstufen (steuert Datendichte und Wortwahl)
Globale Einstellung `experienceLevel` (im Onboarding abgefragt, jederzeit änderbar): **Einfach · Fortgeschritten · Experte**.

| Konzept | Einfach | Fortgeschritten | Experte |
|---|---|---|---|
| CTL | Fitness | Fitness (CTL) | CTL |
| ATL | Ermüdung | Ermüdung (ATL) | ATL |
| TSB | Frische | Frische (TSB) | TSB |
| TSS | Belastung | Belastung (TSS) | TSS |
| NP | Gewichtete Leistung | Gewichtete Leistung (NP) | NP |
| IF | Intensität | Intensität (IF) | IF |

- *Einfach:* Ampeln, Ringe, kurze Klartexte, wenige Zahlen. Detail-Charts hinter „Mehr Details".
- *Fortgeschritten:* zusätzlich Zonenverteilung, Verlauf, Soll-Ist.
- *Experte:* alles, Rohkanäle, Fachkürzel, Power-Duration-Kurve ohne Umweg.
- **Jede Kennzahl** hat ein Info-Icon → Bottom Sheet mit kurzer, verständlicher Erklärung.
- Hinweis: TrainingPeaks beansprucht meines Wissens Markenrechte an einigen Kürzeln (TSS, NP, IF). Deshalb in der Standard-UI neutrale Begriffe. Vor Release rechtlich prüfen lassen.

## 8. Wichtige Komponenten und Muster
- **Chart-Scrubbing:** Ein Finger auf einem Chart in scrollbarer Seite kollidiert mit Scrollen. → **Long-Press-to-Scrub** oder Vollbild-Querformat-Chart. HUD erscheint **über** dem Finger. Scrubbing synchronisiert den Marker auf der Karte (und umgekehrt). Kanal-Chips schalten Linien ein/aus. Umschalter „Nach Zeit / Nach Distanz".
- **Ampel „Form"** mit Klartext und **Datenbasis** („basiert auf 6 Wochen Training"). Bei dünner Datenlage keine Empfehlung, sondern Hinweis.
- **Empty States** sind eigene, gestaltete Screens (kein leerer Bildschirm): First-Run mit „Garmin verbinden / FIT importieren / Demo ansehen", Fortschrittsanzeige beim Backfill.
- **Loading:** Skeleton-Loader statt Spinner bei Listen/Karten.
- **Fehler:** verständliche, lokalisierte Meldung + Wiederholen-Aktion.
- **Push-Rechte:** Berechtigung erst im Kontext anfragen (z. B. nach Coach-Verknüpfung), nicht beim Start. Android: Notification Channels pro Kategorie.

## 9. Qualitätssicherung UI
- **Widget-Galerie** (nur Debug-Route oder Widgetbook): alle Kernkomponenten in allen Zuständen (hell/dunkel, Textskalierung 1,0/1,3, leer/lädt/Fehler).
- **Golden Tests** für Kernkomponenten, damit Design-Abweichungen automatisch auffallen.
- Kontrast- und Farbsehschwäche-Prüfung der Zonen-/Kanalfarben dokumentieren.
