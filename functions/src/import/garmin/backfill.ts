import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import axios from "axios";
import * as crypto from "crypto";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const OAuth = require("oauth-1.0a");

export const garminConsumerKey = defineSecret("GARMIN_CONSUMER_KEY");
export const garminConsumerSecret = defineSecret("GARMIN_CONSUMER_SECRET");

export function getOAuthClient(consumerKey: string, consumerSecret: string) {
  return new OAuth({
    consumer: { key: consumerKey, secret: consumerSecret },
    signature_method: "HMAC-SHA1",
    hash_function(baseString: string, key: string) {
      return crypto.createHmac("sha1", key).update(baseString).digest("base64");
    },
  });
}

export const MAX_BACKFILL_CHUNK_DAYS = 30;

export interface BackfillChunk {
  startSec: number;
  endSec: number;
  days: number;
}

/**
 * Teilt einen Backfill-Zeitraum (z. B. 90 Tage) in Chunks von maximal 30 Tagen auf,
 * da die Garmin Backfill API Zeitfenster > 30 Tage mit HTTP 400 ablehnt.
 * Beispiel für 90 Tage: [now-30d..now], [now-60d..now-30d], [now-90d..now-60d].
 */
export function buildBackfillChunks(
  nowSec: number,
  totalDays = 90,
  maxChunkDays = MAX_BACKFILL_CHUNK_DAYS
): BackfillChunk[] {
  const clampedDays = Math.min(Math.max(totalDays, 1), 90);
  const chunks: BackfillChunk[] = [];
  let remainingDays = clampedDays;
  let currentEndSec = nowSec;

  while (remainingDays > 0) {
    const chunkDays = Math.min(remainingDays, maxChunkDays);
    const currentStartSec = currentEndSec - chunkDays * 24 * 60 * 60;
    chunks.push({
      startSec: currentStartSec,
      endSec: currentEndSec,
      days: chunkDays,
    });
    currentEndSec = currentStartSec;
    remainingDays -= chunkDays;
  }

  return chunks;
}

/**
 * Führt den offiziellen Garmin Backfill für bis zu 90 Tage über die Wellness- und Activity-APIs aus.
 * Teilt den Zeitraum in <= 30-Tage-Chunks und fragt Aktivitäten, ActivityDetails, Dailies, Sleeps,
 * HRV, Epochs, BodyComps und UserMetrics sequenziell mit kurzem Delay an.
 */
export async function executeGarminBackfill(
  uid: string,
  days = 90,
  secrets?: { key: string; secret: string },
  options?: { delayMs?: number; nowSec?: number }
): Promise<{
  success: boolean;
  fromSec: number;
  toSec: number;
  chunksRequested: number;
  chunks: BackfillChunk[];
  endpointsRequested: number;
}> {
  const clampedDays = Math.min(Math.max(days, 1), 90);

  const db = admin.firestore();
  const tokenDoc = await db.collection("users").doc(uid).collection("private").doc("integrations").get();
  const garminData = tokenDoc.data()?.garmin;

  if (!garminData || !garminData.oauthToken || !garminData.oauthTokenSecret) {
    throw new HttpsError("failed-precondition", "Garmin is not connected.");
  }

  const key = secrets?.key || garminConsumerKey.value();
  const secret = secrets?.secret || garminConsumerSecret.value();

  if (!key || !secret) {
    throw new HttpsError("failed-precondition", "Garmin secrets are not configured in Secret Manager.");
  }

  const oauth = getOAuthClient(key, secret);

  const nowSec = options?.nowSec ?? Math.floor(Date.now() / 1000);
  const delayMs = options?.delayMs ?? 50;
  const chunks = buildBackfillChunks(nowSec, clampedDays, MAX_BACKFILL_CHUNK_DAYS);
  const startSec = chunks.length > 0 ? chunks[chunks.length - 1].startSec : nowSec;

  const endpointTypes = [
    "activities",
    "activityDetails",
    "dailies",
    "sleeps",
    "hrv",
    "epochs",
    "bodyComps",
    "userMetrics",
  ];

  let requestedCount = 0;
  const errors: string[] = [];

  for (let cIdx = 0; cIdx < chunks.length; cIdx++) {
    const chunk = chunks[cIdx];

    for (const type of endpointTypes) {
      const url =
        `https://apis.garmin.com/wellness-api/rest/backfill/${type}` +
        `?summaryStartTimeInSeconds=${chunk.startSec}&summaryEndTimeInSeconds=${chunk.endSec}`;

      try {
        const requestData = { url, method: "GET" };
        const authHeader = oauth.toHeader(
          oauth.authorize(requestData, {
            key: garminData.oauthToken,
            secret: garminData.oauthTokenSecret,
          })
        );

        // Garmin Backfill antwortet regulär mit HTTP 202 Accepted (leerer Body)
        await axios.get(url, {
          headers: authHeader,
          validateStatus: (status) => status === 200 || status === 202,
        });
        requestedCount++;
      } catch (err: any) {
        if (err.response?.status === 202) {
          requestedCount++;
          continue;
        }

        const responseData = err.response?.data;
        const errorMsg =
          typeof responseData === "object"
            ? JSON.stringify(responseData)
            : responseData || err.message;
        console.warn(`Garmin Backfill Hinweis für ${type} (${chunk.startSec}-${chunk.endSec}):`, errorMsg);

        if (String(errorMsg).includes("HISTORICAL_DATA_EXPORT")) {
          errors.push(`Feature HISTORICAL_DATA_EXPORT für ${type} noch nicht aktiv`);
        }
      }
    }

    // Kurzes Delay zwischen den 30-Tage-Chunks zur Einhaltung der Garmin Rate-Limits
    if (delayMs > 0 && cIdx < chunks.length - 1) {
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }

  // Status in integrationStatus aktualisieren
  await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
    backfill: {
      state: "IN_PROGRESS",
      from: new Date(startSec * 1000).toISOString(),
      to: new Date(nowSec * 1000).toISOString(),
      targetDays: clampedDays,
      chunksRequested: chunks.length,
      requestedAt: FieldValue.serverTimestamp(),
      receivedActivities: 0,
      receivedHealthDays: 0,
      endpointsRequested: requestedCount,
      notes: errors.length > 0 ? errors.join("; ") : null,
    },
  }, { merge: true });

  return {
    success: true,
    fromSec: startSec,
    toSec: nowSec,
    chunksRequested: chunks.length,
    chunks,
    endpointsRequested: requestedCount,
  };
}

/**
 * Callable Function: Fordert einen historischen 90-Tage-Backfill bei Garmin an.
 */
export const requestGarminBackfill = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret], enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { days = 90 } = request.data || {};
    try {
      return await executeGarminBackfill(uid, days, {
        key: garminConsumerKey.value(),
        secret: garminConsumerSecret.value(),
      });
    } catch (error: any) {
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", `Backfill request failed: ${error.message}`);
    }
  }
);

/**
 * Abwärtskompatibler Alias für garminBackfill
 */
export const garminBackfill = requestGarminBackfill;
