/**
 * @file auth.ts
 * @description OAuth-1.0a-Authentifizierung und Statusverwaltung für Garmin Connect.
 *
 * Verwaltet den Start der Autorisierung (`garminAuthStart`), den sicheren
 * Token-Austausch inkl. Abbruch- und Fehlerbereinigung (`garminAuthCallback`),
 * das saubere Zurücksetzen offener Kopplungsversuche (`garminAuthCancel`)
 * sowie die vollständige Trennung inkl. Token-Löschung (`garminDisconnect`).
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import axios from "axios";
import * as crypto from "crypto";
import {
  executeGarminBackfill,
  getOAuthClient,
  garminConsumerKey,
  garminConsumerSecret,
} from "./backfill";

/** Feste OAuth-1.0a-Callback-URL im Firebase Hosting für das Garmin Developer Portal. */
export const GARMIN_CALLBACK_URL = "https://orbit-app-mvp.web.app/callback/garmin";

/** Maximale Timeout-Dauer (10 Sekunden) für synchrone Garmin-OAuth-API-Aufrufe. */
const GARMIN_OAUTH_TIMEOUT_MS = 10000;

/**
 * Prüft, ob ein von Garmin oder dem Client übergebener `oauth_verifier` gültig ist.
 *
 * Bei einer Ablehnung durch den Nutzer leitet Garmin häufig mit `oauth_verifier=null`
 * oder leerem Parameter weiter; solche Werte werden als Abbruch behandelt.
 */
export function isValidGarminVerifier(verifier: unknown): verifier is string {
  if (typeof verifier !== "string") {
    return false;
  }
  const normalized = verifier.trim().toLowerCase();
  return (
    normalized.length > 0 &&
    normalized !== "null" &&
    normalized !== "undefined" &&
    normalized !== "denied"
  );
}

/**
 * Normalisiert die Eingabedaten für `garminAuthCallback` und erkennt Abbrüche deterministisch.
 */
export function normalizeGarminCallbackInput(data: unknown): {
  oauthToken: string | null;
  oauthVerifier: string | null;
  isCancelled: boolean;
} {
  const payload = (data && typeof data === "object" ? data : {}) as Record<string, unknown>;
  const rawToken = typeof payload.oauthToken === "string" ? payload.oauthToken.trim() : "";
  const rawVerifier = typeof payload.oauthVerifier === "string" ? payload.oauthVerifier.trim() : "";
  const rawDenied = typeof payload.denied === "string" ? payload.denied.trim() : "";
  const cancelledFlag = payload.cancelled === true || rawDenied.length > 0;

  if (cancelledFlag || !isValidGarminVerifier(rawVerifier)) {
    return {
      oauthToken: rawToken.length > 0 ? rawToken : null,
      oauthVerifier: null,
      isCancelled: true,
    };
  }

  return {
    oauthToken: rawToken.length > 0 ? rawToken : null,
    oauthVerifier: rawVerifier,
    isCancelled: false,
  };
}

/**
 * Aktualisiert den öffentlichen Garmin-Verbindungsstatus nur dann, wenn noch keine
 * aktive Verbindung (`CONNECTED`) besteht, damit eine versehentliche Wiederholung
 * oder ein abgebrochener Zweitversuch niemals eine laufende Verbindung überschreibt.
 */
async function updateNonConnectedGarminStatus(
  db: FirebaseFirestore.Firestore,
  uid: string,
  updateData: Record<string, unknown>
): Promise<void> {
  const statusRef = db.collection("users").doc(uid).collection("integrationStatus").doc("garmin");
  const currentSnap = await statusRef.get();
  const currentState = currentSnap.exists ? currentSnap.data()?.state : null;
  if (currentState === "CONNECTED") {
    return;
  }

  await statusRef.set(
    {
      provider: "GARMIN",
      ...updateData,
    },
    { merge: true }
  );
}

/**
 * 1. Schritt: Startet den OAuth-1.0a-Flow für Garmin Connect.
 *
 * Fordert einen temporären Request Token an, speichert dessen Secret ausschließlich
 * im geschützten Dokument `users/{uid}/private/garminOAuth1` und setzt den Client-Status
 * auf `CONNECTING`, damit Frontend- und Reload-Zustände synchron bleiben.
 */
