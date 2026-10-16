# ORBIT Metrik-Spezifikation (`docs/METRICS_SPEC.md`)

> **Wissenschaftliche Grundlage für die ORBIT Performance- & Telemetrie-Engine (Phase 20)**
> Alle mathematischen Formeln basieren auf publizierten sportwissenschaftlichen Standardwerken (Coggan, Skiba, Morton, Banister, Daniels, Minetti, Friel).
> **ACHTUNG:** Gemäß AGENTS.md und GPL-v2-Leitplanken ist jegliche Übernahme von Code oder Text aus GoldenCheetah oder proprietären Quellen streng verboten. Alle Algorithmen sind in eigenem TypeScript- und Dart-Code realisiert.

---

## 1. Radsport-Metriken (Power-Engine)

### 1.1 Normalized Power (NP®), Intensity Factor (IF®) und Training Stress Score (TSS®)
Die klassische Durchschnittsleistung bildet die physiologische Belastung bei wechselnder Intensität nicht ab, da der Glykogen- und Sauerstoffverbrauch mit steigender Intensität überproportional zunimmt (nicht-lineare metabolische Kosten).

#### A. Algorithmus zur Normalized Power (Coggan)
1. **30-Sekunden-Mittelwert:** Für jede Sekunde $t \ge 30$ wird der gleitende Mittelwert der Leistung über die vorangegangenen 30 Sekunden berechnet:
   $$P_{30\text{s}}(t) = \frac{1}{30} \sum_{i=0}^{29} P(t-i)$$
   *Pausen- und Lückenbehandlung:* Ist die Aufzeichnung unterbrochen (Auto-Pause) oder beträgt das Intervall $\Delta t > 1\text{s}$, wird die Zeitreihe vor der 30s-Glättung auf 1 Hz interpoliert bzw. Nullen in echten Rollphasen korrekt eingerechnet.
2. **4. Potenzierung:** Jeder 30s-Wert wird in die 4. Potenz erhoben:
   $$\tilde{P}(t) = \left(P_{30\text{s}}(t)\right)^4$$
3. **Mittelwertbildung:** Der arithmetische Mittelwert aller quadrierten Werte wird gebildet:
   $$\overline{\tilde{P}} = \frac{1}{N - 29} \sum_{k=30}^N \tilde{P}(k)$$
4. **4. Wurzel:** Die 4. Wurzel des Durchschnitts ergibt die Normalized Power:
   $$\text{NP} = \sqrt[4]{\overline{\tilde{P}}} = \left(\overline{\tilde{P}}\right)^{0.25}$$

#### B. Intensity Factor (IF)
Verhältnis der physiologischen Belastung zur aktuellen funktionellen Schwellenleistung (FTP):
$$\text{IF} = \frac{\text{NP}}{\text{FTP}}$$

#### C. Training Stress Score (TSS)
Berechnung der Gesamttrainingsbelastung bezogen auf 1 Stunde Maximallast an der Schwelle ($\text{TSS} = 100$ für 1h @ FTP):
$$\text{TSS} = \frac{t_{\text{duration\_sec}} \times \text{NP} \times \text{IF}}{\text{FTP} \times 3600} \times 100 = \frac{t_{\text{duration\_sec}} \times \text{NP}^2}{\text{FTP}^2 \times 36} \quad [\%]$$

#### D. Variability Index (VI)
Maß für die Gleichmäßigkeit des Pacings:
$$\text{VI} = \frac{\text{NP}}{\overline{P}_{\text{avg}}}$$
- $\text{VI} \le 1.05$: Sehr gleichmäßiges Pacing (z. B. flaches Einzelzeitfahren / Triathlon).
- $1.06 \le \text{VI} \le 1.15$: Leicht hügelig oder gemäßigte Gruppenfahrt.
- $\text{VI} > 1.15$: Kriterium, Cross-Country oder ungleichmäßiges Intervalltraining.

---

### 1.2 Critical Power ($CP$) & Skiba $W'\text{bal}$-Modell

