import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * Löscht eine Aktivität sowie die zugehörigen Storage-Dateien (.fit und .streams.json.gz).
 * DSGVO-konform in europe-west3 (Frankfurt).
 */
export const deleteActivity = onCall(
  { region: "europe-west3", enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { activityId, athleteId } = request.data || {};
    if (!activityId || !athleteId) {
      throw new HttpsError("invalid-argument", "Missing activityId or athleteId.");
    }

    // Basic authorization: user must be the athlete.
    if (uid !== athleteId) {
      throw new HttpsError("permission-denied", "Only the athlete can delete their activities.");
    }

    const db = admin.firestore();
    const bucket = admin.storage().bucket();

    const activityRef = db.collection("activities").doc(activityId);
    const doc = await activityRef.get();

    if (!doc.exists) {
      throw new HttpsError("not-found", "Activity not found.");
    }

    if (doc.data()?.athleteId !== athleteId) {
      throw new HttpsError("permission-denied", "Athlete ID mismatch.");
    }

    // Delete the activity document
    await activityRef.delete();

    // Delete associated files
    const fitFile = bucket.file(`users/${athleteId}/fit/${activityId}.fit`);
    const streamFile = bucket.file(`users/${athleteId}/streams/${activityId}.json.gz`);

    try {
      await fitFile.delete();
    } catch (e) {
      // Ignore if not found
    }

    try {
      await streamFile.delete();
    } catch (e) {
      // Ignore if not found
    }

    return { success: true };
  }
);
