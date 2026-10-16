/**
 * Lauf-Metriken: Grade-Adjusted Pace (GAP), Normalized Graded Pace (NGP) und rTSS.
 * 
 * Wissenschaftliche Grundlagen:
 * - Minetti et al. (2002): Energetische Kosten des Bergauf- und Bergablaufens
 *   Cr(g) = 155.4*g^5 - 30.4*g^4 - 43.3*g^3 + 46.3*g^2 + 19.5*g + 3.6  [J/(kg*m)]
 *   f(g) = Cr(g) / Cr(0), Cr(0) = 3.6 J/(kg*m)
 *   v_eq = v * f(g)
 * - NGP: 30s-Gleitender Mittelwert von v_eq -> 4. Potenz -> Durchschnitt -> 4. Wurzel
 * - IF_run = v_ngp / v_threshold = ThresholdPace / NGP_pace
 * - rTSS = (Dauer_s * IF_run^2) / 36
 */

export interface RunningMetricsResult {
  ngpMps: number;
  ngpSecPerKm: number;
  avgPaceSecPerKm: number;
  avgSpeedMps: number;
  ifRun: number;
  rTSS: number;
  elevationGainM: number;
  elevationLossM: number;
}

/**
 * Berechnet die energetischen Kosten nach Minetti et al. (2002) für eine Steigung g (in Dezimal, z.B. 0.05 für 5%).
 */
export function minettiEnergyCost(gradeDecimal: number): number {
  // Steigung auf physiologisch relevante Grenzen beschränken (-0.40 bis +0.40)
  const g = Math.max(-0.40, Math.min(0.40, gradeDecimal));
  const g2 = g * g;
  const g3 = g2 * g;
  const g4 = g3 * g;
  const g5 = g4 * g;
  return 155.4 * g5 - 30.4 * g4 - 43.3 * g3 + 46.3 * g2 + 19.5 * g + 3.6;
}

/**
 * Wandelt Geschwindigkeit (m/s) und Steigung (in Prozent, z.B. 5 für 5%)
 * in eine steigungsbereinigte äquivalente Flachland-Geschwindigkeit v_eq (m/s) um.
 */
export function calculateGradeAdjustedSpeed(speedMps: number, gradePercent: number): number {
  if (speedMps <= 0) return 0;
  const gradeDecimal = gradePercent / 100;
  const cost = minettiEnergyCost(gradeDecimal);
  const costFlat = 3.6; // Cr(0)
  const factor = cost / costFlat;
  return speedMps * factor;
}

/**
 * Berechnet NGP (Normalized Graded Pace), IF und rTSS für einen Lauf-Stream.
 */
export function calculateRunningMetrics(
  speedsMps: number[],
  altitudesM?: (number | null)[],
  thresholdPaceSecPerKm = 300 // Standard 5:00 min/km
): RunningMetricsResult {
  if (!speedsMps || speedsMps.length === 0 || thresholdPaceSecPerKm <= 0) {
    return {
      ngpMps: 0,
      ngpSecPerKm: 0,
      avgPaceSecPerKm: 0,
      avgSpeedMps: 0,
      ifRun: 0,
      rTSS: 0,
      elevationGainM: 0,
      elevationLossM: 0,
    };
  }

  const n = speedsMps.length;
  const vEq = new Array<number>(n);
  let totalDistM = 0;
  let elevationGainM = 0;
  let elevationLossM = 0;

  for (let i = 0; i < n; i++) {
    const rawV = Math.max(0, speedsMps[i] || 0);
    totalDistM += rawV; // 1 Sekunde Intervall -> Meter

    let gradePercent = 0;
    if (altitudesM && i > 0 && rawV > 0.5) {
      const prevAlt = altitudesM[i - 1];
      const curAlt = altitudesM[i];
      if (prevAlt !== null && curAlt !== null && !isNaN(prevAlt) && !isNaN(curAlt)) {
        const dAlt = curAlt - prevAlt;
        const distStep = rawV;
        gradePercent = (dAlt / distStep) * 100;
        if (dAlt > 0) elevationGainM += dAlt;
        if (dAlt < 0) elevationLossM += Math.abs(dAlt);
      }
    }

    vEq[i] = calculateGradeAdjustedSpeed(rawV, gradePercent);
  }

  const avgSpeedMps = totalDistM / n;
  const avgPaceSecPerKm = avgSpeedMps > 0 ? 1000 / avgSpeedMps : 0;

  // NGP über 30s gleitenden Mittelwert der äquivalenten Geschwindigkeit
  let ngpMps = avgSpeedMps;
  if (n >= 30) {
    let sum4 = 0;
    let rollSum = 0;
    for (let i = 0; i < 30; i++) {
      rollSum += vEq[i];
    }
    sum4 += Math.pow(rollSum / 30, 4);

    for (let i = 30; i < n; i++) {
      rollSum += vEq[i] - vEq[i - 30];
      const avg30 = rollSum / 30;
      sum4 += Math.pow(avg30, 4);
    }
    const count = n - 29;
    ngpMps = Math.pow(sum4 / count, 0.25);
  }

  const ngpSecPerKm = ngpMps > 0 ? 1000 / ngpMps : 0;
  const vThresholdMps = 1000 / thresholdPaceSecPerKm;
  const ifRun = vThresholdMps > 0 ? ngpMps / vThresholdMps : 0;
  const rTSS = (n * Math.pow(ifRun, 2)) / 36;

  return {
    ngpMps: Number(ngpMps.toFixed(2)),
    ngpSecPerKm: Math.round(ngpSecPerKm),
    avgPaceSecPerKm: Math.round(avgPaceSecPerKm),
    avgSpeedMps: Number(avgSpeedMps.toFixed(2)),
    ifRun: Number(ifRun.toFixed(3)),
    rTSS: Number(rTSS.toFixed(1)),
    elevationGainM: Math.round(elevationGainM),
    elevationLossM: Math.round(elevationLossM),
  };
}
