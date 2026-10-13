import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { updateSportBests } from "./bests";

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

  // Bestwerte aktualisieren (falls Leistungswerte im Summary vorhanden)
  if (data.sport && data.summary?.avgPowerW) {
    const avgW = Math.round(data.summary.avgPowerW);
    // Näherungsweise Standard-MMP aus Summary erzeugen
    const mmp: Record<string, number> = {
      "5": Math.round(avgW * 1.5),
      "60": Math.round(avgW * 1.25),
      "300": Math.round(avgW * 1.1),
      "1200": avgW,
    };
    await updateSportBests(event.params.uid, data.sport, mmp);
  }

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
