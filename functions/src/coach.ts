import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

export * from "./coach/dashboard";
export * from "./seeds/seed_coach_athletes";

// Erzeugt einen 6-stelligen alphanumerischen Einladungscode
function generateInviteCode(): string {
  return crypto.randomBytes(3).toString("hex").toUpperCase();
}

/**
 * Löscht das Feld `coachId` aus allen Dokumenten einer Query in Chunks von maximal 400 Operationen.
 */
async function clearCoachIdFromQuery(query: admin.firestore.Query): Promise<number> {
  const snapshot = await query.get();
  if (snapshot.empty) return 0;

  const db = admin.firestore();
  let totalUpdated = 0;
  const docs = snapshot.docs;
  const CHUNK_SIZE = 400;

  for (let i = 0; i < docs.length; i += CHUNK_SIZE) {
    const chunk = docs.slice(i, i + CHUNK_SIZE);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.update(doc.ref, {
        coachId: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    totalUpdated += chunk.length;
  }
  return totalUpdated;
}

/**
 * Setzt das Feld `coachId` auf allen Dokumenten einer Query in Chunks von maximal 400 Operationen.
 */
async function setCoachIdOnQuery(query: admin.firestore.Query, coachId: string): Promise<number> {
  const snapshot = await query.get();
  if (snapshot.empty) return 0;

  const db = admin.firestore();
  let totalUpdated = 0;
  const docs = snapshot.docs;
  const CHUNK_SIZE = 400;

  for (let i = 0; i < docs.length; i += CHUNK_SIZE) {
    const chunk = docs.slice(i, i + CHUNK_SIZE);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.update(doc.ref, {
        coachId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    totalUpdated += chunk.length;
  }
  return totalUpdated;
}

export const createInvite = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const userDoc = await admin.firestore().collection("users").doc(uid).get();
  if (userDoc.data()?.role !== "TRAINER") {
    throw new HttpsError("permission-denied", "Only trainers can create invites.");
  }

  const code = generateInviteCode();
  const db = admin.firestore();

  await db.collection("invites").doc(code).set({
    coachId: uid,
    expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)), // 7 Days
    maxUses: 10,
    usedBy: [],
  });

  return { code };
});

