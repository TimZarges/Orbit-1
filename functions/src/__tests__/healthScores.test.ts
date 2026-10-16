/**
 * ORBIT Phase 21 - Health & Recovery Unit-Tests.
 * Prüft 30-Tage-Baselines, Erholungs-Score, Graceful Degradation,
 * Tagesbelastung & Zielkorridor, Schlafschuld & Schlafbedarf sowie Korrelationen.
 */

import {
  calculateRollingBaseline,
  calculateUserBaselines,
} from "../health/baselines";
import {
  calculateRecoveryScore,
  sigmoidScore,
} from "../health/recovery";
import {
  calculateDailyStrain,
  calculateOptimalStrainTarget,
} from "../health/strain";
import {
  calculateSleepNeed,
  calculate7DaySleepDebt,
  calculateSleepScore,
} from "../health/sleep";
import { calculateOrbitScore } from "../health/orbitScore";
import {
  analyzeJournalCorrelations,
  CorrelationInputRecord,
} from "../health/correlations";
import { DailyHealthInput, UserBaselines } from "../health/types";

describe("Phase 21 - Health & Recovery Score Engine", () => {
  // =========================================================================
  // 1. Rolllierende 30-Tage-Baselines & Normbänder
  // =========================================================================
  describe("1. Rolllierende 30-Tage-Baselines", () => {
    it("berechnet Mittelwert und Standardabweichung für eine 30-Tage-Serie exakt", () => {
      // 30 Tage HRV-Werte um einen Mittelwert von 60 ms mit Streuung
      const hrvValues = [
        58, 62, 59, 61, 60, 63, 57, 60, 62, 59,
        61, 60, 58, 62, 60, 59, 61, 63, 58, 60,
        61, 59, 60, 62, 58, 61, 60, 59, 62, 60,
      ];

      const baseline = calculateRollingBaseline(hrvValues, 1.0);
      expect(baseline).toBeDefined();
      expect(baseline!.count).toBe(30);
      expect(baseline!.mean).toBeCloseTo(60.17, 1);
      expect(baseline!.standardDeviation).toBeGreaterThan(1.0);
      expect(baseline!.normBandMin).toBeLessThan(baseline!.mean);
      expect(baseline!.normBandMax).toBeGreaterThan(baseline!.mean);
      expect(baseline!.normBandMax - baseline!.normBandMin).toBeCloseTo(
        2 * baseline!.standardDeviation,
        1
      );
    });

    it("liefert undefined bei weniger als 3 validen Messwerten", () => {
      expect(calculateRollingBaseline([])).toBeUndefined();
      expect(calculateRollingBaseline([60])).toBeUndefined();
      expect(calculateRollingBaseline([60, 62])).toBeUndefined();
      expect(calculateRollingBaseline([60, 62, 64])).toBeDefined();
    });

    it("extrahiert alle 5 Baselines aus DailyHealthInput Historie", () => {
      const history: DailyHealthInput[] = [];
      for (let i = 1; i <= 30; i++) {
        history.push({
          date: `2026-09-${i.toString().padStart(2, "0")}`,
          hrvMs: 55 + (i % 5),
          restingHrBpm: 52 + (i % 3),
          sleepSeconds: (7.5 + (i % 2) * 0.5) * 3600,
          respirationRate: 14.0 + (i % 3) * 0.2,
          bodyBattery: 75 + (i % 10),
        });
      }

      const baselines = calculateUserBaselines(history);
      expect(baselines.hrv).toBeDefined();
      expect(baselines.rhr).toBeDefined();
      expect(baselines.sleep).toBeDefined();
      expect(baselines.respiration).toBeDefined();
      expect(baselines.bodyBattery).toBeDefined();

      expect(baselines.hrv!.count).toBe(30);
      expect(baselines.rhr!.mean).toBeCloseTo(53.0, 0);
      expect(baselines.sleep!.mean).toBeCloseTo(7.75, 1);
    });
  });

  // =========================================================================
  // 2. ORBIT Erholungs-Score & Ampel-Klassifikation
  // =========================================================================
  describe("2. ORBIT Erholungs-Score", () => {
    const mockBaselines: UserBaselines = {
      hrv: { mean: 60, standardDeviation: 10, count: 30, normBandMin: 50, normBandMax: 70 },
      rhr: { mean: 52, standardDeviation: 4, count: 30, normBandMin: 48, normBandMax: 56 },
      sleep: { mean: 7.75, standardDeviation: 0.8, count: 30, normBandMin: 6.95, normBandMax: 8.55 },
      respiration: { mean: 14.5, standardDeviation: 1.0, count: 30, normBandMin: 13.5, normBandMax: 15.5 },
      bodyBattery: { mean: 80, standardDeviation: 8, count: 30, normBandMin: 72, normBandMax: 88 },
    };

    it("liefert GRÜN (>= 67 %) bei überdurchschnittlicher Erholung", () => {
      // HRV 72 (+1.2 sigma), RHR 48 (-1.0 sigma), Schlaf 90 %, Body Battery 90
      const today: DailyHealthInput = {
        date: "2026-10-16",
        hrvMs: 72,
        restingHrBpm: 48,
        sleepScore: 90,
        bodyBattery: 90,
        respirationRate: 14.2,
      };

      const result = calculateRecoveryScore(today, mockBaselines);
      expect(result.score).toBeGreaterThanOrEqual(67);
      expect(result.classification).toBe("GREEN");
      expect(result.recommendationDe).toContain("Bereit für");
      expect(result.recommendationEn).toContain("Primed for");
      expect(result.zHrv).toBeCloseTo(1.2, 1);
      expect(result.zRhr).toBeCloseTo(1.0, 1);
    });

    it("liefert ROT (<= 33 %) bei hoher vegetativer Belastung / Übermüdung", () => {
      // HRV 42 (-1.8 sigma), RHR 60 (+2.0 sigma), Schlaf 40 %, Body Battery 40, Atemfrequenz erhöht 16.5
      const today: DailyHealthInput = {
        date: "2026-10-16",
        hrvMs: 42,
        restingHrBpm: 60,
        sleepScore: 40,
        bodyBattery: 40,
        respirationRate: 16.5,
      };

      const result = calculateRecoveryScore(today, mockBaselines);
      expect(result.score).toBeLessThanOrEqual(33);
      expect(result.classification).toBe("RED");
      expect(result.recommendationDe).toContain("Fokus auf aktive Erholung");
    });

    it("liefert GELB (34–66 %) im soliden Normalbereich", () => {
      // Exakt auf Baseline
      const today: DailyHealthInput = {
        date: "2026-10-16",
        hrvMs: 60,
        restingHrBpm: 52,
        sleepScore: 70,
        bodyBattery: 75,
        respirationRate: 14.5,
      };

      const result = calculateRecoveryScore(today, mockBaselines);
      expect(result.score).toBeGreaterThanOrEqual(34);
      expect(result.score).toBeLessThanOrEqual(66);
      expect(result.classification).toBe("YELLOW");
    });

    it("prüft die mathematische Sensitivität der logistischen Sigmoid-Funktion", () => {
      expect(sigmoidScore(0)).toBe(50);
      expect(sigmoidScore(1.0)).toBeCloseTo(77.7, 1);
      expect(sigmoidScore(-1.0)).toBeCloseTo(22.3, 1);
      expect(sigmoidScore(2.0)).toBeGreaterThan(90);
      expect(sigmoidScore(-2.0)).toBeLessThan(10);
    });
  });

  // =========================================================================
  // 3. Graceful Degradation (Pflicht-Test!)
  // =========================================================================
  describe("3. Graceful Degradation (Fehlende Sensoren auf älteren Garmin-Uhren)", () => {
    it("berechnet Erholungs-Score ohne HRV und Atemfrequenz ohne NaN oder 0", () => {
      // Ältere Garmin liefert NUR Ruhepuls und Schlaf
      const todayWithoutHrv: DailyHealthInput = {
        date: "2026-10-16",
        restingHrBpm: 50, // Gut (-0.5 sigma bei mean 52, std 4)
        sleepScore: 85,
        // hrvMs fehlt!
        // respirationRate fehlt!
        // bodyBattery fehlt!
      };

      const baselines: UserBaselines = {
        rhr: { mean: 52, standardDeviation: 4, count: 20, normBandMin: 48, normBandMax: 56 },
      };

      const result = calculateRecoveryScore(todayWithoutHrv, baselines);

      // Muss valide Zahl zwischen 0 und 100 sein
      expect(isNaN(result.score)).toBe(false);
      expect(isFinite(result.score)).toBe(true);
      expect(result.score).toBeGreaterThan(50);
      expect(result.score).toBeLessThanOrEqual(100);

      // Gewichte müssen dynamisch normiert sein: HRV = 0, RHR + Schlaf = 1.0
      expect(result.weightsUsed.hrv).toBe(0);
      expect(result.weightsUsed.respOrBb).toBe(0);
      expect(result.weightsUsed.rhr + result.weightsUsed.sleep).toBeCloseTo(1.0, 2);
    });

    it("verarbeitet komplett leere Messwerte mit sicherem 50 % YELLOW Fallback", () => {
      const emptyDay: DailyHealthInput = { date: "2026-10-16" };
      const emptyBaselines: UserBaselines = {};

      const result = calculateRecoveryScore(emptyDay, emptyBaselines);
      expect(result.score).toBe(50);
      expect(result.classification).toBe("YELLOW");
      expect(result.weightsUsed.hrv).toBe(0);
    });
  });

  // =========================================================================
  // 4. ORBIT Tagesbelastung & Dynamischer Zielkorridor
  // =========================================================================
  describe("4. ORBIT Tagesbelastung (0–100) & Dynamischer Zielkorridor", () => {
    it("berechnet logarithmische Belastungsskala für Ruhetag, Training und Wettkampf", () => {
      // Ruhetag ohne Training
      const restDay = calculateDailyStrain(0, 200, 25);
      expect(restDay.score).toBeLessThanOrEqual(20);

      // Moderater Trainingstag: 80 TSS + Alltag
      const workoutDay = calculateDailyStrain(80, 600, 35);
      expect(workoutDay.score).toBeGreaterThanOrEqual(35);
      expect(workoutDay.score).toBeLessThanOrEqual(55);

      // Harter Long-Ride: 350 TSS + hoher Kalorienverbrauch
      const epicDay = calculateDailyStrain(350, 2200, 45);
      expect(epicDay.score).toBeGreaterThanOrEqual(65);
      expect(epicDay.score).toBeLessThanOrEqual(85);
    });

    it("passt den optimalen Belastungs-Zielkorridor dynamisch an den Erholungs-Score an", () => {
      // Hohe Erholung (85 % Grün) -> Hoher Zielbereich (z. B. 60–81)
      const greenTarget = calculateOptimalStrainTarget(85);
      expect(greenTarget.min).toBeGreaterThanOrEqual(58);
      expect(greenTarget.max).toBeGreaterThanOrEqual(75);

      // Moderate Erholung (50 % Gelb) -> Moderater Bereich (ca. 40–61)
      const yellowTarget = calculateOptimalStrainTarget(50);
      expect(yellowTarget.min).toBeCloseTo(41, 1);
      expect(yellowTarget.max).toBeCloseTo(61, 1);

      // Niedrige Erholung (20 % Rot) -> Regenerativer Bereich (10–31)
      const redTarget = calculateOptimalStrainTarget(20);
      expect(redTarget.min).toBe(10);
      expect(redTarget.max).toBeLessThanOrEqual(35);
    });
  });

  // =========================================================================
  // 5. Schlafbedarf, 7-Tage-Schlafschuld & Schlaf-Score
  // =========================================================================
  describe("5. Schlafbedarf & 7-Tage-Schlafschuld", () => {
    it("akkumuliert Schlafschuld über 7 Tage mit Deckelung auf 6.0 Stunden", () => {
      // 7 Tage à 6.0h Schlaf bei 8.0h Bedarf -> 7 x 2.0h = 14h Defizit -> gedeckelt auf 6.0h
      const history = [
        { durationHours: 6.0, needHours: 8.0 },
        { durationHours: 6.0, needHours: 8.0 },
        { durationHours: 6.0, needHours: 8.0 },
        { durationHours: 6.0, needHours: 8.0 },
        { durationHours: 6.0, needHours: 8.0 },
        { durationHours: 6.0, needHours: 8.0 },
        { durationHours: 6.0, needHours: 8.0 },
      ];

      const { accumulatedDebtHours, dailyDebts } = calculate7DaySleepDebt(history);
      expect(dailyDebts).toHaveLength(7);
      expect(dailyDebts[0]).toBe(2.0);
      expect(accumulatedDebtHours).toBe(6.0); // Gedeckelt
    });

    it("berechnet Schlafbedarf mit Belastungsaufschlag und 50 % Schuldabbau", () => {
      // Basis 7.75h + Belastung 60 (0.012 * 60 = 0.72h) + 50 % von 3.0h Schuld (1.5h) = 9.97h
      const needResult = calculateSleepNeed(7.75, 60, 3.0);
      expect(needResult.baseNeedHours).toBe(7.75);
      expect(needResult.strainSurchargeHours).toBe(0.72);
      expect(needResult.needHours).toBeCloseTo(9.97, 2);
    });

    it("berechnet 4-Faktoren-Schlaf-Score gewichtet", () => {
      const scoreResult = calculateSleepScore({
        sleepDurationHours: 8.0,
        needHours: 8.0,
        timeInBedHours: 8.5, // ~94 % Effizienz
        deepHours: 1.8,
        remHours: 1.6, // 3.4h von 8.0h = 42.5 % Tief+REM (optimal >= 40 %)
        bedtimeConsistencyMinutes: 20, // Stabile Bettzeit
      });

      expect(scoreResult.score).toBeGreaterThanOrEqual(90);
      expect(scoreResult.durationScore).toBe(100);
      expect(scoreResult.efficiencyScore).toBeGreaterThan(90);
      expect(scoreResult.stagesScore).toBe(100);
      expect(scoreResult.consistencyScore).toBeGreaterThan(75);
    });
  });

  // =========================================================================
  // 6. Finaler ORBIT Gesamt-Score (0–100)
  // =========================================================================
  describe("6. Finaler ORBIT Gesamt-Score", () => {
    it("berechnet harmonischen Leit-Index aus Konsistenz, TSB, Erholung und Schlaf", () => {
      const topState = calculateOrbitScore({
        consistencyRatio: 1.0, // 100 % Trainingskonsistenz
        tsb: 0, // Perfekte Form (100 %)
        recoveryAvg7d: 82, // 82 % Erholung
        sleepAvg7d: 88, // 88 % Schlaf
        accumulatedDebt7dHours: 0.5,
      });

      expect(topState.score).toBeGreaterThanOrEqual(85);
      expect(topState.consistencyScore).toBe(100);
      expect(topState.tsbScore).toBe(100);

      // Erschöpfter Zustand mit Übertraining
      const fatigueState = calculateOrbitScore({
        consistencyRatio: 0.6,
        tsb: -35, // Stark ermüdet
        recoveryAvg7d: 35,
        sleepAvg7d: 60,
        accumulatedDebt7dHours: 5.0, // Hohe Schlafschuld
      });

      expect(fatigueState.score).toBeLessThanOrEqual(50);
      expect(fatigueState.tsbScore).toBeLessThan(50);
    });
  });

  // =========================================================================
  // 7. Journal-Korrelations-Engine (Punkt f)
  // =========================================================================
  describe("7. Journal-Korrelations-Engine", () => {
    it("erkennt statistisch bedeutsame Einflüsse von spätem Koffein und Alkohol", () => {
      const records: CorrelationInputRecord[] = [];

      for (let i = 1; i <= 20; i++) {
        const isAlcoholDay = i % 4 === 0; // 5 Tage mit Alkohol
        const isCaffeineDay = i % 3 === 0 && !isAlcoholDay; // Tage mit spätem Koffein

        records.push({
          date: `2026-10-${i.toString().padStart(2, "0")}`,
          journal: {
            alcohol: isAlcoholDay,
            lateCaffeine: isCaffeineDay,
          },
          // An Alkohol-Tagen: HRV um 16 ms niedriger (44 vs 60), Ruhepuls 56 vs 50
          hrvMs: isAlcoholDay ? 44 : 60,
          restingHrBpm: isAlcoholDay ? 56 : 50,
          // An Koffein-Tagen: Tiefschlaf um 25 Min. kürzer (45 vs 70 min)
          deepSleepMinutes: isCaffeineDay ? 45 : 70,
          recoveryScore: isAlcoholDay ? 38 : 72,
        });
      }

      const insights = analyzeJournalCorrelations(records);
      expect(insights.length).toBeGreaterThanOrEqual(2);

      // Alkohol-Insight für HRV vorhanden
      const alcoholHrv = insights.find((ins) => ins.tag === "alcohol" && ins.metric === "hrv");
      expect(alcoholHrv).toBeDefined();
      expect(alcoholHrv!.delta).toBeLessThan(-10);
      expect(alcoholHrv!.insightDe).toContain("Alkohol sank deine HRV");
      expect(alcoholHrv!.insightEn).toContain("alcohol, your HRV dropped");

      // Koffein-Insight für Tiefschlaf vorhanden
      const caffeineDeep = insights.find(
        (ins) => ins.tag === "lateCaffeine" && ins.metric === "deepSleep"
      );
      expect(caffeineDeep).toBeDefined();
      expect(caffeineDeep!.delta).toBeLessThan(-15);
      expect(caffeineDeep!.insightDe).toContain("Tiefschlaf im Schnitt");
      expect(caffeineDeep!.insightEn).toContain("deep sleep was");
    });

    it("gibt leeres Array zurück bei weniger als 14 Tagen Historie", () => {
      const fewRecords: CorrelationInputRecord[] = [
        { date: "2026-10-01", journal: { alcohol: true }, hrvMs: 50 },
        { date: "2026-10-02", journal: { alcohol: false }, hrvMs: 65 },
      ];
      expect(analyzeJournalCorrelations(fewRecords)).toHaveLength(0);
    });
  });
});
