/**
 * @file auth.ts
 * @description Authentifizierungs- und DSGVO-Cloud Functions für ORBIT (europe-west3).
 * Verwaltet initiale Rollenzuweisungen (Athlet/Coach), vollständige Kontolöschungen
 * gemäß Art. 17 DSGVO ("Recht auf Vergessenwerden") sowie Datenexporte nach Art. 20 DSGVO.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";
import {
  garminConsumerKey,
  garminConsumerSecret,
  getOAuthClient,
} from "./import/garmin/backfill";
import { claimCoachInvitesForAthlete } from "./coach";

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
  let normalizedEmail =
    typeof request.auth?.token.email === "string"
      ? request.auth.token.email.trim().toLowerCase()
      : "";
  if (!normalizedEmail) {
    try {
      const authRecord = await admin.auth().getUser(uid);
      normalizedEmail = (authRecord.email || "").trim().toLowerCase();
    } catch (_) {
      // Optional in isolierten Unit-Tests ohne Auth-Backend
    }
  }

  batch.set(userRef, {
    uid,
    ...(normalizedEmail ? { email: normalizedEmail } : {}),
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

  // Offene E-Mail-Einladungen von Coaches automatisch als PENDING-Anfrage übernehmen
  if (role === "ATHLETE" && normalizedEmail) {
    try {
      await claimCoachInvitesForAthlete(admin.firestore(), uid, normalizedEmail);
    } catch (_) {
      // Einladungs-Übernahme darf die Registrierung niemals blockieren
    }
  }

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
 * Führt bei bestehender Garmin-Connect-Verknüpfung die offizielle API-Deregistrierung
 * durch und bereinigt alle zugehörigen Token- und Index-Dokumente vor der Kontolöschung.
 * Externe API-Fehler werden protokolliert, blockieren aber niemals die DSGVO-Löschung.
 *
 * @param db - Firestore-Instanz.
 * @param uid - Firebase-UID des zu löschenden Nutzers.
 * @param consumerCreds - Optionaler Test-Override für Consumer Key/Secret.
 */
export async function deregisterGarminUserIfConnected(
  db: admin.firestore.Firestore,
  uid: string,
  consumerCreds?: { key?: string; secret?: string }
): Promise<{ attemptedApiDeregister: boolean; deletedGarminIds: string[] }> {
  const userRef = db.collection("users").doc(uid);
  const privateIntegrationsRef = userRef.collection("private").doc("integrations");
  const statusRef = userRef.collection("integrationStatus").doc("garmin");
  const legacyIntegrationRef = userRef.collection("integrations").doc("garmin");

  const [privateSnap, statusSnap, legacySnap] = await Promise.all([
    privateIntegrationsRef.get(),
    statusRef.get(),
    legacyIntegrationRef.get(),
  ]);

  const privateGarmin = privateSnap.data()?.garmin;
  const legacyData = legacySnap.data();
  const statusData = statusSnap.data();

  const oauthToken: string | undefined =
    privateGarmin?.oauthToken || legacyData?.oauthToken;
  const oauthTokenSecret: string | undefined =
    privateGarmin?.oauthTokenSecret || legacyData?.oauthTokenSecret;

  const garminIds = new Set<string>();
  for (const candidate of [
    privateGarmin?.garminUserId,
    statusData?.garminUserId,
    legacyData?.garminUserId,
  ]) {
    if (typeof candidate === "string" && candidate.trim().length > 0) {
      garminIds.add(candidate.trim());
    }
  }

  let attemptedApiDeregister = false;
  if (oauthToken && oauthTokenSecret) {
    attemptedApiDeregister = true;
    try {
      const key = consumerCreds?.key ?? garminConsumerKey.value();
      const secret = consumerCreds?.secret ?? garminConsumerSecret.value();
      if (key && secret) {
        const oauth = getOAuthClient(key, secret);
        const deregisterReq = {
          url: "https://apis.garmin.com/wellness-api/rest/user/registration",
          method: "DELETE",
        };
        const authHeader = oauth.toHeader(
          oauth.authorize(deregisterReq, {
            key: oauthToken,
            secret: oauthTokenSecret,
          })
        );
        await axios.delete(deregisterReq.url, {
          headers: authHeader,
          timeout: 5000,
        });
      }
    } catch (garminErr) {
      // Externer Garmin-Fehler darf das Recht auf Löschung (Art. 17 DSGVO) nie blockieren
      console.warn(
        `Garmin deregistration warning for uid ${uid}:`,
        garminErr
      );
    }
  }

  // Alle gefundenen garminUsers-Mappings sowie Token-/Integrations-Dokumente löschen
  const cleanupOps: Array<Promise<unknown>> = [
    deleteQueryInBatches(db.collection("garminUsers").where("uid", "==", uid)),
  ];
  for (const gId of garminIds) {
    cleanupOps.push(db.collection("garminUsers").doc(gId).delete());
  }
  if (legacySnap.exists) {
    cleanupOps.push(legacyIntegrationRef.delete());
  }
  if (statusSnap.exists) {
    cleanupOps.push(statusRef.delete());
  }
  if (privateSnap.exists) {
    cleanupOps.push(
      privateIntegrationsRef.update({
        garmin: admin.firestore.FieldValue.delete(),
      })
    );
  }
  await Promise.allSettled(cleanupOps);

  return {
    attemptedApiDeregister,
    deletedGarminIds: Array.from(garminIds),
  };
}

