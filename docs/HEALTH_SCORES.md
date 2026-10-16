# ORBIT Health & Recovery Score Spezifikation

Dieses Dokument definiert die mathematischen Grundlagen, sportwissenschaftlichen Referenzen und Implementierungsdetails für das **Health & Recovery Cockpit (Phase 21)** der ORBIT-Plattform.

> **Rechtliche & Medizinische Leitplanken:**
> 1. **Markenrecht:** Es werden keinerlei geschützte Begriffe von Drittanbietern (wie „Whoop“, „Strain“ oder geschützte 0–21 Skalen) verwendet. ORBIT nutzt eigene, transparente **0–100 Skalen**:
>    - **ORBIT Erholung (0–100 %)**
>    - **ORBIT Tagesbelastung (0–100)**
>    - **ORBIT Schlaf-Score (0–100 %)**
>    - **ORBIT Gesamt-Score (0–100)**
> 2. **Medizinischer Disclaimer:** Alle Messwerte und Hinweise sind rein sportwissenschaftliche Trainingssteuerungshilfen und **kein Medizinprodukt**. Abweichungen werden stets neutral relativ zur persönlichen 30-Tage-Baseline dargestellt (*„Außerhalb deines 30-Tage-Normbereichs“*), niemals als Krankheitswarnung oder Diagnose.
> 3. **Graceful Degradation (Pflicht):** Ältere oder reduzierte Sensoren (z. B. Garmin-Modelle ohne nächtliche HRV oder Atemfrequenz) müssen fehlerfrei verarbeitet werden. Gewichte verteilen sich dynamisch auf vorhandene Daten, ohne `NaN` oder `0` zu erzeugen.

---

## 1. Rolllierende 30-Tage-Baselines & Normbänder

Zur Beurteilung des vegetativen Nervensystems (Sympathikus vs. Parasympathikus) sind absolute Grenzwerte ungeeignet, da HRV, Ruhepuls und Atemfrequenz stark interindividuell variieren. ORBIT berechnet für jeden Athleten rollierende 30-Tage-Baselines.

### 1.1 Exponentiell gewichtete Baseline ($\mu_{30d}, \sigma_{30d}$)
Für einen Datenstrom $x_1, x_2, \dots, x_N$ der letzten $N \le 30$ Tage (Mindestanzahl $N \ge 3$ für erste Vorab-Baselines, $N \ge 14$ für stabile Konfidenz):

$$\mu = \frac{1}{N} \sum_{i=1}^N x_i$$

$$\sigma = \sqrt{\frac{1}{N-1} \sum_{i=1}^N (x_i - \mu)^2}$$

Das **persönliche Normband** entspricht dem Bereich:

$$\text{Normband} = [\mu - 1.0 \cdot \sigma, \; \mu + 1.0 \cdot \sigma]$$

Statistisch liegen bei normalverteilten Biomarkern ca. 68,3 % aller gesunden Tage innerhalb dieses Bandes. Tage außerhalb des Bandes signalisieren signifikante vegetative Reaktionen.

Baselines werden berechnet für:
1. **Nächtliche HRV** (rMSSD in ms)
2. **Ruheherzfrequenz (RHR)** (Schläge/min)
3. **Schlafdauer** (Stunden bzw. Minuten)
4. **Nächtliche Atemfrequenz** (Atemzüge/min)
5. **Body Battery** (Morgenwert bzw. Nacht-Aufladung, 0–100)

---

## 2. ORBIT Erholungs-Score (0–100 %)

Der Erholungs-Score quantifiziert die physiologische Bereitschaft für hochintensive Reize auf einer Skala von **0 bis 100 %**.

### 2.1 Standard-Gewichtung (Vollbestückung)
Sind alle Sensordaten vorhanden, gilt folgende Gewichtung:
- **$w_{\text{hrv}} = 0.45$** (Nächtliche HRV vs. 30-Tage-Baseline)
- **$w_{\text{rhr}} = 0.25$** (Ruhepuls vs. 30-Tage-Baseline, invertiert)
- **$w_{\text{sleep}} = 0.20$** (Schlaf-Score der vorangegangenen Nacht)
- **$w_{\text{resp\_bb}} = 0.10$** (Stabilität der Atemfrequenz & Body Battery)

