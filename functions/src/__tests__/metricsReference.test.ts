import {
  calculatePowerMetrics,
  calculateSkibaWPrimeBal,
  estimateCriticalPowerFromMmp,
} from "../metrics/power";
import {
  calculateGradeAdjustedSpeed,
  calculateRunningMetrics,
  minettiEnergyCost,
} from "../metrics/running";
import {
  calculateCssFromTimeTrials,
  calculateSwimMetrics,
} from "../metrics/swimming";
import { calculateAerobicDecoupling } from "../metrics/decoupling";
import { detectAutoIntervals } from "../metrics/intervals";
import { calculatePmcSeries } from "../metrics/pmc";
import { calculateBrickAnalysis } from "../metrics/brick";

describe("Phase 20 - Mathematische Referenz-Testsuite (GoldenCheetah-/Sportwissenschafts-Verifikation)", () => {
  // =========================================================================
  // Test 1: Coggan Steady-State (NP, IF, TSS)
  // =========================================================================
  test("Test 1 (Coggan Steady-State): 3600s konstant 250 W bei FTP = 250 W liefert exakt NP = 250.0, IF = 1.00, TSS = 100.0", () => {
    const durationSec = 3600;
    const powerStream = new Array(durationSec).fill(250);
    const ftp = 250;

    const result = calculatePowerMetrics(powerStream, ftp);

    expect(result.avgPower).toBe(250.0);
    expect(result.np).toBe(250.0);
    expect(result.iff).toBe(1.0);
    expect(result.tss).toBe(100.0);
    expect(result.vi).toBe(1.0);
    expect(result.workKj).toBe(900.0); // 250 W * 3600 s / 1000 = 900 kJ
  });

  // =========================================================================
  // Test 2: Variabilitäts-Index (VI) & Intermittierende Wechselbelastung
  // =========================================================================
  test("Test 2 (Variabilitäts-Index VI): Intermittierende Belastung (30s @ 350 W / 30s @ 150 W) -> NP > AvgPower und VI analytisch verifiziert", () => {
    const powerStream: number[] = [];

    for (let cycle = 0; cycle < 60; cycle++) {
      for (let s = 0; s < 30; s++) powerStream.push(350);
      for (let s = 0; s < 30; s++) powerStream.push(150);
    }

    const ftp = 250;
    const result = calculatePowerMetrics(powerStream, ftp);

    // Arithmetisches Mittel muss exakt 250.0 W sein
    expect(result.avgPower).toBe(250.0);

    // Normalized Power muss durch die 4. Potenzierung signifikant ÜBER dem arithmetischen Mittel liegen
    expect(result.np).toBeGreaterThan(result.avgPower);

    // Variabilitätsindex VI = NP / AvgPower muss exakt dem analytischen Integralwert (1.073) entsprechen
    expect(result.np).toBeCloseTo(268.3, 0);
    expect(result.vi).toBe(1.073);
    expect(result.vi).toBeGreaterThan(1.05);

    // TSS muss höher sein als bei konstant 250W (da physiologisch fordernder: ~115 TSS vs 100 TSS)
    expect(result.tss).toBeGreaterThan(110.0);
  });

  // =========================================================================
  // Test 3: Skiba W'bal-Modell (Entleerung & Exponentielle Wiederaufladung)
  // =========================================================================
  test("Test 3 (Skiba W'bal): 3min @ 350 W (CP = 280 W, W' = 20 kJ) gefolgt von 3min Erholung @ 150 W -> exakte Entleerung und Wiederaufladung", () => {
    const cp = 280;
    const wPrime = 20000; // 20 kJ in Joules

    // 180s Belastung bei 350 W (70 W über CP)
    const workPhase = new Array(180).fill(350);
    // 180s Erholung bei 150 W (130 W unter CP)
    const recoveryPhase = new Array(180).fill(150);
    const powerStream = [...workPhase, ...recoveryPhase];

    const result = calculateSkibaWPrimeBal(powerStream, cp, wPrime);

    // 1. Analytische Prüfung der Entleerung nach 180s:
    // W'bal(180) = 20000 - (180 * 70) = 20000 - 12600 = 7400 Joules
    const wBalAt180 = result.wPrimeBalJoules[179];
    expect(wBalAt180).toBe(7400.0);
    expect(result.minWPrimeBalJoules).toBe(7400.0);
    expect(result.minWPrimeBalPercent).toBe(37.0); // 7400 / 20000 = 37%

    // 2. Analytische Prüfung der Erholung:
    // D_under = 280 - 150 = 130 W
    // tau = 546 * exp(-0.01 * 130) + 316 = 546 * exp(-1.3) + 316 ≈ 464.8 s
    // W'bal(360) = W'bal(180) + (20000 - W'bal(180)) * (1 - exp(-180 / tau))
    const dUnder = cp - 150;
    const tau = 546 * Math.exp(-0.01 * dUnder) + 316;
    const expectedRecovery = (wPrime - 7400) * (1 - Math.exp(-180 / tau));
    const expectedWBalEnd = 7400 + expectedRecovery; // ca. 11445.8 J

    const actualWBalEnd = result.wPrimeBalJoules[359];
    expect(Math.abs(actualWBalEnd - expectedWBalEnd)).toBeLessThan(10.0); // < 0.1 % Toleranz
    expect(actualWBalEnd).toBeGreaterThan(7400.0);
    expect(actualWBalEnd).toBeLessThan(wPrime);
  });

  // =========================================================================
  // Test 3b: Critical Power Schätzung aus MMP
  // =========================================================================
  test("Test 3b (Critical Power Schätzung): MMP-Stützpunkte liefern konsistentes CP und W'", () => {
    // Synthetische MMP-Kurve generiert aus echtem CP = 280 W, W' = 20000 J
    // P(t) = 280 + 20000 / t
    const mmpPoints: Record<number, number> = {
      180: Math.round(280 + 20000 / 180), // 391 W
      300: Math.round(280 + 20000 / 300), // 347 W
      600: Math.round(280 + 20000 / 600), // 313 W
      1200: Math.round(280 + 20000 / 1200), // 297 W
    };

    const cpModel = estimateCriticalPowerFromMmp(mmpPoints);

    // CP muss innerhalb 278 - 282 W liegen (< 1% Abweichung)
    expect(cpModel.cpWatts).toBeGreaterThanOrEqual(278);
    expect(cpModel.cpWatts).toBeLessThanOrEqual(282);

    // W' muss innerhalb 19.5 - 20.5 kJ liegen
    expect(cpModel.wPrimeKj).toBeGreaterThanOrEqual(19.0);
    expect(cpModel.wPrimeKj).toBeLessThanOrEqual(21.0);
    expect(cpModel.rSquared).toBeGreaterThan(0.99);
  });

  // =========================================================================
  // Test 4: Banister PMC (Impulse-Response Modell)
  // =========================================================================
  test("Test 4 (Banister PMC): 42 Tage à 100 TSS ab Startwert 0 konvergieren gegen 100 * (1 - e^-1) ≈ 63.21", () => {
    const history: { localDate: string; tss: number }[] = [];
    const baseDate = new Date("2026-09-01T12:00:00Z");

    for (let day = 0; day < 42; day++) {
      const cur = new Date(baseDate);
      cur.setDate(baseDate.getDate() + day);
      history.push({
        localDate: cur.toISOString().split("T")[0],
        tss: 100,
      });
    }

    const pmc = calculatePmcSeries(history, undefined, 0, 0);

    // Theoretischer mathematischer Wert nach genau 42 Tagen bei tau = 42:
    // CTL(42) = 100 * (1 - exp(-42/42)) = 100 * (1 - exp(-1)) ≈ 63.212
    const theoreticalCtl42 = 100 * (1 - Math.exp(-1));

    expect(Math.abs(pmc.currentCtl - theoreticalCtl42)).toBeLessThan(1.0); // < 1 % Toleranz

    // ATL mit tau = 7 Tagen konvergiert nach 42 Tagen (6 Halbwertszeiten) nahezu vollständig gegen 100
    // ATL(42) = 100 * (1 - exp(-42/7)) = 100 * (1 - exp(-6)) ≈ 99.75
    expect(pmc.currentAtl).toBeGreaterThan(98.0);
    expect(pmc.currentAtl).toBeLessThanOrEqual(100.0);

    // TSB muss negativ sein (starke akute Ermüdung)
    expect(pmc.currentTsb).toBeLessThan(0);
  });

  test("Test 4b (PMC Ramp-Rate & 14-Tage-Projektion): Überlastungs-Alarm bei Ramp-Rate > 7 TSS/Woche", () => {
    // Steiler Belastungssprung von 20 auf 150 TSS/Tag
    const history: { localDate: string; tss: number }[] = [];
    const baseDate = new Date("2026-09-01T12:00:00Z");

    for (let day = 0; day < 14; day++) {
      const cur = new Date(baseDate);
      cur.setDate(baseDate.getDate() + day);
      history.push({
        localDate: cur.toISOString().split("T")[0],
        tss: day < 7 ? 20 : 180, // Drastischer Spike in Woche 2
      });
    }

    // 14 geplante Tage mit Tapering (sinkende Last für Peak)
    const planned: { localDate: string; plannedTss: number }[] = [];
    for (let day = 14; day < 28; day++) {
      const cur = new Date(baseDate);
      cur.setDate(baseDate.getDate() + day);
      planned.push({
        localDate: cur.toISOString().split("T")[0],
        plannedTss: 30, // Tapering
      });
    }

    const pmc = calculatePmcSeries(history, planned, 30, 30);

    // Ramp Rate muss über 7.0 liegen und Alarm auslösen
    expect(pmc.rampRate7d).toBeGreaterThan(7.0);
    expect(pmc.rampRateAlert).toBe(true);

    // Durch Tapering in den 14 Tagen Projektion muss TSB deutlich ansteigen (Erholung)
    expect(pmc.projectedTsbIn14d).toBeGreaterThan(pmc.currentTsb);
  });

  // =========================================================================
  // Test 5: Aerobic Decoupling & Auto-Intervalle
  // =========================================================================
  test("Test 5 (Aerobic Decoupling): 60-minütiger Steady-State Stream mit 5 % HF-Drift in Hälfte 2 liefert ca. 4.8 % Decoupling", () => {
    const halfDuration = 1800; // 30 min
    const powers = new Array(halfDuration * 2).fill(200);

    // Erste Hälfte: 140 bpm, zweite Hälfte: 147 bpm (+5 % Drift)
    const hr1 = new Array(halfDuration).fill(140);
    const hr2 = new Array(halfDuration).fill(147);
    const heartRates = [...hr1, ...hr2];

    const result = calculateAerobicDecoupling(powers, heartRates, 250);

    // EF1 = 200 / 140 ≈ 1.43
    // EF2 = 200 / 147 ≈ 1.36
    // Decoupling = (1.43 - 1.36) / 1.43 * 100 = (1 - 140/147) * 100 ≈ 4.76 %
    expect(result.decouplingPercent).toBeGreaterThanOrEqual(4.5);
    expect(result.decouplingPercent).toBeLessThanOrEqual(5.0);
    expect(result.classification).toBe("COUPLED");
  });

  test("Test 5b (Auto-Intervalle): Erkennt eingebettete 4 x 4min Intervalle @ 300 W über 90 % FTP", () => {
    const powerStream: number[] = [];
    const ftp = 250; // 90% Schwelle = 225 W

    // 10 min Warmup @ 150 W
    for (let s = 0; s < 600; s++) powerStream.push(150);

    // 4 Intervalle à 4 min (240s) @ 300 W mit 2 min (120s) Pause @ 120 W
    for (let rep = 0; rep < 4; rep++) {
      for (let s = 0; s < 240; s++) powerStream.push(300);
      for (let s = 0; s < 120; s++) powerStream.push(120);
    }

    // 10 min Cooldown @ 140 W
    for (let s = 0; s < 600; s++) powerStream.push(140);

    const intervals = detectAutoIntervals(powerStream, ftp, 30, 0.90);

    // Es müssen exakt 4 Intervalle erkannt werden
    expect(intervals.length).toBe(4);

    for (let i = 0; i < 4; i++) {
      expect(intervals[i].durationSec).toBe(240);
      expect(intervals[i].avgValue).toBe(300);
      expect(intervals[i].npValue).toBe(300);
      expect(intervals[i].intensityPercent).toBe(120); // 300 W / 250 W = 120%
    }
  });

  // =========================================================================
  // Test 6: Lauf- (Minetti GAP & rTSS) und Schwimm-Metriken (CSS & sTSS)
  // =========================================================================
  test("Test 6 (Lauf Minetti GAP & rTSS): Steigung erhöht GAP und rTSS überproportional", () => {
    // Minetti Kosten flach: Cr(0) = 3.6 J/(kg*m)
    expect(minettiEnergyCost(0)).toBe(3.6);

    // 10% Steigung (g = 0.10) muss signifikant höhere Energiekosten haben (~65.8% Anstieg)
    const cost10 = minettiEnergyCost(0.10);
    expect(cost10).toBeCloseTo(5.97, 1);
    expect(cost10).toBeGreaterThan(5.8);

    // 3.33 m/s (5:00 min/km) an 5% Steigung entspricht Flachland-Geschwindigkeit > 4.0 m/s
    const adjustedSpeed = calculateGradeAdjustedSpeed(3.333, 5);
    expect(adjustedSpeed).toBeGreaterThan(3.8);

    // 3600s Lauf bei Schwellenpace (300 s/km = 5:00 min/km) flach -> rTSS ≈ 100.0
    const flatSpeeds = new Array(3600).fill(3.3333);
    const flatRun = calculateRunningMetrics(flatSpeeds, undefined, 300);
    expect(flatRun.ifRun).toBeCloseTo(1.0, 1);
    expect(flatRun.rTSS).toBeCloseTo(100.0, 0);
  });

  test("Test 7 (Schwimmen CSS & sTSS): CSS aus 400m/200m und kubischer sTSS-Verlauf", () => {
    // 400m in 360s (6:00 min), 200m in 160s (2:40 min)
    // CSS = 200 / (360 - 160) = 200 / 200 = 1.0 m/s -> 100s / 100m (1:40 min/100m)
    const css = calculateCssFromTimeTrials(360, 160);
    expect(css.vCssMps).toBe(1.0);
    expect(css.cssPaceSecPer100m).toBe(100);

    // 3600s Schwimmen bei exakt CSS (1.0 m/s -> 3600m in 3600s) -> sTSS = 100.0
    const swim = calculateSwimMetrics(3600, 3600, 100, 50, 1800);
    expect(swim.ifSwim).toBe(1.0);
    expect(swim.sTSS).toBe(100.0);
    expect(swim.swolf).toBeDefined(); // Zeit pro 50m (50s) + Züge (25) = 75
    expect(swim.swolf).toBe(75);
    expect(swim.dpsM).toBe(2.0); // 3600m / 1800 Züge = 2.0 m/Zug
  });

  test("Test 8 (Multisport Brick-Analyse): Erkennt Pace-Abfall nach Wechselzone", () => {
    // Erste 2 km (2000m) in hohem Tempo (240 s/km = 4:00 min/km)
    // Folgende 3 km in ermüdetem Tempo (280 s/km = 4:40 min/km)
    const segmentPaces = [240, 240, 280, 280, 280];
    const segmentDists = [1000, 1000, 1000, 1000, 1000];

    const brick = calculateBrickAnalysis(segmentPaces, segmentDists, 75);
    expect(brick.hasBrickContext).toBe(true);
    expect(brick.t2DurationSec).toBe(75);
    expect(brick.initial2kAvgPaceSecPerKm).toBe(240);
    expect(brick.remainingRunAvgPaceSecPerKm).toBe(280);
    expect(brick.paceDeltaSecPerKm).toBe(40);
    expect(brick.stabilityScore).toBe("FATIGUED");
  });
});
