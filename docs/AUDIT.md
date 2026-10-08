# Audit Bericht (Phase 00)

## Ausgangslage
Das Repository ist aktuell komplett leer (bis auf die übernommenen Antigravity-Konfigurations- und Dokumentationsdateien). Es gibt **keinen bestehenden Flutter-Code**, keine `lib/`, keine `pubspec.yaml` und keine `test/`-Ordner. 

Dieses Projekt stellt den kompletten Neuaufbau von "Orbit" ("Orbit - 1") dar. Da kein Altsystem in diesem Verzeichnis liegt, entfallen Migrationen oder das Verschieben von Legacy-Code.

## Auffälligkeiten
- **Keine Secrets oder Keys im Repo:** Da noch kein Code existiert, sind auch keine versehentlichen Secrets committet worden. Die `.gitignore` muss nach der Flutter-Initialisierung aber entsprechend um die Firebase/Keystore-Einträge aus `00_ANLEITUNG_ANTIGRAVITY.md` ergänzt werden.
- **`fit_sdk` Zustand:** Da keine `pubspec.yaml` existiert, gibt es auch kein veraltetes `fit_sdk` Package auf Client-Seite. Wir können direkt die empfohlene Entscheidung treffen, FIT-Parsing ausschließlich serverseitig (z.B. `@garmin/fitsdk` in Cloud Functions) zu implementieren.

## Vorschlag für Zielstruktur & Entscheidungen
Auf Basis von `docs/DESIGN.md`, `docs/DATA_MODEL.md` und `docs/REQUIREMENTS.md` schlage ich folgende Architektur für den Neuaufbau vor:

### 1. State-Management
**Empfehlung: `flutter_riverpod`**
- Bietet Compile-Time Safety und hervorragendes Caching.
- Eignet sich ideal für die Trennung von UI und Business-Logik und macht Abhängigkeiten explizit.

### 2. Routing & Navigation
**Empfehlung: `go_router`**
- Rollenbasierte Navigation (Athlet vs. Trainer) kann über Router-Redirects und Guards (z.B. Redirect auf Basis des `role`-Felds des aktuellen Nutzers) elegant umgesetzt werden.
- Unterstützt Deeplinks out-of-the-box (wichtig für spätere Push-Benachrichtigungen oder Chat).
- Eine BottomNavigationBar/NavigationRail (ShellRoute) lässt sich hiermit sehr gut realisieren.

### 3. Modelle & Datenserialisierung
**Empfehlung: Dart 3 (Sealed Classes & Records) + `freezed` / `json_serializable`**
- Für komplexe Domain-Modelle (insb. Firestore-Daten) ist `freezed` zusammen mit `json_serializable` weiterhin Goldstandard bzgl. Typsicherheit, Immutability und `copyWith`-Methoden. Der Overhead durch `build_runner` ist auf modernen Rechnern minimal.
- Für reine interne UI-States oder Pattern Matching nutzen wir Dart 3 native Features.

### 4. Ordnerstruktur (Feature-First)
```text
lib/
├── core/
│   ├── design/        # Design-System (Farben, Typografie nach DESIGN.md)
│   ├── errors/        # Fehlerbehandlung
│   ├── l10n/          # Lokalisierung (gen_l10n)
│   ├── routing/       # go_router Setup & Guards
│   ├── utils/         # Helfer
│   └── widgets/       # Shared UI-Komponenten (Widget-Galerie)
├── data/
│   ├── models/        # DTOs und Domain Models
│   ├── repositories/  # Datenabstraktion (Firebase etc.)
│   └── services/      # Externe APIs, Firebase Services
├── features/
│   ├── auth/
│   ├── calendar/
│   ├── chat/
│   ├── dashboard/
│   └── settings/
└── main.dart
```

### 5. `fit_sdk`
FIT-Parsing wird ausschließlich serverseitig (Node.js Cloud Functions) umgesetzt. Der Flutter-Client schickt rohe Dateien nur an Cloud Storage / API und empfängt aggregierte Metriken. Das hält den Client leicht.
