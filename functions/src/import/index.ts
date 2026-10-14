import { onObjectFinalized } from "firebase-functions/v2/storage";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { parseFitAndSave } from "./fitParser";

export * from "./fitParser";
export * from "./deleteActivity";
export * from "./garmin";

// Storage-Trigger für den FIT-Datei-Upload
export const processFitUpload = onObjectFinalized(
  { bucket: process.env.STORAGE_BUCKET || "orbit-app-mvp.firebasestorage.app" },
  async (event) => {
  const filePath = event.data.name;
  if (!filePath) return;

  // users/{uid}/fit/{activityId}.fit
  const match = filePath.match(/^users\/([^\/]+)\/fit\/([^\/]+)\.fit$/);
  if (!match) {
    logger.info(`Ignored file: ${filePath}`);
    return;
  }

  const uid = match[1];
  const activityId = match[2];

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

    await parseFitAndSave(uid, activityId, buffer, "FIT_UPLOAD");
    logger.info(`Successfully processed FIT file ${filePath}`);
  } catch (error: any) {
    logger.error(`Error processing FIT file ${filePath}:`, error);
    await activityRef.set({
      processing: {
        state: "FAILED",
        errorCode: error.message,
      },
    }, { merge: true });
  }
});
