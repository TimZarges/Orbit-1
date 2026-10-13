import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import axios from "axios";
import * as crypto from "crypto";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const OAuth = require("oauth-1.0a");

const garminConsumerKey = defineSecret("GARMIN_CONSUMER_KEY");
const garminConsumerSecret = defineSecret("GARMIN_CONSUMER_SECRET");

function getOAuthClient(consumerKey: string, consumerSecret: string) {
  return new OAuth({
    consumer: { key: consumerKey, secret: consumerSecret },
    signature_method: "HMAC-SHA1",
    hash_function(baseString: string, key: string) {
      return crypto.createHmac("sha1", key).update(baseString).digest("base64");
    },
  });
}

/**
 * Fordert einen historischen Aktivitäten-Backfill bei Garmin an.
 * Garmin bestätigt mit HTTP 202 und pusht die Daten asynchron an den Webhook.
 */
export const garminBackfill = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { days = 30 } = request.data || {};
    const clampedDays = Math.min(Math.max(days, 1), 90); // Max 90 Tage gemäß Garmin-Vorgaben

    const db = admin.firestore();
    const tokenDoc = await db.collection("users").doc(uid).collection("private").doc("integrations").get();
    const garminData = tokenDoc.data()?.garmin;

    if (!garminData || !garminData.oauthToken || !garminData.oauthTokenSecret) {
      throw new HttpsError("failed-precondition", "Garmin is not connected.");
    }

    const key = garminConsumerKey.value();
    const secret = garminConsumerSecret.value();
    const oauth = getOAuthClient(key, secret);

    const nowSec = Math.floor(Date.now() / 1000);
    const startSec = nowSec - (clampedDays * 24 * 60 * 60);

    const requestData = {
      url: `https://apis.garmin.com/wellness-api/rest/backfill/activities?summaryStartTimeInSeconds=${startSec}&summaryEndTimeInSeconds=${nowSec}`,
      method: "GET",
    };

    try {
      const authHeader = oauth.toHeader(
        oauth.authorize(requestData, { key: garminData.oauthToken, secret: garminData.oauthTokenSecret })
      );

      await axios.get(requestData.url, { headers: authHeader });

      // Status aktualisieren
      await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
        backfill: {
          state: "IN_PROGRESS",
          from: new Date(startSec * 1000).toISOString(),
          to: new Date(nowSec * 1000).toISOString(),
          requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, { merge: true });

      return { success: true, fromSec: startSec, toSec: nowSec };
    } catch (error: any) {
      console.error("Garmin Backfill Error:", error.response?.data || error.message);
      // Wenn 202 zurückkommt, ist es bei Axios manchmal kein Fehler
      if (error.response?.status === 202) {
        await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
          backfill: {
            state: "IN_PROGRESS",
            from: new Date(startSec * 1000).toISOString(),
            to: new Date(nowSec * 1000).toISOString(),
            requestedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        }, { merge: true });
        return { success: true };
      }

      const responseData = error.response?.data;
      const errorMsg = typeof responseData === 'object' ? JSON.stringify(responseData) : (responseData || error.message);
      if (errorMsg.includes("HISTORICAL_DATA_EXPORT")) {
        throw new HttpsError(
          "permission-denied",
          "Garmin hat den historischen Backfill noch nicht freigeschaltet (erfordert das Feature 'HISTORICAL_DATA_EXPORT' im Garmin Developer Portal). Neue Aktivitäten werden ab sofort automatisch per Webhook übertragen."
        );
      }

      throw new HttpsError("internal", `Backfill request failed: ${error.message}`);
    }
  }
);
