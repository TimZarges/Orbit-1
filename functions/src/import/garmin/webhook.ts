import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import axios from "axios";
import * as crypto from "crypto";
import * as zlib from "zlib";
import {
  garminConsumerKey,
  garminConsumerSecret,
  getOAuthClient,
} from "./backfill";
import {
  ActivityLap,
  ActivityStreams,
  expandStreamsTo,
  getActiveCoachIdForActivities,
  initStreams,
} from "../activityParser";

/**
 * Mappt Garmin-Aktivitätstypen auf die standardisierten ORBIT-Sportarten.
 */
export function mapGarminSport(rawType?: string): { sport: string; subSport?: string } {
  if (!rawType) return { sport: "OTHER" };
  const type = rawType.toUpperCase();
  if (type.includes("CYCLING") || type.includes("BIKE") || type.includes("BIK") || type.includes("RIDE") || type.includes("VELO")) {
    return { sport: "BIKE" };
  }
  if (type.includes("RUN") || type.includes("JOG")) {
    return { sport: "RUN" };
  }
  if (type.includes("SWIM")) {
    if (type.includes("OPEN_WATER")) {
      return { sport: "SWIM", subSport: "OPEN_WATER" };
    }
    if (type.includes("LAP") || type.includes("POOL")) {
      return { sport: "SWIM", subSport: "POOL" };
    }
    return { sport: "SWIM" };
  }
  if (type.includes("STRENGTH") || type.includes("FITNESS") || type.includes("WEIGHT")) {
    return { sport: "STRENGTH" };
  }
  if (type.includes("MULTI") || type.includes("TRIATHLON")) {
    return { sport: "MULTISPORT" };
  }
  return { sport: "OTHER" };
}

/**
 * Ermittelt die ORBIT-Benutzer-ID anhand der Garmin-Benutzer-ID.
 * Prüft zuerst den Schnellindex garminUsers/{garminUserId} und nutzt collectionGroup als Fallback.
 */
