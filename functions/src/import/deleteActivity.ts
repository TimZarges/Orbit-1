import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const deleteActivity = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { activityId, athleteId } = data;
  if (!activityId || !athleteId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing activityId or athleteId.');
  }

  // Basic authorization: user must be the athlete, or a coach of the athlete.
  // For now, we only implement athlete self-deletion, coaches aren't supposed to delete athlete activities.
  if (context.auth.uid !== athleteId) {
    throw new functions.https.HttpsError('permission-denied', 'Only the athlete can delete their activities.');
  }

  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  const activityRef = db.collection('activities').doc(activityId);
  const doc = await activityRef.get();
  
  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', 'Activity not found.');
  }

  if (doc.data()?.athleteId !== athleteId) {
    throw new functions.https.HttpsError('permission-denied', 'Athlete ID mismatch.');
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
});
