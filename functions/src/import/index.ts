import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import { parseFitAndSave } from './fitParser';

// Storage trigger for FIT uploads
export const processFitUpload = functions.storage.object().onFinalize(async (object) => {
  const filePath = object.name;
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
  const activityRef = db.collection('activities').doc(activityId);

  try {
    await activityRef.set({
      athleteId: uid,
      processing: { state: 'PROCESSING' }
    }, { merge: true });

    const bucket = admin.storage().bucket(object.bucket);
    const file = bucket.file(filePath);
    const [buffer] = await file.download();

    await parseFitAndSave(uid, activityId, buffer, 'FIT_UPLOAD');
    logger.info(`Successfully processed FIT file ${filePath}`);

  } catch (error: any) {
    logger.error(`Error processing FIT file ${filePath}:`, error);
    await activityRef.set({
      processing: {
        state: 'FAILED',
        errorCode: error.message
      }
    }, { merge: true });
  }
});

export { deleteActivity } from './deleteActivity';
