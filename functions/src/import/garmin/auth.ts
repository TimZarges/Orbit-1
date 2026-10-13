import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import axios from "axios";
import * as crypto from "crypto";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const OAuth = require("oauth-1.0a");

// Secrets aus Google Cloud Secret Manager
const garminConsumerKey = defineSecret("GARMIN_CONSUMER_KEY");
const garminConsumerSecret = defineSecret("GARMIN_CONSUMER_SECRET");

const CALLBACK_URL = "https://orbit-app-mvp.web.app/callback/garmin";

/**
 * Erstellt eine signierte OAuth 1.0a Instanz mit HMAC-SHA1.
 */
function getOAuthClient(consumerKey: string, consumerSecret: string) {
  return new OAuth({
    consumer: {
      key: consumerKey,
      secret: consumerSecret,
    },
    signature_method: "HMAC-SHA1",
    hash_function(baseString: string, key: string) {
      return crypto.createHmac("sha1", key).update(baseString).digest("base64");
    },
  });
}

/**
 * 1. Schritt: Startet den OAuth 1.0a Flow.
 * Ruft den Garmin Request Token ab und gibt die Authentifizierungs-URL zurück.
 */
export const garminAuthStart = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const key = garminConsumerKey.value();
    const secret = garminConsumerSecret.value();

    if (!key || !secret) {
      throw new HttpsError("failed-precondition", "Garmin credentials are not configured.");
    }

    const oauth = getOAuthClient(key, secret);
    const requestData = {
      url: "https://connectapi.garmin.com/oauth-service/oauth/request_token",
      method: "POST",
      data: { oauth_callback: CALLBACK_URL },
    };

    try {
      const authHeader = oauth.toHeader(oauth.authorize(requestData));
      const response = await axios.post(requestData.url, null, {
        headers: {
          ...authHeader,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      });

      // Response: oauth_token=...&oauth_token_secret=...
      const params = new URLSearchParams(response.data);
      const oauthToken = params.get("oauth_token");
      const oauthTokenSecret = params.get("oauth_token_secret");

      if (!oauthToken || !oauthTokenSecret) {
        throw new Error("Failed to parse request token from Garmin response.");
      }

      // Temporären Request Token Secret sicher in Firestore (private) ablegen
      await admin.firestore().collection("users").doc(uid).collection("private").doc("garminOAuth1").set({
        oauthToken,
        oauthTokenSecret,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Authorization-URL für den Browser / In-App WebView
      const authUrl = `https://connect.garmin.com/oauthConfirm?oauth_token=${encodeURIComponent(oauthToken)}`;

      return { authUrl, oauthToken };
    } catch (error: any) {
      console.error("Garmin AuthStart Error:", error.response?.data || error.message);
      throw new HttpsError("internal", `Garmin Auth Request failed: ${error.message}`);
    }
  }
);

/**
 * 2. Schritt: Tauscht den verifizierten Request Token gegen den permanenten Access Token ein.
 * Holt zugleich die permanente Garmin User ID ab (wichtig für den Webhook!).
 */
export const garminAuthCallback = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { oauthToken, oauthVerifier } = request.data;
    if (!oauthVerifier) {
      throw new HttpsError("invalid-argument", "Missing oauthVerifier.");
    }

    const key = garminConsumerKey.value();
    const secret = garminConsumerSecret.value();

    // Gespeichertes Secret des Request Tokens laden
    const stateDoc = await admin.firestore().collection("users").doc(uid).collection("private").doc("garminOAuth1").get();
    if (!stateDoc.exists) {
      throw new HttpsError("not-found", "No pending Garmin OAuth session found.");
    }

    const stateData = stateDoc.data();
    if (!stateData || !stateData.oauthTokenSecret) {
      throw new HttpsError("not-found", "Invalid Garmin OAuth session.");
    }

    const requestToken = oauthToken || stateData.oauthToken;
    const requestTokenSecret = stateData.oauthTokenSecret;
    const oauth = getOAuthClient(key, secret);

    const requestData = {
      url: "https://connectapi.garmin.com/oauth-service/oauth/access_token",
      method: "POST",
      data: { oauth_verifier: oauthVerifier },
    };

    try {
      const authHeader = oauth.toHeader(
        oauth.authorize(requestData, { key: requestToken, secret: requestTokenSecret })
      );

      const response = await axios.post(requestData.url, null, {
        headers: {
          ...authHeader,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      });

      // Response: oauth_token=...&oauth_token_secret=...
      const params = new URLSearchParams(response.data);
      const accessToken = params.get("oauth_token");
      const accessTokenSecret = params.get("oauth_token_secret");

      if (!accessToken || !accessTokenSecret) {
        throw new Error("Invalid access token response from Garmin.");
      }

      // Garmin User ID abrufen (zur eindeutigen Verknüpfung bei Push Webhooks)
      let garminUserId = params.get("userId") || params.get("user_id");

      if (!garminUserId) {
        // Fallback: Benutzer-ID über User-Id Endpunkt abrufen
        try {
          const userReqData = {
            url: "https://apis.garmin.com/wellness-api/rest/user/id",
            method: "GET",
          };
          const userHeader = oauth.toHeader(
            oauth.authorize(userReqData, { key: accessToken, secret: accessTokenSecret })
          );
          const userRes = await axios.get(userReqData.url, { headers: userHeader });
          garminUserId = userRes.data?.userId;
        } catch (e: any) {
          console.warn("Could not fetch user ID from endpoint, using token hash as fallback:", e.message);
          garminUserId = crypto.createHash("sha256").update(accessToken).digest("hex").substring(0, 16);
        }
      }

      // 1. Tokens sicher speichern (NUR in private)
      await admin.firestore().collection("users").doc(uid).collection("private").doc("integrations").set({
        garmin: {
          version: "OAUTH1",
          oauthToken: accessToken,
          oauthTokenSecret: accessTokenSecret,
          garminUserId: garminUserId,
          connectedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, { merge: true });

      // 2. Temporäres Auth-Dokument löschen
      await stateDoc.ref.delete();

      // 3. Öffentlichen Status aktualisieren (Client-lesbar für UI)
      await admin.firestore().collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
        state: "CONNECTED",
        provider: "GARMIN",
        garminUserId: garminUserId,
        connectedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSyncAt: null,
      });

      return { success: true, garminUserId };
    } catch (error: any) {
      console.error("Garmin AuthCallback Error:", error.response?.data || error.message);
      throw new HttpsError("internal", `Garmin Token Exchange failed: ${error.message}`);
    }
  }
);

/**
 * 3. Schritt: Trennt die Garmin-Verbindung und löscht alle Tokens.
 */
export const garminDisconnect = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const db = admin.firestore();

  // Tokens löschen
  await db.collection("users").doc(uid).collection("private").doc("integrations").update({
    garmin: admin.firestore.FieldValue.delete(),
  });

  // Status auf getrennt setzen
  await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
    state: "DISCONNECTED",
    provider: "GARMIN",
    disconnectedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});