export async function getUidForGarminUser(garminUserId: string): Promise<string | null> {
  const db = admin.firestore();

  // 1. Direkter Primärschlüssel-Lookup
  const directDoc = await db.collection("garminUsers").doc(garminUserId).get();
  if (directDoc.exists && directDoc.data()?.uid) {
    return directDoc.data()!.uid;
  }

  // 2. Fallback: collectionGroup über integrationStatus
  const statusDocs = await db.collectionGroup("integrationStatus")
    .where("garminUserId", "==", garminUserId)
    .limit(1)
    .get();

  if (!statusDocs.empty) {
    const uid = statusDocs.docs[0].ref.parent.parent?.id;
    if (uid) {
      // Schnellindex für zukünftige Anfragen reparieren/aktualisieren
      await db.collection("garminUsers").doc(garminUserId).set({
        uid,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return uid;
    }
  }

  return null;
}

/**
 * Prüft, ob ein Garmin-Webhook-Item bereits Inline-Daten (Push) enthält
 * oder lediglich ein Ping-Objekt mit callbackURL ist.
 */
export function hasInlineSummaryData(item: any): boolean {
  if (!item || typeof item !== "object") return false;
  return (
    item.summaryId !== undefined ||
    item.activityId !== undefined ||
    item.durationInSeconds !== undefined ||
    item.calendarDate !== undefined ||
    Array.isArray(item.samples) ||
    (item.summary !== undefined && typeof item.summary === "object") ||
    item.restingHeartRateInBeatsPerMinute !== undefined ||
    item.lastNightAvg !== undefined ||
    item.weightInGrams !== undefined ||
    item.vo2Max !== undefined ||
    item.averageStressLevel !== undefined ||
    item.steps !== undefined ||
    item.totalSteps !== undefined
  );
}

/**
 * Löst eine Liste von Webhook-Einträgen auf:
 * - Liegen die Summary-Felder direkt im Payload (Push) -> direkt zurückgeben.
 * - Enthält das Item eine `callbackURL` (Ping) -> `callbackURL` mit OAuth 1.0a signiert abrufen.
 */
export async function resolveGarminWebhookItems(
  rawItems: any[],
  secrets?: { key: string; secret: string }
): Promise<any[]> {
  if (!Array.isArray(rawItems) || rawItems.length === 0) return [];

  const resolved: any[] = [];
  const db = admin.firestore();

  for (const item of rawItems) {
    if (!item || typeof item !== "object") continue;

    if (hasInlineSummaryData(item)) {
      resolved.push(item);
      continue;
    }

    if (typeof item.callbackURL === "string" && item.callbackURL.length > 0) {
      const garminUserId = item.userId;
      if (!garminUserId) continue;

      const uid = await getUidForGarminUser(garminUserId);
      if (!uid) {
        console.warn(`resolveGarminWebhookItems: Kein ORBIT-Nutzer für garminUserId ${garminUserId}`);
        continue;
      }

      const tokenDoc = await db.collection("users").doc(uid).collection("private").doc("integrations").get();
      const garminData = tokenDoc.data()?.garmin;
      if (!garminData?.oauthToken || !garminData?.oauthTokenSecret) {
        console.warn(`resolveGarminWebhookItems: Fehlende OAuth-Tokens für Nutzer ${uid}`);
        continue;
      }

      const key = secrets?.key || garminConsumerKey.value();
      const secret = secrets?.secret || garminConsumerSecret.value();
      if (!key || !secret) {
        console.warn("resolveGarminWebhookItems: Garmin Consumer Secrets nicht verfügbar");
        continue;
      }

      try {
        const oauth = getOAuthClient(key, secret);
        const requestData = { url: item.callbackURL, method: "GET" };
        const authHeader = oauth.toHeader(
          oauth.authorize(requestData, {
            key: garminData.oauthToken,
            secret: garminData.oauthTokenSecret,
          })
        );

        const response = await axios.get(item.callbackURL, { headers: authHeader });
        const fetchedData = response.data;

        if (Array.isArray(fetchedData)) {
          for (const entry of fetchedData) {
            if (entry && typeof entry === "object") {
              resolved.push({ userId: entry.userId || garminUserId, ...entry });
            }
          }
        } else if (fetchedData && typeof fetchedData === "object") {
          resolved.push({ userId: fetchedData.userId || garminUserId, ...fetchedData });
        }
      } catch (err: any) {
        console.error(`Fehler beim Abruf der Garmin callbackURL (${item.callbackURL}):`, err.message);
      }
    }
  }

  return resolved;
}

/**
 * Extrahiert aus einem Garmin `activityDetails`-Objekt die 1Hz-Zeitreihen (`samples`:
 * Watt, HF, Kadenz, Speed, GPS-Koordinaten, Höhe, Temperatur, Links/Rechts-Balance)
 * sowie `laps` im selben Format wie beim .fit/.tcx/.gpx-Upload.
 */
export function extractGarminStreamsAndLaps(
  act: any,
  startTimeInSeconds?: number,
  durationSec?: number
): {
  streams: ActivityStreams | null;
  laps: ActivityLap[];
  computedSummary: {
    avgHr?: number;
    maxHr?: number;
    avgPowerW?: number;
    maxPowerW?: number;
    avgCadence?: number;
    elevationGainM?: number;
  };
} {
  const summaryObj = act?.summary && typeof act.summary === "object" ? act.summary : {};
  const baseStartSec =
    startTimeInSeconds ??
    summaryObj.startTimeInSeconds ??
    act?.startTimeInSeconds ??
    0;
  const baseDurationSec = Math.max(
    1,
    Math.ceil(
      durationSec ??
        summaryObj.durationInSeconds ??
        act?.durationInSeconds ??
        0
    )
  );

  const rawSamples = Array.isArray(act?.samples) ? act.samples : [];
  let streams: ActivityStreams | null = null;

  let hrSum = 0;
  let hrCount = 0;
  let maxHr = 0;
  let powerSum = 0;
  let powerCount = 0;
  let maxPower = 0;
  let cadSum = 0;
  let cadCount = 0;
  let elevationGain = 0;
  let prevAlt: number | null = null;

  if (rawSamples.length > 0) {
    streams = initStreams(baseDurationSec);

    for (let i = 0; i < rawSamples.length; i++) {
      const s = rawSamples[i];
      if (!s || typeof s !== "object") continue;

      let offset = i;
      if (typeof s.timerDurationInSeconds === "number") {
        offset = Math.round(s.timerDurationInSeconds);
      } else if (typeof s.clockDurationInSeconds === "number") {
        offset = Math.round(s.clockDurationInSeconds);
      } else if (typeof s.offsetInSeconds === "number") {
        offset = Math.round(s.offsetInSeconds);
      } else if (typeof s.startTimeInSeconds === "number" && baseStartSec > 0) {
        offset = Math.round(s.startTimeInSeconds - baseStartSec);
      }

      if (offset < 0 || offset > Math.max(baseDurationSec * 2, 86400)) {
        continue;
      }

      expandStreamsTo(streams, offset);

      const hr = s.heartRate ?? s.heartRateInBeatsPerMinute;
      if (typeof hr === "number") {
        streams.heartRate[offset] = hr;
        hrSum += hr;
        hrCount++;
        if (hr > maxHr) maxHr = hr;
      }

      const power = s.powerInWatts ?? s.power;
      if (typeof power === "number") {
        streams.power[offset] = power;
        powerSum += power;
        powerCount++;
        if (power > maxPower) maxPower = power;
      }

      const cadence =
        s.bikeCadenceInRPM ??
        s.stepsPerMinute ??
        s.runCadenceInStepsPerMinute ??
        s.swimCadenceInStrokesPerMinute ??
        s.cadence;
      if (typeof cadence === "number") {
        streams.cadence[offset] = cadence;
        cadSum += cadence;
        cadCount++;
      }

      const speed = s.speedMetersPerSecond ?? s.speed;
      if (typeof speed === "number") {
        streams.speed[offset] = speed;
      }

      const altitude = s.elevationInMeters ?? s.altitudeInMeters ?? s.altitude;
      if (typeof altitude === "number") {
        streams.altitude[offset] = altitude;
        if (prevAlt !== null && altitude > prevAlt) {
          elevationGain += altitude - prevAlt;
        }
        prevAlt = altitude;
      }

      const lat = s.latitudeInDegree ?? s.latitude ?? s.lat;
      if (typeof lat === "number") {
        streams.positionLat[offset] = lat;
      }

      const lng = s.longitudeInDegree ?? s.longitude ?? s.lng ?? s.lon;
      if (typeof lng === "number") {
        streams.positionLng[offset] = lng;
      }

      const temp = s.airTemperatureCelcius ?? s.temperatureCelsius ?? s.temperature;
      if (typeof temp === "number") {
        streams.temperature[offset] = temp;
      }

      const lrBalance = s.leftRightBalance ?? s.pedalBalance;
      if (typeof lrBalance === "number") {
        streams.leftRightBalance[offset] = lrBalance;
      }
    }

    streams.length = streams.time.length;
  }

  const rawLaps = Array.isArray(act?.laps) ? act.laps : [];
  const laps: ActivityLap[] = rawLaps.map((lap: any, idx: number) => ({
    index: idx + 1,
    startTimeUtcSec: typeof lap.startTimeInSeconds === "number" ? lap.startTimeInSeconds : baseStartSec,
    durationSec: Math.round(lap.durationInSeconds ?? lap.totalTimerTimeInSeconds ?? 0),
    distanceM: Math.round(lap.distanceInMeters ?? lap.totalDistanceInMeters ?? 0),
    avgHr: lap.averageHeartRateInBeatsPerMinute ?? lap.avgHr,
    maxHr: lap.maxHeartRateInBeatsPerMinute ?? lap.maxHr,
    avgPowerW: lap.averagePowerInWatts ?? lap.avgPowerW,
    maxPowerW: lap.maxPowerInWatts ?? lap.maxPowerW,
    avgCadence:
      lap.averageBikeCadenceInRoundsPerMinute ??
      lap.averageRunCadenceInStepsPerMinute ??
      lap.avgCadence,
    avgSpeedMps: lap.averageSpeedInMetersPerSecond ?? lap.avgSpeedMps,
    elevationGainM: lap.totalElevationGainInMeters ?? lap.elevationGainM,
  }));

  return {
    streams,
    laps,
    computedSummary: {
      avgHr: hrCount > 0 ? Math.round(hrSum / hrCount) : undefined,
      maxHr: maxHr > 0 ? maxHr : undefined,
      avgPowerW: powerCount > 0 ? Math.round(powerSum / powerCount) : undefined,
      maxPowerW: maxPower > 0 ? maxPower : undefined,
      avgCadence: cadCount > 0 ? Math.round(cadSum / cadCount) : undefined,
      elevationGainM: elevationGain > 0 ? Math.round(elevationGain) : undefined,
    },
  };
}

/**
 * Der HTTPS-Endpunkt, den Garmin aufruft.
 * Muss öffentlich erreichbar sein und innerhalb von <= 3 Sekunden mit HTTP 200 OK antworten.
 * Unterstützt auch GET-Pings für die Endpunkt-Verifizierung von Garmin.
 */
export const garminWebhook = onRequest(async (req, res) => {
  // Garmin Health / Activity API sendet gelegentlich GET oder HEAD zur URL-Validierung
  if (req.method === "GET" || req.method === "HEAD") {
    res.status(200).send("OK");
    return;
  }

  // Sicherheits-Check: Nur POST erlaubt für Payloads
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const payload = req.body;

    // Roh-Payload sofort in Firestore ablegen für asynchrone Bearbeitung (Antwortzeit <= 3s)
    await admin.firestore().collection("webhookEvents").add({
      source: "GARMIN",
      payload: payload,
      status: "RECEIVED",
      receivedAt: FieldValue.serverTimestamp(),
    });

    // Garmin verlangt 200 OK oder 202 Accepted
    res.status(200).send("OK");
  } catch (error) {
    console.error("Garmin Webhook Ingestion Error:", error);
    // Bei internen Fehlern trotzdem 200 senden, um Garmin Retry-Stürme zu verhindern
    res.status(200).send("OK");
  }
});

/**
 * Asynchrone Hintergrund-Verarbeitung der Webhook-Payloads via Firestore Trigger.
 * Unterstützt sowohl Push-Payloads (inline) als auch Ping-Payloads (callbackURL).
 */
export const processGarminWebhook = onDocumentCreated(
  {
    document: "webhookEvents/{docId}",
    secrets: [garminConsumerKey, garminConsumerSecret],
  },
  async (event) => {
    const doc = event.data;
    if (!doc) return;

    const data = doc.data();
    if (data.source !== "GARMIN" || data.status !== "RECEIVED") return;

    try {
      const payload = data.payload || {};

      // 1. De-Registrierungen verarbeiten (Nutzer hat App bei Garmin getrennt)
      if (Array.isArray(payload.deregistrations)) {
        for (const dereg of payload.deregistrations) {
          if (dereg.userId) {
            await handleDeregistration(dereg.userId);
          }
        }
      }

      // 2. Aktivitäten verarbeiten (activities & activityDetails, inkl. Ping/callbackURL)
      const rawActivities = [
        ...(Array.isArray(payload.activities) ? payload.activities : []),
        ...(Array.isArray(payload.activityDetails) ? payload.activityDetails : []),
      ];

      if (rawActivities.length > 0) {
        const resolvedActivities = await resolveGarminWebhookItems(rawActivities);
        for (const act of resolvedActivities) {
          await handleGarminActivity(act);
        }
      }

      // 3. Tägliche Gesundheitsmetriken verarbeiten (Push & Ping/callbackURL)
      const healthCategories: Array<{
        key: string;
        type: "daily" | "sleep" | "hrv" | "epoch" | "bodyComp" | "stress" | "userMetrics";
      }> = [
        { key: "dailies", type: "daily" },
        { key: "sleeps", type: "sleep" },
        { key: "hrv", type: "hrv" },
        { key: "epochs", type: "epoch" },
        { key: "bodyComps", type: "bodyComp" },
        { key: "stressDetails", type: "stress" },
        { key: "userMetrics", type: "userMetrics" },
      ];

      for (const cat of healthCategories) {
        if (Array.isArray(payload[cat.key]) && payload[cat.key].length > 0) {
          const resolvedItems = await resolveGarminWebhookItems(payload[cat.key]);
          for (const item of resolvedItems) {
            await handleDailyMetrics(item, cat.type);
          }
        }
      }

      // Event als verarbeitet markieren
      await doc.ref.update({
        status: "PROCESSED",
        processedAt: FieldValue.serverTimestamp(),
      });
    } catch (e: any) {
      console.error("Garmin Webhook Worker Error:", e);
      await doc.ref.update({
        status: "FAILED",
        error: e.message || String(e),
      });
    }
  }
);

/**
 * Parst und speichert eine Garmin-Aktivität (bzw. `activityDetails` inkl. `samples` & `laps`)
 * verlustfrei in der `activities`-Collection und komprimiert Zeitreihen in Cloud Storage.
 * Prüft Duplikate per Hash aus (athleteId, startTime, duration, sportType).
 */
export async function handleGarminActivity(act: any) {
  // In activityDetails können Summary-Felder unter act.summary liegen
  const summarySource = act?.summary && typeof act.summary === "object"
    ? { ...act.summary, ...act, userId: act.userId || act.summary.userId }
    : act;

  const garminUserId = summarySource?.userId;
  if (!garminUserId) return;

  const uid = await getUidForGarminUser(garminUserId);
  if (!uid) {
    console.warn(`handleGarminActivity: Kein ORBIT-Nutzer für garminUserId ${garminUserId} gefunden`);
    return;
  }

  const rawId = summarySource.activityId
    ? String(summarySource.activityId)
    : (summarySource.summaryId ? String(summarySource.summaryId).replace(/-detail$/, "") : null);
  if (!rawId) {
    console.warn("handleGarminActivity: Fehlende summaryId/activityId");
    return;
  }

  const startTimeInSeconds = typeof summarySource.startTimeInSeconds === "number"
    ? summarySource.startTimeInSeconds
    : (summarySource.startTimeGMT
      ? Math.floor(new Date(summarySource.startTimeGMT).getTime() / 1000)
      : Math.floor(Date.now() / 1000));
  const startTimeOffsetInSeconds = typeof summarySource.startTimeOffsetInSeconds === "number"
    ? summarySource.startTimeOffsetInSeconds
    : 0;

  const utcOffsetMinutes = Math.round(startTimeOffsetInSeconds / 60);
  const localDate = new Date((startTimeInSeconds + startTimeOffsetInSeconds) * 1000)
    .toISOString()
    .split("T")[0];

  const { sport, subSport } = mapGarminSport(summarySource.activityType || summarySource.sport);
  const durationSec =
    summarySource.durationInSeconds ||
    summarySource.activeTimeInSeconds ||
    summarySource.elapsedDurationInSeconds ||
    0;
  const distanceM = summarySource.distanceInMeters || 0;

  // Duplikat-Hash gemäß Anforderung 18.2: sha256(athleteId_startTime_duration_sport)
  const duplicateHash = crypto
    .createHash("sha256")
    .update(`${uid}_${startTimeInSeconds}_${Math.round(durationSec)}_${sport}`)
    .digest("hex");

  const db = admin.firestore();

  // Prüfung auf bestehendes Duplikat
  const existingByHash = await db.collection("activities")
    .where("athleteId", "==", uid)
    .where("duplicateHash", "==", duplicateHash)
    .limit(1)
    .get();

  let targetActivityId = `garmin_${rawId}`;
  let activityDocRef = db.collection("activities").doc(targetActivityId);

  if (!existingByHash.empty) {
    // Bestehendes Dokument weiterverwenden
    activityDocRef = existingByHash.docs[0].ref;
    targetActivityId = activityDocRef.id;
  }

  // Streams (samples) & Laps extrahieren, falls in activityDetails enthalten
  const { streams, laps, computedSummary } = extractGarminStreamsAndLaps(
    act,
    startTimeInSeconds,
    durationSec
  );

  const summary: Record<string, any> = {};
  const avgHr = summarySource.averageHeartRateInBeatsPerMinute ?? computedSummary.avgHr;
  const maxHr = summarySource.maxHeartRateInBeatsPerMinute ?? computedSummary.maxHr;
  const avgPowerW = summarySource.averagePowerInWatts ?? computedSummary.avgPowerW;
  const maxPowerW = summarySource.maxPowerInWatts ?? computedSummary.maxPowerW;
  const avgCadence =
    summarySource.averageBikeCadenceInRoundsPerMinute ??
    summarySource.averageRunCadenceInStepsPerMinute ??
    computedSummary.avgCadence;
  const elevationGainM = summarySource.totalElevationGainInMeters ?? computedSummary.elevationGainM;

  if (typeof avgHr === "number") summary.avgHr = avgHr;
  if (typeof maxHr === "number") summary.maxHr = maxHr;
  if (typeof avgPowerW === "number") summary.avgPowerW = avgPowerW;
  if (typeof maxPowerW === "number") summary.maxPowerW = maxPowerW;
  if (typeof avgCadence === "number") summary.avgCadence = avgCadence;
  if (typeof elevationGainM === "number") summary.elevationGainM = elevationGainM;

  if (typeof summarySource.averageSpeedInMetersPerSecond === "number" && summarySource.averageSpeedInMetersPerSecond > 0) {
    summary.avgPaceSecPerKm = Math.round(1000 / summarySource.averageSpeedInMetersPerSecond);
  } else if (distanceM > 0 && durationSec > 0) {
    summary.avgPaceSecPerKm = Math.round((durationSec / distanceM) * 1000);
  }
  if (typeof summarySource.steps === "number") summary.steps = summarySource.steps;

  const activeCoachId = await getActiveCoachIdForActivities(uid);

  const activityData: Record<string, any> = {
    athleteId: uid,
    coachId: activeCoachId,
    startTimeUtc: Timestamp.fromMillis(startTimeInSeconds * 1000),
    utcOffsetMinutes,
    localDate,
    sport,
    title: summarySource.activityName || `Garmin ${sport}`,
    source: "GARMIN",
    externalId: rawId,
    duplicateHash,
    durationSec: Math.round(durationSec),
    distanceM: Math.round(distanceM),
    summary,
    processing: { state: "READY" },
    createdAt: FieldValue.serverTimestamp(),
  };

  if (subSport) {
    activityData.subSport = subSport;
  }

  if (laps.length > 0) {
    activityData.laps = laps;
  }

  // Wenn Sekunden-Streams (samples) aus activityDetails vorliegen, als .json.gz in Storage speichern
  if (streams && streams.length > 0) {
    const streamJson = JSON.stringify(streams);
    const streamGz = zlib.gzipSync(Buffer.from(streamJson, "utf-8"));
    const streamsPath = `users/${uid}/streams/${targetActivityId}.json.gz`;

    const bucket = admin.storage().bucket();
    const streamFile = bucket.file(streamsPath);
    await streamFile.save(streamGz, {
      contentType: "application/gzip",
      metadata: { contentEncoding: "gzip" },
    });

    activityData.streamsPath = streamsPath;
  }

  // Verlängerung / Merge in Firestore
  await activityDocRef.set(activityData, { merge: true });

  // Falls Backfill aktiv ist, Zähler hochzählen
  await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
    lastSyncAt: FieldValue.serverTimestamp(),
    "backfill.receivedActivities": FieldValue.increment(1),
  }, { merge: true });
}

