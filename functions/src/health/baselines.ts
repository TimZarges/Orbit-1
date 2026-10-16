/**
 * Berechnet rollierende 30-Tage-Baselines und Normbänder für vegetative Biomarker.
 */

import { DailyHealthInput, RollingBaseline, UserBaselines } from "./types";

/**
 * Berechnet arithmetischen Mittelwert und Standardabweichung für eine Serie.
 * Erfordert mindestens 3 Datenpunkte für eine statistisch aussagekräftige Baseline.
 */
export function calculateRollingBaseline(
  values: number[],
  minSigma: number = 1.0
): RollingBaseline | undefined {
  const valid = values.filter((v) => typeof v === "number" && !isNaN(v) && isFinite(v) && v > 0);
  const n = valid.length;

  if (n < 3) {
    return undefined;
  }

  const mean = valid.reduce((acc, val) => acc + val, 0) / n;

  // Unverzerrte Stichproben-Standardabweichung (Bessel-Korrektur n-1)
  const sumSquaredDiffs = valid.reduce((acc, val) => acc + Math.pow(val - mean, 2), 0);
  const rawSigma = Math.sqrt(sumSquaredDiffs / (n - 1));
  const sigma = Math.max(minSigma, rawSigma);

  return {
    mean: +mean.toFixed(2),
    standardDeviation: +sigma.toFixed(2),
    count: n,
    normBandMin: +(mean - sigma).toFixed(2),
    normBandMax: +(mean + sigma).toFixed(2),
  };
}

/**
 * Berechnet alle 30-Tage-Baselines aus der Historie eines Athleten.
 * Verarbeitet bis zu 30 der jüngsten Einträge.
 */
export function calculateUserBaselines(history: DailyHealthInput[]): UserBaselines {
  // Sortiere chronologisch und nimm maximal 30 Tage
  const recent = history.slice(-30);

  const hrvValues: number[] = [];
  const rhrValues: number[] = [];
  const sleepHoursValues: number[] = [];
  const respValues: number[] = [];
  const bbValues: number[] = [];

  for (const entry of recent) {
    if (typeof entry.hrvMs === "number" && entry.hrvMs > 0) {
      hrvValues.push(entry.hrvMs);
    }
    if (typeof entry.restingHrBpm === "number" && entry.restingHrBpm > 0) {
      rhrValues.push(entry.restingHrBpm);
    }
    if (typeof entry.sleepSeconds === "number" && entry.sleepSeconds > 0) {
      sleepHoursValues.push(entry.sleepSeconds / 3600);
    }
    if (typeof entry.respirationRate === "number" && entry.respirationRate > 0) {
      respValues.push(entry.respirationRate);
    }
    if (typeof entry.bodyBattery === "number" && entry.bodyBattery > 0) {
      bbValues.push(entry.bodyBattery);
    }
  }

  return {
    hrv: calculateRollingBaseline(hrvValues, 2.0),
    rhr: calculateRollingBaseline(rhrValues, 1.5),
    sleep: calculateRollingBaseline(sleepHoursValues, 0.4),
    respiration: calculateRollingBaseline(respValues, 0.3),
    bodyBattery: calculateRollingBaseline(bbValues, 3.0),
  };
}
