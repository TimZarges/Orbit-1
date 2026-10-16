/**
 * Finaler ORBIT Gesamt-Score (0–100).
 * Verbindet Trainingskonsistenz, Form (TSB), vegetative Erholung und Schlaf.
 */

import { OrbitScoreResult } from "./types";

/**
 * Berechnet den übergeordneten ORBIT Leit-Index (0–100).
 */
export function calculateOrbitScore(input: {
  consistencyRatio: number; // 0.0 bis 1.0 (z. B. 5 von 6 geplanten Einheiten = 0.83)
  tsb: number; // Training Stress Balance (-50 bis +40)
  recoveryAvg7d: number; // 7-Tage-Mittelwert Erholung (0-100)
  sleepAvg7d: number; // 7-Tage-Mittelwert Schlaf-Score (0-100)
  accumulatedDebt7dHours?: number; // Akkumulierte Schlafschuld
}): OrbitScoreResult {
  // 1. Konsistenz Score (30 %)
  const consistencyScore = Math.max(0, Math.min(100, Math.round(input.consistencyRatio * 100)));

  // 2. TSB Form Score (25 %)
  // Optimaler Wettkampf- und Leistungsbereich liegt zwischen -10 und +10 TSB
  let tsbScore = 100;
  if (input.tsb < -10) {
    // Übermüdung: -2.5 Punkte pro TSB unter -10 (bei TSB -30 -> 50 %, bei TSB -50 -> 0 %)
    tsbScore = Math.max(0, 100 - Math.abs(input.tsb - -10) * 2.5);
  } else if (input.tsb > 10) {
    // Detraining / Formverlust: -3 Punkte pro TSB über +10
    tsbScore = Math.max(0, 100 - (input.tsb - 10) * 3.0);
  }

  // 3. 7-Tage-Erholungs-Durchschnitt (25 %)
  const recoveryAvg7d = Math.max(0, Math.min(100, input.recoveryAvg7d));

  // 4. 7-Tage-Schlaf-Durchschnitt mit Malus bei hoher Schlafschuld (20 %)
  let effectiveSleep = Math.max(0, Math.min(100, input.sleepAvg7d));
  if (typeof input.accumulatedDebt7dHours === "number" && input.accumulatedDebt7dHours > 2.0) {
    // 5 Punkte Abzug pro Stunde Schlafschuld über 2h
    effectiveSleep = Math.max(0, effectiveSleep - (input.accumulatedDebt7dHours - 2.0) * 5.0);
  }

  const finalOrbitScore = Math.round(
    consistencyScore * 0.3 +
    tsbScore * 0.25 +
    recoveryAvg7d * 0.25 +
    effectiveSleep * 0.2
  );

  return {
    score: Math.max(0, Math.min(100, finalOrbitScore)),
    consistencyScore,
    tsbScore: Math.round(tsbScore),
    recoveryAvg7d: Math.round(recoveryAvg7d),
    sleepAvg7d: Math.round(effectiveSleep),
  };
}
