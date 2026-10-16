/**
 * ORBIT Tagesbelastung (0–100) & Dynamischer Belastungs-Zielkorridor.
 */

import { DailyStrainResult, StrainTargetRange } from "./types";

/**
 * Berechnet den optimalen Belastungs-Zielkorridor (0–100) für heute,
 * abhängig vom Erholungs-Score des Morgens.
 */
export function calculateOptimalStrainTarget(recoveryScore: number): StrainTargetRange {
  const r = Math.max(0, Math.min(100, recoveryScore));

  if (r >= 67) {
    // Hohe Erholung (Grün): Bereit für substanzielle Trainingsreize
    const min = Math.round(55 + 0.25 * (r - 67));
    const max = Math.round(75 + 0.35 * (r - 67));
    return { min, max: Math.min(100, max) };
  } else if (r >= 34) {
    // Moderate Erholung (Gelb): Moderater Trainingsbereich
    const min = Math.round(35 + 0.35 * (r - 34));
    const max = Math.round(55 + 0.35 * (r - 34));
    return { min, max };
  } else {
    // Niedrige Erholung (Rot): Regenerativer Bereich
    const min = 10;
    const max = Math.round(25 + 0.3 * r);
    return { min, max };
  }
}

/**
 * Berechnet die kumulierte ORBIT Tagesbelastung (0–100) aus Trainings-TSS
 * und Alltagsstress/Kalorienverbrauch.
 */
export function calculateDailyStrain(
  activitiesTss: number = 0,
  activeCalories?: number,
  avgStress?: number,
  recoveryScoreForTarget?: number
): DailyStrainResult {
  const validTss = Math.max(0, activitiesTss);

  // Alltags-Belastung aus Stress & aktiven Kalorien
  let alltagLoad = 0;
  if (typeof avgStress === "number" && avgStress > 0) {
    alltagLoad += avgStress * 0.35;
  }
  if (typeof activeCalories === "number" && activeCalories > 0) {
    alltagLoad += (activeCalories / 100) * 1.8;
  }

  const totalRawLoad = validTss + alltagLoad;

  // Logarithmisch gedämpfte 0–100 Skala
  let score = 0;
  if (totalRawLoad > 0) {
    score = Math.min(100, Math.round(21.5 * Math.log(1 + totalRawLoad / 15)));
  }

  const targetRange = calculateOptimalStrainTarget(
    typeof recoveryScoreForTarget === "number" ? recoveryScoreForTarget : 50
  );

  return {
    score,
    trainingTss: +validTss.toFixed(1),
    alltagLoad: +alltagLoad.toFixed(1),
    totalRawLoad: +totalRawLoad.toFixed(1),
    targetRange,
  };
}
