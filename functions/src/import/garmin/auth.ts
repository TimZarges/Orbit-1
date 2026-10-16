import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";
import * as crypto from "crypto";
import { executeGarminBackfill, getOAuthClient, garminConsumerKey, garminConsumerSecret } from "./backfill";

const CALLBACK_URL = "https://orbit-app-mvp.web.app/callback/garmin";

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
      throw new HttpsError("failed-precondition", "Garmin credentials are not configured in Secret Manager.");
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
 * Holt die Garmin User ID ab, setzt den Schnellindex und stößt automatisch den 90-Tage-Backfill an.
 */
export const garminAuthCallback = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { oauthToken, oauthVerifier } = request.data || {};
    if (!oauthVerifier) {
      throw new HttpsError("invalid-argument", "Missing oauthVerifier.");
    }

    const key = garminConsumerKey.value();
    const secret = garminConsumerSecret.value();

    if (!key || !secret) {
      throw new HttpsError("failed-precondition", "Garmin credentials are not configured in Secret Manager.");
    }

    const db = admin.firestore();

    // Gespeichertes Secret des Request Tokens laden
    const stateDoc = await db.collection("users").doc(uid).collection("private").doc("garminOAuth1").get();
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

      // 1. Tokens sicher speichern (NUR in private, Art. 9 / Sicherheitsregel)
      await db.collection("users").doc(uid).collection("private").doc("integrations").set({
        garmin: {
          version: "OAUTH1",
          oauthToken: accessToken,
          oauthTokenSecret: accessTokenSecret,
          garminUserId: garminUserId,
          connectedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, { merge: true });

      // 2. Schnellindex anlegen (ermöglicht Webhook-Lookup in wenigen Millisekunden)
      if (garminUserId) {
        await db.collection("garminUsers").doc(garminUserId).set({
          uid,
          connectedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      // 3. Temporäres Auth-Dokument löschen
      await stateDoc.ref.delete();

      // 4. Öffentlichen Status aktualisieren (Client-lesbar für UI)
      await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
        state: "CONNECTED",
        provider: "GARMIN",
        garminUserId: garminUserId,
        connectedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSyncAt: null,
      }, { merge: true });

      // 5. Automatischer 90-Tage Backfill direkt nach erfolgreicher Kopplung (Anforderung 18.1.3)
      try {
        await executeGarminBackfill(uid, 90, { key, secret });
      } catch (backfillErr: any) {
        console.warn("Automatischer Garmin-Backfill nach Login fehlgeschlagen:", backfillErr.message);
      }

      return { success: true, garminUserId };
    } catch (error: any) {
      console.error("Garmin AuthCallback Error:", error.response?.data || error.message);
      throw new HttpsError("internal", `Garmin Token Exchange failed: ${error.message}`);
    }
  }
);

/**
 * 3. Schritt: Trennt die Garmin-Verbindung, löscht Tokens und Schnellindex.
 */
export const garminDisconnect = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const db = admin.firestore();

  // Aktuelle Garmin User ID auslesen
  const statusDoc = await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").get();
  const garminUserId = statusDoc.data()?.garminUserId;

  // Tokens löschen
  await db.collection("users").doc(uid).collection("private").doc("integrations").update({
    garmin: admin.firestore.FieldValue.delete(),
  });

  // Schnellindex löschen
  if (garminUserId) {
    await db.collection("garminUsers").doc(garminUserId).delete();
  }

  // Status auf getrennt setzen
  await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set({
    state: "DISCONNECTED",
    provider: "GARMIN",
    garminUserId: admin.firestore.FieldValue.delete(),
    disconnectedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  return { success: true };
});
