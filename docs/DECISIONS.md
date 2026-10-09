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

### 2026-10-09: Metrik-Methoden (Phase 05)
- **Kontext:** Berechnung von Belastungswerten (TSS, CTL, ATL, etc.) für Rad, Lauf und Schwimmen.
- **Entscheidung & Begründung:**
  1. **Lauf-Belastung:** Primär **rTSS** (basierend auf Pace & Threshold Pace), da es die mechanische Belastung besser abbildet. Fallback auf **hrTSS** (basierend auf HF & Schwellen-HF), falls GPS/Pace unzuverlässig (z.B. Indoor) aber HF vorhanden ist.
  2. **sTSS (Schwimmen):** `sTSS = (Dauer_in_h) * (IF^3) * 100`, wobei `IF = Normalized Pace / Critical Swim Speed (CSS)`. Da Wasserwiderstand kubisch wächst, ist die dritte Potenz fachlich korrekt.
  3. **Behandlung fehlender Daten:** 
     - Keine FTP/Schwellenwerte: Berechnung mit Standard-Schätzwerten (z.B. HF-Max-Formel), Metrik-Qualität wird als `INSUFFICIENT` markiert.
     - Indoor ohne Leistung/Pace: Fallback auf hrTSS. Wenn auch keine HF, dann `TSS = 0` (oder manuelle RPE-Eingabe in Phase 09).
  4. **CTL/ATL-Modell:** Exponentieller gleitender Durchschnitt (EMA). CTL-Konstante = 42 Tage, ATL = 7 Tage. Startwert bei neuen Athleten ist 0 (baut sich über 6 Wochen auf, Option zur manuellen Vorgabe in Profil-Einstellungen).
  5. **NP (Glättung & Nullwerte):** 30-Sekunden gleitender Durchschnitt. Datenlücken < 30s werden als 0-Watt gewertet (verhindert das künstliche "Schönrechnen" bei Tretpausen).
  6. **Umgang mit langen Pausen:** Pausen > 30s (z.B. Ampel, Kaffeepause) setzen das 30s-Fenster zurück (verhindern Verzerrung durch extrem lange Null-Phasen im Moving Average).
- **Alternativen:** TRIMP statt hrTSS (weniger vergleichbar mit Rad-TSS), simple Durchschnitts-Pace statt rTSS.
