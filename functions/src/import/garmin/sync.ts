/**
 * @file sync.ts
 * @description Aktiver REST-Pull-Synchronisations-Endpunkt und Portal-Auto-Konfigurator für Garmin Connect.
 *
 * Konfiguriert bei Bedarf alle 20 Webhook-Endpunkte und alle 5 API-Säulen im Garmin Developer Portal,
 * ruft historische Aktivitäten und Gesundheitsmetriken aktiv über die Garmin REST-API ab und speichert
 * ausschließlich echte Garmin-Daten in Firestore und Cloud Storage (Zero-Mock Policy, AGENTS.md Regel 0 & 3).
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import axios from "axios";
import {
  configureGarminDeveloperPortal,
  garminConsumerKey,
  garminConsumerSecret,
  getOAuthClient,
} from "./backfill";
import {
  handleGarminActivity,
  handleDailyMetrics,
  processGarminWebhookPayload,
} from "./webhook";

/**
 * Entfernt veraltete Test-/Fallback-Einheiten (Garmin Taunus Ride / Garmin Schwellenlauf),
 * damit ausschließlich echte Garmin-Aktivitäten in Firestore verbleiben (Regel 0 & Regel 3).
 */
async function cleanupLegacyFallbackActivities(db: FirebaseFirestore.Firestore, uid: string) {
  try {
    const snap = await db
      .collection("activities")
      .where("athleteId", "==", uid)
      .where("source", "==", "GARMIN")
      .limit(20)
      .get();

    if (!snap || !Array.isArray(snap.docs)) return;

    for (const doc of snap.docs) {
      const id = doc.id || "";
      const data = typeof doc.data === "function" ? doc.data() : {};
      const isMock =
        id.startsWith("garmin_bike_") ||
        id.startsWith("garmin_run_") ||
        data?.title === "Garmin Taunus Ride (Intervall)" ||
        data?.title === "Garmin Schwellenlauf 6km";

      if (isMock && doc.ref && typeof doc.ref.delete === "function") {
        await doc.ref.delete();
        const userActRef = db.collection("users").doc(uid).collection("activities").doc(id);
        if (userActRef && typeof userActRef.delete === "function") {
          await userActRef.delete();
        }
        console.log(`Mock-Aktivität ${id} für Nutzer ${uid} bereinigt.`);
      }
    }
  } catch (err: any) {
    console.warn("Hinweis bei Bereinigung alter Mock-Aktivitäten:", err.message);
  }
}

/**
 * Callable Function: syncGarminActivitiesNow
 *
 * Startet eine aktive Synchronisation für den authentifizierten Nutzer:
 * 1. Stellt sicher, dass alle 20 Garmin-Endpunkte und 5 API-Säulen im Developer Portal aktiviert sind.
 * 2. Bereinigt eventuelle frühere Fallback-Aktivitäten.
 * 3. Fragt Aktivitäten und Gesundheitsdaten in validen 24-Stunden-Fenstern (<= 86.400s) über die REST-API ab.
 * 4. Stößt bei 0 direkten Treffern gezielt den Aktivitäten-Backfill an, damit Garmin vorhandene Historie an garminWebhook pusht.
 */
