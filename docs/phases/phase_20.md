# PHASE 20 — Profi-Analyse nach GoldenCheetah-Vorbild & Gründlicher Formel-Abgleich

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH – Sportwissenschaftliche Kernalgorithmen).
- **Lizenz-Regel:** GoldenCheetah steht unter GPL v2. **Keinen Quellcode kopieren!** Wir implementieren die öffentlich publizierten sportwissenschaftlichen Formeln (Coggan, Skiba, Morton, Banister, Daniels) komplett in eigenem TypeScript/Dart-Code und gleichen die Zahlenwerte gegen Referenzdaten ab.
- **Design:** Kuratierte, aufgeräumte Ansichten im ORBIT-Look (`#001F47` Navy, `#00D2FF` Cyan, `#FF6B00` Amber, `#10B981` Emerald).

## Arbeitspakete

### 20.1 Mathematische Kern-Engine (`functions/src/metrics/` & Dart-Modelle)
Implementiere und verifiziere folgende Berechnungen mit dokumentierten Formeln in `docs/METRICS_SPEC.md`:
1. **Normalisierte Leistung (NP), Intensity Factor (IF) & TSS (nach Coggan):**
   - Exakter 30-Sekunden-Gleitmittelwert (inkl. korrekter Behandlung von Pausen/Coasting und variablen Aufzeichnungsintervallen), 4. Potenz, Mittelwertbildung, 4. Wurzel.
   - Alternativen für Lauf (**rTSS / NGP** – Normalized Graded Pace unter Berücksichtigung der Steigung) und Schwimmen (**sTSS** über CSS).
2. **Critical Power Modell (CP, W′, Pmax) & W′bal (Differential-/Integral-Modell nach Skiba):**
   - Schätzung von CP und W′ aus der Mean-Maximal-Power-Kurve (Bestwerte über 1s, 5s, 15s, 1m, 3m, 5m, 12m, 20m, 60m der letzten 90 Tage).
   - Berechnung der **W′bal-Zeitreihe** (in kJ bzw. %) für jede Radausfahrt mit Wattmesser: Zeigt Sekunde für Sekunde die Erschöpfung und Erholung der anaeroben Reserve.
3. **PMC – Performance Management Chart (Banister Impulse-Response):**
   - Tägliche Fortschreibung von **CTL** (Chronic Training Load / Fitness, $\tau = 42$ Tage), **ATL** (Acute Training Load / Ermüdung, $\tau = 7$ Tage) und **TSB** (Training Stress Balance / Form = $\text{CTL}_{\text{gestern}} - \text{ATL}_{\text{gestern}}$) inkl. Ramp Rate (CTL-Anstieg pro Woche mit Überlastungswarnung ab > 7 TSS/Tag).
4. **Aerobe Effizienz & Entkopplung (EF & Pa:Hr / Pw:Hr):**
   - Efficiency Factor ($\text{EF} = \text{NP} / \overline{\text{HF}}$ bzw. $\text{NGP} / \overline{\text{HF}}$).
   - **Aerobic Decoupling (%):** Vergleich des EF der ersten gegenüber der zweiten Aktivitätshälfte (grün < 5 %, gelb 5–8 %, rot > 8 %).
5. **Automatische Intervallerkennung & Bestwerte:**
   - Algorithmus zur Erkennung gefahrener/gelaufener Intervalle direkt aus dem Watt-/Pace-Stream (auch wenn der Athlet vergessen hat, die Lap-Taste zu drücken) + automatischer Abgleich mit bestehenden All-Time- und 90-Tage-Bestwerten.
6. **Schwimm- & Multisport-Metriken:**
   - **SWOLF**, Zugfrequenz, DPS (Distanz pro Zug) sowie **Brick-/Wechselanalyse** (T1/T2 Zeiten und Pace-Abfall auf den ersten 2 km Laufen nach dem Radfahren).

### 20.2 Referenz-Testsuite (GoldenCheetah-Abgleich)
1. Lege unter `functions/test/metrics_reference.spec.ts` eine präzise Testsuite an.
2. Prüfe alle Formeln gegen synthetische Referenz-Streams (z. B. 60 min exakt 250 W bei FTP 250 W MUSS exakt `NP = 250.0`, `IF = 1.00`, `TSS = 100.0` ergeben; Stufen-Intervall-Test für Skiba W′bal; 42-Tage-Konstantlast-Test für CTL/ATL/TSB) sowie gegen echte Test-FIT-Dateien.
3. Maximale erlaubte Abweichung zu den Referenzwerten: **< 0,5 %**.

### 20.3 Kuratierte Analyse-Ansichten im ORBIT-Design (Mobile & Coach-Web)
Baue den Tab **„Analyse“** und die **Aktivitäts-Detailansicht** mit folgenden kartenbasierten Ansichten aus:
1. **Aktivitäts-Cockpit:** Synchronisierte Multi-Graphen (Watt + W′bal-Kurve, HF, Pace, Kadenz, Höhe), Zeit-in-Zonen-Histogramme (Watt-, HF-, Pace-Zonen), Intervall-Tabelle (Durchschnittswatt, HF, EF je Intervall) und Aero/Decoupling-Badge.
2. **Saison- & Leistungs-Cockpit:**
   - Interaktiver **PMC-Graph (Fitness / Ermüdung / Form)** mit Zukunfts-Projektion basierend auf den geplanten Workouts der nächsten 14 Tage.
   - **Power- / Pace-Profil-Kurve (MMP)** mit Vergleich *„Letzte 42 Tage vs. Beste Saison“* und ausgewiesenem CP / W′-Wert.

## STOPP-Punkte & Abnahmekriterien
- **STOPP 1:** Lege `docs/METRICS_SPEC.md` mit allen mathematischen Formeln und die Ergebnisse der Referenz-Unit-Tests (`metrics_reference.spec.ts`) vor.
- **STOPP 2 (Phasenabschluss):** Nachweis, dass eine importierte Rad- und Laufeinheit alle neuen Metriken berechnet und im UI fehlerfrei darstellt.
- Nach meiner Freigabe: Commit & Push auf GitHub mit Tag `v0.20.0`.