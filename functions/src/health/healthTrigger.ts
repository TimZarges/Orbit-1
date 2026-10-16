/**
 * Cloud Function Trigger für tägliche Gesundheits- und Erholungs-Scores.
 * Schreibt bei Änderungen in users/{uid}/dailyMetrics/{date} die berechneten Scores zurück.
 */

import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { calculateUserBaselines } from "./baselines";
import { calculateRecoveryScore } from "./recovery";
import { calculateDailyStrain } from "./strain";
import { calculateSleepNeed, calculate7DaySleepDebt, calculateSleepScore } from "./sleep";
import { calculateOrbitScore } from "./orbitScore";
import { DailyHealthInput } from "./types";

/**
 * Führt die vollständige Score-Berechnung für einen Tag aus und speichert
 * die aggregierten Scores im Tagesdokument users/{uid}/dailyMetrics/{date}.
 */
export async function computeDailyHealthScores(
  db: FirebaseFirestore.Firestore,
  uid: string,
  targetDate: string
): Promise<void> {
  const metricsCol = db.collection("users").doc(uid).collection("dailyMetrics");

  // Letzte 30 Tage Historie bis einschließlich targetDate laden
  const historySnap = await metricsCol
    .where(admin.firestore.FieldPath.documentId(), "<=", targetDate)
    .orderBy(admin.firestore.FieldPath.documentId(), "desc")
    .limit(30)
    .get();

  if (historySnap.empty) {
    return;
  }

  // Chronologisch sortieren (älteste zuerst)
  const historyDocs = historySnap.docs.reverse();
  const history: DailyHealthInput[] = historyDocs.map((doc) => {
    const d = doc.data();
    return {
      date: doc.id,
      restingHrBpm: d.restingHrBpm,
      hrvMs: d.hrvMs,
      sleepSeconds: d.sleepSeconds,
      deepSleepSeconds: d.deepSleepSeconds,
      remSleepSeconds: d.remSleepSeconds,
      awakeSleepSeconds: d.awakeSleepSeconds,
      timeInBedSeconds: d.timeInBedSeconds,
      sleepScore: d.sleepScore,
      respirationRate: d.respirationRate,
      bodyBattery: d.bodyBattery,
      avgStress: d.stress ?? d.avgStress,
      activeCalories: d.activeCalories,
      activitiesTss: d.activitiesTss ?? d.tss,
      bedtimeIso: d.bedtimeIso,
      wakeTimeIso: d.wakeTimeIso,
    };
  });

  const todayInput = history.find((h) => h.date === targetDate) ?? history[history.length - 1];

  // 1. 30-Tage-Baselines berechnen
  const baselines = calculateUserBaselines(history);

  // 2. ORBIT Erholungs-Score
  const recovery = calculateRecoveryScore(todayInput, baselines);

  // 3. Tagesbelastung & dynamischer Zielkorridor
  const strain = calculateDailyStrain(
    todayInput.activitiesTss,
    todayInput.activeCalories,
    todayInput.avgStress,
    recovery.score
  );

  // 4. Schlaf-Historie für 7-Tage-Schlafschuld
  const sleepDebtHistory = history.map((h) => {
    const durHours = (h.sleepSeconds ?? 0) / 3600;
    return {
      durationHours: durHours,
      needHours: 7.75, // Standard Basisbedarf
    };
  });
  const { accumulatedDebtHours } = calculate7DaySleepDebt(sleepDebtHistory);

  // Gestrige Tagesbelastung ermitteln
  const yesterdayDoc = history.length >= 2 ? history[history.length - 2] : undefined;
  const yesterdayStrain = yesterdayDoc?.activitiesTss ?? 0;
  const sleepNeed = calculateSleepNeed(7.75, yesterdayStrain, accumulatedDebtHours);

  // Detaillierter Schlaf-Score
  const actualSleepHours = (todayInput.sleepSeconds ?? 0) / 3600;
  const timeInBedHours = todayInput.timeInBedSeconds
    ? todayInput.timeInBedSeconds / 3600
    : undefined;
  const deepHours = todayInput.deepSleepSeconds
    ? todayInput.deepSleepSeconds / 3600
    : undefined;
  const remHours = todayInput.remSleepSeconds
    ? todayInput.remSleepSeconds / 3600
    : undefined;

  const sleepScoreResult = calculateSleepScore({
    sleepDurationHours: actualSleepHours,
    needHours: sleepNeed.needHours,
    timeInBedHours,
    deepHours,
    remHours,
  });

  // 5. Finaler ORBIT Score
  // Konsistenz aus aktiven Tagen der letzten 7 Tage
  const recent7 = history.slice(-7);
  const activeDays = recent7.filter((h) => (h.activitiesTss ?? 0) > 0).length;
  const consistencyRatio = Math.min(1.0, activeDays / 5.0); // 5 aktive Tage = 100 % Konsistenz

  const recoveryAvg7d =
    recent7.reduce((acc, h) => acc + (h.hrvMs ? 65 : 50), 0) / (recent7.length || 1);

  const orbitScoreResult = calculateOrbitScore({
    consistencyRatio,
    tsb: 0, // Fallback falls kein PMC im Daily Doc
    recoveryAvg7d,
    sleepAvg7d: sleepScoreResult.score,
    accumulatedDebt7dHours: accumulatedDebtHours,
  });

  // Ergebnis in users/{uid}/dailyMetrics/{targetDate} speichern
  await metricsCol.doc(targetDate).set(
    {
      scoresVersion: "1",
      calculatedAt: FieldValue.serverTimestamp(),
      recovery: {
        score: recovery.score,
        classification: recovery.classification,
        recommendationDe: recovery.recommendationDe,
        recommendationEn: recovery.recommendationEn,
        zHrv: recovery.zHrv ?? null,
        zRhr: recovery.zRhr ?? null,
        weightsUsed: recovery.weightsUsed,
      },
      strain: {
        score: strain.score,
        trainingTss: strain.trainingTss,
        alltagLoad: strain.alltagLoad,
        totalRawLoad: strain.totalRawLoad,
        targetRange: strain.targetRange,
      },
      sleep: {
        score: sleepScoreResult.score,
        needHours: sleepNeed.needHours,
        actualHours: +actualSleepHours.toFixed(2),
        accumulatedDebtHours,
        durationScore: sleepScoreResult.durationScore,
        efficiencyScore: sleepScoreResult.efficiencyScore,
        stagesScore: sleepScoreResult.stagesScore,
      },
      orbitScore: {
        score: orbitScoreResult.score,
        consistencyScore: orbitScoreResult.consistencyScore,
        tsbScore: orbitScoreResult.tsbScore,
        recoveryAvg7d: orbitScoreResult.recoveryAvg7d,
        sleepAvg7d: orbitScoreResult.sleepAvg7d,
      },
      baselines: {
        hrvMean: baselines.hrv?.mean ?? null,
        hrvStd: baselines.hrv?.standardDeviation ?? null,
        rhrMean: baselines.rhr?.mean ?? null,
        rhrStd: baselines.rhr?.standardDeviation ?? null,
        sleepMeanHours: baselines.sleep?.mean ?? null,
        sleepStdHours: baselines.sleep?.standardDeviation ?? null,
      },
    },
    { merge: true }
  );
}