### 2.2 Z-Score-Transformation & Sigmoid-Skalierung
Für HRV und Ruhepuls wird die Abweichung zur Baseline in Einheiten der Standardabweichung (Z-Score) ermittelt:

$$z_{\text{hrv}} = \frac{\text{HRV}_{\text{heute}} - \mu_{\text{hrv}}}{\sigma_{\text{hrv}}}$$

Da eine niedrigere Ruheherzfrequenz ein Zeichen besserer Erholung / kardiovaskulärer Ökonomie ist, wird das Vorzeichen invertiert:

$$z_{\text{rhr}} = \frac{\mu_{\text{rhr}} - \text{RHR}_{\text{heute}}}{\sigma_{\text{rhr}}}$$

Die Z-Scores werden über eine logistische Sigmoid-Funktion mit Steigungsparameter $k = 1.25$ in Teil-Scores $S \in [0, 100]$ überführt:

$$S(z) = \frac{100}{1 + e^{-k \cdot z}}$$

- $z = 0$ (exakt auf Baseline) $\implies S = 50.0$
- $z = +1.0$ ($1\sigma$ über Baseline) $\implies S \approx 77.7$
- $z = -1.0$ ($1\sigma$ unter Baseline) $\implies S \approx 22.3$

Für die Atemfrequenz führt eine signifikante Erhöhung (z. B. beginnender Infekt, Überlastung, Höhe) zu Punktabzug:

$$z_{\text{resp}} = \frac{\text{Resp}_{\text{heute}} - \mu_{\text{resp}}}{\sigma_{\text{resp}}}$$

$$S_{\text{resp}} = \max(0, \; 100 - 35 \cdot \max(0, z_{\text{resp}}))$$

### 2.3 Graceful Degradation (Dynamische Gewichtsnormierung)
Fehlen einzelne Metriken (z. B. ältere Garmin Forerunner ohne nächtliches HRV-Tracking), werden deren Gewichte $w_j = 0$ gesetzt. Die verbleibenden Gewichte werden normiert:

$$w'_i = \frac{w_i}{\sum_{k \in \text{verfügbar}} w_k}$$

$$\text{RecoveryScore} = \sum_{i \in \text{verfügbar}} w'_i \cdot S_i$$

Hierdurch liefert der Score auch bei reinen RHR- + Schlaf-Daten stets ein valides, stabiles Ergebnis zwischen 0 und 100 %.

### 2.4 Ampel-Klassifikation
- **Grün (67–100 %):** *Bereit für Spitzenbelastungen & Schwellen-Intervalle.*
- **Gelb (34–66 %):** *Gute Grundverfassung, moderates GA1-Training, Technik- oder Erhaltungseinheiten.*
- **Rot (0–33 %):** *Erhöhte vegetative Belastung. Fokus auf aktive Erholung, Schlaf, Dehnen oder Ruhetag.*

---

## 3. ORBIT Tagesbelastung (0–100) & Dynamischer Zielkorridor

Die Tagesbelastung erfasst die kardiovaskuläre und metabolische Gesamtexposition des Tages.

### 3.1 Belastungs-Kombination (Training + Alltag)
1. **Trainings-TSS ($TSS_{\text{workout}}$):** Summe aller Training Stress Scores aus Aktivitäten des Tages.
2. **Alltags-Belastung ($Load_{\text{alltag}}$):** Ermittelt aus Garmin Alltagsstress ($\overline{\text{Stress}} \in [0, 100]$) und aktiven Kalorien ($E_{\text{act}}$ in kcal):

$$Load_{\text{alltag}} = \overline{\text{Stress}} \cdot 0.35 + \left(\frac{E_{\text{act}}}{100}\right) \cdot 1.8$$

