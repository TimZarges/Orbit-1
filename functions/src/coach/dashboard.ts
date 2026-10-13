import * as admin from "firebase-admin";
import { onDocumentWritten, onDocumentCreated } from "firebase-functions/v2/firestore";

/**
 * Schnittstelle für ein aggregiertes Athleten-Dokument im Trainer-Dashboard.
 * Pfad: `coachDashboard/{coachId}/athletes/{athleteId}`
 */
export interface CoachDashboardAthlete {
  athleteId: string;
  coachId: string;
  name: string;
  avatarUrl: string | null;
  sport: string;
  formStatus: "wellLoaded" | "optimal" | "caution" | "fresh" | "building";
  ctl: number;
  atl: number;
  tsb: number;
  compliance7d: number;
  actualLoad7d: number;
  plannedLoad7d: number;
  unreadMessagesCount: number;
  pendingProposalsCount: number;
  latestActivity: {
    date: string;
    title: string;
    sport: string;
    load: number;
    distanceM?: number;
  } | null;
  raceGoal: {
    title: string;
    date: string;
    distance?: string;
    daysRemaining: number;
  } | null;
  alert: "NO_ACTIVITY_7D" | "LOAD_SPIKE" | null;
  updatedAt: admin.firestore.FieldValue;
}

/**
 * Berechnet den FormStatus anhand von CTL und TSB.
 */
function determineFormStatus(ctl: number, tsb: number): "wellLoaded" | "optimal" | "caution" | "fresh" | "building" {
  if (ctl < 15) return "building";
  if (tsb < -25) return "caution";
  if (tsb >= -25 && tsb <= -5) return "wellLoaded";
  if (tsb > -5 && tsb <= 15) return "optimal";
  return "fresh";
}

/**
 * Berechnet und synchronisiert ein einzelnes Athleten-Dashboard-Dokument für einen Coach.
 */
