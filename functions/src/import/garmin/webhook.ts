import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

/**
 * Der HTTPS-Endpunkt, den Garmin aufruft.
 * Muss öffentlich erreichbar sein und SOFORT mit 200 OK antworten.
 */
export const garminWebhook = onRequest(async (req, res) => {
  // Sicherheits-Check: POST Methode
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  try {
    const payload = req.body;
    
    // Garmin schickt Arrays von Aktivitäten oder De-Auth Events
    // Wir speichern das rohe Payload sofort ab und antworten.
    await admin.firestore().collection("webhookEvents").add({
      source: "GARMIN",
      payload: payload,
      status: "RECEIVED",
      receivedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Garmin verlangt 200 OK oder 202 Accepted.
    res.status(200).send("OK");
  } catch (error) {
    console.error("Webhook processing error:", error);
    // Selbst bei Fehlern im Speichern besser 200 senden, damit Garmin nicht endlos retried,
    // oder 500, wenn wir es WIRKLICH neu zugestellt bekommen wollen.
    res.status(500).send("Internal Error");
  }
});

/**
 * Asynchrone Verarbeitung der Webhooks.
 */
export const processGarminWebhook = onDocumentCreated("webhookEvents/{docId}", async (event) => {
  const doc = event.data;
  if (!doc) return;

  const data = doc.data();
  if (data.source !== "GARMIN" || data.status !== "RECEIVED") return;

  try {
    const payload = data.payload;

    // TODO: Payload parsen. 
    // Garmin-Struktur: 
    // { "activityDetails": [{ "userId": "...", "summaryId": "..." }] }
    // { "deregistrations": [{ "userId": "..." }] }

    if (payload.deregistrations) {
      for (const dereg of payload.deregistrations) {
        await handleDeregistration(dereg.userId);
      }
    }

    if (payload.activityDetails) {
      for (const _act of payload.activityDetails) {
        // Activity laden und parsen...
      }
    }

    // Health-Daten verarbeiten (Dailies, Sleeps, HRV)
    if (Array.isArray(payload.dailies)) {
      for (const daily of payload.dailies) {
        await handleDailyMetrics(daily, "daily");
      }
    }

    if (Array.isArray(payload.sleeps)) {
      for (const sleep of payload.sleeps) {
        await handleDailyMetrics(sleep, "sleep");
      }
    }

    if (Array.isArray(payload.hrv)) {
      for (const hrvItem of payload.hrv) {
        await handleDailyMetrics(hrvItem, "hrv");
      }
    }

    await doc.ref.update({
      status: "PROCESSED",
      processedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  } catch (e: any) {
    console.error("Webhook Worker Error:", e);
    await doc.ref.update({
      status: "FAILED",
      error: e.message
    });
  }
});

/**
 * Verarbeitet eingehende Health-Objekte von Garmin und führt sie per Upsert zusammen.
 */
async function handleDailyMetrics(item: any, type: "daily" | "sleep" | "hrv") {
  const garminUserId = item.userId;
  if (!garminUserId) return;

  const db = admin.firestore();
  const statusDocs = await db.collectionGroup("integrationStatus")
    .where("garminUserId", "==", garminUserId)
    .limit(1)
    .get();

  if (statusDocs.empty) {
    console.warn(`No user found for garminUserId: ${garminUserId}`);
    return;
  }

  const uid = statusDocs.docs[0].ref.parent.parent?.id;
  if (!uid) return;

  const localDate = item.calendarDate;
  if (!localDate || typeof localDate !== "string") {
    console.warn(`Missing or invalid calendarDate in Garmin ${type} item`);
    return;
  }

  const updateData: Record<string, any> = {
    source: "GARMIN",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (type === "daily") {
    if (typeof item.restingHeartRateInBeatsPerMinute === "number") {
      updateData.restingHrBpm = item.restingHeartRateInBeatsPerMinute;
    }
    if (typeof item.averageStressLevel === "number") {
      updateData.stress = item.averageStressLevel;
    }
    const steps = item.steps ?? item.totalSteps;
    if (typeof steps === "number") {
      updateData.steps = steps;
    }
    if (typeof item.bodyBatteryChargedValue === "number" || typeof item.bodyBattery === "number") {
      updateData.bodyBattery = item.bodyBattery ?? item.bodyBatteryChargedValue;
    }
  } else if (type === "sleep") {
    if (typeof item.durationInSeconds === "number") {
      updateData.sleepSeconds = item.durationInSeconds;
    }
    const sleepScore = item.overallSleepScore?.value ?? item.sleepScore;
    if (typeof sleepScore === "number") {
      updateData.sleepScore = sleepScore;
    }
  } else if (type === "hrv") {
    const hrvValue = item.lastNightAvg ?? item.hrv;
    if (typeof hrvValue === "number") {
      updateData.hrvMs = hrvValue;
    }
  }

  // Idempotenter Upsert (Merge): Bestehende Felder des Tages bleiben erhalten
  await db.collection("users").doc(uid).collection("dailyMetrics").doc(localDate).set(updateData, { merge: true });
}

async function handleDeregistration(garminUserId: string) {
  const db = admin.firestore();
  // Da die integrations in einem Subdocument private liegen, können wir keine Collection Group Query über bestimmte Felder ohne Index machen,
  // oder wir speichern die garminUserId im integrationStatus (öffentlich/lesbar) und suchen darüber.
  
  const statusDocs = await db.collectionGroup("integrationStatus").where("garminUserId", "==", garminUserId).get();
  for (const statusDoc of statusDocs.docs) {
    // uid extrahieren
    const uid = statusDoc.ref.parent.parent?.id;
    if (uid) {
      // Tokens löschen
      await db.collection("users").doc(uid).collection("private").doc("integrations").update({
        "garmin": admin.firestore.FieldValue.delete()
      });
      // Status auf getrennt setzen
      await statusDoc.ref.update({
        state: "DISCONNECTED",
        garminUserId: admin.firestore.FieldValue.delete(),
        disconnectedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  }
}