3. **Gesamtrohbelastung $L$:**

$$L = TSS_{\text{workout}} + Load_{\text{alltag}}$$

4. **Logarithmisch gedämpfte 0–100 Skala:**
Zur Vermeidung von linearen Verzerrungen bei extremen Ultra-Einheiten wird eine logarithmische Sättigungskurve angewendet:

$$\text{Tagesbelastung} = \min\left(100, \; \text{round}\left(21.5 \cdot \ln\left(1 + \frac{L}{15}\right)\right)\right)$$

- $L = 0 \implies \text{Tagesbelastung} = 0$
- $L = 35 \implies \text{Tagesbelastung} \approx 26$ (Ruhiger Bürotag ohne Sport)
- $L = 80 \implies \text{Tagesbelastung} \approx 39$ (Alltag + 45 min lockerer Lauf)
- $L = 160 \implies \text{Tagesbelastung} \approx 53$ (Alltag + 90 min EB-Fahrt)
- $L = 300 \implies \text{Tagesbelastung} \approx 65$ (Harte Intervallfahrt, 3h Rad)
- $L = 600 \implies \text{Tagesbelastung} \approx 80$ (Königsetappe / Halbdistanz)

### 3.2 Dynamischer Belastungs-Zielkorridor
Abhängig vom Erholungs-Score des Morgens berechnet ORBIT den optimalen Zielkorridor $[T_{\min}, T_{\max}]$ für den heutigen Tag:

- **Bei hoher Erholung ($R \ge 67\%$, Grün):**
  $$T_{\min} = 55 + 0.25 \cdot (R - 67), \quad T_{\max} = 75 + 0.35 \cdot (R - 67)$$
  *(Beispiel $R = 85\% \implies \text{Zielbereich } 60–81$)*
- **Bei moderater Erholung ($34\% \le R < 67\%$, Gelb):**
  $$T_{\min} = 35 + 0.35 \cdot (R - 34), \quad T_{\max} = 55 + 0.35 \cdot (R - 34)$$
  *(Beispiel $R = 50\% \implies \text{Zielbereich } 41–61$)*
- **Bei niedriger Erholung ($R < 34\%$, Rot):**
  $$T_{\min} = 10, \quad T_{\max} = 25 + 0.30 \cdot R$$
  *(Beispiel $R = 20\% \implies \text{Zielbereich } 10–31$)*

---

## 4. Schlaf-Analyse, Schlafbedarf & Schlafschuld

### 4.1 Schlafbedarf heute
Der Schlafbedarf setzt sich aus dem individuellen Basisbedarf, dem physiologischen Zuschlag aus der gestrigen Tagesbelastung und dem partiellen Abbau akkumulierter Schlafschuld zusammen:

$$\text{Schlafbedarf (h)} = \text{Basisbedarf} + (0.012 \cdot \text{Tagesbelastung}_{\text{gestern}}) + 0.50 \cdot \text{Schlafschuld}_{7d}$$

- **Standard-Basisbedarf:** $7.75\text{ h}$ ($7\text{ h } 45\text{ min}$).
- **Schlafschuld eines Tages:** $\text{Schuld}_d = \max(0, \; \text{Bedarf}_d - \text{Dauer}_d)$.
- **7-Tage-Akkumulierte Schlafschuld:** Summe der Schlafschulden der letzten 7 Tage (gedeckelt auf max. $6.0\text{ h}$, um unrealistische Extremwerte zu verhindern).

### 4.2 Schlaf-Score (0–100 %)
Der Schlaf-Score gewichtet vier Qualitätsfaktoren:
1. **Schlafdauer vs. Bedarf (50 %):**
   $$S_{\text{dur}} = \min\left(100, \; \frac{\text{Ist-Schlafdauer}}{\text{Schlafbedarf}} \cdot 100\right)$$
2. **Schlafeffizienz (25 %):**
   $$S_{\text{eff}} = \min\left(100, \; \max\left(0, \; \frac{\text{Schlafzeit}}{\text{Zeit im Bett}} \cdot 100\right)\right)$$
