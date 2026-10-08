import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

// Helper function to generate a random invite code
function generateInviteCode(): string {
  return crypto.randomBytes(4).toString("hex").toUpperCase();
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
    usedBy: []
  });

  return { code };
});

export const redeemInvite = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { code } = request.data;
  if (!code) {
    throw new HttpsError("invalid-argument", "Code is required.");
  }

  const db = admin.firestore();
  return db.runTransaction(async (transaction) => {
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

    // Update athlete user doc
    const userRef = db.collection("users").doc(uid);
    
    // Add to usedBy
    const newUsedBy = [...inviteData.usedBy, uid];
    transaction.update(inviteRef, { usedBy: newUsedBy });

    // Create coachLink
    transaction.set(linkRef, {
      athleteId: uid,
      coachId: coachId,
      status: "ACTIVE",
      permissions: {
        calendar: true,
        activities: true,
        health: false
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update user
    transaction.update(userRef, {
      coachId: coachId,
      "consents.coachSharing": {
        at: admin.firestore.FieldValue.serverTimestamp(),
        version: "v1"
      }
    });

    return { success: true, coachId };
  });
});

export const updatePermissions = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { coachId, permissions } = request.data;
  const linkId = `${uid}_${coachId}`;
  
  const db = admin.firestore();
  const linkRef = db.collection("coachLinks").doc(linkId);
  
  await linkRef.update({
    permissions,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Note: If permissions.activities is revoked, we'd need to set coachId to null on all activities.
  // This can be done via batch update, but is omitted for brevity in Phase 02 prototype.
  
  return { success: true };
});

export const revokeLink = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { linkId } = request.data;
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

  const batch = db.batch();
  batch.update(linkRef, {
    status: "REVOKED",
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Remove coachId from user
  const userRef = db.collection("users").doc(athleteId);
  batch.update(userRef, { coachId: null });

  // Again, would need to run query and batch update all activities/plannedWorkouts here.
  
  await batch.commit();

  return { success: true };
});