export const garminAuthStart = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret], enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Nutzer ist nicht authentifiziert.");
    }

    const key = garminConsumerKey.value();
    const secret = garminConsumerSecret.value();

    if (!key || !secret) {
      throw new HttpsError(
        "failed-precondition",
        "Garmin-Zugangsdaten sind im Secret Manager nicht konfiguriert."
      );
    }

    const db = admin.firestore();
    const oauth = getOAuthClient(key, secret);
    const requestData = {
      url: "https://connectapi.garmin.com/oauth-service/oauth/request_token",
      method: "POST",
      data: { oauth_callback: GARMIN_CALLBACK_URL },
    };

    try {
      // OAuth-1.0a-Header signieren und Request Token bei Garmin abrufen
      const authHeader = oauth.toHeader(oauth.authorize(requestData));
      const response = await axios.post(requestData.url, null, {
        headers: {
          ...authHeader,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        timeout: GARMIN_OAUTH_TIMEOUT_MS,
      });

      const params = new URLSearchParams(response.data);
      const oauthToken = params.get("oauth_token");
      const oauthTokenSecret = params.get("oauth_token_secret");

      if (!oauthToken || !oauthTokenSecret) {
        throw new Error("Request Token konnte aus der Garmin-Antwort nicht gelesen werden.");
      }

      // Temporäres Request-Token-Secret strikt serverseitig ablegen
      await db.collection("users").doc(uid).collection("private").doc("garminOAuth1").set({
        oauthToken,
        oauthTokenSecret,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Offenen Anmeldestatus sichtbar machen, ohne eine bestehende Verbindung zu überschreiben
      await updateNonConnectedGarminStatus(db, uid, {
        state: "CONNECTING",
        authStartedAt: FieldValue.serverTimestamp(),
        errorMessage: FieldValue.delete(),
      });

      const authUrl = `https://connect.garmin.com/oauthConfirm?oauth_token=${encodeURIComponent(oauthToken)}`;
      return { authUrl, oauthToken };
    } catch (error: any) {
      console.error("Garmin AuthStart Error:", error.response?.data || error.message);

      // Halboffene Session bereinigen, damit der Client sauber in einen Fehlerzustand wechseln kann
      await db
        .collection("users")
        .doc(uid)
        .collection("private")
        .doc("garminOAuth1")
        .delete()
        .catch(() => undefined);

      await updateNonConnectedGarminStatus(db, uid, {
        state: "ERROR",
        errorMessage: "Verbindung zu Garmin Connect konnte nicht gestartet werden. Bitte erneut versuchen.",
      }).catch(() => undefined);

      throw new HttpsError("internal", `Garmin-Anfrage fehlgeschlagen: ${error.message}`);
    }
  }
);

/**
 * Bricht einen laufenden, noch nicht bestätigten Garmin-Kopplungsversuch sauber ab.
 *
 * Löscht das temporäre OAuth-1.0a-Request-Token und setzt den Status auf `DISCONNECTED`
 * (oder auf Wunsch nach Timeout mit verständlichem Hinweis zurück), sofern noch keine
 * aktive Verbindung vorliegt.
 */
export const garminAuthCancel = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Nutzer ist nicht authentifiziert.");
    }

    const reason =
      typeof request.data?.reason === "string" ? request.data.reason.trim() : "cancelled";
    const db = admin.firestore();

    // Temporäre Session verwerfen
    await db
      .collection("users")
      .doc(uid)
      .collection("private")
      .doc("garminOAuth1")
      .delete()
      .catch(() => undefined);

    if (reason === "timeout") {
      await updateNonConnectedGarminStatus(db, uid, {
        state: "ERROR",
        errorMessage:
          "Die Garmin-Bestätigung hat zu lange gedauert und wurde zurückgesetzt. Bitte starte die Verbindung erneut.",
      });
    } else {
      await updateNonConnectedGarminStatus(db, uid, {
        state: "DISCONNECTED",
        errorMessage: FieldValue.delete(),
        cancelledAt: FieldValue.serverTimestamp(),
      });
    }

    return { success: true, cancelled: true };
  }
);

