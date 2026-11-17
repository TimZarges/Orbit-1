/**
 * @file auth.ts
 * @description Authentifizierungs- und DSGVO-Cloud Functions für ORBIT (europe-west3).
 * Verwaltet initiale Rollenzuweisungen (Athlet/Coach), vollständige Kontolöschungen
 * gemäß Art. 17 DSGVO ("Recht auf Vergessenwerden") sowie Datenexporte nach Art. 20 DSGVO.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Weist einem frisch registrierten Nutzer seine initiale Rolle (ATHLETE oder TRAINER) zu
 * und legt das initiale Nutzerdokument inklusive Profil, Einheiten, Benachrichtigungseinstellungen
 * und Schwellenwerthistorie in Firestore an.
 *
 * @throws {HttpsError} unauthenticated - Wenn der Nutzer nicht angemeldet ist.
 * @throws {HttpsError} invalid-argument - Bei ungültiger Rolle.
 * @throws {HttpsError} already-exists - Wenn bereits eine Rolle hinterlegt wurde.
 */
export const setInitialRole = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { role, profile, consents, thresholds, settings } = request.data;
  
  if (role !== "ATHLETE" && role !== "TRAINER") {
    throw new HttpsError("invalid-argument", "Invalid role specified.");
  }

  const userRef = admin.firestore().collection("users").doc(uid);
  const userDoc = await userRef.get();

  if (userDoc.exists) {
    const data = userDoc.data();
    if (data?.role) {
      throw new HttpsError("already-exists", "Role is already set.");
    }
  }

  const batch = admin.firestore().batch();
  
  // Set custom claims
  await admin.auth().setCustomUserClaims(uid, { role });

  const now = admin.firestore.FieldValue.serverTimestamp();

  batch.set(userRef, {
    uid,
    email: request.auth?.token.email,
    createdAt: now,
    role,
    trainerVerified: false,
    coachId: null,
    profile: {
      ...profile,
      timezone: profile?.timezone || "Europe/Berlin",
    },
    settings: {
      units: settings?.units === "imperial" ? "imperial" : "metric",
      language: settings?.language || "de",
      themeMode: "system",
      notifications: {
        chat: true,
        newPlannedWorkout: true,
        dailyReminder: false,
        newActivity: true,
        weeklySummary: true,
      },
    },
    consents: {
      healthData: consents?.healthData || null,
      privacyVersion: consents?.privacyVersion || "v1",
    },
  }, { merge: true });

  if (thresholds && typeof thresholds === "object" && !thresholds.autoEstimate) {
    const thresholdDocRef = userRef.collection("thresholdHistory").doc("initial");
    const todayIso = new Date().toISOString().split("T")[0];
    batch.set(thresholdDocRef, {
      effectiveFrom: todayIso,
      ...(typeof thresholds.restingHrBpm === "number" ? { restingHrBpm: thresholds.restingHrBpm } : {}),
      ...(typeof thresholds.maxHrBpm === "number" ? { maxHrBpm: thresholds.maxHrBpm } : {}),
      ...(typeof thresholds.ftpW === "number" ? { ftpW: thresholds.ftpW } : {}),
      ...(typeof thresholds.runThresholdPaceSecPerKm === "number"
        ? { runThresholdPaceSecPerKm: thresholds.runThresholdPaceSecPerKm }
        : {}),
      ...(typeof thresholds.swimCssSecPer100m === "number"
        ? { swimCssSecPer100m: thresholds.swimCssSecPer100m }
        : {}),
      source: "MANUAL",
      createdAt: now,
    });
  }

  await batch.commit();

  return { success: true };
});

/**
 * Hilfsfunktion: Löscht alle Dokumente einer Firestore-Query gebündelt in
 * Batches von maximal 400 Schreiboperationen (innerhalb des 500er-Limits).
 */
async function deleteQueryInBatches(query: admin.firestore.Query): Promise<number> {
  const snapshot = await query.get();
  if (snapshot.empty) return 0;

  const db = admin.firestore();
  const docs = snapshot.docs;
  const CHUNK_SIZE = 400;
  let deleted = 0;

  for (let i = 0; i < docs.length; i += CHUNK_SIZE) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + CHUNK_SIZE);
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += chunk.length;
  }
  return deleted;
}

/**
 * Führt die vollständige und DSGVO-konforme Löschung des Nutzerkontos durch (Art. 17 DSGVO).
 * Bereinigt rückstandslos:
 * 1. Alle `coachLinks` (als Athlet und als Coach) inkl. `authorizedCoachIds` & `coachId`
 *    auf ehemals verbundenen Athletenprofilen sowie `coachDashboard`-Einträge.
 * 2. Alle Einladungscodes (`invites`) des Coaches.
 * 3. Top-Level-Collections (`activities`, `plannedWorkouts`, `chats`, `garminUsers`).
 * 4. Das Nutzerdokument `users/{uid}` inkl. aller Subcollections (`db.recursiveDelete`).
 * 5. Alle Cloud-Storage-Dateien unter `users/{uid}/` (`rawActivities/`, `fit/`, `streams/`, `avatars/`).
 * 6. Den Firebase-Authentication-Account (`admin.auth().deleteUser(uid)`).
 *
 * @throws {HttpsError} unauthenticated - Wenn die Anfrage nicht authentifiziert ist.
 */