export async function syncCoachDashboardAthlete(coachId: string, athleteId: string): Promise<void> {
  const db = admin.firestore();

  // 1. Prüfe, ob die Verknüpfung aktiv ist
  const linkDoc = await db.collection("coachLinks").doc(`${athleteId}_${coachId}`).get();
  if (!linkDoc.exists || linkDoc.data()?.status !== "ACTIVE") {
    // Wenn nicht aktiv, entferne aus dem Dashboard
    await db.collection("coachDashboard").doc(coachId).collection("athletes").doc(athleteId).delete();
    return;
  }

  // 2. Athleten-Profil laden
  const userDoc = await db.collection("users").doc(athleteId).get();
  const userData = userDoc.data() || {};
  const profile = userData.profile || {};
  const athleteName = profile.name || userData.email || "Athlet";
  const avatarUrl = profile.avatarUrl || null;
  const primarySport = profile.primarySport || "TRIATHLON";

  // RaceGoal
  let raceGoalObj: CoachDashboardAthlete["raceGoal"] = null;
  if (profile.raceGoal && profile.raceGoal.date) {
    const targetDate = new Date(profile.raceGoal.date);
    const diffDays = Math.ceil((targetDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    raceGoalObj = {
      title: profile.raceGoal.title || "Wettkampf",
      date: profile.raceGoal.date,
      distance: profile.raceGoal.distance,
      daysRemaining: diffDays,
    };
  }

  // 3. Neuestes Aggregat laden (für CTL, ATL, TSB)
  const today = new Date();
  const todayStr = today.toISOString().split("T")[0];
  const aggSnap = await db
    .collection("users")
    .doc(athleteId)
    .collection("aggregates")
    .orderBy(admin.firestore.FieldPath.documentId(), "desc")
    .limit(1)
    .get();

  let ctl = 0;
  let atl = 0;
  let tsb = 0;
  if (!aggSnap.empty) {
    const aggData = aggSnap.docs[0].data();
    ctl = aggData.ctl || 0;
    atl = aggData.atl || 0;
    tsb = aggData.tsb || 0;
  }
  const formStatus = determineFormStatus(ctl, tsb);

  // 4. 7-Tage-Historie für Soll-Ist-Compliance
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const sevenDaysAgoStr = sevenDaysAgo.toISOString().split("T")[0];

  const [planSnap, actSnap] = await Promise.all([
    db
      .collection("plannedWorkouts")
      .where("athleteId", "==", athleteId)
      .where("localDate", ">=", sevenDaysAgoStr)
      .where("localDate", "<=", todayStr)
      .get(),
    db
      .collection("activities")
      .where("athleteId", "==", athleteId)
      .where("localDate", ">=", sevenDaysAgoStr)
      .where("localDate", "<=", todayStr)
      .get(),
  ]);

  let plannedLoad7d = 0;
  planSnap.forEach((doc) => {
    plannedLoad7d += doc.data().plannedLoad || 0;
  });

  let actualLoad7d = 0;
  actSnap.forEach((doc) => {
    actualLoad7d += doc.data().load || 0;
  });

  const compliance7d = plannedLoad7d > 0
    ? Math.min(100, Math.round((actualLoad7d / plannedLoad7d) * 100))
    : 100;

  // 5. Letzte Aktivität
  const latestActSnap = await db
    .collection("activities")
    .where("athleteId", "==", athleteId)
    .orderBy("startTimeUtc", "desc")
    .limit(1)
    .get();

  let latestActivity: CoachDashboardAthlete["latestActivity"] = null;
  if (!latestActSnap.empty) {
    const actData = latestActSnap.docs[0].data();
    latestActivity = {
      date: actData.localDate || actData.startTimeUtc?.toDate()?.toISOString()?.split("T")[0] || "",
      title: actData.title || "Aktivität",
      sport: actData.sport || "BIKE",
      load: actData.load || 0,
      distanceM: actData.distanceM,
    };
  }

  // 6. Offene Schwellenwert-Vorschläge
  const propSnap = await db
    .collection("users")
    .doc(athleteId)
    .collection("thresholdProposals")
    .where("status", "==", "PENDING")
    .get();
  const pendingProposalsCount = propSnap.docs.length;

  // 7. Ungelesene Chat-Nachrichten
  let unreadMessagesCount = 0;
  const chatSnap = await db.collection("chats").doc(`${athleteId}_${coachId}`).get();
  if (chatSnap.exists) {
    const chatData = chatSnap.data() || {};
    unreadMessagesCount = chatData.unread?.[coachId] || 0;
  }

  // 8. Alerts
  let alert: CoachDashboardAthlete["alert"] = null;
  if (actualLoad7d === 0 && (!latestActivity || new Date(latestActivity.date).getTime() < sevenDaysAgo.getTime())) {
    alert = "NO_ACTIVITY_7D";
  } else if (ctl > 0 && actualLoad7d > ctl * 10) {
    alert = "LOAD_SPIKE";
  }

  // 9. Speichern im Coach-Dashboard
  const dashboardDoc: CoachDashboardAthlete = {
    athleteId,
    coachId,
    name: athleteName,
    avatarUrl,
    sport: primarySport,
    formStatus,
    ctl: Math.round(ctl),
    atl: Math.round(atl),
    tsb: Math.round(tsb),
    compliance7d,
    actualLoad7d: Math.round(actualLoad7d),
    plannedLoad7d: Math.round(plannedLoad7d),
    unreadMessagesCount,
    pendingProposalsCount,
    latestActivity,
    raceGoal: raceGoalObj,
    alert,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db
    .collection("coachDashboard")
    .doc(coachId)
    .collection("athletes")
    .doc(athleteId)
    .set(dashboardDoc, { merge: true });
}

/**
 * Cloud Function Trigger: Aktualisiert oder löscht das Dashboard-Dokument bei Änderungen an coachLinks.
 */
export const onCoachLinkChanged = onDocumentWritten("coachLinks/{linkId}", async (event) => {
  const afterData = event.data?.after?.data();
  const beforeData = event.data?.before?.data();

  const athleteId = afterData?.athleteId || beforeData?.athleteId;
  const coachId = afterData?.coachId || beforeData?.coachId;

  if (!athleteId || !coachId) return;

  if (!event.data?.after?.exists || afterData?.status === "REVOKED") {
    // Verknüpfung beendet -> Dokument aus dem Dashboard entfernen
    await admin
      .firestore()
      .collection("coachDashboard")
      .doc(coachId)
      .collection("athletes")
      .doc(athleteId)
      .delete();
  } else if (afterData?.status === "ACTIVE") {
    await syncCoachDashboardAthlete(coachId, athleteId);
  }
});

/**
 * Trigger bei neuer Aktivität: Aktualisiert das Coach-Dashboard des zugeordneten Trainers.
 */
export const onActivityCreatedForCoachDashboard = onDocumentCreated("activities/{activityId}", async (event) => {
  const actData = event.data?.data();
  if (!actData) return;

  const athleteId = actData.athleteId;
  const coachId = actData.coachId;

  if (athleteId && coachId) {
    await syncCoachDashboardAthlete(coachId, athleteId);
  }
});