3. **Schlafarchitektur (15 %):**
   Anteil regenerativer Phasen (Tiefschlaf + REM):
   $$S_{\text{stages}} = \min\left(100, \; \frac{\text{Tiefschlaf} + \text{REM}}{\text{Gesamtschlaf}} \cdot \frac{100}{0.40}\right)$$
   *(Optimalwert $\ge 40\%$ Tief- + REM-Schlaf)*
4. **Schlaf-Konsistenz (10 %):**
   Standardabweichung der Einschlaf- und Aufwachzeiten der letzten 7 Tage:
   $$S_{\text{cons}} = \max\left(0, \; 100 - \frac{\sigma_{\text{zeit}} \text{ (in min)}}{45} \cdot 50\right)$$

---

## 5. Finaler ORBIT Gesamt-Score (0–100)

Der finale ORBIT Score aggregiert das Zusammenspiel von Belastung, Erholung und Gesundheit zu einer übergeordneten Orientierungsgröße:

$$\text{ORBIT Score} = 0.30 \cdot S_{\text{consistency}} + 0.25 \cdot S_{\text{tsb}} + 0.25 \cdot \overline{S_{\text{rec}, 7d}} + 0.20 \cdot \overline{S_{\text{sleep}, 7d}}$$

- **$S_{\text{consistency}}$:** Trainingskonsistenz (Anteil aktiver Tage im Wochenzyklus vs. Plan).
- **$S_{\text{tsb}}$:** Banister Form-Faktor (Optimalbereich $\text{TSB} \in [-10, +10] \implies 100$, starke Übermüdung $<-30$ oder Detraining $>+25$ führen zu prozentualem Abschlag).
- **$\overline{S_{\text{rec}, 7d}}$:** 7-Tage-Mittelwert des ORBIT Erholungs-Scores.
- **$\overline{S_{\text{sleep}, 7d}}$:** 7-Tage-Mittelwert des Schlaf-Scores minus Malus bei hoher Schlafschuld ($> 3\text{ h}$).

---

## 6. Journal-Korrelations-Engine

Athleten erfassen im 15-Sekunden-Morgen-Journal Verhaltensfaktoren als binäre Tags:
- `lateCaffeine` (Später Kaffeekonsum nach 15 Uhr)
- `alcohol` (Alkoholkonsum am Vorabend)
- `muscleSoreness` (Muskelkater / DOMS)
- `highStress` (Hoher mentaler Alltagsstress)
- `poorFeeling` (Subjektiv erschöpft / unruhig)
- `goodHydration` (Gute Trinkmenge $\ge 2.5\text{ l}$)
- `lateMeal` (Schwere Mahlzeit kurz vor dem Schlafen)
- `travelAltitude` (Reise, Zeitverschiebung oder Höhentraining)

### Statistische Auswertung (ab $N \ge 14$ Einträgen)
Für jeden Tag $t$ mit Tag $F$ vs. Tage ohne $F$:

$$\Delta\text{HRV} = \overline{\text{HRV}}_{F=1} - \overline{\text{HRV}}_{F=0}$$

$$\Delta\text{RHR} = \overline{\text{RHR}}_{F=1} - \overline{\text{RHR}}_{F=0}$$

$$\Delta\text{DeepSleep} = \overline{\text{Deep}}_{F=1} - \overline{\text{Deep}}_{F=0}$$

$$\Delta\text{Recovery} = \overline{\text{Recovery}}_{F=1} - \overline{\text{Recovery}}_{F=0}$$

Ist die Differenz statistisch auffällig ($|\Delta\text{HRV}| \ge 3\text{ ms}$ oder $|\Delta\text{Deep}| \ge 10\text{ min}$ oder $|\Delta\text{RHR}| \ge 1.5\text{ bpm}$), formuliert die Engine einen neutralen, motivierenden Zusammenhangssatz im Health-Cockpit.