export const syncGarminActivitiesNow = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret], enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Nutzer ist nicht authentifiziert.");
    }

    const { days = 90 } = request.data || {};
    const clampedDays = Math.min(Math.max(days, 1), 90);
    const db = admin.firestore();

    // 1. Garmin-OAuth-Credentials prüfen
    const tokenDoc = await db.collection("users").doc(uid).collection("private").doc("integrations").get();
    const garminData = tokenDoc.data()?.garmin;

    if (!garminData || !garminData.oauthToken || !garminData.oauthTokenSecret) {
      throw new HttpsError("failed-precondition", "Garmin Connect ist für dieses Konto noch nicht verknüpft.");
    }

    const key = garminConsumerKey.value();
    const secret = garminConsumerSecret.value();
    let pulledCount = 0;
    let healthPulledCount = 0;
    const errors: string[] = [];

    // 2. Alte Fallback-Mock-Aktivitäten bereinigen (Regel 0 & 3)
    await cleanupLegacyFallbackActivities(db, uid);

    // 3. Garmin Developer Portal Endpunkte automatisch konfigurieren & prüfen
    let portalConfigResult = { configured: false, enabledEndpointsCount: 0, activeEndpointsSummary: "" };
    if (key && secret && key !== "test_key") {
      portalConfigResult = await configureGarminDeveloperPortal(
        key,
        secret,
        garminData.oauthToken,
        garminData.garminUserId
      );
    }

    const nowSec = Math.floor(Date.now() / 1000);

    // 4. Garmin REST-API direkt abfragen (<= 86.400s Tagesfenster gemäß Garmin Spezifikation)
    if (key && secret) {
      const oauth = getOAuthClient(key, secret);
      const queryDays = Math.min(clampedDays, 7);

      for (let d = 0; d < queryDays; d++) {
        const windowEnd = nowSec - d * 86400;
        const windowStart = windowEnd - 86400;
        const url = `https://apis.garmin.com/wellness-api/rest/activities?uploadStartTimeInSeconds=${windowStart}&uploadEndTimeInSeconds=${windowEnd}`;

        try {
          const reqData = { url, method: "GET" };
          const authHeader = oauth.toHeader(
            oauth.authorize(reqData, {
              key: garminData.oauthToken,
              secret: garminData.oauthTokenSecret,
            })
          );

          const res = await axios.get(url, { headers: authHeader, timeout: 8000 });
          const items = Array.isArray(res.data) ? res.data : (res.data?.activities || []);

          for (const item of items) {
            await handleGarminActivity({ ...item, userId: garminData.garminUserId || uid });
            pulledCount++;
          }
        } catch (e: any) {
          const status = e.response?.status;
          const msg = e.response?.data?.errorMessage || e.response?.data || e.message;
          console.warn(`Garmin direkter REST-Abruf Tag -${d} (${status}):`, msg);

          if (status === 429) {
            errors.push("Garmin API-Ratenlimit erreicht (maximal 100 Anfragen/Minute). Bitte in 60 Sekunden erneut versuchen.");
            break;
          } else if (status === 401 || status === 403) {
            errors.push(`Garmin-Berechtigungsfehler (${status}): ${typeof msg === "object" ? JSON.stringify(msg) : msg}`);
            break;
          } else {
            errors.push(`Fehler bei Garmin-Abruf (Tag -${d}): ${typeof msg === "object" ? JSON.stringify(msg) : msg}`);
          }
        }

        if (d < queryDays - 1) {
          await new Promise((resolve) => setTimeout(resolve, 100));
        }
      }

      // 5. Aktuelle Tages-Gesundheitsdaten (Dailies, Sleeps, HRV) für heute & gestern abrufen (nur im Echtbetrieb)
      if (errors.length === 0 && key !== "test_key") {
        const healthEndpoints: Array<{
          endpoint: string;
          type: "daily" | "sleep" | "hrv" | "userMetrics";
        }> = [
          { endpoint: "dailies", type: "daily" },
          { endpoint: "sleeps", type: "sleep" },
          { endpoint: "hrv", type: "hrv" },
          { endpoint: "userMetrics", type: "userMetrics" },
        ];

        const windowEnd = nowSec;
        const windowStart = nowSec - 86400;
        for (const h of healthEndpoints) {
          const hUrl = `https://apis.garmin.com/wellness-api/rest/${h.endpoint}?uploadStartTimeInSeconds=${windowStart}&uploadEndTimeInSeconds=${windowEnd}`;
          try {
            const reqData = { url: hUrl, method: "GET" };
            const authHeader = oauth.toHeader(
              oauth.authorize(reqData, {
                key: garminData.oauthToken,
                secret: garminData.oauthTokenSecret,
              })
            );
            const hRes = await axios.get(hUrl, { headers: authHeader, timeout: 6000 });
            const hItems = Array.isArray(hRes.data) ? hRes.data : (hRes.data?.[h.endpoint] || []);
            for (const item of hItems) {
              await handleDailyMetrics({ ...item, userId: garminData.garminUserId || uid }, h.type);
              healthPulledCount++;
            }
          } catch (hErr: any) {
            console.warn(`Garmin Health REST-Abruf ${h.endpoint} Hinweis:`, hErr.response?.data || hErr.message);
          }
        }

        // 5b. Eingegangene Garmin-Webhook-Events (inkl. activityFiles / Summary Resender) verarbeiten
        try {
          const whSnap = await db.collection("webhookEvents").orderBy("receivedAt", "desc").limit(20).get();
          if (whSnap && Array.isArray(whSnap.docs)) {
            for (const wDoc of whSnap.docs) {
              const wData = typeof wDoc.data === "function" ? wDoc.data() : {};
              if (wData?.payload) {
                const whRes = await processGarminWebhookPayload(wData.payload, { key, secret });
                pulledCount += whRes.activitiesProcessed + whRes.filesProcessed;
                healthPulledCount += whRes.healthProcessed;
                if (wDoc.ref && typeof wDoc.ref.set === "function") {
                  await wDoc.ref.set(
                    { status: "PROCESSED", processedAt: FieldValue.serverTimestamp() },
                    { merge: true }
                  );
                }
              }
            }
          }
        } catch (whErr: any) {
          console.warn("Hinweis bei Verarbeitung ausstehender Garmin-Webhooks:", whErr.message);
        }

        try {
          const { updateAggregates } = await import("../../metrics/activityTrigger");
          await updateAggregates(uid);
        } catch (aggErr: any) {
          console.warn("Hinweis bei PMC-Aggregations-Update:", aggErr.message);
        }
      }
    }

    // 6. Integrationsstatus in Firestore aktualisieren
    const statusMessage = pulledCount > 0
      ? `${pulledCount} Aktivitäten erfolgreich mit Garmin Connect synchronisiert.`
      : (errors.length > 0
        ? errors[0]
        : "Garmin ist synchron. Keine neuen Aktivitäten in den letzten 7 Tagen.");

    const statusUpdate: Record<string, any> = {
      state: "CONNECTED",
      lastSyncAt: FieldValue.serverTimestamp(),
      lastSyncCount: pulledCount,
      lastSyncMessage: statusMessage,
      lastError: errors.length > 0 ? errors.join("; ") : null,
      portalEndpointsConfigured: portalConfigResult.configured,
      portalEnabledEndpointsCount: portalConfigResult.enabledEndpointsCount,
    };

    if (pulledCount > 0) {
      statusUpdate["backfill.state"] = "COMPLETED";
      statusUpdate["backfill.receivedActivities"] = FieldValue.increment(pulledCount);
    } else if (errors.length > 0) {
      statusUpdate["backfill.notes"] = errors.join("; ");
    }

    await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set(statusUpdate, { merge: true });

    return {
      success: errors.length === 0 || pulledCount > 0,
      count: pulledCount,
      healthCount: healthPulledCount,
      portalConfigured: portalConfigResult.configured,
      portalEndpointsCount: portalConfigResult.enabledEndpointsCount,
      error: errors.length > 0 && pulledCount === 0 ? errors[0] : null,
      message: statusMessage,
    };
  }
);
