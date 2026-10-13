import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

/**
 * Firestore-Trigger für geplante Einheiten (`plannedWorkouts/{workoutId}`).
 * Pflegt das denormalisierte `coachId`-Feld für Trainer-Abfragen, sofern
 * eine aktive Kalender-Freigabe (`permissions.calendar == true`) vorliegt.
 */
export const onPlannedWorkoutWritten = onDocumentWritten("plannedWorkouts/{workoutId}", async (event) => {
  const after = event.data?.after;
  if (!after || !after.exists) return; // Gelöscht -> nichts zu tun

  const data = after.data();
  if (!data) return;

  const athleteId = data.athleteId;
  if (!athleteId) return;

  // Wenn coachId bereits gesetzt ist, keine erneute Prüfung nötig
  if (data.coachId) return;

  const db = admin.firestore();
  
  // 1. Zugeordneten Coach des Athleten laden
  const userDoc = await db.collection("users").doc(athleteId).get();
  const coachId = userDoc.data()?.coachId;
  if (!coachId) return;

  // 2. Prüfen, ob Kalender-Berechtigung aktiv ist
  const linkDoc = await db.collection("coachLinks").doc(`${athleteId}_${coachId}`).get();
  if (!linkDoc.exists) return;

  const permissions = linkDoc.data()?.permissions;
  if (permissions?.calendar !== true) return;

  // 3. coachId auf dem plannedWorkout-Dokument denormalisieren
  await after.ref.update({
    coachId: coachId,
  });
});
