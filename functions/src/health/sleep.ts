/**
 * ORBIT Schlafbedarf, 7-Tage-Schlafschuld & differenzierter Schlaf-Score (0–100 %).
 */

import { SleepNeedResult, SleepScoreResult } from "./types";

/**
 * Berechnet den individuellen Schlafbedarf (in Stunden) für die kommende Nacht
 * basierend auf Basisbedarf, gestriger Tagesbelastung und akkumulierter Schlafschuld.
 */
export function calculateSleepNeed(
  baseNeedHours: number = 7.75,
  yesterdayStrain: number = 0,
  accumulatedDebt7dHours: number = 0
): SleepNeedResult {
  const base = Math.max(5.0, Math.min(10.0, baseNeedHours));
  const strain = Math.max(0, Math.min(100, yesterdayStrain));

  // Zuschlag aus Belastung: bis zu ~1.2 Stunden bei Maximallast
  const strainSurchargeHours = +(0.012 * strain).toFixed(2);

  // 50 % der akkumulierten Schlafschuld der letzten 7 Tage abbauen (gedeckelt auf max 3h Zuschlag)
  const cappedDebt = Math.max(0, Math.min(6.0, accumulatedDebt7dHours));
  const debtPaybackHours = +(0.5 * cappedDebt).toFixed(2);

  const needHours = +(base + strainSurchargeHours + debtPaybackHours).toFixed(2);

  return {
    needHours,
    baseNeedHours: base,
    strainSurchargeHours,
    accumulatedDebtHours: cappedDebt,
  };
}

/**
 * Berechnet die akkumulierte 7-Tage-Schlafschuld aus einer Serie von Schlafprotokollen.
 */
export function calculate7DaySleepDebt(
  dailySleepHistory: Array<{ durationHours: number; needHours: number }>
): { accumulatedDebtHours: number; dailyDebts: number[] } {
  // Betrachte maximal die letzten 7 Tage
  const recent = dailySleepHistory.slice(-7);
  const dailyDebts: number[] = [];
  let totalDebt = 0;

  for (const day of recent) {
    const debt = Math.max(0, day.needHours - day.durationHours);
    dailyDebts.push(+debt.toFixed(2));
    totalDebt += debt;
  }

  // Akkumulierte Schlafschuld auf max. 6.0 Stunden deckeln
  const accumulatedDebtHours = +Math.min(6.0, totalDebt).toFixed(2);

  return {
    accumulatedDebtHours,
    dailyDebts,
  };
}

/**
 * Berechnet den 4-Faktoren-Schlaf-Score (0–100 %).
 */
export function calculateSleepScore(input: {
  sleepDurationHours: number;
  needHours: number;
  timeInBedHours?: number;
  deepHours?: number;
  remHours?: number;
  bedtimeConsistencyMinutes?: number;
}): SleepScoreResult {
  const duration = Math.max(0, input.sleepDurationHours);
  const need = Math.max(1.0, input.needHours);

  // 1. Schlafdauer vs. Bedarf (50 %)
  const durationScore = Math.max(0, Math.min(100, (duration / need) * 100));

  // 2. Schlafeffizienz (25 %)
  let efficiencyScore = 90; // Plausibler Standardwert
  if (typeof input.timeInBedHours === "number" && input.timeInBedHours > 0) {
    efficiencyScore = Math.max(0, Math.min(100, (duration / input.timeInBedHours) * 100));
  }

  // 3. Schlafarchitektur (15 %) - Tiefschlaf + REM
  let stagesScore = 85;
  if (
    typeof input.deepHours === "number" &&
    typeof input.remHours === "number" &&
    duration > 0
  ) {
    const restorativeRatio = (input.deepHours + input.remHours) / duration;
    // 40 % Tief- und REM-Schlaf gilt als Optimum
    stagesScore = Math.max(0, Math.min(100, (restorativeRatio / 0.4) * 100));
  }

  // 4. Schlaf-Konsistenz (10 %) - Einschlaf-/Aufwachzeit-Stabilität
  let consistencyScore = 85;
  if (typeof input.bedtimeConsistencyMinutes === "number") {
    // stdDev <= 15 min -> 100 %, stdDev = 45 min -> ~50 %, stdDev >= 90 min -> 0 %
    consistencyScore = Math.max(0, Math.min(100, 100 - (input.bedtimeConsistencyMinutes / 45) * 50));
  }

  const weightedTotal =
    durationScore * 0.5 +
    efficiencyScore * 0.25 +
    stagesScore * 0.15 +
    consistencyScore * 0.1;

  return {
    score: Math.max(0, Math.min(100, Math.round(weightedTotal))),
    durationScore: Math.round(durationScore),
    efficiencyScore: Math.round(efficiencyScore),
    stagesScore: Math.round(stagesScore),
    consistencyScore: Math.round(consistencyScore),
  };
}
