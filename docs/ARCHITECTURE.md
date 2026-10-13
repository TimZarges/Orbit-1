# Architektur & Technische Konventionen (ORBIT v1.0)

> Dieses Dokument beschreibt die verbindliche technische Architektur der ORBIT-Plattform.
> Stand: Release-Stand Phase 16.

---

## 1. Verzeichnisstruktur (Feature-First)

Die App folgt einem konsequenten Feature-First-Ansatz. Features sind in sich geschlossen und teilen sich nur explizit freigegebene Komponenten im `core`-Layer.

```text
lib/
├── core/                  # App-weite Grundlagen
│   ├── design/            # AppColors, AppTheme, Volt-Regeln, Widget-Galerie
│   ├── metrics/           # Zonenmodelle (Z1–Z7), Vorschau-Formeln
│   └── widgets/           # InfoTerm, wiederverwendbare Basis-Komponenten
├── features/              # UI und Geschäftslogik nach Feature gekapselt
│   ├── activities/        # Cockpit, Telemetrie, Rundenvergleich, TodayTabScreen
│   ├── auth/              # Authentifizierung, Onboarding, Rollen (ATHLETE / TRAINER)
│   ├── calendar/          # Monats-/Wochenkalender, Soll-Ist-Abgleich
│   ├── chat/              # 1:1 Echtzeit-Chat, Snapshot-Sharing, FCM-Pushs
│   ├── coach_link/        # Trainer-Athlet-Verknüpfung, Kader-Raster, Massenzuweisung
│   ├── diagnostics/       # Schwellenwert-Erkennung (FTP, LTHR, CSS), geführte Feldtests
│   ├── home/              # Dynamischer HomeCardResolver, Volt Daily Ring
│   ├── profile/           # Profil, Schwellenwerte, Saisonziel-Modal
│   ├── settings/          # Einstellungen, Garmin Connect OAuth, Datenschutz-Sheet
│   └── workout_builder/   # Strukturierter Trainingseditor, Vorlagenbibliothek
├── l10n/                  # ARB-Dateien & Lokalisierungs-Code (de / en)
└── main.dart              # App-Einstiegspunkt & Flavor-Initialisierung
```

---

## 2. State-Management (Riverpod)

Wir setzen auf `flutter_riverpod` (v2):
- **Unidirektionaler Datenfluss:** Widgets lauschen deklarativ auf Provider via `ref.watch()`.
- **Ressourceneffizienz:** `autoDispose` auf temporären Ansichts-Providern verhindert Memory-Leaks und offene Streams.
- **Repository-Pattern:** UI-Widgets kommunizieren niemals direkt mit Firebase, sondern stets über Provider und Domain-Services.

---

## 3. Datenarchitektur & Backend-First

- **Metriken serverseitig:** Sämtliche physiologischen Kennzahlen (TSS, Normalized Power, Intensity Factor, CTL/ATL/TSB, Bestwerte) werden im Cloud Functions Backend (2nd Gen, `europe-west3`) berechnet. Im Client existieren ausschließlich leichtgewichtige Vorschau-Varianten für den Workout Builder.
- **Zeitreihen-Optimierung:** Roh-Streams (z. B. 10 Hz Sensordaten) werden beim Import auf 1 Hz resampled und als `.json.gz` in Google Cloud Storage abgelegt. Firestore-Hauptdokumente bleiben schlank ($< 20\text{ KB}$), wodurch das 1-MB-Firestore-Limit niemals überschritten wird.
- **O(1) Coach-Aggregation:** Für Trainer pflegen Cloud Functions serverseitig aggregierte Dokumente unter `coachDashboard/{coachId}/athletes/{athleteId}`. Ein Trainer lädt 25+ Athleten mit einer einzigen Abfrage.

---

## 4. Routing & Athlete-Kontext

- Deklarative Navigation mit `go_router`.
- **Athlete-Kontext:** Alle Athleten-Screens hängen von einer `athleteId` ab (eigene UID bei Athleten oder die UID des ausgewählten Athleten, wenn ein Trainer den Screen öffnet). Es wird niemals `currentUser.uid` fest in Feature-Screens verdrahtet.

---

## 5. Sicherheit & Datenschutz (DSGVO Art. 9)

- **Least-Privilege Security Rules:** Grundsatz „Deny all" in `firestore.rules` und `storage.rules`.
- **Rollen-Integrität:** Rollen (`role`), Verknüpfungen (`coachId`) und Trainerverifizierungen sind niemals vom Client beschreibbar.
- **Granulare Freigaben:** Trainer erhalten nur Zugriff auf Kalender, Aktivitäten oder Gesundheitsdaten, wenn der Athlet das entsprechende Recht (`calendar`, `activities`, `health`) explizit aktiviert hat.
- **Souveränität:** Schwellenwert-Vorschläge können vom Trainer eingereicht, aber ausschließlich vom Athleten übernommen werden.
