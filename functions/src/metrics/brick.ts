/**
 * Multisport & Brick-Analyse (Koppeltraining Rad -> Lauf).
 * 
 * Bewertet die Wechselzeiten (T1 / T2) und die Laufökonomie auf den ersten
 * 2 Kilometern nach dem Radsplit im Vergleich zum restlichen Lauf.
 */

export interface BrickAnalysisResult {
  hasBrickContext: boolean;
  t1DurationSec?: number;
  t2DurationSec?: number;
  initial2kAvgPaceSecPerKm?: number;
  remainingRunAvgPaceSecPerKm?: number;
  paceDeltaSecPerKm?: number;
  paceDecouplingPercent?: number;
  stabilityScore: "EXCELLENT" | "STABLE" | "FATIGUED";
}

/**
 * Analysiert den Koppeleffekt auf den ersten 2 km des Laufs.
 */
export function calculateBrickAnalysis(
  runPacesSecPerKm: number[],
  segmentDistancesM: number[],
  t2DurationSec?: number
): BrickAnalysisResult {
  if (!runPacesSecPerKm || runPacesSecPerKm.length < 2) {
    return {
      hasBrickContext: false,
      stabilityScore: "STABLE",
    };
  }

  // Finde die ersten 2000m
  let cumulativeDist = 0;
  let splitIdx = 0;

  for (let i = 0; i < segmentDistancesM.length; i++) {
    cumulativeDist += segmentDistancesM[i];
    if (cumulativeDist >= 2000) {
      splitIdx = i + 1;
      break;
    }
  }

  if (splitIdx === 0 || splitIdx >= runPacesSecPerKm.length) {
    splitIdx = Math.floor(runPacesSecPerKm.length / 2);
  }

  const initialSlice = runPacesSecPerKm.slice(0, splitIdx);
  const remainingSlice = runPacesSecPerKm.slice(splitIdx);

  const initialPace = average(initialSlice);
  const remainingPace = remainingSlice.length > 0 ? average(remainingSlice) : initialPace;

  // Delta: Positiv bedeutet, der Athlet wurde nach 2km langsamer (Pace-Zahl stieg)
  const paceDelta = remainingPace - initialPace;
  const paceDecoupling = initialPace > 0 ? (paceDelta / initialPace) * 100 : 0;

  let stabilityScore: "EXCELLENT" | "STABLE" | "FATIGUED" = "STABLE";
  if (Math.abs(paceDecoupling) <= 3.0) {
    stabilityScore = "EXCELLENT";
  } else if (paceDecoupling > 8.0) {
    stabilityScore = "FATIGUED";
  }

  return {
    hasBrickContext: true,
    t2DurationSec,
    initial2kAvgPaceSecPerKm: Math.round(initialPace),
    remainingRunAvgPaceSecPerKm: Math.round(remainingPace),
    paceDeltaSecPerKm: Math.round(paceDelta),
    paceDecouplingPercent: Number(paceDecoupling.toFixed(1)),
    stabilityScore,
  };
}

function average(values: number[]): number {
  if (!values || values.length === 0) return 0;
  const sum = values.reduce((a, b) => a + (b || 0), 0);
  return sum / values.length;
}
