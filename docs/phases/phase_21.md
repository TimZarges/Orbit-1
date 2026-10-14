# PHASE 21 — Health & Recovery Cockpit (Ringe, Erholung, Schlaf, Belastung, Journal & Berichte)

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: HOCH – Gesundheitsdaten Art. 9 DSGVO & Score-Formeln).
- **Markenrecht & Wording:** Keine geschützten Whoop-Begriffe („Strain“, „Whoop Recovery“) verwenden. Wir nutzen klare eigene Begriffe (**ORBIT Erholung**, **Tagesbelastung**, **Schlaf-Score**, **ORBIT Score**) auf einer offenen, transparent erklärten **0–100 Skala**.
- **Medizinischer Disclaimer:** Hinweise bei Abweichungen (z. B. Atemfrequenz, Ruhepuls, HRV) immer neutral formulieren (*„Außerhalb deines 30-Tage-Normbereichs“*), niemals als medizinische Diagnose oder Krankheitswarnung.
- **Platzierung (Antwort 18 a+c):** Drei Ringe prominent auf dem **„Heute“-Screen** (auf Marken-Navy `#001F47`), tiefgehende Detail-Analyse im **dunklen Health-Cockpit unter „Analyse“**, sowie Schnellzugriff auf Baselines & Journal über das **Avatar-Menü**.

## Arbeitspakete (Umsetzung aller Punkte a bis h)

### 21.1 Offene Score-Engine & 30-Tage-Baselines (Punkte b, c, d, h)
Implementiere in `functions/src/health/scores.ts` die Berechnung auf Basis der Garmin Health-API-Daten (bzw. manueller Einträge):
1. **Rolllierende 30-Tage-Baselines (Punkt h):**
   - Berechne für jeden Nutzer täglich den exponentiell gewichteten 30-Tage-Mittelwert und die Standardabweichung ($\sigma$) für: **nächtliche HRV (rMSSD)**, **Ruheherzfrequenz (RHR)**, **Atemfrequenz**, **Schlafdauer** und **Body Battery**.
2. **ORBIT Erholungs-Score (0–100 %, Punkt b):**
   - Gewichtete Formel aus: HRV-Abweichung zur 30-Tage-Baseline (45 %), RHR-Abweichung zur Baseline (25 %), Schlaf-Score der letzten Nacht (20 %) und Atemfrequenz/Body-Battery-Stabilität (10 %).
   - Ampel-Klassifikation: Grün (67–100 %: *Bereit für hohe Intensität*), Gelb (34–66 %: *Moderat trainieren*), Rot (0–33 %: *Fokus auf Regeneration*).
3. **ORBIT Tagesbelastung (0–100, Punkt c):**
   - Kombiniert die Trainings-Belastung des Tages (TSS aller Aktivitäten) mit der Alltags-Belastung aus Garmin Stress/Epochen/aktiven Kalorien auf einer logarithmischen 0–100 Skala.
   - Berechne ein **dynamisches Tagesziel (Optimaler Belastungsbereich)** abhängig vom heutigen Erholungs-Score (z. B. bei 85 % Erholung → empfohlene Belastung 65–80; bei 25 % Erholung → Empfehlung < 35).
4. **Schlaf-Analyse, Schlafbedarf & Schlafschuld (Punkt d):**
   - Berechnung von **Schlafbedarf** = individueller Basisbedarf (z. B. 7:45 h) + Aufschlag durch gestrige Tagesbelastung + 50 % der akkumulierten **Schlafschuld** der letzten 7 Tage.
   - **Schlaf-Score (0–100 %)** aus: Erreichte Schlafdauer vs. Schlafbedarf (50 %), Schlafeffizienz & Wachphasen (25 %), Anteil Tief-+REM-Schlaf (15 %) und **Schlaf-Konsistenz** (Einschlaf-/Aufwachzeit-Treue der letzten 7 Tage, 10 %).
5. **Finaler ORBIT Gesamt-Score (0–100):**
   - Vereint langfristige Trainings-Konsistenz, aktuelle Form (TSB), Erholungs-Balance und Plan-Erfüllung zu einer motivierenden Leit-Kennzahl.

### 21.2 Drei Ringe auf „Heute“ & Dunkles Health-Cockpit (Punkte a, e)
1. **Drei Ringe auf dem „Heute“-Tab (Punkt a):**
   - Rendere auf einer edlen `#001F47` Navy-Hero-Card die drei konzentrischen bzw. nebeneinander liegenden ORBIT-Ringe: **Erholung (%)**, **Tagesbelastung (inkl. Ziel-Korridor-Markierung)** und **Schlaf (%)** mit einem kurzen, klaren Tagessatz (*„Deine HRV liegt 8 ms über deinem 30-Tage-Schnitt. Idealer Tag für dein geplantes Schwellen-Intervall.“*).
2. **Health-Cockpit unter „Analyse“ & Avatar-Menü (Punkt e):**
   - Detail-Karten mit 7-/30-/90-Tage-Trendgraphen inkl. eingezeichnetem grauen **30-Tage-Normband** für HRV, Ruhepuls, Schlafphasen, Schlafschuld, Atemfrequenz sowie **Garmin Stress & Body-Battery-Tagesverlauf**.

### 21.3 Tägliches Kurz-Journal & Korrelationen (Punkt f)
1. Ein 15-Sekunden-Morgen-Check-in (optional per Tap auf dem Heute-Screen oder im Avatar-Menü) mit schnellen Toggle-Chips: *Koffein spät*, *Alkohol*, *Muskelkater*, *Hoher Alltagsstress*, *Schlecht gefühlt*, *Hydration gut*, *Reise/Höhe*.
2. **Automatische Korrelations-Auswertung:** Zeige im Health-Cockpit ab ≥ 14 Einträgen einfache, statistisch saubere Erkenntnisse (*„An Tagen mit spätem Koffein war dein Tiefschlaf im Schnitt 18 % kürzer“*).

### 21.4 Wochen- & Monatsberichte + Trainer-Ampel (Punkt g)
1. Automatisch generierte **Wochen- und Monats-Reports** (als In-App-Story-View & Karte): Zusammenfassung von Trainingsstunden, TSS, durchschnittlicher Erholung, Schlafschuld-Entwicklung und Top-Leistungen.
2. **Trainer-Ansicht:** Im Coach-Dashboard sieht der Trainer neben jedem Athleten (sofern der Art.-9-Health-Consent in Phase 18.3 aktiviert wurde!) die aktuelle **Erholungs-Ampel (Grün/Gelb/Rot)** samt HRV-Trendpfeil, um das Training rechtzeitig anzupassen.

## STOPP-Punkt & Abnahmekriterien
- **STOPP:** Präsentiere die Score-Formeln in `docs/HEALTH_SCORES.md`, Unit-Tests für Grenzfälle (fehlende HRV auf älteren Garmin-Uhren muss graceful auf RHR+Schlaf zurückfallen!) und UI-Tests für die 3 Ringe.
- Nach meiner Freigabe: Commit & Push auf GitHub mit Tag `v0.21.0`.