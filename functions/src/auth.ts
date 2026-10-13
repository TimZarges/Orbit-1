import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const setInitialRole = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const { role, profile, consents } = request.data;
  
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
      timezone: profile?.timezone || "UTC", // Fallback
    },
    settings: {
      units: "metric",
      language: "de",
      themeMode: "system",
      notifications: {
        chat: true,
        newPlannedWorkout: true,
        dailyReminder: false,
        newActivity: true,
        weeklySummary: true,
      }
    },
    consents: {
      healthData: consents?.healthData || null,
      privacyVersion: consents?.privacyVersion || "v0",
    }
  }, { merge: true });

  await batch.commit();

  return { success: true };
});

export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  
  // Rekursives Löschen aller Daten & Subcollections (inkl. dailyMetrics, Art. 17 DSGVO)
  await db.recursiveDelete(userRef);

  // Firebase Auth Nutzer löschen
  await admin.auth().deleteUser(uid);

  return { success: true };
});

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

