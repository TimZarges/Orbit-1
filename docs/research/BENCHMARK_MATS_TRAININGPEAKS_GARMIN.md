# ORBIT Benchmark-Analyse: MATS Coach, TrainingPeaks & Garmin Connect
**Erstellt:** 10. November 2026  
**Untersuchte Plattformen:** MATS.coach (Mobile & Web), TrainingPeaks (Mobile & Web), Garmin Connect (Web)  
**Basis:** 47 Mobile-Screenshots (`docs/research/screenshots/tp_mats/`), Live-Browser-Inspektion der geöffneten Desktop-Webanwendungen in Safari, sowie Abgleich mit der ORBIT-Architektur (`AGENTS.md`, `docs/DESIGN.md`, `docs/DATA_MODEL.md`).

---

## 1. Executive Summary & Produkt-Positionierung

ORBIT positioniert sich exakt im Schnittfeld der drei führenden Plattformen:

```
                  ┌───────────────────────────────────────┐
                  │              MATS.coach               │
                  │  • Minimalistisches, ruhiges UI       │
                  │  • Partnerschaftliches Coaching       │
                  │  • Verfügbarkeitsprofile & Check-in   │
                  │  • 2D RPE-Quadrant (Wohlbefinden/RPE) │
                  └──────────────────┬────────────────────┘
                                     │
                                     ▼
┌─────────────────────────┐       ORBIT       ┌─────────────────────────┐
│      TrainingPeaks      │ ◄───────────────► │     Garmin Connect      │
│ • Banister PMC (CTL/ATL)│                   │ • Hardware-Ökosystem    │
│ • EF, VI, Pw:Hr Drift   │                   │ • 24/7 Health-Baselines │
│ • MMP Power-Duration    │                   │ • FIT 1Hz Roh-Streams   │
│ • 7-Zonen-Modelle       │                   │ • Intensitätsminuten    │
└─────────────────────────┘                   └─────────────────────────┘
```

| Dimension | MATS.coach | TrainingPeaks | Garmin Connect | **ORBIT Ziel-Standard** |
| :--- | :--- | :--- | :--- | :--- |
| **Design & UX** | Modern, clean, viel Weißraum, reduzierte Farbpalette (Teal/Mint) | Datenlastig, tabellarisch, Enterprise-Look, steile Lernkurve | Dashboard-Kacheln, consumer-orientiert | **High-End Dark Navy (`#001F47`) mit Volt (`#CDFB17`), 120 FPS Mobile-First** |
| **Coaching-Beziehung** | Stark im Fokus: Check-in, Verfügbarkeitsprofil, Einladungs-Flow | Stark, aber primär textbasiert über Workouts & Kalender | Rein sozial / Community, keine Vereins-/Trainer-Schnittstelle | **Echtes Trainer-Athlet-Tandem, granulare Freigaben, direkte In-App Interaktion** |
| **Subjektives Feedback** | **2D-Quadrant** (Wohlbefinden vs. Intensität) | Einfacher Slider / Smiley (Gefühl 1–5, RPE 1–10) | Keine RPE-Erfassung nach Einheiten | **2D ORBIT Puck (RPE vs. Wohlbefinden) direkt nach Aktivitätsabschluss** |
| **Telemetrie-Tiefe** | Gut: HF, Leistung, Tempo, Zonen, 3-Zonen-Modell (LIT/MIT/HIT) | Exzellent: NP, IF, TSS, VI, EF, Pw:Hr, VAM, MMP-Kurve, 1Hz Sync | Gut: HF, Pace, Power, aber wenig aerobe Entkopplung/Drift | **Volle wissenschaftliche Tiefe (CP, W′bal, PMC, EF, VI, Pw:Hr)** |
| **Recovery & Health** | Ruhe-HF, einfacher Fragebogen | Ruhe-HF, Schlafstunden (Garmin Health), HFV | 24/7 HF, Schlafphasen, Body Battery, Intensitätsminuten | **3 Ringe (Erholung, Belastung, Schlaf), 30d-Baselines, Schlafanalyse** |

