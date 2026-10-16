/**
 * ORBIT Erholungs-Score (0–100 %) mit Graceful Degradation und dynamischer Gewichtsnormierung.
 */

import {
  DailyHealthInput,
  RecoveryClassification,
  RecoveryResult,
  UserBaselines,
} from "./types";

// Standard-Populations-Baselines als sanfter Fallback für die ersten 1–2 Tage
const DEFAULT_HRV_BASELINE = { mean: 55, standardDeviation: 15 };
const DEFAULT_RHR_BASELINE = { mean: 56, standardDeviation: 6 };
const DEFAULT_RESP_BASELINE = { mean: 14.5, standardDeviation: 1.5 };

/**
 * Logistische Sigmoid-Transformation eines Z-Scores in eine 0–100 Skala.
 * Steigung k = 1.25 sorgt für physiologisch ausgewogene Sensitivität:
 * z = 0 -> 50 %, z = +1.0 -> ~77.7 %, z = -1.0 -> ~22.3 %, z = +2.0 -> ~92.4 %
 */
export function sigmoidScore(z: number, k: number = 1.25): number {
  const score = 100 / (1 + Math.exp(-k * z));
  return Math.max(0, Math.min(100, score));
}

/**
 * Berechnet den ORBIT Erholungs-Score (0–100 %) für den heutigen Tag.
 * Unterstützt Graceful Degradation bei unvollständigen Sensor-Daten.
 */
export function calculateRecoveryScore(
  today: DailyHealthInput,
  baselines: UserBaselines
): RecoveryResult {
  const rawWeights: Record<string, number> = {
    hrv: 0.45,
    rhr: 0.25,
    sleep: 0.20,
    respOrBb: 0.10,
  };

  const scores: Record<string, number> = {};
  let zHrv: number | undefined;
  let zRhr: number | undefined;

  // 1. HRV Score
  if (typeof today.hrvMs === "number" && today.hrvMs > 0) {
    const base = baselines.hrv ?? DEFAULT_HRV_BASELINE;
    zHrv = (today.hrvMs - base.mean) / base.standardDeviation;
    scores.hrv = sigmoidScore(zHrv);
  }

  // 2. Ruhepuls Score (invertiert: niedriger Ruhepuls = bessere Erholung)
  if (typeof today.restingHrBpm === "number" && today.restingHrBpm > 0) {
    const base = baselines.rhr ?? DEFAULT_RHR_BASELINE;
    zRhr = (base.mean - today.restingHrBpm) / base.standardDeviation;
    scores.rhr = sigmoidScore(zRhr);
  }

  // 3. Schlaf Score
  if (typeof today.sleepScore === "number" && today.sleepScore >= 0) {
    scores.sleep = Math.max(0, Math.min(100, today.sleepScore));
  } else if (typeof today.sleepSeconds === "number" && today.sleepSeconds > 0) {
    // 7.75 Stunden Basisbedarf = 27900s
    scores.sleep = Math.max(0, Math.min(100, (today.sleepSeconds / 27900) * 100));
  }

  // 4. Atemfrequenz & Body Battery
  const respOrBbScores: number[] = [];
  if (typeof today.bodyBattery === "number" && today.bodyBattery >= 0) {
    respOrBbScores.push(Math.max(0, Math.min(100, today.bodyBattery)));
  }
  if (typeof today.respirationRate === "number" && today.respirationRate > 0) {
    const base = baselines.respiration ?? DEFAULT_RESP_BASELINE;
    const zResp = (today.respirationRate - base.mean) / base.standardDeviation;
    // Erhöhte Atemfrequenz führt zu Punktabzug
    const respScore = Math.max(0, Math.min(100, 100 - 35 * Math.max(0, zResp)));
    respOrBbScores.push(respScore);
  }
  if (respOrBbScores.length > 0) {
    scores.respOrBb = respOrBbScores.reduce((a, b) => a + b, 0) / respOrBbScores.length;
  }

  // Dynamische Gewichtsnormierung (Graceful Degradation)
  let activeWeightSum = 0;
  for (const key of Object.keys(scores)) {
    activeWeightSum += rawWeights[key] ?? 0;
  }

  // Fallback, falls überhaupt keine Vitalwerte geliefert wurden (Default: moderater 50% Erholungswert)
  if (activeWeightSum === 0) {
    return {
      score: 50,
      classification: "YELLOW",
      recommendationDe: "Keine aktuellen Vitalwerte erfasst. Moderates Training empfohlen.",
      recommendationEn: "No current biometric data available. Moderate training recommended.",
      weightsUsed: { hrv: 0, rhr: 0, sleep: 0, respOrBb: 0 },
    };
  }

  const normalizedWeights: Record<string, number> = {};
  let totalScore = 0;

  for (const [key, scoreVal] of Object.entries(scores)) {
    const normWeight = (rawWeights[key] ?? 0) / activeWeightSum;
    normalizedWeights[key] = +normWeight.toFixed(4);
    totalScore += normWeight * scoreVal;
  }

  const finalScore = Math.max(0, Math.min(100, Math.round(totalScore)));

  // Ampel-Klassifikation
  let classification: RecoveryClassification;
  let recommendationDe: string;
  let recommendationEn: string;

  if (finalScore >= 67) {
    classification = "GREEN";
    if (zHrv !== undefined && zHrv >= 0.5) {
      recommendationDe = "Exzellente Erholung. Bereit für Schwellenintervalle und intensive Einheiten.";
      recommendationEn = "Excellent recovery. Primed for threshold intervals and high-intensity sessions.";
    } else {
      recommendationDe = "Sehr gute Verfassung. Dein Körper ist bereit für hohe Trainingsreize.";
      recommendationEn = "Very good shape. Your body is primed for demanding training stimuli.";
    }
  } else if (finalScore >= 34) {
    classification = "YELLOW";
    recommendationDe = "Solide Grundverfassung. Moderates Grundlagentraining oder Erhaltungsreize ideal.";
    recommendationEn = "Solid baseline state. Ideal for steady endurance or maintenance workouts.";
  } else {
    classification = "RED";
    recommendationDe = "Erhöhte vegetative Belastung. Fokus auf aktive Erholung, Mobility oder Ruhetag.";
    recommendationEn = "Elevated autonomic stress. Focus on active recovery, mobility, or rest.";
  }

  return {
    score: finalScore,
    classification,
    recommendationDe,
    recommendationEn,
    zHrv: zHrv !== undefined ? +zHrv.toFixed(2) : undefined,
    zRhr: zRhr !== undefined ? +zRhr.toFixed(2) : undefined,
    weightsUsed: {
      hrv: normalizedWeights.hrv ?? 0,
      rhr: normalizedWeights.rhr ?? 0,
      sleep: normalizedWeights.sleep ?? 0,
      respOrBb: normalizedWeights.respOrBb ?? 0,
    },
  };
}
