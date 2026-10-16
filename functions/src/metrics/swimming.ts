/**
 * Schwimm-Metriken: CSS (Critical Swim Speed), sTSS, SWOLF und DPS.
 * 
 * Formeln:
 * - v_CSS = (400 - 200) / (T_400 - T_200)  [m/s]
 * - Pace_CSS = (T_400 - T_200) / 2  [s/100m]
 * - IF_swim = v_avg / v_CSS = Pace_CSS / Pace_avg
 * - sTSS = (Dauer_s * IF_swim^3) / 36
 * - SWOLF = Zeit_pro_Bahn (s) + Zugzahl_pro_Bahn
 * - DPS (Distance per Stroke) = Distanz (m) / Gesamtzugzahl
 */

export interface SwimMetricsResult {
  avgPaceSecPer100m: number;
  avgSpeedMps: number;
  ifSwim: number;
  sTSS: number;
  swolf?: number;
  strokeRateSpm?: number;
  dpsM?: number;
}

/**
 * Berechnet CSS (Critical Swim Speed) in s/100m und m/s aus den Zeiten für 400m und 200m Freistil.
 */
export function calculateCssFromTimeTrials(t400Sec: number, t200Sec: number) {
  if (t400Sec <= t200Sec || t200Sec <= 0) {
    throw new Error("T400 muss größer als T200 sein.");
  }
  const vCssMps = 200 / (t400Sec - t200Sec);
  const cssPaceSecPer100m = (t400Sec - t200Sec) / 2;
  return {
    vCssMps: Number(vCssMps.toFixed(3)),
    cssPaceSecPer100m: Math.round(cssPaceSecPer100m),
  };
}

/**
 * Berechnet sTSS und biomechanische Effizienzparameter für eine Schwimmeinheit.
 */
export function calculateSwimMetrics(
  distanceM: number,
  durationSec: number,
  cssSecPer100m = 90, // Standard 1:30 min/100m
  poolLengthM?: number,
  totalStrokes?: number
): SwimMetricsResult {
  if (distanceM <= 0 || durationSec <= 0 || cssSecPer100m <= 0) {
    return { avgPaceSecPer100m: 0, avgSpeedMps: 0, ifSwim: 0, sTSS: 0 };
  }

  const avgSpeedMps = distanceM / durationSec;
  const avgPaceSecPer100m = (durationSec / distanceM) * 100;

  const vCssMps = 100 / cssSecPer100m;
  const ifSwim = avgSpeedMps / vCssMps;

  // sTSS skaliert mit der 3. Potenz des Strömungswiderstands
  const sTSS = (durationSec * Math.pow(ifSwim, 3)) / 36;

  let swolf: number | undefined;
  let strokeRateSpm: number | undefined;
  let dpsM: number | undefined;

  if (totalStrokes && totalStrokes > 0) {
    dpsM = Number((distanceM / totalStrokes).toFixed(2));
    strokeRateSpm = Number(((totalStrokes / durationSec) * 60).toFixed(1));

    if (poolLengthM && poolLengthM > 0) {
      const lengths = distanceM / poolLengthM;
      if (lengths > 0) {
        const timePerLength = durationSec / lengths;
        const strokesPerLength = totalStrokes / lengths;
        swolf = Math.round(timePerLength + strokesPerLength);
      }
    }
  }

  return {
    avgPaceSecPer100m: Math.round(avgPaceSecPer100m),
    avgSpeedMps: Number(avgSpeedMps.toFixed(2)),
    ifSwim: Number(ifSwim.toFixed(3)),
    sTSS: Number(sTSS.toFixed(1)),
    swolf,
    strokeRateSpm,
    dpsM,
  };
}