---

## 2. Detaillierte Systemanalyse: MATS.coach

### 2.1 UI & Design-Philosophie
- **Farbwelt & Typografie:** Sanftes Petrol/Teal (`#0F6B66`), dezentes Mint für Erfolgsstatus, Pastell-Cyan für geplante Einheiten, klare serifenlose Typografie mit hohem Kontrast.
- **Header & Navigation:** 
  - Fünf klare Bottom-Tabs: *Start*, *Kalender*, *AI Coach*, *Analyse*, *Mehr*.
  - Profil-Avatar oben rechts mit Status-Badge.
- **Tages-Check-in:** 
  - Prominente Karte: *„Kurzer Check-in wartet: 9 Fragen · ca. 45 Sek. für deine Readiness- und Krankheitsrisiko-Werte“*.
  - Schafft tägliche Verbindlichkeit und füllt subjektive Baselines, bevor das Training beginnt.

### 2.2 Der 2D RPE-Quadrant („MATS Score“)
- **Konzept:** Anstelle getrennter Schieberegler für Erschöpfung und Laune nutzt MATS einen zweidimensionalen Koordinaten-Puck:
  - **Y-Achse:** *Wohlbefinden* (Oben: Schlecht [Rot] → Unten: Sehr gut [Grün]).
  - **X-Achse:** *Intensität* (Links: Einfach [Grün] → Rechts: Schwer [Rot]).
- **Interaktion:** Der Athlet zieht den runden Puck mit 4-Wege-Pfeilen intuitiv in den passenden Quadranten.
- **Berechnung:** Ergibt einen normierten Score (z. B. `2,1`), der direkt in die Belastungs- und Erholungs-Matrix einfließt.

### 2.3 Workout Builder & Trainings-Bibliothek
- **Blöcke-System:** Strukturiert in *Warm up*, *Ramp up*, *Recovery*, *Repetitions (z. B. 2 steps rep · 8 Wiederholungen)*.
- **Visuelle Vorschau:** Stufenprofil-Balkendiagramm direkt über der Zeitangabe.
- **Sportwissenschaftliche Tags:** Workouts sind strikt getaggt nach Intensitätszonen: `#lit` (Low Intensity), `#mit` (Moderate Intensity), `#hit` (High Intensity).
- **Integrierte Ernährungsstrategie:** Eigener Menüpunkt *„••• Ernährung“* direkt im Workout-Planer, um Kohlenhydrat- und Hydrationsvorgaben an die Einheit zu koppeln.

### 2.4 Aktivitäts-Cockpit
- **Mehrstufige Reiter:** *Überblick*, *Tempo*, *Herzfrequenz*, *Kadenz*.
- **Farbcodierte GPS-Streckenlinie:** Die Route auf der Karte wird dynamisch nach der gewählten Metrik eingefärbt (z. B. Geschwindigkeits-Gradient von Rot [Schnell] bis Grün [Langsam], oder HF-Gradient).
- **Sportwissenschaftliche Modelle:**
  - **3-Zonen Polarized Modell:** Prozentuale Aufteilung in LIT, MIT und HIT (z. B. 100% LIT bei Grundlagenläufen) mit Ampelanzeige für polarisierte vs. pyramidale Verteilung.
  - **Critical Speed / Power Curve:** Logarithmische Distanzachse (50m, 112m, 250m, 559m, 1.3km, 2.8km, 6.3km) mit Allzeit- und Einheiten-Vergleich.
  - **Splits & Runden:** Klare tabellarische Aufschlüsselung von Kilometersplits mit Höhenmeter-Zuwachs und Durchschnittspuls.

### 2.5 Trainer-Athlet-Verbindung
- Eigener Bereich *„Trainer verwalten“* mit virtuellem Einladungscode.
- **Verfügbarkeitsprofile (`Verfügbarkeitsprofile`):** Der Athlet hinterlegt, an welchen Wochentagen wie viele Stunden für Training zur Verfügung stehen – der Trainer plant darauf basierend, ohne Terminkollisionen zu erzeugen.

