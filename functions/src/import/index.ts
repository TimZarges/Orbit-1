import { onObjectFinalized } from "firebase-functions/v2/storage";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { parseActivityAndSave } from "./activityParser";

export * from "./activityParser";
export * from "./deleteActivity";
export * from "./garmin";

/**
 * Storage-Trigger für Aktivitäts-Dateiuploads (.fit, .tcx, .gpx, inkl. .gz).
 * Reagiert auf Uploads in users/{uid}/fit/... und users/{uid}/uploads/...
 */
export const processFitUpload = onObjectFinalized(
  { bucket: process.env.STORAGE_BUCKET || "orbit-app-mvp.firebasestorage.app" },
  async (event) => {
    const filePath = event.data.name;
    if (!filePath) return;

    // Unterstützt users/{uid}/fit/{activityId}.ext, users/{uid}/rawActivities/{activityId}.ext oder users/{uid}/uploads/{activityId}.ext
    // Erweiterungen: .fit, .tcx, .gpx (auch komprimiert als .gz)
    const match = filePath.match(/^users\/([^\/]+)\/(?:fit|uploads|rawActivities)\/([^\/]+)\.(fit|tcx|gpx)(?:\.gz)?$/i);
    if (!match) {
      logger.info(`Ignored file (no supported activity extension): ${filePath}`);
      return;
    }

    const uid = match[1];
    const activityId = match[2];
    const extension = match[3].toLowerCase();

    let source: "FIT_UPLOAD" | "TCX_UPLOAD" | "GPX_UPLOAD" = "FIT_UPLOAD";
    if (extension === "tcx") source = "TCX_UPLOAD";
    else if (extension === "gpx") source = "GPX_UPLOAD";

    const db = admin.firestore();
    const activityRef = db.collection("activities").doc(activityId);

    try {
      await activityRef.set({
        athleteId: uid,
        processing: { state: "PROCESSING" },
      }, { merge: true });

      const bucket = admin.storage().bucket(event.data.bucket);
      const file = bucket.file(filePath);
      const [buffer] = await file.download();

      const result = await parseActivityAndSave(uid, activityId, buffer, source, filePath);
      logger.info(`Successfully processed ${source} file ${filePath} -> Activity ID ${result.activityId} (duplicate: ${result.isDuplicate})`);
    } catch (error: any) {
      logger.error(`Error processing activity file ${filePath}:`, error);
      await activityRef.set({
        processing: {
          state: "FAILED",
          errorCode: error.message || String(error),
        },
      }, { merge: true });
    }
  }
);

/**
 * Alias für processFitUpload zur semantischen Unterstützung aller Formate
 */
export const processActivityUpload = processFitUpload;
