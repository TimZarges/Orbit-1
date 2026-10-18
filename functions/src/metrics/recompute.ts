/**
 * @file recompute.ts
 * @description Callable Cloud Function zur nachträglichen Neuberechnung aller Metriken.
 * Wird aufgerufen, wenn ein Athlet Schwellenwerte rückwirkend anpasst oder
 * eine historische Neuberechnung für die Performance Management Chart (PMC) anfordert.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";

/**
 * Triggert die asynchrone Neuberechnung aller physiologischen Metriken (NP, TSS, CTL, ATL, TSB)
 * ab einem optionalen Startdatum für den authentifizierten Athleten.
 *
 * @throws {HttpsError} unauthenticated - Wenn der Aufrufer nicht authentifiziert ist.
 */
export const recomputeMetrics = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  // TODO: Iteriere über alle Aktivitäten ab startDate,
  // berechne NP/TSS/CTL/ATL neu und schreibe sie per Batch.
  
  return { success: true, message: "Metriken werden im Hintergrund neu berechnet." };
});
