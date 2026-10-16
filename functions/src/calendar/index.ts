import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { sendWorkoutUpdatePush } from "../notifications";

/**
 * Firestore-Trigger für geplante Einheiten (`plannedWorkouts/{workoutId}`).
 * 1. Pflegt das denormalisierte `coachId`-Feld für Trainer-Abfragen, sofern
 *    eine aktive Kalender-Freigabe (`permissions.calendar == true`) vorliegt.
 * 2. Sendet eine Push-Benachrichtigung an den Athleten, wenn ein Coach
 *    eine Einheit neu plant oder modifiziert.
 */
export const onPlannedWorkoutWritten = onDocumentWritten("plannedWorkouts/{workoutId}", async (event) => {
  const after = event.data?.after;
  if (!after || !after.exists) return; // Gelöscht -> nichts zu tun

  const data = after.data();
  if (!data) return;

  const athleteId = data.athleteId;
  if (!athleteId) return;

  const db = admin.firestore();

  // 1. Zugeordneten Coach des Athleten laden
  const userDoc = await db.collection("users").doc(athleteId).get();
  const coachId = userDoc.data()?.coachId;

  // Wenn coachId noch nicht gesetzt ist und ein Link besteht, coachId denormalisieren
  if (!data.coachId && coachId) {
    const linkDoc = await db.collection("coachLinks").doc(`${athleteId}_${coachId}`).get();
    if (linkDoc.exists) {
      const permissions = linkDoc.data()?.permissions;
      if (permissions?.calendar === true) {
        await after.ref.update({
          coachId: coachId,
        });
      }
    }
  }

  // 2. Push-Benachrichtigung an den Athleten, wenn die Einheit vom Coach stammt
  const authorId = data.authorId || data.createdBy;
  const isCreatedByCoach = (authorId && authorId !== athleteId) || (coachId && authorId === coachId);
  const beforeData = event.data?.before?.exists ? event.data.before.data() : null;

  // Nur pushen, wenn neu erstellt oder relevante Daten geändert wurden
  if (isCreatedByCoach && (!beforeData || beforeData.title !== data.title || beforeData.localDate !== data.localDate)) {
    let coachName: string | undefined;
    if (coachId) {
      const coachUserDoc = await db.collection("users").doc(coachId).get();
      coachName = coachUserDoc.data()?.displayName || coachUserDoc.data()?.name;
    }

    await sendWorkoutUpdatePush({
      recipientId: athleteId,
      workoutId: event.params.workoutId,
      title: data.title || "Trainingseinheit",
      date: data.localDate || "demnächst",
      coachName,
    });
  }
});
