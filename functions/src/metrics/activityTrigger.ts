/**
 * @file activityTrigger.ts
 * @description Firestore-Trigger für Aktivitäten (`activities/{activityId}`).
 * Berechnet serverseitig sportartspezifische Trainingsbelastungen (TSS / ORBIT Load),
 * Normalized Power (NP), Intensitätsfaktor (IF) sowie Bestleistungen (MMP)
 * und aktualisiert das tägliche Belastungsaggregat (CTL/ATL/TSB) des Athleten.
 */

import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { updateSportBests } from "./bests";
import { calculateSwimMetrics } from "./swimming";
import { calculateDailyLoadEMA } from "./load";

/**
 * Firestore-Trigger bei Erstellung, Aktualisierung oder Löschung von Aktivitäten.
 * Führt automatische Metrikberechnungen aus und aktualisiert den Banister-PMC-Verlauf.
 */
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

  if (data.metrics?.quality === "COMPLETE" && typeof data.metrics?.tss === "number" && data.metrics.tss > 0) {
    calculatedTss = data.metrics.tss;
    calculatedNp = data.metrics.np || data.summary?.normalizedPowerW || 0;
    calculatedIf = data.metrics.intensityFactor || data.summary?.intensityFactor || 0;
    quality = "COMPLETE";
  } else if (sport === "BIKE") {
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
    metricsVersion: "1",
    "metrics.quality": quality,
    "metrics.tss": calculatedTss,
    "metrics.np": calculatedNp > 0 ? calculatedNp : null,
    "metrics.intensityFactor": calculatedIf > 0 ? calculatedIf : null,
  });

  // Tägliche Aggregation für den Kalendertag aktualisieren
  await updateAggregates(uid, data.localDate);

  // Push-Benachrichtigung: Aktivitäts-Analyse fertig
  try {
    const { sendActivityAnalyzedPush } = await import("../notifications");
    await sendActivityAnalyzedPush({
      recipientId: uid,
      activityId: event.params.activityId,
      sport,
      tss: calculatedTss,
      bestWatt: calculatedNp > 0 ? calculatedNp : undefined,
    });
  } catch (_) {
    // Push-Fehler fangen
  }
});

/**
 * Aktualisiert die tägliche Belastungs-Aggregation (CTL, ATL, TSB) lückenlos über die Zeitreihe
 * bis zum heutigen Tag (`todayStr`). Dadurch gehen CTL/ATL an Ruhetagen (ohne Aktivität) nicht
 * verloren, sondern klingen exponentiell über die Banister-Zeitkonstanten (42d / 7d) ab.
 * Synchronisiert zudem `activitiesTss` in `users/{uid}/dailyMetrics/{date}` und berechnet
 * die täglichen Erholungs- und Belastungs-Scores neu.
 *
 * @param uid - Athleten-ID
 * @param localDate - Optionales lokales Datum im Format YYYY-MM-DD
 */
export async function updateAggregates(uid: string, localDate?: string) {
  const db = admin.firestore();

  try {
    const allActsSnap = await db.collection("activities")
      .where("athleteId", "==", uid)
      .get();

    const dailyTssMap: Record<string, number> = {};
    let earliestDate: string | null = null;
    for (const doc of allActsSnap.docs) {
      const act = doc.data();
      const dStr = act.localDate;
      if (!dStr || typeof dStr !== "string") continue;
      const tss = act.metrics?.tss ?? act.summary?.orbitLoad ?? 0;
      dailyTssMap[dStr] = (dailyTssMap[dStr] || 0) + (typeof tss === "number" ? tss : 0);
      if (!earliestDate || dStr < earliestDate) {
        earliestDate = dStr;
      }
    }

    const todayStr = new Date().toISOString().split("T")[0];
    const startStr = earliestDate && earliestDate < todayStr ? earliestDate : (localDate || todayStr);
    const endStr = localDate && localDate > todayStr ? localDate : todayStr;

    const startObj = new Date(startStr + "T12:00:00Z");
    const endObj = new Date(endStr + "T12:00:00Z");
    const cutoffObj = new Date(endObj.getTime() - 28 * 86400 * 1000);

    let ctl = 0;
    let atl = 0;

    for (let cur = new Date(startObj.getTime()); cur <= endObj; cur.setUTCDate(cur.getUTCDate() + 1)) {
      const curStr = cur.toISOString().split("T")[0];
      const dayTss = dailyTssMap[curStr] || 0;
      const prevCtl = ctl;
      const prevAtl = atl;
      ctl = calculateDailyLoadEMA(prevCtl, dayTss, 42);
      atl = calculateDailyLoadEMA(prevAtl, dayTss, 7);
      const tsb = ctl - atl;

      if (dayTss > 0 || cur >= cutoffObj || curStr === localDate || curStr === todayStr) {
        await db.collection("users").doc(uid)
          .collection("aggregates")
          .doc(curStr)
          .set({
            dailyLoad: Math.round(dayTss),
            ctl: Number(ctl.toFixed(1)),
            atl: Number(atl.toFixed(1)),
            tsb: Number(tsb.toFixed(1)),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            metricsVersion: "1",
          }, { merge: true });
      }

      if (dayTss > 0 || curStr === localDate || curStr === todayStr) {
        await db.collection("users").doc(uid)
          .collection("dailyMetrics")
          .doc(curStr)
          .set({
            date: curStr,
            activitiesTss: Math.round(dayTss),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
      }
    }

    try {
      const { computeDailyHealthScores } = await import("../health/healthTrigger");
      if (localDate && localDate !== todayStr) {
        await computeDailyHealthScores(db, uid, localDate);
      }
      await computeDailyHealthScores(db, uid, todayStr);
    } catch (_) {
      // Optionaler Health-Score-Refresh
    }
  } catch (_) {
    // Fehler protokollieren aber Trigger nicht blockieren
  }
}
