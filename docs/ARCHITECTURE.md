# Architektur & Konventionen

Dieses Dokument beschreibt die technische Architektur der ORBIT-App und dient als Leitfaden für neue Features.

## 1. Verzeichnisstruktur (Feature-First)
Die App folgt einem Feature-First Ansatz. Features sind gekapselt und teilen sich nur explizit freigegebene Komponenten im `core` oder `data` Layer.

```text
lib/
├── core/              # App-weite Grundlagen (Design-System, Routing, Fehlerbehandlung, l10n, Basis-Widgets)
├── data/              # Daten-Layer (Repositories, API Services, DTOs/Domain Models)
├── features/          # UI und Geschäftslogik nach Feature gekapselt
│   ├── auth/          # Login, Onboarding
│   ├── calendar/      # Kalenderansichten, Workouts
│   ├── dashboard/     # Home-Screen
│   └── ...            # Weitere Features
└── main.dart          # App-Einstiegspunkt
```

## 2. State-Management
Wir nutzen `flutter_riverpod` für das State-Management.
- **Provider:** Definieren globale Zustände und fassen Logik zusammen.
- **ConsumerWidget:** UI-Komponenten reagieren reaktiv auf Provider.
- Vermeide direkte `setState`-Aufrufe in komplexen Widgets.

## 3. Datenfluss & Modelle
- **Dart 3:** Wir nutzen Records und Sealed Classes für Pattern Matching und leichte Datenstrukturen.
- **Freezed:** Für Firestore-Modelle und komplexe State-Objekte nutzen wir `@freezed` und `json_serializable` für Immutability und Typsicherheit.
- **Backend-First:** Metriken, FIT-Dateien und komplexe Berechnungen (z.B. ORBIT Score) werden im Cloud Functions Backend berechnet, nicht im Client.

## 4. Routing
- Wir nutzen `go_router`.
- Die Navigation wird deklarativ beschrieben. Ein `GoRouter` Guard entscheidet anhand des `role`-Felds des aktuellen Nutzers (Athlet vs. Trainer), welche Routen zugelassen sind.

## 5. Design-System
- Keine hartkodierten Farben oder Abstände in den UI-Komponenten!
- Alle Werte stammen aus dem Design-System in `lib/core/design/` (ThemeExtensions), angelehnt an `docs/DESIGN.md`.

## 6. Dev/Prod Flavors
- Getrennte Firebase-Umgebungen (`orbit-dev`, `orbit-prod`).
- Entsprechende Konfiguration in `firebase_options_dev.dart` und `firebase_options_prod.dart`.