/**
 * Verarbeitet eingehende Health-Objekte von Garmin und führt sie per Upsert zusammen.
 * Schreibt in users/{uid}/dailyMetrics/{localDate} per { merge: true }.
 */
async function handleDailyMetrics(
  item: any,
  type: "daily" | "sleep" | "hrv" | "epoch" | "bodyComp" | "stress" | "userMetrics"
) {
  const garminUserId = item.userId;
  if (!garminUserId) return;

  const uid = await getUidForGarminUser(garminUserId);
  if (!uid) {
    console.warn(`handleDailyMetrics: Kein ORBIT-Nutzer für garminUserId ${garminUserId} gefunden`);
    return;
  }

  const db = admin.firestore();

  // localDate ermitteln
  let localDate = item.calendarDate;
  if (!localDate && typeof item.startTimeInSeconds === "number") {
    const offset = typeof item.startTimeOffsetInSeconds === "number" ? item.startTimeOffsetInSeconds : 0;
    localDate = new Date((item.startTimeInSeconds + offset) * 1000).toISOString().split("T")[0];
  }

  if (!localDate || typeof localDate !== "string") {
    console.warn(`handleDailyMetrics: Fehlendes localDate für Typ ${type}`);
    return;
  }

  const updateData: Record<string, any> = {
    source: "GARMIN",
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (type === "daily") {
    if (typeof item.restingHeartRateInBeatsPerMinute === "number") {
      updateData.restingHrBpm = item.restingHeartRateInBeatsPerMinute;
    }
    if (typeof item.averageStressLevel === "number") {
      updateData.stress = item.averageStressLevel;
    }
    const steps = item.steps ?? item.totalSteps;
    if (typeof steps === "number") {
      updateData.steps = steps;
    }
    if (typeof item.bodyBatteryChargedValue === "number" || typeof item.bodyBattery === "number") {
      updateData.bodyBattery = item.bodyBattery ?? item.bodyBatteryChargedValue;
    }
  } else if (type === "sleep") {
    if (typeof item.durationInSeconds === "number") {
      updateData.sleepSeconds = item.durationInSeconds;
    }
    const sleepScore = item.overallSleepScore?.value ?? item.sleepScore;
    if (typeof sleepScore === "number") {
      updateData.sleepScore = sleepScore;
    }
  } else if (type === "hrv") {
    const hrvValue = item.lastNightAvg ?? item.hrv;
    if (typeof hrvValue === "number") {
      updateData.hrvMs = hrvValue;
    }
    if (typeof item.weeklyAvg === "number") {
      updateData.hrvWeeklyAvg = item.weeklyAvg;
    }
  } else if (type === "epoch") {
    if (typeof item.steps === "number") {
      updateData.steps = FieldValue.increment(item.steps);
    }
  } else if (type === "bodyComp") {
    if (typeof item.weightInGrams === "number") {
      updateData.weightKg = +(item.weightInGrams / 1000).toFixed(1);
    }
    if (typeof item.bodyFatPercentage === "number") {
      updateData.bodyFatPct = +item.bodyFatPercentage.toFixed(1);
    }
  } else if (type === "stress") {
    if (typeof item.averageStressLevel === "number") {
      updateData.stress = item.averageStressLevel;
    }
    if (typeof item.maxStressLevel === "number") {
      updateData.maxStress = item.maxStressLevel;
    }
  } else if (type === "userMetrics") {
    if (typeof item.vo2Max === "number") {
      updateData.vo2Max = item.vo2Max;
    }
    if (typeof item.fitnessAge === "number") {
      updateData.fitnessAge = item.fitnessAge;
    }
  }

  // Idempotenter Upsert (Merge): Bestehende Felder des Tages bleiben erhalten
  await db.collection("users").doc(uid).collection("dailyMetrics").doc(localDate).set(updateData, { merge: true });

  // Status und Backfill-Statistik aktualisieren
  await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
    lastSyncAt: FieldValue.serverTimestamp(),
    "backfill.receivedHealthDays": FieldValue.increment(1),
  }, { merge: true });
}

/**
 * Entfernt die Tokens und den Verbindungsstatus, wenn der Nutzer die Verknüpfung bei Garmin widerruft.
 */
async function handleDeregistration(garminUserId: string) {
  const db = admin.firestore();
  const uid = await getUidForGarminUser(garminUserId);

  if (uid) {
    // 1. Tokens sicher löschen (Art. 17 DSGVO)
    await db.collection("users").doc(uid).collection("private").doc("integrations").update({
      garmin: FieldValue.delete(),
    });

    // 2. Status auf DISCONNECTED setzen
    await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").update({
      state: "DISCONNECTED",
      garminUserId: FieldValue.delete(),
      disconnectedAt: FieldValue.serverTimestamp(),
    });

    // 3. Schnellindex löschen
    await db.collection("garminUsers").doc(garminUserId).delete();
  }
}