/**
 * Führt die vollständige und DSGVO-konforme Löschung des Nutzerkontos durch (Art. 17 DSGVO).
 * Bereinigt rückstandslos:
 * 1. Aktive Garmin-Connect-Verknüpfung (offizielle Garmin-Deregistrierung im `try/catch`,
 *    `garminUsers`, `users/{uid}/integrations/garmin`, `integrationStatus/garmin` & Tokens).
 * 2. Alle `coachLinks` (als Athlet und als Coach) inkl. `authorizedCoachIds` & `coachId`
 *    auf ehemals verbundenen Athletenprofilen sowie `coachDashboard`-Einträge.
 * 3. Alle Einladungscodes (`invites`) des Coaches.
 * 4. Top-Level-Collections (`activities`, `plannedWorkouts`, `chats`, `garminUsers`).
 * 5. Das Nutzerdokument `users/{uid}` inkl. aller Subcollections (`db.recursiveDelete`).
 * 6. Alle Cloud-Storage-Dateien unter `users/{uid}/` (`rawActivities/`, `fit/`, `streams/`, `avatars/`).
 * 7. Den Firebase-Authentication-Account (`admin.auth().deleteUser(uid)`).
 *
 * @throws {HttpsError} unauthenticated - Wenn die Anfrage nicht authentifiziert ist.
 */
export const deleteAccount = onCall(
  { secrets: [garminConsumerKey, garminConsumerSecret] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);

    // 0. Garmin Connect deregistrieren & Token-/Index-Dokumente bereinigen
    await deregisterGarminUserIfConnected(db, uid);

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

  // 2. Eigene Coach-Einladungen (invites & coachInvites) und Coach-Dashboard löschen
  await Promise.all([
    deleteQueryInBatches(db.collection("invites").where("coachId", "==", uid)),
    deleteQueryInBatches(db.collection("coachInvites").where("coachId", "==", uid)),
    deleteQueryInBatches(db.collection("coachInvites").where("athleteId", "==", uid)),
    db.recursiveDelete(db.collection("coachDashboard").doc(uid)),
  ]);

  // Etwaige Einladungscode-Verwendungen (`invites.usedBy`) bereinigen
  try {
    const redeemedInvites = await db
      .collection("invites")
      .where("usedBy", "array-contains", uid)
      .get();
    if (!redeemedInvites.empty) {
      const cleanBatch = db.batch();
      for (const invDoc of redeemedInvites.docs) {
        cleanBatch.update(invDoc.ref, {
          usedBy: admin.firestore.FieldValue.arrayRemove(uid),
        });
      }
      await cleanBatch.commit();
    }
  } catch (_) {
    // Optionale Bereinigung blockiert niemals die Kontolöschung
  }

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
  }
);

