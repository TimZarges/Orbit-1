import { calculatePowerMetrics } from "./power";

/**
 * Aerobe Entkopplung (Aerobic Decoupling / Pa:Hr / Pw:Hr nach Friel).
 * 
 * Vergleicht die aerobe Effizienz (EF = Leistung / Herzfrequenz) der ersten
 * mit der zweiten Aktivitätshälfte:
 * Decoupling = ((EF_1 - EF_2) / EF_1) * 100  [%]
 * 
 * Klassifikation:
 * - < 5.0 %: COUPLED (Grün - Hervorragende aerobe Basis)
 * - 5.0 % bis 8.0 %: MODERATE (Gelb - Akzeptabler kardiovaskulärer Drift)
 * - > 8.0 %: DECOUPLED (Rot - Deutlicher Drift / Ermüdung / Dehydrierung)
 */

export type DecouplingClassification = "COUPLED" | "MODERATE" | "DECOUPLED";

export interface DecouplingResult {
  efTotal: number;
  efHalf1: number;
  efHalf2: number;
  decouplingPercent: number;
  classification: DecouplingClassification;
  avgHrHalf1: number;
  avgHrHalf2: number;
  npHalf1: number;
  npHalf2: number;
}

/**
 * Berechnet das Aerobic Decoupling für Leistungs- (oder Geschwindigkeits-) und Herzfrequenzdaten.
 */
export function calculateAerobicDecoupling(
  powersOrSpeeds: number[],
  heartRates: number[],
  ftpOrThreshold = 250
): DecouplingResult {
  const n = Math.min(powersOrSpeeds.length, heartRates.length);
  if (n < 600) {
    // Unter 10 Minuten nicht aussagekräftig für kardiovaskulären Drift
    return {
      efTotal: 0,
      efHalf1: 0,
      efHalf2: 0,
      decouplingPercent: 0,
      classification: "COUPLED",
      avgHrHalf1: 0,
      avgHrHalf2: 0,
      npHalf1: 0,
      npHalf2: 0,
    };
  }

  const half = Math.floor(n / 2);

  const p1 = powersOrSpeeds.slice(0, half);
  const p2 = powersOrSpeeds.slice(half, n);

  const hr1 = heartRates.slice(0, half);
  const hr2 = heartRates.slice(half, n);

  // NP oder mittlere Leistung je Hälfte
  const np1 = calculatePowerMetrics(p1, ftpOrThreshold).np || average(p1);
  const np2 = calculatePowerMetrics(p2, ftpOrThreshold).np || average(p2);
  const npTotal = calculatePowerMetrics(powersOrSpeeds, ftpOrThreshold).np || average(powersOrSpeeds);

  const avgHr1 = average(hr1);
  const avgHr2 = average(hr2);
  const avgHrTotal = average(heartRates);

  const ef1 = avgHr1 > 0 ? np1 / avgHr1 : 0;
  const ef2 = avgHr2 > 0 ? np2 / avgHr2 : 0;
  const efTotal = avgHrTotal > 0 ? npTotal / avgHrTotal : 0;

  let decouplingPercent = 0;
  if (ef1 > 0) {
    decouplingPercent = ((ef1 - ef2) / ef1) * 100;
  }

  let classification: DecouplingClassification = "COUPLED";
  if (decouplingPercent > 8.0) {
    classification = "DECOUPLED";
  } else if (decouplingPercent >= 5.0) {
    classification = "MODERATE";
  }

  return {
    efTotal: Number(efTotal.toFixed(2)),
    efHalf1: Number(ef1.toFixed(2)),
    efHalf2: Number(ef2.toFixed(2)),
    decouplingPercent: Number(decouplingPercent.toFixed(1)),
    classification,
    avgHrHalf1: Math.round(avgHr1),
    avgHrHalf2: Math.round(avgHr2),
    npHalf1: Math.round(np1),
    npHalf2: Math.round(np2),
  };
}

function average(values: number[]): number {
  if (!values || values.length === 0) return 0;
  let sum = 0;
  let count = 0;
  for (const v of values) {
    if (v !== null && !isNaN(v) && v > 0) {
      sum += v;
      count++;
    }
  }
  return count > 0 ? sum / count : 0;
}
