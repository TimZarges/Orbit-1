import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const recomputeMetrics = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  // TODO: Iteriere über alle Aktivitäten ab startDate,
  // berechne NP/TSS/CTL/ATL neu und schreibe sie per Batch.
  
  return { success: true, message: "Metriken werden im Hintergrund neu berechnet." };
});