/**
 * Bereinigt beliebige Export-Objekte rekursiv für die maschinenlesbare Ausgabe
 * gemäß Art. 20 DSGVO: entfernt vertrauliche Server-/OAuth-Secrets (z. B. Garmin
 * `oauthTokenSecret` / `accessTokenSecret` / `refreshToken`) und wandelt
 * Firestore-Timestamps in standardisierte ISO-8601-Zeitstempel um.
 */
export function sanitizeExportValue(value: unknown): unknown {
  const blockedKeys = new Set([
    "oauthtoken",
    "oauthtokensecret",
    "accesstoken",
    "accesstokensecret",
    "refreshtoken",
    "tokensecret",
    "consumersecret",
    "garminsecrets",
    "passwordhash",
    "private",
  ]);

  if (value === null || value === undefined) {
    return value;
  }
  if (
    typeof (value as { toDate?: () => Date }).toDate === "function"
  ) {
    return (value as { toDate: () => Date }).toDate().toISOString();
  }
  if (Array.isArray(value)) {
    return value.map((item) => sanitizeExportValue(item));
  }
  if (typeof value === "object") {
    const cleanObj: Record<string, unknown> = {};
    for (const [key, entryVal] of Object.entries(value as Record<string, unknown>)) {
      if (blockedKeys.has(key.toLowerCase())) {
        continue;
      }
      cleanObj[key] = sanitizeExportValue(entryVal);
    }
    return cleanObj;
  }
  return value;
}

/**
 * Erstellt einen vollständigen maschinenlesbaren Datenexport des Nutzers
 * gemäß Art. 20 DSGVO ("Recht auf Datenübertragbarkeit").
 * Exportiert Profil, Aktivitäten, Coach-Verknüpfungen, Einwilligungen, tägliche
 * Metriken und Schwellenwerthistorie als JSON – garantiert ohne Server-/OAuth-Secrets.
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
  const [
    userDoc,
    dailyMetricsSnapshot,
    thresholdSnapshot,
    consentsSnapshot,
    activitiesSnapshot,
    athleteLinksSnapshot,
    coachLinksSnapshot,
  ] = await Promise.all([
    userRef.get(),
    userRef.collection("dailyMetrics").get(),
    userRef.collection("thresholdHistory").get(),
    userRef.collection("consents").get(),
    db.collection("activities").where("athleteId", "==", uid).limit(500).get(),
    db.collection("coachLinks").where("athleteId", "==", uid).get(),
    db.collection("coachLinks").where("coachId", "==", uid).get(),
  ]);

  // Health-Daten (dailyMetrics, Art. 20 DSGVO Datenübertragbarkeit)
  const dailyMetrics: Record<string, unknown> = {};
  dailyMetricsSnapshot.forEach((doc) => {
    dailyMetrics[doc.id] = sanitizeExportValue(doc.data());
  });

  // Schwellenwert-Historie
  const thresholdHistory: Record<string, unknown> = {};
  thresholdSnapshot.forEach((doc) => {
    thresholdHistory[doc.id] = sanitizeExportValue(doc.data());
  });

  // Einwilligungs-Protokoll (Art. 7 / Art. 9 DSGVO)
  const consents: Record<string, unknown> = {};
  consentsSnapshot.forEach((doc) => {
    consents[doc.id] = sanitizeExportValue(doc.data());
  });

  // Aktivitäten-Metadaten (inkl. Verweis auf herunterladbare .FIT-Dateien)
  const activities = activitiesSnapshot.docs.map((doc) =>
    sanitizeExportValue({
      id: doc.id,
      ...doc.data(),
    })
  );

  // Coach-Athleten-Verknüpfungen
  const coachLinks = [
    ...athleteLinksSnapshot.docs,
    ...coachLinksSnapshot.docs,
  ].map((doc) =>
    sanitizeExportValue({
      id: doc.id,
      ...doc.data(),
    })
  );

  return {
    exportedAt: new Date().toISOString(),
    userData: sanitizeExportValue(userDoc.data() || {}),
    activities,
    coachLinks,
    consents,
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