/**
 * Trigger: Wird aufgerufen, wenn in users/{uid}/dailyMetrics/{date} geschrieben wird.
 */
export const onDailyMetricsWritten = onDocumentWritten(
  "users/{uid}/dailyMetrics/{date}",
  async (event) => {
    if (!event.data) return;
    const after = event.data.after;
    if (!after.exists) return; // Gelöscht

    const data = after.data();
    if (!data) return;

    // Schleifenschutz: Falls scoresVersion schon gesetzt ist und sich keine Rohdaten geändert haben
    const beforeData = event.data.before?.data();
    if (data.scoresVersion === "1" && beforeData?.scoresVersion === "1") {
      const rawChanged =
        data.restingHrBpm !== beforeData.restingHrBpm ||
        data.hrvMs !== beforeData.hrvMs ||
        data.sleepSeconds !== beforeData.sleepSeconds ||
        data.stress !== beforeData.stress ||
        data.activitiesTss !== beforeData.activitiesTss;
      if (!rawChanged) {
        return; // Keine Änderung der Rohmetriken
      }
    }

    const uid = event.params.uid;
    const date = event.params.date;
    if (!uid || !date) return;

    const db = admin.firestore();
    try {
      await computeDailyHealthScores(db, uid, date);
    } catch (err) {
      console.error(`Fehler bei computeDailyHealthScores für ${uid} am ${date}:`, err);
    }
  }
);
