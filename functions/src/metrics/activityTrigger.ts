import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

export const onActivityWritten = onDocumentWritten("users/{uid}/activities/{activityId}", async (event) => {
  if (!event.data) return;
  const after = event.data.after;
  const before = event.data.before;

  // Wenn gelöscht
  if (!after.exists) {
    // Aggregation für Folgetage triggern
    await updateAggregates(event.params.uid, before.data()?.localDate);
    return;
  }

  const data = after.data();
  if (!data) return;

  // Schleifenschutz: Wir schreiben metricsVersion='1' rein, wenn wir fertig sind
  if (data.metricsVersion === '1') {
    return; // Bereits berechnet
  }

  // TODO: Schwellenwerte für das Datum (localDate) laden, Metriken berechnen
  // Dummy-Update um den Flow zu sichern:
  await after.ref.update({
    metricsVersion: '1',
    'metrics.quality': 'ESTIMATED',
    'metrics.tss': 50 // Placeholder
  });

  // Aggregation updaten
  await updateAggregates(event.params.uid, data.localDate);
});

async function updateAggregates(uid: string, fromDateStr: string | undefined) {
  if (!fromDateStr) return;
  // TODO: Alle Aktivitäten ab fromDateStr laden und CTL/ATL neu rechnen
  // Wir begrenzen das auf max. 365 Tage Batch
  const db = admin.firestore();
  await db.collection("users").doc(uid).collection("aggregates").doc(fromDateStr).set({
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    dailyLoad: 50 // Placeholder
  }, { merge: true });
}