---

## 3. Detaillierte Systemanalyse: TrainingPeaks

### 3.1 Leistungs- & Belastungssteuerung (PMC / Banister)
- **Die drei Säulen des PMC (Performance Management Chart):**
  - **Fitness (CTL - Chronic Training Load):** 42-Tage-Exponentialgewichtung (Blau).
  - **Ermüdung / Fatigue (ATL - Acute Training Load):** 7-Tage-Exponentialgewichtung (Magenta).
  - **Form (TSB - Training Stress Balance):** $TSB = CTL_{gestern} - ATL_{gestern}$ (Orange).
- **Fitness-Rampenraten:** Sparkline-Trendkarten über *7 Tage*, *28 Tage*, *90 Tage* und *365 Tage*, um Übertraining oder zu schnellen Belastungsaufbau sofort numerisch zu erkennen.
- **Trainingsbereitschaft-Skala:** Horizontale Segment-Skala von *Überlastung* (Orange) bis *Regeneration* (Blass-Orange).

### 3.2 Wissenschaftliche Telemetrie-Matrix
Im Aktivitäts-Cockpit von TrainingPeaks werden alle Gold-Standard-Metriken strukturiert dargestellt:
1. **Normalisierte Leistung (NP):** Berechnet nach der 30s-Gleitmittel-Formel 4. Potenz ($NP = \sqrt[4]{\frac{1}{N}\sum P_{30s}^4}$).
2. **Intensitätsfaktor (IF):** Verhältnis von NP zur Schwellenleistung ($IF = \frac{NP}{FTP}$).
3. **Training Stress Score (TSS):** Belastungsscore ($TSS = \frac{t \cdot NP \cdot IF}{FTP \cdot 3600} \cdot 100$). Bei Laufen: `rTSS` basierend auf Pace.
4. **Variabilitätsindex (VI):** Gleichmäßigkeit der Leistungsabgabe ($VI = \frac{NP}{\bar{P}}$). Werte nahe 1,00–1,05 bedeuten gleichmäßiges Pacing (z. B. Zeitfahren/Triathlon), Werte > 1,20 spiegeln Kriterien oder hügeliges Terrain wider.
5. **Aerobe Entkopplung / Drift (`Pw:Hr` bzw. `Pa:Hr`):** Prozentuale Drift zwischen der ersten und zweiten Hälfte der Einheit ($\text{Drift} = \frac{EF_1 - EF_2}{EF_1}$). Ein Wert $< 5\%$ belegt eine stabile aerobe Basis; Werte $> 10\%$ deuten auf Ermüdung, Hitze oder Dehydrierung hin.
6. **Effizienzfaktor (EF):** $EF = \frac{NP}{\bar{HR}}$ (beim Radfahren) bzw. $EF = \frac{\bar{Speed}}{\bar{HR}}$ (beim Laufen).
7. **VAM (Velocità Ascensionale Media):** Steigrate in Höhenmetern pro Stunde ($m/h$).

### 3.3 Multi-Stream Synchronisation & Spitzenwerte
- **1Hz synchronisierter Graph:** Überlagerung von Leistung (Lila), Puls (Rot), Geschwindigkeit (Blau), Trittfrequenz (Gelb) und Höhenprofil (Graue Fläche).
- **Spitzenwerte (Peak Performances):** Automatische Erkennung und Medaillenvergabe (Gold, Silber, Bronze) für historische Bestwerte über definierte Zeitintervalle (5s, 20s, 2m, 10m, 30m) inklusive Allzeit-Ranking.
- **7-Zonen-Modelle:**
  - Leistung: Coggan 7 Zonen (Active Recovery bis Neuromuscular).
  - Puls: Joe Friel 7 Zonen (Recovery bis Anaerobic Capacity).

---

## 4. Detaillierte Systemanalyse: Garmin Connect

