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
  requestAthleteLinkByEmail,
  claimPendingCoachInvites,
  respondToCoachLinkRequest,
  downloadActivityFit,
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

  it("E-Mail-Einladung für bestehende UND noch nicht registrierte Athleten (coachInvites -> claimPendingCoachInvites -> DSGVO-Bestätigung)", async () => {
    const db = admin.firestore();
    const coachUid = "coach_email_1";
    const existingAthleteUid = "athlete_existing_1";
    const lateAthleteUid = "athlete_late_1";
    const existingEmail = "existing.athlete@orbit.training";
    const lateEmail = "late.athlete@orbit.training";

    await db.collection("users").doc(coachUid).set({
      uid: coachUid,
      role: "TRAINER",
      email: "coach.email@orbit.training",
      profile: { firstName: "Tim", lastName: "Coach" },
    });
    await db.collection("users").doc(existingAthleteUid).set({
      uid: existingAthleteUid,
      role: "ATHLETE",
      email: existingEmail,
      profile: { firstName: "Anna", lastName: "Sprint" },
    });

    // 1. E-Mail-Anfrage an bereits registrierten Athleten -> direktes PENDING coachLink + inviteCode
    const existingRes = await (requestAthleteLinkByEmail as any).run({
      auth: { uid: coachUid },
      data: { email: existingEmail },
    });
    expect(existingRes.success).toBe(true);
    expect(existingRes.deliveryMode).toBe("IN_APP_PENDING");
    expect(existingRes.accountExists).toBe(true);
    expect(existingRes.inviteCode).toHaveLength(6);

    const existingLinkSnap = await db.collection("coachLinks").doc(`${existingAthleteUid}_${coachUid}`).get();
    expect(existingLinkSnap.exists).toBe(true);
    expect(existingLinkSnap.data()?.status).toBe("PENDING");

    // 2. E-Mail-Einladung an noch nicht registrierte Adresse -> persistentes coachInvites-Dokument + inviteCode + mail-Queue
    const lateRes = await (requestAthleteLinkByEmail as any).run({
      auth: { uid: coachUid },
      data: { email: lateEmail },
    });
    expect(lateRes.success).toBe(true);
    expect(lateRes.deliveryMode).toBe("INVITE_CREATED_NO_ACCOUNT");
    expect(lateRes.accountExists).toBe(false);
    expect(lateRes.inviteCode).toHaveLength(6);

    const inviteSnap = await db.collection("coachInvites").doc(lateRes.inviteId).get();
    expect(inviteSnap.exists).toBe(true);
    expect(inviteSnap.data()?.status).toBe("PENDING_REGISTRATION");
    expect(inviteSnap.data()?.athleteEmail).toBe(lateEmail);

    // 3. Spätere Registrierung des Athleten mit dieser E-Mail-Adresse -> claimPendingCoachInvites
    await db.collection("users").doc(lateAthleteUid).set({
      uid: lateAthleteUid,
      role: "ATHLETE",
      email: lateEmail,
      profile: { firstName: "Lukas", lastName: "Tri" },
    });

    const claimRes = await (claimPendingCoachInvites as any).run({
      auth: { uid: lateAthleteUid, token: { email: lateEmail } },
      data: {},
    });
    expect(claimRes.claimedCount).toBe(1);
    expect(claimRes.claimedCoachIds).toContain(coachUid);

    const claimedLinkSnap = await db.collection("coachLinks").doc(`${lateAthleteUid}_${coachUid}`).get();
    expect(claimedLinkSnap.exists).toBe(true);
    expect(claimedLinkSnap.data()?.status).toBe("PENDING");

    // 4. Athlet bestätigt mit expliziter DSGVO-Einwilligung -> Link wird ACTIVE
    const acceptRes = await (respondToCoachLinkRequest as any).run({
      auth: { uid: lateAthleteUid },
      data: {
        linkId: `${lateAthleteUid}_${coachUid}`,
        accept: true,
        gdprConsent: true,
      },
    });
    expect(acceptRes.success).toBe(true);
    expect(acceptRes.status).toBe("ACTIVE");
  });

  it("Re-Invite & Re-Link nach Trennung/Ablehnung + Wiederverwendung von Code & Altlasten-Bereinigung", async () => {
    const coachUid = "coach_relink";
    const athleteUid = "athlete_relink";
    const athleteEmail = "relink.athlet@verein.de";
    const db = admin.firestore();

    await db.collection("users").doc(coachUid).set({
      uid: coachUid,
      role: "TRAINER",
      email: "coach.relink@verein.de",
      profile: { firstName: "Max", lastName: "Coach" },
    });
    await db.collection("users").doc(athleteUid).set({
      uid: athleteUid,
      role: "ATHLETE",
      email: athleteEmail,
      profile: { firstName: "Elena", lastName: "ReLink" },
    });

    const linkId = `${athleteUid}_${coachUid}`;

    // 1. Erstmalige Verbindung über 6-stelligen Einladungscode
    const inviteRes = await (createInvite as any).run({
      auth: { uid: coachUid },
      data: {},
    });
    const code = inviteRes.code as string;

    await (redeemInvite as any).run({
      auth: { uid: athleteUid },
      data: { code },
    });

    // 2. Verbindung trennen (`revokeLink`) -> Status REVOKED + usedBy bereinigt
    await (revokeLink as any).run({
      auth: { uid: athleteUid },
      data: { linkId },
    });

    const afterRevokeLink = await db.collection("coachLinks").doc(linkId).get();
    expect(afterRevokeLink.data()?.status).toBe("REVOKED");

    const afterRevokeInvite = await db.collection("invites").doc(code).get();
    expect(afterRevokeInvite.data()?.usedBy).not.toContain(athleteUid);

    // 3. Coach lädt denselben Athleten erneut per E-Mail ein -> Reaktivierung als sauberes PENDING
    const reinviteRes = await (requestAthleteLinkByEmail as any).run({
      auth: { uid: coachUid },
      data: { email: athleteEmail },
    });
    expect(reinviteRes.success).toBe(true);
    expect(reinviteRes.reactivated).toBe(true);
    expect(reinviteRes.status).toBe("PENDING");

    const pendingSnap = await db.collection("coachLinks").doc(linkId).get();
    expect(pendingSnap.data()?.status).toBe("PENDING");
    expect(pendingSnap.data()?.permissions?.activities).toBe(false);
    expect(pendingSnap.data()?.permissions?.calendar).toBe(false);

    // 4. Athlet lehnt einmal ab (`accept: false`) -> REVOKED; Coach sendet nochmals -> PENDING
    await (respondToCoachLinkRequest as any).run({
      auth: { uid: athleteUid },
      data: { linkId, accept: false, gdprConsent: false },
    });
    expect((await db.collection("coachLinks").doc(linkId).get()).data()?.status).toBe("REVOKED");

    const secondReinvite = await (requestAthleteLinkByEmail as any).run({
      auth: { uid: coachUid },
      data: { email: athleteEmail },
    });
    expect(secondReinvite.reactivated).toBe(true);
    expect(secondReinvite.status).toBe("PENDING");

    // 5. Athlet bestätigt diesmal mit DSGVO-Opt-in -> ACTIVE
    const acceptAgain = await (respondToCoachLinkRequest as any).run({
      auth: { uid: athleteUid },
      data: { linkId, accept: true, gdprConsent: true },
    });
    expect(acceptAgain.status).toBe("ACTIVE");

    // 6. Aktive Verbindung blockiert doppelte E-Mail-Einladung sauber mit already-exists
    await expect(
      (requestAthleteLinkByEmail as any).run({
        auth: { uid: coachUid },
        data: { email: athleteEmail },
      })
    ).rejects.toThrow(/already connected/i);

    // 7. Erneut trennen und denselben 6-stelligen Code erfolgreich wieder einlösen
    await (revokeLink as any).run({
      auth: { uid: coachUid },
      data: { linkId },
    });
    const reRedeem = await (redeemInvite as any).run({
      auth: { uid: athleteUid },
      data: { code },
    });
    expect(reRedeem.success).toBe(true);
    expect((await db.collection("coachLinks").doc(linkId).get()).data()?.status).toBe("ACTIVE");
  });

  it("Coach trennt aktive Verbindung (revokeLink durch Coach) -> revokedAt, revokedBy='COACH', Entzug authorizedCoachIds & .fit-Sperre", async () => {
    const coachUid = "coach_disconnect";
    const athleteUid = "athlete_disconnect";
    const athleteEmail = "disconnect.athlet@verein.de";
    const db = admin.firestore();
    const linkId = `${athleteUid}_${coachUid}`;

    await db.collection("users").doc(coachUid).set({
      uid: coachUid,
      role: "TRAINER",
      email: "coach.disconnect@verein.de",
      profile: { firstName: "Tim", lastName: "Trainer" },
    });
    await db.collection("users").doc(athleteUid).set({
      uid: athleteUid,
      role: "ATHLETE",
      email: athleteEmail,
      profile: { firstName: "Sara", lastName: "Run" },
    });
    await db.collection("activities").doc("act_fit_sec").set({
      athleteId: athleteUid,
      coachId: null,
      title: "Dauerlauf",
      sport: "RUN",
    });

    // 1. E-Mail-Einladung + DSGVO-Bestätigung durch Athleten
    await (requestAthleteLinkByEmail as any).run({
      auth: { uid: coachUid },
      data: { email: athleteEmail },
    });
    await (respondToCoachLinkRequest as any).run({
      auth: { uid: athleteUid },
      data: { linkId, accept: true, gdprConsent: true },
    });

    const beforeDisconnect = await db.collection("users").doc(athleteUid).get();
    expect(beforeDisconnect.data()?.authorizedCoachIds).toContain(coachUid);

    const coachClientDb = testEnv.authenticatedContext(coachUid).firestore();
    await assertSucceeds(coachClientDb.collection("activities").doc("act_fit_sec").get());

    // 2. Verbundener Coach trennt die Beziehung direkt per athleteId/linkId
    const disconnectRes = await (revokeLink as any).run({
      auth: { uid: coachUid },
      data: { athleteId: athleteUid },
    });
    expect(disconnectRes.success).toBe(true);

    // 3. Verifikation: REVOKED, revokedBy === 'COACH', revokedAt vorhanden, authorizedCoachIds bereinigt
    const revokedLinkSnap = await db.collection("coachLinks").doc(linkId).get();
    expect(revokedLinkSnap.data()?.status).toBe("REVOKED");
    expect(revokedLinkSnap.data()?.revokedBy).toBe("COACH");
    expect(revokedLinkSnap.data()?.revokedAt).toBeDefined();

    const afterDisconnectAthlete = await db.collection("users").doc(athleteUid).get();
    expect(afterDisconnectAthlete.data()?.authorizedCoachIds || []).not.toContain(coachUid);
    expect(afterDisconnectAthlete.data()?.coachId).toBeUndefined();

    // 4. Sofortiger Verlust von Firestore-Aktivitätensicht & .fit-Download-Berechtigung
    await assertFails(coachClientDb.collection("activities").doc("act_fit_sec").get());
    await expect(
      (downloadActivityFit as any).run({
        auth: { uid: coachUid },
        data: { activityId: "act_fit_sec" },
      })
    ).rejects.toThrow(/No active coach permission/i);
  });
});