export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  // 1. Alle Coach-Athleten-Verknüpfungen bereinigen (Nutzer als Athlet oder Coach)
  const [athleteLinksSnap, coachLinksSnap] = await Promise.all([
    db.collection("coachLinks").where("athleteId", "==", uid).get(),
    db.collection("coachLinks").where("coachId", "==", uid).get(),
  ]);

  const linkCleanupBatch = db.batch();
  // Falls der Nutzer Athlet war, seinen Eintrag aus dem Dashboard der Coaches entfernen
  for (const linkDoc of athleteLinksSnap.docs) {
    const coachId = linkDoc.data()?.coachId;
    if (typeof coachId === "string" && coachId.length > 0) {
      linkCleanupBatch.delete(
        db.collection("coachDashboard").doc(coachId).collection("athletes").doc(uid)
      );
    }
    linkCleanupBatch.delete(linkDoc.ref);
  }

  // Falls der Nutzer Coach war, authorizedCoachIds & coachId bei seinen Athleten bereinigen
  for (const linkDoc of coachLinksSnap.docs) {
    const athleteId = linkDoc.data()?.athleteId;
    if (typeof athleteId === "string" && athleteId.length > 0) {
      const athleteRef = db.collection("users").doc(athleteId);
      const athleteSnap = await athleteRef.get();
      if (athleteSnap.exists) {
        const updatePayload: Record<string, any> = {
          authorizedCoachIds: admin.firestore.FieldValue.arrayRemove(uid),
        };
        if (athleteSnap.data()?.coachId === uid) {
          updatePayload.coachId = admin.firestore.FieldValue.delete();
        }
        linkCleanupBatch.update(athleteRef, updatePayload);
      }
    }
    linkCleanupBatch.delete(linkDoc.ref);
  }
  await linkCleanupBatch.commit();

  // 2. Eigene Coach-Einladungen und Coach-Dashboard löschen
  await deleteQueryInBatches(db.collection("invites").where("coachId", "==", uid));
  await db.recursiveDelete(db.collection("coachDashboard").doc(uid));

  // 3. Top-Level Aktivitäten, geplante Trainings, Chats & Garmin-Mappings bereinigen
  await Promise.all([
    deleteQueryInBatches(db.collection("activities").where("athleteId", "==", uid)),
    deleteQueryInBatches(db.collection("plannedWorkouts").where("athleteId", "==", uid)),
    deleteQueryInBatches(db.collection("plannedWorkouts").where("coachId", "==", uid)),
    deleteQueryInBatches(db.collection("garminUsers").where("uid", "==", uid)),
    deleteQueryInBatches(db.collection("betaFeedback").where("userId", "==", uid)),
  ]);

  const [chatsAsAthlete, chatsAsCoach] = await Promise.all([
    db.collection("chats").where("athleteId", "==", uid).get(),
    db.collection("chats").where("coachId", "==", uid).get(),
  ]);
  for (const chatDoc of [...chatsAsAthlete.docs, ...chatsAsCoach.docs]) {
    await db.recursiveDelete(chatDoc.ref);
  }

  // 4. Nutzerdokument inklusive aller Subcollections rekursiv löschen
  await db.recursiveDelete(userRef);

  // 5. Sämtliche Storage-Dateien unter users/{uid}/ rückstandslos löschen
  try {
    await admin.storage().bucket().deleteFiles({
      prefix: `users/${uid}/`,
      force: true,
    });
  } catch (storageErr) {
    // Protokollieren ohne die Auth-Löschung zu blockieren, falls Bucket-Ordner leer ist
    console.warn(`Storage cleanup warning for users/${uid}/:`, storageErr);
  }

  // 6. Abschließend den Firebase-Auth-Account löschen
  await admin.auth().deleteUser(uid);

  return { success: true };
});

/**
 * Erstellt einen vollständigen maschinenlesbaren Datenexport des Nutzers
 * gemäß Art. 20 DSGVO ("Recht auf Datenübertragbarkeit").
 * Exportiert Profil, tägliche Metriken und Schwellenwerthistorie als JSON.
 *
 * @throws {HttpsError} unauthenticated - Wenn die Anfrage nicht authentifiziert ist.
 */
export const exportAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();
  
  // Health-Daten (dailyMetrics, Art. 20 DSGVO Datenübertragbarkeit)
  const dailyMetricsSnapshot = await userRef.collection("dailyMetrics").get();
  const dailyMetrics: Record<string, any> = {};
  dailyMetricsSnapshot.forEach((doc) => {
    dailyMetrics[doc.id] = doc.data();
  });

  // Schwellenwert-Historie
  const thresholdSnapshot = await userRef.collection("thresholdHistory").get();
  const thresholdHistory: Record<string, any> = {};
  thresholdSnapshot.forEach((doc) => {
    thresholdHistory[doc.id] = doc.data();
  });

  return {
    userData: userDoc.data() || {},
    dailyMetrics,
    thresholdHistory,
  };
});

/**
 * Setzt den E-Mail-Verifizierungsstatus eines Beta-Nutzers über das Admin SDK
 * direkt auf `true`, damit Login und Onboarding ohne E-Mail-Loop funktionieren.
 *
 * @param uid - Die Firebase Auth UID des Testnutzers.
 */
export async function verifyBetaUserEmail(uid: string): Promise<void> {
  await admin.auth().updateUser(uid, {
    emailVerified: true,
  });
}