/**
 * 2. Schritt: Tauscht den verifizierten Request Token gegen den permanenten Access Token ein.
 *
 * Behandelt abgelehnte Autorisierungen (`oauth_verifier=null`) und abgelaufene Sessions
 * deterministisch, speichert Tokens ausschließlich in `private/integrations`, legt den
 * Webhook-Schnellindex an, setzt `CONNECTED` und stößt anschließend den 90-Tage-Backfill an.
 */
export const garminAuthCallback = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret], enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Nutzer ist nicht authentifiziert.");
    }

    const db = admin.firestore();
    const { oauthToken, oauthVerifier, isCancelled } = normalizeGarminCallbackInput(request.data);

    // Abbruch oder `oauth_verifier=null` von Garmin sauber zurücksetzen statt 401 zu provozieren
    if (isCancelled || !oauthVerifier) {
      await db
        .collection("users")
        .doc(uid)
        .collection("private")
        .doc("garminOAuth1")
        .delete()
        .catch(() => undefined);

      await updateNonConnectedGarminStatus(db, uid, {
        state: "DISCONNECTED",
        errorMessage: "Garmin-Autorisierung wurde im Browser abgebrochen.",
        cancelledAt: FieldValue.serverTimestamp(),
      });

      throw new HttpsError("cancelled", "Garmin-Autorisierung wurde im Browser abgebrochen.");
    }

    const key = garminConsumerKey.value();
    const secret = garminConsumerSecret.value();

    if (!key || !secret) {
      throw new HttpsError(
        "failed-precondition",
        "Garmin-Zugangsdaten sind im Secret Manager nicht konfiguriert."
      );
    }

    // Gespeichertes Request-Token-Secret laden
    const stateRef = db.collection("users").doc(uid).collection("private").doc("garminOAuth1");
    const stateDoc = await stateRef.get();
    if (!stateDoc.exists) {
      await updateNonConnectedGarminStatus(db, uid, {
        state: "ERROR",
        errorMessage: "Keine aktive Garmin-Anmeldesitzung gefunden. Bitte starte die Verbindung erneut.",
      });
      throw new HttpsError(
        "not-found",
        "Keine aktive Garmin-Anmeldesitzung gefunden. Bitte starte die Verbindung erneut."
      );
    }

    const stateData = stateDoc.data();
    if (!stateData || !stateData.oauthTokenSecret) {
      await stateRef.delete().catch(() => undefined);
      await updateNonConnectedGarminStatus(db, uid, {
        state: "ERROR",
        errorMessage: "Die Garmin-Anmeldesitzung ist ungültig. Bitte starte erneut.",
      });
      throw new HttpsError("not-found", "Ungültige Garmin-OAuth-Sitzung.");
    }

    // Prüfen, ob ein veralteter Callback aus einem früheren Tab übermittelt wurde
    if (oauthToken && stateData.oauthToken && oauthToken !== stateData.oauthToken) {
      throw new HttpsError(
        "failed-precondition",
        "Dieser Bestätigungscode gehört zu einem älteren Anmeldeversuch. Bitte nutze den aktuell geöffneten Tab."
      );
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
        timeout: GARMIN_OAUTH_TIMEOUT_MS,
      });

      const params = new URLSearchParams(response.data);
      const accessToken = params.get("oauth_token");
      const accessTokenSecret = params.get("oauth_token_secret");

      if (!accessToken || !accessTokenSecret) {
        throw new Error("Ungültige Access-Token-Antwort von Garmin.");
      }

      // Garmin User ID ermitteln (für eindeutige Zuordnung eingehender Push-Webhooks)
      let garminUserId = params.get("userId") || params.get("user_id");

      if (!garminUserId) {
        try {
          const userReqData = {
            url: "https://apis.garmin.com/wellness-api/rest/user/id",
            method: "GET",
          };
          const userHeader = oauth.toHeader(
            oauth.authorize(userReqData, { key: accessToken, secret: accessTokenSecret })
          );
          const userRes = await axios.get(userReqData.url, {
            headers: userHeader,
            timeout: GARMIN_OAUTH_TIMEOUT_MS,
          });
          garminUserId = userRes.data?.userId;
        } catch (e: any) {
          console.warn(
            "Garmin User-ID-Endpunkt nicht erreichbar, nutze Token-Hash als Fallback:",
            e.message
          );
          garminUserId = crypto
            .createHash("sha256")
            .update(accessToken)
            .digest("hex")
            .substring(0, 16);
        }
      }

      // 1. Permanente Tokens ausschließlich im geschützten private-Dokument speichern
      await db.collection("users").doc(uid).collection("private").doc("integrations").set(
        {
          garmin: {
            version: "OAUTH1",
            oauthToken: accessToken,
            oauthTokenSecret: accessTokenSecret,
            garminUserId,
            connectedAt: FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );

      // 2. Schnellindex für eingehende Garmin-Webhooks anlegen
      if (garminUserId) {
        await db.collection("garminUsers").doc(garminUserId).set(
          {
            uid,
            connectedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }

      // 3. Temporäre OAuth-1.0a-Session löschen
      await stateRef.delete();

      // 4. Öffentlichen Verbindungsstatus auf CONNECTED setzen und etwaige Alt-Fehler löschen
      await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set(
        {
          state: "CONNECTED",
          provider: "GARMIN",
          garminUserId,
          connectedAt: FieldValue.serverTimestamp(),
          lastSyncAt: null,
          errorMessage: FieldValue.delete(),
        },
        { merge: true }
      );

      // 5. Automatischer 90-Tage-Backfill best-effort nach erfolgreicher Statusspeicherung
      try {
        await executeGarminBackfill(uid, 90, { key, secret });
      } catch (backfillErr: any) {
        console.warn("Automatischer Garmin-Backfill nach Login fehlgeschlagen:", backfillErr.message);
      }

      return { success: true, garminUserId };
    } catch (error: any) {
      console.error("Garmin AuthCallback Error:", error.response?.data || error.message);

      // Temporäre Session aufräumen und Fehlerzustand für sauberen UI-Neustart setzen
      await stateRef.delete().catch(() => undefined);
      await updateNonConnectedGarminStatus(db, uid, {
        state: "ERROR",
        errorMessage:
          "Bestätigungscode konnte bei Garmin nicht eingelöst werden. Bitte starte die Verbindung erneut.",
      }).catch(() => undefined);

      throw new HttpsError("internal", `Garmin Token-Austausch fehlgeschlagen: ${error.message}`);
    }
  }
);

/**
 * 3. Schritt: Trennt die Garmin-Verbindung, löscht Tokens, offene Auth-Sessions und Schnellindex.
 */
export const garminDisconnect = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Nutzer ist nicht authentifiziert.");
    }

    const db = admin.firestore();

    // Aktuelle Garmin User ID vor dem Löschen auslesen
    const statusDoc = await db
      .collection("users")
      .doc(uid)
      .collection("integrationStatus")
      .doc("garmin")
      .get();
    const garminUserId = statusDoc.data()?.garminUserId;

    // Permanente und temporäre Garmin-Daten sicher entfernen (ohne Fehler bei fehlendem Dokument)
    await db.collection("users").doc(uid).collection("private").doc("integrations").set(
      {
        garmin: FieldValue.delete(),
      },
      { merge: true }
    );
    await db
      .collection("users")
      .doc(uid)
      .collection("private")
      .doc("garminOAuth1")
      .delete()
      .catch(() => undefined);

    // Webhook-Schnellindex löschen
    if (garminUserId) {
      await db.collection("garminUsers").doc(garminUserId).delete().catch(() => undefined);
    }

    // Status sauber auf DISCONNECTED setzen und Fehlermeldungen bereinigen
    await db.collection("users").doc(uid).collection("integrationStatus").doc("garmin").set(
      {
        state: "DISCONNECTED",
        provider: "GARMIN",
        garminUserId: FieldValue.delete(),
        errorMessage: FieldValue.delete(),
        disconnectedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { success: true };
  }
);
