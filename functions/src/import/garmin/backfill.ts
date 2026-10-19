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

        if (err.response?.status === 429 || String(errorMsg).includes("Rate limit quota violation")) {
          errors.push("Garmin API-Ratenlimit erreicht (100 Anfragen/Minute)");
          break; // Weiteres Bombardieren des Rate-Limiters verhindern
        }

        if (String(errorMsg).includes("HISTORICAL_DATA_EXPORT")) {
          errors.push(`Feature HISTORICAL_DATA_EXPORT für ${type} noch nicht aktiv`);
        }
      }

      if (delayMs > 0) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }

    // Kurzes Delay zwischen den 30-Tage-Chunks zur Einhaltung der Garmin Rate-Limits
    if (delayMs > 0 && cIdx < chunks.length - 1) {
      await new Promise((resolve) => setTimeout(resolve, delayMs * 2));
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

const GARMIN_WEBHOOK_URL = "https://europe-west3-orbit-app-mvp.cloudfunctions.net/garminWebhook";

/**
 * Extrahiert Set-Cookie-Header in ein Cookie-Jar-Objekt.
 */
function updateCookieJar(setCookieHeader: string[] | string | undefined, jar: Record<string, string>) {
  if (!setCookieHeader) return;
  const list = Array.isArray(setCookieHeader) ? setCookieHeader : [setCookieHeader];
  for (const raw of list) {
    const firstPart = raw.split(";")[0];
    const eqIdx = firstPart.indexOf("=");
    if (eqIdx > 0) {
      const name = firstPart.substring(0, eqIdx).trim();
      const val = firstPart.substring(eqIdx + 1).trim();
      jar[name] = val;
    }
  }
}

/**
 * Formatiert das Cookie-Jar-Objekt als HTTP Cookie-Header.
 */
function formatCookieHeader(jar: Record<string, string>): string {
  return Object.entries(jar)
    .map(([k, v]) => `${k}=${v}`)
    .join("; ");
}

/**
 * Konfiguriert im Garmin Connect Developer Portal (`https://apis.garmin.com/tools`)
 * automatisch alle 5 API-Säulen (Daily Health Stats, Activity, Courses, Training, Women's Health)
 * sowie alle 20 Webhook-Endpunkte auf `garminWebhook` (`enabled = true`, `onHold = false`, `uploadType = push`).
 */
export async function configureGarminDeveloperPortal(
  consumerKey: string,
  consumerSecret: string,
  userAccessToken?: string,
  garminUserId?: string
): Promise<{
  configured: boolean;
  enabledEndpointsCount: number;
  urlMatchesCount: number;
  activeEndpointsSummary: string;
  stepsLog?: string[];
  partnerVerificationInfo?: string;
  resenderResult?: string;
  dataViewerResult?: string;
}> {
  const jar: Record<string, string> = {};
  const stepsLog: string[] = [];
  const ua =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15";

  try {
    // 1. Initiale Login-Seite abrufen für erstes SESSION-Cookie
    const initRes = await axios.get("https://apis.garmin.com/tools/login", {
      headers: { "User-Agent": ua },
      timeout: 8000,
      validateStatus: () => true,
    });
    if (!initRes || !initRes.headers) {
      return {
        configured: false,
        enabledEndpointsCount: 0,
        urlMatchesCount: 0,
        activeEndpointsSummary: "skip_mock",
      };
    }
    updateCookieJar(initRes.headers["set-cookie"], jar);
    stepsLog.push(`1. GET /tools/login -> ${initRes.status}`);

    // 2. Login per POST mit Consumer Key & Consumer Secret
    const loginBody = new URLSearchParams({
      consumerKey: consumerKey.trim(),
      consumerSecret: consumerSecret.trim(),
    }).toString();

    const loginRes = await axios.post("https://apis.garmin.com/tools/login", loginBody, {
      headers: {
        "User-Agent": ua,
        "Content-Type": "application/x-www-form-urlencoded",
        "Referer": "https://apis.garmin.com/tools/login",
        "Origin": "https://apis.garmin.com",
        "Cookie": formatCookieHeader(jar),
      },
      maxRedirects: 0,
      timeout: 8000,
      validateStatus: () => true,
    });
    updateCookieJar(loginRes.headers?.["set-cookie"], jar);
    stepsLog.push(`2. POST /tools/login -> ${loginRes.status} (loc=${loginRes.headers?.location || "none"})`);

    // 3. Zuerst GET /tools/apiConfiguration aufrufen (initialisiert Spring @SessionAttributes)
    const getApiConfigRes = await axios.get("https://apis.garmin.com/tools/apiConfiguration", {
      headers: {
        "User-Agent": ua,
        "Cookie": formatCookieHeader(jar),
      },
      maxRedirects: 0,
      timeout: 8000,
      validateStatus: () => true,
    });
    updateCookieJar(getApiConfigRes.headers?.["set-cookie"], jar);
    stepsLog.push(`3. GET /tools/apiConfiguration -> ${getApiConfigRes.status}`);

    // 4. Alle 5 API-Säulen in /tools/updateApiConfiguration aktivieren
    const apiParams = new URLSearchParams();
    for (const pillarIdx of [0, 1, 2, 3, 4]) {
      apiParams.append(`apiPillars[${pillarIdx}].enabled`, "true");
      apiParams.append(`_apiPillars[${pillarIdx}].enabled`, "on");
    }
    apiParams.append("save", "Save");

    const apiConfigRes = await axios.post(
      "https://apis.garmin.com/tools/updateApiConfiguration",
      apiParams.toString(),
      {
        headers: {
          "User-Agent": ua,
          "Content-Type": "application/x-www-form-urlencoded",
          "Referer": "https://apis.garmin.com/tools/apiConfiguration",
          "Origin": "https://apis.garmin.com",
          "Cookie": formatCookieHeader(jar),
        },
        maxRedirects: 0,
        timeout: 8000,
        validateStatus: () => true,
      }
    );
    updateCookieJar(apiConfigRes.headers?.["set-cookie"], jar);
    stepsLog.push(
      `4. POST /tools/updateApiConfiguration -> ${apiConfigRes.status} (loc=${apiConfigRes.headers?.location || "none"})`
    );

    // 5. Zuerst GET /tools/endpoints aufrufen (initialisiert Spring @SessionAttributes für Endpoints!)
    const getEpRes = await axios.get("https://apis.garmin.com/tools/endpoints", {
      headers: {
        "User-Agent": ua,
        "Cookie": formatCookieHeader(jar),
      },
      maxRedirects: 0,
      timeout: 8000,
      validateStatus: () => true,
    });
    updateCookieJar(getEpRes.headers?.["set-cookie"], jar);
    const initialEpHtml = typeof getEpRes.data === "string" ? getEpRes.data : "";
    const initialUrls = (initialEpHtml.match(new RegExp(GARMIN_WEBHOOK_URL, "g")) || []).length;
    const initialChecked = (initialEpHtml.match(/checked="checked"/g) || []).length;
    stepsLog.push(`5. GET /tools/endpoints -> ${getEpRes.status} (urls=${initialUrls}, checked=${initialChecked})`);

    let urlMatches = initialUrls;
    let enabledMatches = initialChecked;

    // 6. Falls noch nicht alle 20 Endpunkte aktiv sind, alle 20 speichern
    if (initialUrls < 20 || initialChecked < 20) {
      const hasUploadType = new Set([0, 1, 3, 4, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]);
      const epParams = new URLSearchParams();
      for (let i = 0; i <= 19; i++) {
        epParams.append(`endpoints[${i}].url`, GARMIN_WEBHOOK_URL);
        epParams.append(`_endpoints[${i}].onHold`, "on");
        epParams.append(`endpoints[${i}].enabled`, "true");
        epParams.append(`_endpoints[${i}].enabled`, "on");
        if (hasUploadType.has(i)) {
          epParams.append(`endpoints[${i}].uploadType`, "push");
        }
      }
      epParams.append("save", "Save");

      const updateEpRes = await axios.post(
        "https://apis.garmin.com/tools/updateEndpoints",
        epParams.toString(),
        {
          headers: {
            "User-Agent": ua,
            "Content-Type": "application/x-www-form-urlencoded",
            "Referer": "https://apis.garmin.com/tools/endpoints",
            "Origin": "https://apis.garmin.com",
            "Cookie": formatCookieHeader(jar),
          },
          maxRedirects: 0,
          timeout: 15000,
          validateStatus: () => true,
        }
      );
      updateCookieJar(updateEpRes.headers?.["set-cookie"], jar);
      const epHtml = typeof updateEpRes.data === "string" ? updateEpRes.data : "";
      urlMatches = (epHtml.match(new RegExp(GARMIN_WEBHOOK_URL, "g")) || []).length;
      enabledMatches = (epHtml.match(/checked="checked"/g) || []).length;
      stepsLog.push(
        `6. POST /tools/updateEndpoints -> ${updateEpRes.status} (urls=${urlMatches}, checked=${enabledMatches})`
      );
    }

    const verifyApiRes = await axios.get("https://apis.garmin.com/tools/apiConfiguration", {
      headers: {
        "User-Agent": ua,
        "Cookie": formatCookieHeader(jar),
      },
      timeout: 8000,
      validateStatus: () => true,
    });
    const apiHtml = typeof verifyApiRes.data === "string" ? verifyApiRes.data : "";
    const activeTableMatch = apiHtml.match(/<tbody>([\s\S]*?)<\/tbody>/);
    const activeSummary = activeTableMatch
      ? activeTableMatch[1].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim()
      : "";

    let partnerVerificationInfo = "";
    let resenderResult = "";
    let dataViewerResult = "";

    if (userAccessToken || garminUserId) {
      const stripHtmlBoilerplate = (html: string) =>
        html
          .replace(/<head[\s\S]*?<\/head>/gi, "")
          .replace(/<nav[\s\S]*?<\/nav>/gi, "")
          .replace(/<div id="sidebar-wrapper">[\s\S]*?<\/ul>\s*<\/div>/gi, "")
          .replace(/<form[\s\S]*?<\/form>/gi, "")
          .replace(/<footer[\s\S]*?<\/footer>/gi, "")
          .replace(/<script[\s\S]*?<\/script>/gi, "")
          .replace(/<[^>]+>/g, " ")
          .replace(/\s+/g, " ")
          .trim();

      // A) Summary Resender auslösen in 24-Stunden-Fenstern (<= 86400s) für die letzten 7 Tage
      const nowSec = Math.floor(Date.now() / 1000);
      const getResend = await axios.get("https://apis.garmin.com/tools/summaryResender", {
        headers: { "User-Agent": ua, "Cookie": formatCookieHeader(jar) },
        timeout: 8000,
        validateStatus: () => true,
      });
      updateCookieJar(getResend.headers?.["set-cookie"], jar);

      const candidateIds = (garminUserId ? [garminUserId] : [userAccessToken]).filter(Boolean) as string[];
      const resendLogs: string[] = [];

      for (const cid of candidateIds) {
        for (let d = 0; d < 14; d++) {
          const wEnd = nowSec - d * 86400;
          const wStart = wEnd - 86399; // Strikt <= 1 Tag (86399s), da Garmin > 86400s ablehnt!

          const rParams = new URLSearchParams({
            startTime: String(wStart),
            endTime: String(wEnd),
            activityEnabled: "true",
            _activityEnabled: "on",
            activityDetailEnabled: "true",
            _activityDetailEnabled: "on",
            activityFileEnabled: "true",
            _activityFileEnabled: "on",
            dailyEnabled: "true",
            _dailyEnabled: "on",
            sleepEnabled: "true",
            _sleepEnabled: "on",
            hrvEnabled: "true",
            _hrvEnabled: "on",
            userMetricsEnabled: "true",
            _userMetricsEnabled: "on",
            stressEnabled: "true",
            _stressEnabled: "on",
            bodyCompsEnabled: "true",
            _bodyCompsEnabled: "on",
            epochEnabled: "true",
            _epochEnabled: "on",
            pulseOxEnabled: "true",
            _pulseOxEnabled: "on",
            respirationEnabled: "true",
            _respirationEnabled: "on",
            skinTempEnabled: "true",
            _skinTempEnabled: "on",
            healthSnapshotEnabled: "true",
            _healthSnapshotEnabled: "on",
            moveIqsEnabled: "true",
            _moveIqsEnabled: "on",
            manualActivityEnabled: "true",
            _manualActivityEnabled: "on",
            bloodPressureEnabled: "true",
            _bloodPressureEnabled: "on",
            mctEnabled: "true",
            _mctEnabled: "on",
            clientUserId: cid,
            action: "send",
          });

          const postResend = await axios.post(
            "https://apis.garmin.com/tools/summaryResender",
            rParams.toString(),
            {
              headers: {
                "User-Agent": ua,
                "Content-Type": "application/x-www-form-urlencoded",
                "Referer": "https://apis.garmin.com/tools/summaryResender",
                "Origin": "https://apis.garmin.com",
                "Cookie": formatCookieHeader(jar),
              },
              timeout: 10000,
              validateStatus: () => true,
            }
          );
          updateCookieJar(postResend.headers?.["set-cookie"], jar);
          const rHtml = typeof postResend.data === "string" ? postResend.data : JSON.stringify(postResend.data);
          const rAlerts = rHtml.match(/<div[^>]*class="[^"]*alert[^"]*"[^>]*>([\s\S]*?)<\/div>/gi);
          const alertText = rAlerts
            ? rAlerts.map((a) => a.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim()).join(" | ")
            : stripHtmlBoilerplate(rHtml).substring(0, 200);
          if (d === 0 || !alertText.includes("invalid")) {
            resendLogs.push(`cid=${cid.substring(0, 8)} d=-${d}: ${alertText}`);
          }
          // Wenn das Format der User-ID von Garmin abgelehnt wird, nicht weitere 6 Tage mit derselben ID testen
          if (alertText.toLowerCase().includes("invalid") || alertText.toLowerCase().includes("not found")) {
            break;
          }
        }
      }
      resenderResult = resendLogs.join(" ;; ");

      // B) Data Viewer abfragen in 24-Stunden-Fenstern (JSON View für CONNECT_ACTIVITY und WELLNESS_DAILY)
      const getViewer = await axios.get("https://apis.garmin.com/tools/dataViewer", {
        headers: { "User-Agent": ua, "Cookie": formatCookieHeader(jar) },
        timeout: 8000,
        validateStatus: () => true,
      });
      updateCookieJar(getViewer.headers?.["set-cookie"], jar);

      const viewerLogs: string[] = [];
      for (const cid of candidateIds) {
        for (const sType of ["CONNECT_ACTIVITY", "WELLNESS_DAILY", "WELLNESS_SLEEP", "HRV"]) {
          const wEnd = nowSec;
          const wStart = wEnd - 86399;
          const vParams = new URLSearchParams({
            startTime: String(wStart),
            endTime: String(wEnd),
            clientUserId: cid,
            timeType: "summaryTime",
            dataViewerSummaryType: sType,
            resultView: "json",
            action: "querySummaries",
          });
          const postViewer = await axios.post(
            "https://apis.garmin.com/tools/dataViewer",
            vParams.toString(),
            {
              headers: {
                "User-Agent": ua,
                "Content-Type": "application/x-www-form-urlencoded",
                "Referer": "https://apis.garmin.com/tools/dataViewer",
                "Origin": "https://apis.garmin.com",
                "Cookie": formatCookieHeader(jar),
              },
              timeout: 10000,
              validateStatus: () => true,
            }
          );
          updateCookieJar(postViewer.headers?.["set-cookie"], jar);
          const vHtml = typeof postViewer.data === "string" ? postViewer.data : JSON.stringify(postViewer.data);
          const cleaned = stripHtmlBoilerplate(vHtml);
          viewerLogs.push(`[${cid.substring(0, 8)}:${sType}] -> ${cleaned.substring(0, 400)}`);
        }
      }
      dataViewerResult = viewerLogs.join(" || ");
    }

    return {
      configured: urlMatches > 0,
      enabledEndpointsCount: enabledMatches,
      urlMatchesCount: urlMatches,
      activeEndpointsSummary: activeSummary,
      stepsLog,
      partnerVerificationInfo,
      resenderResult,
      dataViewerResult,
    };
  } catch (err: any) {
    console.warn("Garmin Developer Portal Auto-Config Hinweis:", err.message);
    return {
      configured: false,
      enabledEndpointsCount: 0,
      urlMatchesCount: 0,
      activeEndpointsSummary: err.message,
      stepsLog,
    };
  }
}
