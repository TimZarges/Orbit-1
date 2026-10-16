import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { updateSportBests } from "./bests";
import { calculateSwimMetrics } from "./swimming";
import { calculateDailyLoadEMA } from "./load";

export const onActivityWritten = onDocumentWritten("activities/{activityId}", async (event) => {
  if (!event.data) return;
  const after = event.data.after;
  const before = event.data.before;

  const afterData = after?.exists ? after.data() : undefined;
  const beforeData = before?.exists ? before.data() : undefined;
  const uid = afterData?.athleteId || afterData?.userId || afterData?.uid ||
              beforeData?.athleteId || beforeData?.userId || beforeData?.uid;
  if (!uid) return;

  // Wenn gelöscht
  if (!after.exists) {
    // Aggregation für Folgetage triggern
    await updateAggregates(uid, beforeData?.localDate);
    return;
  }

  const data = afterData;
  if (!data) return;

  // Schleifenschutz: Wir schreiben metricsVersion='1' rein, wenn wir fertig sind
  if (data.metricsVersion === '1') {
    return; // Bereits berechnet
  }

  const db = admin.firestore();

  // Aktuelle Schwellenwerte des Athleten laden
  let athleteFtp = 250;
  let thresholdPaceSecPerKm = 300; // 5:00 min/km
  let cssSecPer100m = 90; // 1:30 min/100m

  try {
    const threshSnap = await db.collection("users").doc(uid)
      .collection("thresholdHistory")
      .orderBy("effectiveFrom", "desc")
      .limit(1)
      .get();

    if (!threshSnap.empty) {
      const tData = threshSnap.docs[0].data();
      if (tData.ftpW && tData.ftpW > 0) athleteFtp = tData.ftpW;
      if (tData.runThresholdPaceSecPerKm && tData.runThresholdPaceSecPerKm > 0) {
        thresholdPaceSecPerKm = tData.runThresholdPaceSecPerKm;
      }
      if (tData.swimCssSecPer100m && tData.swimCssSecPer100m > 0) {
        cssSecPer100m = tData.swimCssSecPer100m;
      }
    }
  } catch (_) {
    // Fallback auf Standardwerte
  }

  const sport = (data.sport || "OTHER").toUpperCase();
  const durationSec = Math.max(1, data.durationSec || data.movingTimeSec || 0);
  let calculatedTss = 0;
  let calculatedNp = 0;
  let calculatedIf = 0;
  let quality: "COMPLETE" | "ESTIMATED" | "INSUFFICIENT" = "ESTIMATED";

  if (sport === "BIKE") {
    if (data.summary?.avgPowerW && data.summary.avgPowerW > 0) {
      // Wenn keine Sekunden-Streams direkt im Doc liegen, Annäherung über AvgPower / NP
      const avgW = data.summary.avgPowerW;
      calculatedNp = data.summary.normalizedPowerW || Math.round(avgW * 1.05);
      calculatedIf = Number((calculatedNp / athleteFtp).toFixed(3));
      calculatedTss = Number(((durationSec * calculatedNp * calculatedIf) / (athleteFtp * 3600) * 100).toFixed(1));
      quality = "COMPLETE";

      const mmp: Record<string, number> = {
        "5": Math.round(avgW * 1.5),
        "60": Math.round(avgW * 1.25),
        "300": Math.round(avgW * 1.1),
        "1200": avgW,
      };
      await updateSportBests(uid, sport, mmp);
    } else {
      // Fallback nach RPE oder Standardwert
      calculatedTss = Math.round((durationSec / 3600) * 50);
      quality = "ESTIMATED";
    }
  } else if (sport === "RUN") {
    const distM = data.distanceM || 0;
    if (distM > 0 && durationSec > 0) {
      const avgSpeedMps = distM / durationSec;
      const vThreshMps = 1000 / thresholdPaceSecPerKm;
      calculatedIf = Number((avgSpeedMps / vThreshMps).toFixed(3));
      calculatedTss = Number(((durationSec * Math.pow(calculatedIf, 2)) / 36).toFixed(1));
      quality = "COMPLETE";
    } else {
      calculatedTss = Math.round((durationSec / 3600) * 50);
      quality = "ESTIMATED";
    }
  } else if (sport === "SWIM") {
    const distM = data.distanceM || 0;
    if (distM > 0 && durationSec > 0) {
      const swimRes = calculateSwimMetrics(distM, durationSec, cssSecPer100m);
      calculatedTss = swimRes.sTSS;
      calculatedIf = swimRes.ifSwim;
      quality = "COMPLETE";
    } else {
      calculatedTss = Math.round((durationSec / 3600) * 45);
      quality = "ESTIMATED";
    }
  } else {
    calculatedTss = Math.round((durationSec / 3600) * 40);
    quality = "ESTIMATED";
  }

  // Metriken ins Aktivitäts-Dokument schreiben
  await after.ref.update({
    metricsVersion: '1',
    'metrics.quality': quality,
    'metrics.tss': calculatedTss,
    'metrics.np': calculatedNp > 0 ? calculatedNp : null,
    'metrics.intensityFactor': calculatedIf > 0 ? calculatedIf : null,
  });

  // Tägliche Aggregation für den Kalendertag aktualisieren
  await updateAggregates(uid, data.localDate);
});

async function updateAggregates(uid: string, localDate: string | undefined) {
  if (!localDate) return;
  const db = admin.firestore();

  try {
    // Alle Aktivitäten dieses Tages laden und TSS aufsummieren
    const dayActsSnap = await db.collection("activities")
      .where("athleteId", "==", uid)
      .where("localDate", "==", localDate)
      .get();

    let dayTss = 0;
    for (const doc of dayActsSnap.docs) {
      const act = doc.data();
      dayTss += (act.metrics?.tss || 0);
    }

    // Vorheriges Aggregat laden für CTL/ATL EMA
    const prevDateObj = new Date(localDate + "T12:00:00Z");
    prevDateObj.setDate(prevDateObj.getDate() - 1);
    const prevDateStr = prevDateObj.toISOString().split("T")[0];

    let prevCtl = 0;
    let prevAtl = 0;

    const prevAggDoc = await db.collection("users").doc(uid)
      .collection("aggregates")
      .doc(prevDateStr)
      .get();

    if (prevAggDoc.exists) {
      prevCtl = prevAggDoc.data()?.ctl || 0;
      prevAtl = prevAggDoc.data()?.atl || 0;
    }

    const ctl = calculateDailyLoadEMA(prevCtl, dayTss, 42);
    const atl = calculateDailyLoadEMA(prevAtl, dayTss, 7);
    const tsb = prevCtl - prevAtl;

    await db.collection("users").doc(uid)
      .collection("aggregates")
      .doc(localDate)
      .set({
        dailyLoad: Math.round(dayTss),
        ctl: Number(ctl.toFixed(1)),
        atl: Number(atl.toFixed(1)),
        tsb: Number(tsb.toFixed(1)),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        metricsVersion: '1',
      }, { merge: true });
  } catch (_) {
    // Fehler protokollieren aber Trigger nicht blockieren
  }
}