#### A. 2-Parameter Critical Power Modell (Monod & Scherrer)
Die Beziehung zwischen Leistung $P$ und Erschöpfungszeit $t_{\text{lim}}$ im Bereich zwischen 2 und 30 Minuten wird durch eine hyperbolische Funktion beschrieben:
$$P(t) = CP + \frac{W'}{t} \iff W = W' + CP \cdot t$$
- $CP$ (Critical Power in Watt): Die theoretische Dauerleistungsgrenze ohne stetige Erschöpfung der anaeroben Kapazität.
- $W'$ (W-Prime in Joules oder kJ): Die endliche Arbeitskapazität oberhalb von $CP$ (anaerobe Energiereserve).

*Schätzung aus der MMP-Kurve (Mean Maximal Power):*
Aus Stützpunkten der letzten 90 Tage (z. B. $t_1 = 180\text{s}$ und $t_2 = 1200\text{s}$):
$$CP = \frac{P_2 \cdot t_2 - P_1 \cdot t_1}{t_2 - t_1}$$
$$W' = (P_1 - CP) \cdot t_1 = (P_2 - CP) \cdot t_2$$

#### B. $W'\text{bal}$-Zeitreihe (Skiba et al. 2012 / 2015)
Zeigt den aktuellen Füllstand des anaeroben Tanks zu jeder Sekunde der Fahrt:
1. **Entleerung bei $P(t) > CP$:**
   $$W'\text{bal}(t) = W'\text{bal}(t-1) - (P(t) - CP) \cdot \Delta t$$
2. **Dynamische Erholung bei $P(t) < CP$:**
   Die Wiederaufladung erfolgt exponentiell, abhängig von der Erholungsleistung $P_{\text{under}}$ unterhalb $CP$:
   $$D_{\text{under}} = CP - P_{\text{under}}(t)$$
   $$\tau_{W'} = 546 \cdot e^{-0.01 \cdot D_{\text{under}}} + 316 \quad [\text{s}]$$
   $$W'\text{bal}(t) = W'\text{bal}(t-1) + \left(W' - W'\text{bal}(t-1)\right) \cdot \left(1 - e^{-\Delta t / \tau_{W'}}\right)$$
   *Grenzen:* $0 \le W'\text{bal}(t) \le W'$. Fällt $W'\text{bal}$ auf 0, ist der Athlet mathematisch erschöpft.

---

## 2. Lauf-Metriken (Grade-Adjusted Pace & rTSS)

### 2.1 Grade-Adjusted Pace (GAP) nach Minetti et al. (2002)
Beim Laufen an Steigungen steigen die metabolischen Kosten drastisch, bei Gefälle sinken sie (bis zu ca. -10 % Gefälle, darunter steigen sie durch exzentrische Bremsarbeit wieder).

Die energetischen Kosten $C_r$ in $\text{J}/(\text{kg}\cdot\text{m})$ in Abhängigkeit von der Steigung $g = \frac{\Delta h}{\Delta s}$ (im Dezimalformat, z. B. $0.05$ für $5\,\%$ Steigung) werden nach Minetti berechnet:
$$C_r(g) = 155.4 \cdot g^5 - 30.4 \cdot g^4 - 43.3 \cdot g^3 + 46.3 \cdot g^2 + 19.5 \cdot g + 3.6$$
Für ebene Strecken gilt $C_r(0) = 3.6\,\text{J}/(\text{kg}\cdot\text{m})$.

Der Steigungskorrekturfaktor beträgt:
$$f(g) = \frac{C_r(g)}{C_r(0)}$$
Die äquivalente Flachland-Geschwindigkeit beträgt:
$$v_{\text{eq}}(t) = v(t) \cdot f(g(t)) \quad [\text{m/s}]$$
Die Grade-Adjusted Pace ergibt sich als:
$$\text{GAP}(t) = \frac{1000}{v_{\text{eq}}(t)} \quad [\text{s/km}]$$

### 2.2 Normalized Graded Pace (NGP) und Running TSS (rTSS)
1. **NGP:** Aus der äquivalenten Geschwindigkeit $v_{\text{eq}}(t)$ wird analog zu NP der 30s-Rolling-Average gebildet, zur 4. Potenz erhoben, gemittelt und die 4. Wurzel gezogen:
   $$v_{\text{NGP}} = \sqrt[4]{\frac{1}{N - 29} \sum_{k=30}^N \left(\frac{1}{30} \sum_{i=0}^{29} v_{\text{eq}}(k-i)\right)^4} \quad [\text{m/s}]$$
   $$\text{NGP}_{\text{pace}} = \frac{1000}{v_{\text{NGP}}} \quad [\text{s/km}]$$
2. **Intensity Factor Laufen ($\text{IF}_{\text{run}}$):**
   $$\text{IF}_{\text{run}} = \frac{v_{\text{NGP}}}{v_{\text{threshold}}} = \frac{\text{Pace}_{\text{threshold}}}{\text{NGP}_{\text{pace}}}$$
3. **Running Training Stress Score (rTSS):**
   $$\text{rTSS} = \frac{t_{\text{duration\_sec}} \times \text{IF}_{\text{run}}^2}{36} \quad [\%]$$

---

## 3. Schwimm-Metriken (CSS & sTSS)

### 3.1 Critical Swim Speed (CSS)
Die aerobe Schwimmschwelle in Metern pro Sekunde wird aus zwei All-Out-Zeittests (400 m und 200 m) bestimmt:
$$v_{\text{CSS}} = \frac{400 - 200}{T_{400} - T_{200}} = \frac{200}{T_{400} - T_{200}} \quad [\text{m/s}]$$
$$\text{CSS}_{\text{pace}} = \frac{100}{v_{\text{CSS}}} = \frac{T_{400} - T_{200}}{2} \quad [\text{s/100m}]$$

### 3.2 Swim Training Stress Score (sTSS)
Aufgrund des kubischen Strömungswiderstands im Wasser ($P \propto v^3$) skaliert die metabolische Schwimmlast mit der 3. Potenz der Geschwindigkeit:
$$\text{IF}_{\text{swim}} = \frac{\overline{v}}{v_{\text{CSS}}} = \frac{\text{CSS}_{\text{pace}}}{\overline{\text{Pace}}}$$
$$\text{sTSS} = \frac{t_{\text{moving\_sec}} \times \left(\text{IF}_{\text{swim}}\right)^3}{3600} \times 100$$

### 3.3 SWOLF & Distanz pro Zug (DPS)
- **SWOLF:** Maß für Schwimmeffizienz:
  $$\text{SWOLF} = \text{Zeit pro Bahn [s]} + \text{Anzahl Züge pro Bahn}$$
- **Distance Per Stroke (DPS):**
  $$\text{DPS} = \frac{\text{Bahndistanz [m]}}{\text{Anzahl Züge}}$$

---

## 4. Performance Management Chart (PMC — Banister Impulse-Response)

Das PMC bildet die chronische Fitness ($CTL$), die akute Ermüdung ($ATL$) und die resultierende Form ($TSB$) ab.

### 4.1 Tägliche Fortschreibung (EMA)
Mit den Zeitkonstanten $\tau_{\text{CTL}} = 42\,\text{Tagen}$ und $\tau_{\text{ATL}} = 7\,\text{Tagen}$ sowie $\lambda = 1 - e^{-1/\tau}$:
$$\text{CTL}(t) = \text{CTL}(t-1) + \left(\text{TSS}(t) - \text{CTL}(t-1)\right) \cdot \left(1 - e^{-1/42}\right)$$
$$\text{ATL}(t) = \text{ATL}(t-1) + \left(\text{TSS}(t) - \text{ATL}(t-1)\right) \cdot \left(1 - e^{-1/7}\right)$$

### 4.2 Training Stress Balance (TSB)
Formwert für den aktuellen Tag, basierend auf der Balance des Vortags:
$$\text{TSB}(t) = \text{CTL}(t-1) - \text{ATL}(t-1)$$

### 4.3 7-Tage-Ramp-Rate & Überlastungs-Alarm
Die wöchentliche Zuwachsrate der Fitness:
$$\text{RampRate}_{7\text{d}} = \text{CTL}(t) - \text{CTL}(t-7)$$
- $\text{RampRate} \le 5\,\text{TSS/Woche}$: Sicherer, nachhaltiger Aufbau.
- $5 < \text{RampRate} \le 7\,\text{TSS/Woche}$: Optimaler Forcierungsbereich für ambitionierte Athleten.
- $\text{RampRate} > 7\,\text{TSS/Woche}$: **Erhöhtes Überlastungs- und Verletzungsrisiko (Alarmierung in UI)**.

### 4.4 14-Tage-Zukunftsprojektion
Fortschreibung der Gleichungen über die kommenden 14 Tage ($t+1 \dots t+14$) anhand der geplanten Trainingseinheiten (`plannedWorkouts.plannedLoad` bzw. prognostiziertem TSS). Ruhetage fließen mit $\text{TSS} = 0$ ein, sodass Athlet und Trainer den Peak am Wettkampftag exakt voraussehen können.

---

## 5. Aerobe Effizienz & Entkopplung (Aerobic Decoupling)

### 5.1 Efficiency Factor (EF)
Verhältnis aus abgegebener mechanischer Leistung und physiologischer Beanspruchung (Herzfrequenz):
$$\text{EF}_{\text{bike}} = \frac{\text{NP}}{\overline{\text{HR}}} \quad [\text{W/bpm}]$$
$$\text{EF}_{\text{run}} = \frac{v_{\text{NGP}} \cdot 60}{\overline{\text{HR}}} \quad [(\text{m/min})/\text{bpm}]$$

### 5.2 Aerobic Decoupling ($Pa:HR$ / $Pw:HR$)
Vergleich der Effizienz der ersten Aktivitätshälfte ($t_1$) mit der zweiten Aktivitätshälfte ($t_2$) bei Steady-State-Einheiten:
$$\text{Decoupling} = \frac{\text{EF}_1 - \text{EF}_2}{\text{EF}_1} \times 100 \quad [\%]$$

#### Klassifikation & Bewertung:
- **$\text{Decoupling} < 5.0\,\%$ (Grün / Gekoppelt):** Exzellente aerobe Ausdauerbasis; die Herzfrequenz bleibt im Verhältnis zur Leistung stabil.
- **$5.0\,\% \le \text{Decoupling} \le 8.0\,\%$ (Gelb / Moderat):** Leichter kardiovaskulärer Drift; für lange Trainingseinheiten akzeptabel.
- **$\text{Decoupling} > 8.0\,\%$ (Rot / Entkoppelt):** Deutlicher kardiovaskulärer Drift durch Ermüdung, Hitzestress, Flüssigkeitsmangel oder mangelnde Grundlagenausdauer für diese Belastungsdauer.

---

## 6. Automatische Intervall-Erkennung (Auto-Lap Engine)

Trägt der Athlet keine manuellen Laps ein, analysiert ORBIT den Sekunden-Stream automatisch:
1. **Identifikation von Belastungsphasen:**
   Punkte mit $P(t) \ge 0.90 \times \text{FTP}$ (bzw. $v(t) \ge 0.90 \times v_{\text{threshold}}$).
2. **Mindestdauer-Gate:**
   Nur zusammenhängende Blöcke mit Dauer $t_{\text{interval}} \ge 30\,\text{s}$ werden als Belastungsintervall gewertet.
3. **Toleranz bei kurzen Tretunterbrechungen:**
   Kurze Absacker $< 5\,\text{s}$ (z. B. durch Kurven) teilen ein aktives Intervall nicht auf.
4. **Metriken je Intervall:**
   Berechnung von Dauer, Distanz, $\overline{P}$, $\text{NP}$, $\overline{\text{HR}}$, Trittfrequenz und $\text{EF}$.

---

## 7. Multisport & Brick-Analyse (Koppeltraining)
Für Triathlon- und Duathlon-Einheiten (oder zeitnah aufeinanderfolgende Einheiten):
- **T1 / T2 Wechselzeit.**
- **Pace-Stabilität auf den ersten 2 Kilometern:**
  $$\Delta\text{Pace}_{\text{brick}} = \overline{\text{Pace}}_{0-2\text{km}} - \overline{\text{Pace}}_{\text{rest}}$$
  Quantifiziert die Ermüdung der Beinmuskulatur nach dem Radsplit und den Übergang zur sauberen Laufökonomie.