export const redeemInvite = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const rawCode = request.data?.code;
  const code = typeof rawCode === "string" ? rawCode.trim().toUpperCase() : "";
  if (!code) {
    throw new HttpsError("invalid-argument", "Code is required.");
  }

  const db = admin.firestore();
  const txResult = await db.runTransaction(async (transaction) => {
    const inviteRef = db.collection("invites").doc(code);
    const inviteDoc = await transaction.get(inviteRef);

    if (!inviteDoc.exists) {
      throw new HttpsError("not-found", "Invite not found.");
    }

    const inviteData = inviteDoc.data()!;
    if (inviteData.expiresAt.toDate() < new Date()) {
      throw new HttpsError("failed-precondition", "Invite expired.");
    }

    if (inviteData.usedBy.length >= inviteData.maxUses) {
      throw new HttpsError("failed-precondition", "Invite usage limit reached.");
    }

    if (inviteData.usedBy.includes(uid)) {
      throw new HttpsError("already-exists", "You already used this invite.");
    }

    const coachId = inviteData.coachId;
    const linkId = `${uid}_${coachId}`;
    const linkRef = db.collection("coachLinks").doc(linkId);
    const userRef = db.collection("users").doc(uid);

    const initialPermissions = {
      calendar: true,
      activities: true,
      health: false,
      bodyWeightAndNotes: false,
    };

    // Add to usedBy
    const newUsedBy = [...inviteData.usedBy, uid];
    transaction.update(inviteRef, { usedBy: newUsedBy });

    // Create coachLink
    transaction.set(linkRef, {
      athleteId: uid,
      coachId: coachId,
      status: "ACTIVE",
      permissions: initialPermissions,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user
    transaction.set(userRef, {
      coachId: coachId,
      consents: {
        coachSharing: {
          at: admin.firestore.FieldValue.serverTimestamp(),
          version: "v1",
          coachId,
          permissions: initialPermissions,
        },
      },
    }, { merge: true });

    // Audit-Log-Eintrag (Art. 9 DSGVO)
    const auditRef = userRef.collection("consents").doc();
    transaction.set(auditRef, {
      type: "COACH_LINK_REDEEMED",
      coachId,
      permissions: initialPermissions,
      version: "v1",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, coachId };
  });

  // Bestehende Aktivitäten und Trainingspläne für den neuen Trainer freischalten
  await setCoachIdOnQuery(
    db.collection("activities").where("athleteId", "==", uid),
    txResult.coachId
  );
  await setCoachIdOnQuery(
    db.collection("plannedWorkouts").where("athleteId", "==", uid),
    txResult.coachId
  );

  return txResult;
});

export const updatePermissions = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { coachId, permissions } = request.data || {};
  if (!coachId || !permissions) {
    throw new HttpsError("invalid-argument", "coachId and permissions are required.");
  }
  const linkId = `${uid}_${coachId}`;

  const db = admin.firestore();
  const linkRef = db.collection("coachLinks").doc(linkId);
  const linkDoc = await linkRef.get();
  if (!linkDoc.exists) {
    throw new HttpsError("not-found", "Link not found.");
  }
  const linkData = linkDoc.data()!;
  if (linkData.athleteId !== uid) {
    throw new HttpsError("permission-denied", "Only the athlete can update sharing permissions.");
  }

  const normalizedPermissions = {
    activities: Boolean(permissions.activities),
    calendar: Boolean(permissions.calendar),
    health: Boolean(permissions.health),
    bodyWeightAndNotes: Boolean(permissions.bodyWeightAndNotes ?? linkData.permissions?.bodyWeightAndNotes ?? false),
  };

  await linkRef.update({
    permissions: normalizedPermissions,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Art. 9 DSGVO Audit-Log-Eintrag mit Zeitstempel schreiben
  const userRef = db.collection("users").doc(uid);
  await userRef.collection("consents").add({
    type: "COACH_PERMISSIONS_UPDATED",
    coachId,
    previousPermissions: linkData.permissions || {},
    permissions: normalizedPermissions,
    version: "v1",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await userRef.set({
    consents: {
      coachSharing: {
        at: admin.firestore.FieldValue.serverTimestamp(),
        version: "v1",
        coachId,
        permissions: normalizedPermissions,
      },
    },
  }, { merge: true });

  // DSGVO-Synchronisation für Aktivitäten
  if (normalizedPermissions.activities === false) {
    const activitiesQuery = db.collection("activities")
      .where("athleteId", "==", uid)
      .where("coachId", "==", coachId);
    await clearCoachIdFromQuery(activitiesQuery);
  } else {
    const activitiesQuery = db.collection("activities")
      .where("athleteId", "==", uid);
    await setCoachIdOnQuery(activitiesQuery, coachId);
  }

  // DSGVO-Synchronisation für Kalender / Trainingspläne
  if (normalizedPermissions.calendar === false) {
    const workoutsQuery = db.collection("plannedWorkouts")
      .where("athleteId", "==", uid)
      .where("coachId", "==", coachId);
    await clearCoachIdFromQuery(workoutsQuery);
  } else {
    const workoutsQuery = db.collection("plannedWorkouts")
      .where("athleteId", "==", uid);
    await setCoachIdOnQuery(workoutsQuery, coachId);
  }

  return { success: true, permissions: normalizedPermissions };
});

export const revokeLink = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { linkId } = request.data || {};
  if (!linkId) {
    throw new HttpsError("invalid-argument", "linkId is required.");
  }
  const db = admin.firestore();

  const linkRef = db.collection("coachLinks").doc(linkId);
  const linkDoc = await linkRef.get();

  if (!linkDoc.exists) {
    throw new HttpsError("not-found", "Link not found.");
  }

  const linkData = linkDoc.data()!;
  if (linkData.athleteId !== uid && linkData.coachId !== uid) {
    throw new HttpsError("permission-denied", "You are not part of this link.");
  }

  const athleteId = linkData.athleteId;
  const coachId = linkData.coachId;

  // 1. Link-Status auf REVOKED setzen
  await linkRef.update({
    status: "REVOKED",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 2. coachId vom Athleten-Dokument entfernen & Art. 9 Consent-Widerruf dokumentieren
  const userRef = db.collection("users").doc(athleteId);
  await userRef.update({
    coachId: admin.firestore.FieldValue.delete(),
    "consents.coachSharingRevokedAt": admin.firestore.FieldValue.serverTimestamp(),
  });

  await userRef.collection("consents").add({
    type: "COACH_LINK_REVOKED",
    coachId,
    revokedBy: uid,
    version: "v1",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 3. Denormalisiertes coachId-Feld von allen Aktivitäten des Athleten entfernen (DSGVO Art. 9)
  const activitiesQuery = db.collection("activities")
    .where("athleteId", "==", athleteId)
    .where("coachId", "==", coachId);
  await clearCoachIdFromQuery(activitiesQuery);

  // 4. Denormalisiertes coachId-Feld von allen Trainingsplänen des Athleten entfernen
  const workoutsQuery = db.collection("plannedWorkouts")
    .where("athleteId", "==", athleteId)
    .where("coachId", "==", coachId);
  await clearCoachIdFromQuery(workoutsQuery);

  // 5. Chat-Status auf REVOKED setzen (Archiviert: lesbar, aber keine neuen Nachrichten)
  const chatIds = [`${athleteId}_${coachId}`, `${coachId}_${athleteId}`];
  for (const cId of chatIds) {
    const chatRef = db.collection("chats").doc(cId);
    const chatDoc = await chatRef.get();
    if (chatDoc.exists) {
      await chatRef.update({
        status: "REVOKED",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  // 6. Aus dem Coach Dashboard entfernen
  const dashboardRef = db.collection("coachDashboard").doc(coachId).collection("athletes").doc(athleteId);
  const dashboardDoc = await dashboardRef.get();
  if (dashboardDoc.exists) {
    await dashboardRef.delete();
  }

  return { success: true };
});

