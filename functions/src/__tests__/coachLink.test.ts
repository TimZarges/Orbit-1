import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import {
  createInvite,
  redeemInvite,
  updatePermissions,
  revokeLink,
} from "../coach";

// Sicherstellen, dass firebase-admin mit dem Emulator verbunden ist
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8081";
const PROJECT_ID = "orbit-rules-test";

if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT_ID });
}

describe("Phase 18.3 Trainer-Athleten-Kopplung E2E Flow (Invite -> Redeem -> Art. 9 Toggle -> Revoke)", () => {
  let testEnv: RulesTestEnvironment;

  beforeAll(async () => {
    const rulesPath = path.resolve(__dirname, "../../../firestore.rules");
    const rules = fs.readFileSync(rulesPath, "utf8");

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules,
        host: "127.0.0.1",
        port: 8081,
      },
    });
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it("durchläuft den kompletten Flow: Code generieren -> einlösen -> Consent-Toggles + Audit-Log -> Coach sieht Daten -> Trennen -> PERMISSION_DENIED", async () => {
    const coachUid = "coach_bob";
    const athleteUid = "athlete_alice";

    // 0. Basis-Dokumente über Admin SDK im Emulator anlegen
    const db = admin.firestore();
    await db.collection("users").doc(coachUid).set({
      uid: coachUid,
      role: "TRAINER",
      trainerVerified: true,
    });
    await db.collection("users").doc(athleteUid).set({
      uid: athleteUid,
      role: "ATHLETE",
      coachId: null,
    });
    await db.collection("activities").doc("act_1").set({
      athleteId: athleteUid,
      coachId: null,
      title: "Intervallfahrt",
      sport: "BIKE",
    });
    await db.collection("users").doc(athleteUid).collection("dailyMetrics").doc("2026-10-16").set({
      restingHrBpm: 50,
      hrvMs: 72,
      sleepSeconds: 28800,
    });

    const coachClientDb = testEnv.authenticatedContext(coachUid).firestore();

    // Vor Kopplung: Coach bekommt PERMISSION_DENIED
    await assertFails(coachClientDb.collection("activities").doc("act_1").get());
    await assertFails(
      coachClientDb.collection("users").doc(athleteUid).collection("dailyMetrics").doc("2026-10-16").get()
    );

    // 1. Coach generiert 6-stelligen Einladungscode via createInvite
    const inviteRes = await (createInvite as any).run({
      auth: { uid: coachUid },
      data: {},
    });
    expect(inviteRes.code).toBeDefined();
    expect(inviteRes.code).toHaveLength(6);

    // 2. Athlet löst den Code ein via redeemInvite
    const redeemRes = await (redeemInvite as any).run({
      auth: { uid: athleteUid },
      data: { code: inviteRes.code },
    });
    expect(redeemRes.success).toBe(true);
    expect(redeemRes.coachId).toBe(coachUid);

    // Nach Einlösen: Standardfreigabe activities=true, health=false
    await assertSucceeds(coachClientDb.collection("activities").doc("act_1").get());
    await assertFails(
      coachClientDb.collection("users").doc(athleteUid).collection("dailyMetrics").doc("2026-10-16").get()
    );

    // 3. Athlet schaltet Art. 9 DSGVO Gesundheits-Consent und Körpergewicht/Notizen EIN
    const permRes = await (updatePermissions as any).run({
      auth: { uid: athleteUid },
      data: {
        coachId: coachUid,
        permissions: {
          activities: true,
          calendar: true,
          health: true,
          bodyWeightAndNotes: true,
        },
      },
    });
    expect(permRes.success).toBe(true);

    // Prüfe, dass Audit-Log-Eintrag mit Zeitstempel in users/{uid}/consents angelegt wurde
    const auditSnap = await db.collection("users").doc(athleteUid).collection("consents").get();
    expect(auditSnap.size).toBeGreaterThanOrEqual(2); // REDEEMED + UPDATED

    // Coach darf jetzt auch die Gesundheitsdaten (dailyMetrics) lesen!
    await assertSucceeds(
      coachClientDb.collection("users").doc(athleteUid).collection("dailyMetrics").doc("2026-10-16").get()
    );

    // 4. Athlet trennt die Verbindung via revokeLink
    const linkId = `${athleteUid}_${coachUid}`;
    const revokeRes = await (revokeLink as any).run({
      auth: { uid: athleteUid },
      data: { linkId },
    });
    expect(revokeRes.success).toBe(true);

    // 5. Sofort nach Trennung: Coach bekommt PERMISSION_DENIED für Aktivitäten UND Gesundheitsdaten
    await assertFails(coachClientDb.collection("activities").doc("act_1").get());
    await assertFails(
      coachClientDb.collection("users").doc(athleteUid).collection("dailyMetrics").doc("2026-10-16").get()
    );
  });
});
