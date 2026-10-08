# Spec: Kennzahlen und ORBIT Score

> Formeln sind öffentlich dokumentiert. Prüfe sie gegen Fachliteratur, dokumentiere Annahmen im Code und hier. Keine Übernahme von Code aus Golden Cheetah (GPL).
> **Serverseitig maßgeblich** (Cloud Functions, TypeScript). Dart nur für die Workout-Builder-Vorschau. Beide testen gegen `testvectors/*.json`.

## Rad
- **Normalized Power (NP):** 30-s-gleitender Mittelwert der Leistung → 4. Potenz → Mittelwert → 4. Wurzel.
- **Intensity Factor (IF)** = NP / FTP.
- **TSS** = (Dauer_s × NP × IF) / (FTP × 3600) × 100.
- **Variability Index** = NP / Durchschnittsleistung.
- **Power-Duration-Kurve (Mean-Maximal-Power):** beste Durchschnittsleistung je Dauer. Geschätzte FTP/Critical Power daraus (Methode dokumentieren, Nutzer bestätigt).

## Lauf
- Pace, optional Grade-adjusted Pace. Belastung über **rTSS** (Schwellenpace) oder **hrTSS** (Schwellen-HF). Methode wählen und dokumentieren.
- Pace-Zonen aus Schwellenpace.

## Schwimmen
- Pace/100 m, SWOLF, Zugfrequenz (wenn vorhanden). Zonen aus **CSS** (Critical Swim Speed). Belastung **sTSS** (IF aus CSS/Ist-Pace, dokumentierte Formel). Pool (Bahnlänge, Längen) und Freiwasser unterscheiden.

## Gesamt
- **Zonenverteilung** (HF/Leistung/Pace) in Z1–Z7.
- **Trainingsbelastung:** CTL (42-Tage-exp. Mittel der Tagesbelastung), ATL (7-Tage), TSB = CTL(gestern) − ATL(gestern). Täglich über `localDate` aggregiert, in `aggregates` gespeichert.
- **VO₂max-Trend** aus Garmin-Daten, falls vorhanden. **Aerobic Decoupling** (Pa:HR) für lange Einheiten: (EF₁ − EF₂)/EF₁ aus erster/zweiter Hälfte.

## Schwellenwerte und Neuberechnung
Jede Aktivität speichert `thresholdsSnapshot` und `metricsVersion`. Schwellenwert-Änderungen wirken nur **zukünftig**. Neuberechnung der Vergangenheit nur über die Function `recomputeMetrics` auf ausdrücklichen Wunsch.

## ORBIT Score (Belastungsindex 0–100)
**Definition wird in der Analyse-Phase festgelegt und von mir freigegeben (STOPP-Punkt).** Anforderungen: transparent, erklärbar, dokumentiert in `docs/ORBIT_SCORE.md` (Definition, Formel, Annahmen, Grenzen). Orientierung statt medizinischer Aussage.
Vorschlag als Ausgangspunkt: Tageswert = Verhältnis der Tagesbelastung zur persönlichen Referenzbelastung (z. B. 28-Tage-Mittel), skaliert auf 0–100, 50 = typisch für diesen Athleten. Bei dünner Datenlage: kein Score, sondern Hinweis.

## Testvektoren
`testvectors/<metrik>.json` mit Eingabe-Zeitreihe und erwarteten Werten (Toleranz angeben). Mindestens: NP/TSS (konstante und variable Leistung), CTL/ATL (bekannte Tagesfolge), Zonenverteilung, Schwimm-Pace, Randfälle (leere Daten, Lücken, Pausen).

---

## Ergänzung A: Form-Ampel (UI-Abbildung, wird in Phase 10 am STOPP freigegeben)
- Grundlage ist TSB relativ zur **individuellen** CTL (nicht absolute Fremdwerte). Schwellen sind **Konfigurationswerte**, in `DECISIONS.md` begründet und per Test festgeschrieben.
- Vorgabe: vier Zustände mit neutralen Texten (z. B. *Sehr müde · Gut belastet · Ausgeglichen · Frisch*), jeweils mit Datenbasis („basiert auf 6 Wochen Training"). **Mindestdatenlage:** z. B. ≥ 21 Tage mit Daten, sonst „Noch zu wenig Daten", keine Ampel.
- Formulierung ist **Hinweis, keine Anweisung und kein medizinischer Rat** (nie „du musst", nie Gesundheitsversprechen). Kein Alarmismus bei Überlastung, stattdessen neutrale Einordnung und Verweis auf den Trainer.

## Ergänzung B: Schwellenwert-Schätzung (Phase 12, am STOPP freigegeben)
Methoden werden in der Phase begründet, hier die Anforderungen:
- **Rad-FTP:** aus bester Mittelleistung (z. B. 20 min) innerhalb eines definierten Zeitfensters mit dokumentiertem Faktor, oder aus einem Critical-Power-Modell. Mindestanzahl harter Einheiten und Datenqualität prüfen.
- **Lauf:** Schwellen-HF und Schwellenpace aus länger anhaltenden maximalen Anstrengungen. **Schwimmen:** CSS aus 400 m/200 m (oder gleichwertigen Bestleistungen).
- Jeder Vorschlag hat: Wert, Veränderung zum aktuellen Wert, **Konfidenz** (hoch/mittel/niedrig), **Datenbasis** (welche Einheiten, welcher Zeitraum) und eine verständliche Erklärung. Bei niedriger Datenlage **kein** Vorschlag.
- **Nie automatisch übernehmen.** Übernahme erzeugt einen neuen `thresholdHistory`-Eintrag mit `effectiveFrom = heute`.
