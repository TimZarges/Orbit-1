# Entscheidungen (ADR-Log)

> Jede nicht triviale Entscheidung bekommt einen Eintrag: Datum, Kontext, Entscheidung, Begründung, Alternativen. Neueste oben.

## Vorlage
### YYYY-MM-DD: Titel
- **Kontext:**
- **Entscheidung:**
- **Begründung:**
- **Alternativen:**

---

## Bereits festgelegt (vor Projektstart)
- **Geplant ≠ absolviert:** getrennte Collections `plannedWorkouts` und `activities`, gegenseitig verknüpft.
- **Navigation:** rollenabhängig, 4 Tabs je Rolle, Profil hinter dem Avatar.
- **Erfahrungsstufen** Einfach/Fortgeschritten/Experte steuern Datendichte und Begriffe.
- **Metriken serverseitig**, Dart nur Vorschau, gemeinsame Testvektoren.
- **Coach-Zugriff** über denormalisiertes `coachId`, gepflegt per Function.
- **Webhook-Verarbeitung** über `webhookEvents` + Firestore-Trigger (kein Cloud Tasks im MVP).
- **Login:** Google + E-Mail/Passwort; Apple mit iOS-Start.
- **Score-Name:** „ORBIT Score" (nicht „MATS Score").
- **Tooling: Antigravity.** Zentrale Regeln in `AGENTS.md`, modulare Regeln in `.agents/rules/` (glob/model_decision), wiederverwendbare Abläufe als **Skills** in `.agents/skills/`. Workflows werden nicht genutzt, weil sie laut Antigravity-Doku am 1. November 2026 abgeschaltet werden.
- **Repo ist privat.** `google-services.json` darf (nach Rückfrage im Audit) committet werden. Service-Account-Schlüssel, Keystores, `.env` und Secrets nie.
- **Autopilot-Modus** (`/phase-run`): STOPP-Punkte werden zu Checkpoints in `docs/CHECKPOINTS.md`, Branches werden gestapelt, harte Stopps nur bei Blockern, Irreversiblem, Regelverstoß, Audit-Befund oder wiederholtem Fehler. Zweck: maximale Selbstständigkeit bei sichtbaren Review-Schulden.

### 2026-10-08: Architektur-Fundament
- **Kontext:** Neuaufsetzen des Projekts von Null.
- **Entscheidung:** Nutzung von `flutter_riverpod` für State-Management, `go_router` für Routing und Dart 3 Records + `freezed`/`json_serializable` für komplexe Modelle.
- **Begründung:** Sauberster Ansatz für Skalierung, Typsicherheit und Wartbarkeit gemäß `DESIGN.md` und `REQUIREMENTS.md`. Compile-Time Safety bei Providern und Immutable Data Models.
- **Alternativen:** BLoC (mehr Boilerplate) oder Provider (weniger typsicher, schwerer zu testen).

### 2026-10-08: FIT-Parsing
- **Kontext:** Umgang mit `.fit`-Dateien (von Garmin etc.) und dem `fit_sdk`.
- **Entscheidung:** FIT-Parsing wird ausschließlich serverseitig (Node.js Cloud Functions mit `@garmin/fitsdk`) durchgeführt.
- **Begründung:** Der Flutter-Client muss nicht die Last des Parsings tragen. Der Client lädt die rohen Dateien nur hoch und zeigt die serverseitig aufbereiteten, gesampelten Metriken an. Das hält die App leichtgewichtig und zentralisiert die Logik.
- **Alternativen:** Client-seitiges Parsing (führt zu hohem RAM-Bedarf und großen App-Binaries).

### 2026-10-08: Karten-Bibliothek (Spike S2)
- **Kontext:** Wahl der Map-Library für GPS-Routen im Cockpit.
- **Entscheidung:** Nutzung von `flutter_map` mit datenschutzkonformen Tiles statt `google_maps_flutter`.
- **Begründung:** Gesundheitsdaten und IP-Übertragungen an Google erfordern hohe DSGVO-Hürden. `flutter_map` bietet ausreichende Performance für unsere Polylines und lässt sich gut in den Dark Mode integrieren.

### 2026-10-08: Chart-Bibliothek (Spike S1)
- **Kontext:** Performance von Telemetrie-Charts bei >7.000 Datenpunkten.
- **Entscheidung:** Nutzung von `fl_chart` in Kombination mit starkem Downsampling (serverseitig oder Client-seitig auf max. 500 Punkte).
- **Begründung:** Ein kompletter CustomPainter für interaktives Chart-Scrubbing ist zu aufwendig. Mit gedownsampleten Daten performt `fl_chart` ausreichend gut und ist deutlich wartbarer.

### 2026-10-08: FIT-Dateiverarbeitung und ESM Import
- **Kontext:** Das Garmin `@garmin/fitsdk` ist ein reines ES-Module, aber Cloud Functions nutzen per Default CommonJS (v20).
- **Entscheidung:** Das `@garmin/fitsdk` wird über dynamische `import()` Aufrufe in der Laufzeit eingebunden, statt die komplette Cloud Function auf ESM umzustellen.
- **Begründung:** Verhindert tiefgreifende Umbauten des Build-Setups für die Cloud Functions, ermöglicht aber dennoch die Nutzung des offiziellen SDKs.
- **Alternativen:** Komplettes TypeScript Setup auf ESM umstellen (komplex mit jest/firebase) oder externe Konverter nutzen.