### 4.1 24/7 Health- & Telemetrie-Drehscheibe
- **Ruheherzfrequenz-Baselines:** Kontinuierliche Anzeige des aktuellen Werts gegen den 7-Tage-Durchschnitt (z. B. `59 bpm` 7-Tage-Ruhe-HF vs. `55 bpm` aktuellem Schlafwert).
- **Schlafanalyse:** Genaue Aufschlüsselung nach Schlafphasen (Tiefschlaf, Leichtschlaf, REM, Wachzeit) mit Zeitstempeln und Schlaf-Score.
- **Intensitätsminuten:** Wöchentliches radiales Ziel (z. B. `117 / 150 min`), aufgeteilt nach moderater und intensiver Aktivität.
- **Aktivitäts-Feed & Mini-Karten:** Kompakte Übersicht mit GPS-Streckensilhouette, Dauer, Pace/Watt und HF-Spannweite (`Ruhe / Hoch`).

---

## 5. Konkrete Ableitungen & Roadmap-Empfehlungen für ORBIT

Auf Basis des direkten Vergleichs ergeben sich für ORBIT folgende Kern-Verbesserungen:

### 1. Das ORBIT Heute-Cockpit (Verfeinerung nach MATS- & TP-Vorbild)
- **Täglicher Schnell-Check-in:** Ein kompakter, optionaler 30-Sekunden-Morgen-Check-in (Muskelkater, Schlafqualität, Stress, Krankheitsgefühl) ergänzt die automatischen Garmin-Health-Daten.
- **Subjektiver 2D-Post-Workout-Puck:** Nach dem Training öffnet sich der ORBIT-Feedback-Quadrant (*Belastung vs. Wohlbefinden*), dessen Wert direkt in den ORBIT Score und das Trainer-Feedback einfließt.
- **Wochen-Strip mit Status-Dots:** Kompakter 7-Tage-Streifen oben auf dem Dashboard mit roten/grünen Statuspunkten für Planerfüllung.

### 2. Das ORBIT Analyse- & Aktivitäts-Cockpit
- **Wissenschaftliche Telemetrie-Kacheln:**
  - Aufnahme von **Variabilitätsindex (VI)**, **Effizienzfaktor (EF)** und **Aerobem Drift (`Pw:Hr` in %)** in das 2x3 Grid des Aktivitäts-Cockpits.
  - Umschaltung der GPS-Streckenlinien-Farbe nach Metrik (Volt-Solid, HF-Gradient oder Pace-Gradient).
- **MMP- & Critical-Speed-Kurve:** Darstellung der Power-Duration-Kurve gegen Allzeit-PRs mit visueller Medaillen-Kennzeichnung bei neuen Saisonbestwerten.
- **Polarisierte Zonen-Verteilung (LIT / MIT / HIT):** Automatischer Ausweis der 3-Zonen-Polarisierung neben den klassischen 7 Coggan-/Friel-Zonen.

### 3. Trainer-Athlet-Interaktion & Trainingsplanung
- **Athleten-Verfügbarkeitsprofil:** Athleten können im Profil ihre wöchentlichen Zeitfenster pro Wochentag festlegen, die dem Trainer im Kalender farblich hinterlegt angezeigt werden.
- **Block-basierter Workout-Builder:** Visuelle Stufenvorschau mit Leistungsbereichen (% FTP oder Watt) und integriertem Ernährungs-Notizfeld pro Einheit.

---

## 6. Verifikations-Nachweis & Bildreferenzen
Die folgenden Bilddokumente dienen als Referenz für alle zukünftigen UI- und Formel-Entwicklungen:
- `docs/research/screenshots/safari_mats_coach.png` (Desktop Kalender & Bibliothek)
- `docs/research/screenshots/safari_trainingpeaks.png` (Desktop 3-Spalten-Cockpit & PMC)
- `docs/research/screenshots/safari_garmin_connect.png` (Desktop Health & Aktivitäts-Übersicht)
- `docs/research/screenshots/safari_orbit_web_active.png` (Aktuelle ORBIT Web-Plattform)
- 47 mobile Detail-Screenshots unter `docs/research/screenshots/tp_mats/`.
