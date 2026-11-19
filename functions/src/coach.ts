/**
 * @file coach.ts
 * @description Cloud Functions 2nd Gen für die sichere Coach-Athleten-Verbindung
 * in `europe-west3` (Einladungscodes, E-Mail-Einladungen, DSGVO-Annahme/Widerruf,
 * Storage-CORS und `.FIT`-Originaldatei-Download).
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

export * from "./coach/dashboard";
export * from "./seeds/seed_coach_athletes";

/**
 * Erzeugt einen 6-stelligen alphanumerischen Einladungscode.
 */
function generateInviteCode(): string {
  return crypto.randomBytes(3).toString("hex").toUpperCase();
}

/**
 * Bildet eine deterministische Einladungs-ID aus Coach-UID und normalisierter E-Mail.
 */
function buildEmailInviteId(coachUid: string, normalizedEmail: string): string {
  const emailHash = crypto
    .createHash("sha256")
    .update(normalizedEmail)
    .digest("hex")
    .slice(0, 16);
  return `${coachUid}_${emailHash}`;
}

/**
 * Ermittelt den Anzeigenamen aus einem Firestore-Nutzerdokument.
 */
function resolveDisplayName(
  userData: Record<string, any> | undefined,
  fallback: string
): string {
  const profile = userData?.profile;
  const displayName =
    typeof profile?.displayName === "string" ? profile.displayName.trim() : "";
  if (displayName) return displayName;
  const combined = [profile?.firstName, profile?.lastName]
    .filter((v) => typeof v === "string" && v.trim().length > 0)
    .join(" ")
    .trim();
  if (combined) return combined;
  if (typeof userData?.email === "string" && userData.email.trim().length > 0) {
    return userData.email.trim();
  }
  return fallback;
}

/**
 * Sucht für einen Coach einen gültigen, nicht abgelaufenen 6-stelligen Einladungscode
 * oder legt automatisch einen neuen Code in `invites/{code}` an.
 */
async function ensureCoachInviteCode(
  db: admin.firestore.Firestore,
  coachUid: string
): Promise<string> {
  try {
    const existingSnap = await db
      .collection("invites")
      .where("coachId", "==", coachUid)
      .limit(10)
      .get();
    const nowMs = Date.now();
    for (const doc of existingSnap.docs) {
      const data = doc.data();
      const usedBy = Array.isArray(data?.usedBy) ? data.usedBy : [];
      const maxUses = typeof data?.maxUses === "number" ? data.maxUses : 10;
      const expiresAtMs =
        typeof data?.expiresAt?.toMillis === "function"
          ? data.expiresAt.toMillis()
          : nowMs + 1000;
      if (expiresAtMs > nowMs && usedBy.length < maxUses) {
        return doc.id;
      }
    }
  } catch (_) {
    // Fallback auf Neuanlage bei fehlender Abfrageunterstützung in Tests
  }

  const code = generateInviteCode();
  await db.collection("invites").doc(code).set({
    coachId: coachUid,
    expiresAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    ),
    maxUses: 10,
    usedBy: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return code;
}

/**
 * Stellt eine strukturierte Einladungs-E-Mail in die Firestore-Collection `mail` ein
 * (kompatibel mit der Firebase Trigger-Email-Erweiterung). Ein externer Mail-Versand
 * findet nur statt, wenn im Projekt eine Mail-Extension/SMTP konfiguriert ist.
 */
async function queueCoachInviteMail(
  db: admin.firestore.Firestore,
  params: {
    toEmail: string;
    coachId: string;
    coachName: string;
    inviteCode: string;
    accountExists: boolean;
  }
): Promise<boolean> {
  try {
    const actionUrl = params.accountExists
      ? "https://orbit-app-mvp.web.app/app/#/login"
      : "https://orbit-app-mvp.web.app/app/#/register";
    const subject = `ORBIT Coaching-Einladung von ${params.coachName}`;
    const text = [
      `Hallo,`,
      ``,
      `${params.coachName} lädt dich ein, deine Trainingsdaten DSGVO-konform über ORBIT zu teilen.`,
      `Dein 6-stelliger Coach-Einladungscode lautet: ${params.inviteCode}`,
      ``,
      params.accountExists
        ? `Öffne dein ORBIT Profil unter ${actionUrl} und bestätige die eingehende Anfrage (oder gib den Code ein).`
        : `Registriere dich kostenlos unter ${actionUrl} mit dieser E-Mail-Adresse (${params.toEmail}) und gib den Coach-Code ${params.inviteCode} ein.`,
      ``,
      `Ohne deine ausdrückliche DSGVO-Einwilligung hat niemand Zugriff auf deine Daten.`,
    ].join("\n");

    await db.collection("mail").add({
      to: [params.toEmail],
      coachId: params.coachId,
      inviteCode: params.inviteCode,
      type: "COACH_INVITE",
      message: {
        subject,
        text,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  } catch (_) {
    return false;
  }
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

    // Benutzerprofil aktualisieren und geschütztes Array für Storage-Rules-Zugriff pflegen
    transaction.set(userRef, {
      coachId: coachId,
      authorizedCoachIds: admin.firestore.FieldValue.arrayUnion(coachId),
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

  // Profil-Metadaten auf dem Verknüpfungsdokument nachpflegen (für sofortige UI-Anzeige)
  try {
    const [athleteSnap, coachSnap] = await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("users").doc(txResult.coachId).get(),
    ]);
    const aData = athleteSnap.data() || {};
    const cData = coachSnap.data() || {};
    const athleteName =
      aData?.profile?.displayName ||
      [aData?.profile?.firstName, aData?.profile?.lastName].filter(Boolean).join(" ").trim() ||
      aData?.email ||
      "Athlet";
    const coachName =
      cData?.profile?.displayName ||
      [cData?.profile?.firstName, cData?.profile?.lastName].filter(Boolean).join(" ").trim() ||
      cData?.email ||
      "Coach";
    const rawSports = aData?.profile?.sports || aData?.profile?.sportTypes || [];
    await db.collection("coachLinks").doc(`${uid}_${txResult.coachId}`).set({
      athleteName,
      athleteEmail: aData?.email ?? "",
      coachName,
      coachEmail: cData?.email ?? "",
      athleteSports: Array.isArray(rawSports) ? rawSports : [],
    }, { merge: true });
  } catch (_) {
    // Metadaten-Anreicherung optional (z. B. in Unit-Tests mit Mock-Firestore)
  }

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
    authorizedCoachIds: normalizedPermissions.activities
      ? admin.firestore.FieldValue.arrayUnion(coachId)
      : admin.firestore.FieldValue.arrayRemove(coachId),
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

  // 2. coachId und authorizedCoachIds vom Athleten-Dokument entfernen & Art. 9 Consent-Widerruf dokumentieren
  const userRef = db.collection("users").doc(athleteId);
  await userRef.update({
    coachId: admin.firestore.FieldValue.delete(),
    authorizedCoachIds: admin.firestore.FieldValue.arrayRemove(coachId),
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

/**
 * Sendet eine Verbindungsanfrage eines Coaches an einen Athleten per E-Mail-Adresse.
 *
 * Ablauf:
 * 1. Erzeugt oder reaktiviert für den Coach einen 6-stelligen Einladungscode (`invites/{code}`).
 * 2. Sucht einen bestehenden Athleten-Account in `users` (case-insensitiv per Fallback
 *    über `admin.auth().getUserByEmail`) und legt dort eine `PENDING`-Verbindungsanfrage
 *    (`coachLinks/{athleteId}_{coachUid}`) plus In-App-Hinweis an.
 * 3. Existiert noch kein ORBIT-Account für die E-Mail, wird die Einladung persistent in
 *    `coachInvites/{inviteId}` (`status: 'PENDING_REGISTRATION'`) sowie in der `mail`-Queue
 *    abgelegt, sodass sie beim späteren Registrieren/Einloggen automatisch erscheint.
 *
 * @param request - Enthält `email` des gewünschten Athleten.
 * @returns Strukturiertes Statusobjekt inkl. `deliveryMode`, `accountExists` und `inviteCode`.
 */
export const requestAthleteLinkByEmail = onCall(async (request) => {
  const coachUid = request.auth?.uid;
  if (!coachUid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const db = admin.firestore();
  const coachDoc = await db.collection("users").doc(coachUid).get();
  const coachData = coachDoc.data();
  if (coachData?.role !== "TRAINER") {
    throw new HttpsError("permission-denied", "Only trainers can send athlete link requests.");
  }

  const rawEmail = request.data?.email;
  const normalizedEmail = typeof rawEmail === "string" ? rawEmail.trim().toLowerCase() : "";
  if (!normalizedEmail || !normalizedEmail.includes("@")) {
    throw new HttpsError("invalid-argument", "A valid athlete email is required.");
  }

  const coachName = resolveDisplayName(coachData, "Coach");
  const coachEmail = typeof coachData?.email === "string" ? coachData.email : "";
  const inviteCode = await ensureCoachInviteCode(db, coachUid);
  const inviteId = buildEmailInviteId(coachUid, normalizedEmail);

  // 1. Athleten-Account über Firestore `users` oder Firebase Auth (case-insensitiv) ermitteln
  let athleteId = "";
  let athleteData: Record<string, any> = {};

  const athleteSnap = await db.collection("users")
    .where("email", "==", normalizedEmail)
    .limit(1)
    .get();

  if (!athleteSnap.empty) {
    const athleteDoc = athleteSnap.docs[0];
    athleteId = athleteDoc.id;
    athleteData = athleteDoc.data() || {};
  } else {
    // Fallback über Firebase Auth (fängt Groß-/Kleinschreibung oder fehlendes users.email auf)
    try {
      const authRecord = await admin.auth().getUserByEmail(normalizedEmail);
      athleteId = authRecord.uid;
      const docSnap = await db.collection("users").doc(athleteId).get();
      if (docSnap.exists) {
        athleteData = docSnap.data() || {};
        if (!athleteData.email) {
          await db.collection("users").doc(athleteId).set(
            { uid: athleteId, email: normalizedEmail },
            { merge: true }
          );
          athleteData.email = normalizedEmail;
        }
      }
    } catch (_) {
      // Kein Konto in Firebase Auth -> Einladung für spätere Registrierung anlegen
    }
  }

  // 2. Fall A: Konto existiert -> direkte PENDING-Verbindungsanfrage in coachLinks anlegen
  if (athleteId) {
    if (athleteId === coachUid) {
      throw new HttpsError("invalid-argument", "Cannot link with yourself.");
    }
    if (athleteData.role === "TRAINER") {
      throw new HttpsError("failed-precondition", "Target user is not an athlete.");
    }

    const linkId = `${athleteId}_${coachUid}`;
    const linkRef = db.collection("coachLinks").doc(linkId);
    const existingLink = await linkRef.get();
    if (existingLink.exists && existingLink.data()?.status === "ACTIVE") {
      throw new HttpsError("already-exists", "Athlete is already connected with this coach.");
    }

    const athleteName = resolveDisplayName(
      { ...athleteData, email: athleteData.email ?? normalizedEmail },
      normalizedEmail
    );

    // Verbindungsanfrage im Status PENDING speichern (keine Datenfreigabe ohne DSGVO-Opt-in)
    await linkRef.set({
      athleteId,
      coachId: coachUid,
      status: "PENDING",
      requestedBy: coachUid,
      inviteCode,
      coachName,
      coachEmail,
      athleteName,
      athleteEmail: athleteData?.email ?? normalizedEmail,
      permissions: {
        activities: false,
        calendar: false,
        health: false,
        bodyWeightAndNotes: false,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await db.collection("coachInvites").doc(inviteId).set({
      inviteId,
      coachId: coachUid,
      coachName,
      coachEmail,
      athleteId,
      athleteEmail: normalizedEmail,
      inviteCode,
      status: "LINKED_PENDING",
      mailQueued: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Optionale In-App-Benachrichtigung + Mail-Queue-Eintrag anlegen
    try {
      await db.collection("users").doc(athleteId).collection("notifications").add({
        title: "Neue Coach-Verbindungsanfrage",
        body: `${coachName} möchte sich mit deinem ORBIT-Konto verbinden. Bitte im Profil bestätigen.`,
        type: "SYSTEM",
        route: "/profile",
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Benachrichtigung optional
    }

    const mailQueued = await queueCoachInviteMail(db, {
      toEmail: normalizedEmail,
      coachId: coachUid,
      coachName,
      inviteCode,
      accountExists: true,
    });

    return {
      success: true,
      deliveryMode: "IN_APP_PENDING",
      accountExists: true,
      mailQueued,
      mailProviderConfigured: false,
      linkId,
      inviteId,
      athleteId,
      athleteName,
      athleteEmail: normalizedEmail,
      inviteCode,
      status: "PENDING",
    };
  }

  // 3. Fall B: Noch kein ORBIT-Konto -> offene Einladung in `coachInvites` & `mail`-Queue speichern
  await db.collection("coachInvites").doc(inviteId).set({
    inviteId,
    coachId: coachUid,
    coachName,
    coachEmail,
    athleteEmail: normalizedEmail,
    inviteCode,
    status: "PENDING_REGISTRATION",
    mailQueued: true,
    expiresAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)
    ),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  const mailQueued = await queueCoachInviteMail(db, {
    toEmail: normalizedEmail,
    coachId: coachUid,
    coachName,
    inviteCode,
    accountExists: false,
  });

  return {
    success: true,
    deliveryMode: "INVITE_CREATED_NO_ACCOUNT",
    accountExists: false,
    mailQueued,
    mailProviderConfigured: false,
    inviteId,
    athleteId: "",
    athleteName: normalizedEmail,
    athleteEmail: normalizedEmail,
    inviteCode,
    status: "PENDING_REGISTRATION",
  };
});

/**
 * Überführt alle offenen E-Mail-Einladungen (`coachInvites` mit Status
 * `PENDING_REGISTRATION`) für den angegebenen Athleten in `PENDING`-`coachLinks`,
 * sodass sie sofort im „Profil Einfach“ mit DSGVO-Bestätigung erscheinen.
 */
export async function claimCoachInvitesForAthlete(
  db: admin.firestore.Firestore,
  uid: string,
  rawEmail?: string
): Promise<{ claimedCount: number; claimedCoachIds: string[] }> {
  let normalizedEmail = typeof rawEmail === "string" ? rawEmail.trim().toLowerCase() : "";

  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.data() || {};
  if (!normalizedEmail && typeof userData.email === "string") {
    normalizedEmail = userData.email.trim().toLowerCase();
  }
  if (!normalizedEmail) {
    try {
      const authUser = await admin.auth().getUser(uid);
      normalizedEmail = (authUser.email || "").trim().toLowerCase();
    } catch (_) {
      // Ohne E-Mail ist kein Abgleich möglich
    }
  }
  if (!normalizedEmail || userData.role === "TRAINER") {
    return { claimedCount: 0, claimedCoachIds: [] };
  }

  const invitesSnap = await db
    .collection("coachInvites")
    .where("athleteEmail", "==", normalizedEmail)
    .where("status", "==", "PENDING_REGISTRATION")
    .get();

  if (invitesSnap.empty) {
    return { claimedCount: 0, claimedCoachIds: [] };
  }

  const athleteName = resolveDisplayName(
    { ...userData, email: normalizedEmail },
    normalizedEmail
  );
  const nowMs = Date.now();
  const claimedCoachIds: string[] = [];

  for (const inviteDoc of invitesSnap.docs) {
    const inv = inviteDoc.data();
    const coachId = typeof inv.coachId === "string" ? inv.coachId : "";
    if (!coachId || coachId === uid) continue;

    const expiresAtMs =
      typeof inv.expiresAt?.toMillis === "function"
        ? inv.expiresAt.toMillis()
        : nowMs + 1000;
    if (expiresAtMs <= nowMs) continue;

    const linkId = `${uid}_${coachId}`;
    const linkRef = db.collection("coachLinks").doc(linkId);
    const existingLink = await linkRef.get();
    if (!existingLink.exists || existingLink.data()?.status !== "ACTIVE") {
      await linkRef.set({
        athleteId: uid,
        coachId,
        status: "PENDING",
        requestedBy: coachId,
        inviteCode: inv.inviteCode || "",
        coachName: inv.coachName || "Coach",
        coachEmail: inv.coachEmail || "",
        athleteName,
        athleteEmail: normalizedEmail,
        permissions: {
          activities: false,
          calendar: false,
          health: false,
          bodyWeightAndNotes: false,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    await inviteDoc.ref.set({
      status: "CLAIMED_PENDING",
      athleteId: uid,
      claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    claimedCoachIds.push(coachId);
  }

  return { claimedCount: claimedCoachIds.length, claimedCoachIds };
}

/**
 * Ermöglicht dem eingeloggten Athleten den expliziten Abruf und das Überführen
 * offener E-Mail-Einladungen (`coachInvites` -> `PENDING` `coachLinks`).
 */
export const claimPendingCoachInvites = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }
  const tokenEmail =
    typeof request.auth?.token?.email === "string"
      ? request.auth.token.email
      : undefined;
  return claimCoachInvitesForAthlete(admin.firestore(), uid, tokenEmail);
});

/**
 * Zieht eine offene E-Mail-Einladung (`coachInvites`) des Coaches wieder zurück.
 */
export const revokeCoachInvite = onCall(async (request) => {
  const coachUid = request.auth?.uid;
  if (!coachUid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const rawInviteId = request.data?.inviteId;
  const inviteId = typeof rawInviteId === "string" ? rawInviteId.trim() : "";
  if (!inviteId) {
    throw new HttpsError("invalid-argument", "inviteId is required.");
  }

  const inviteRef = admin.firestore().collection("coachInvites").doc(inviteId);
  const inviteSnap = await inviteRef.get();
  if (!inviteSnap.exists) {
    throw new HttpsError("not-found", "Invite not found.");
  }
  if (inviteSnap.data()?.coachId !== coachUid) {
    throw new HttpsError("permission-denied", "Only the inviting coach can revoke this invite.");
  }

  await inviteRef.update({
    status: "REVOKED",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

/**
 * Beantwortet eine eingehende Coach-Verbindungsanfrage durch den Athleten.
 * Erfordert beim Akzeptieren zwingend die ausdrückliche DSGVO-Datenfreigabe (`gdprConsent === true`).
 *
 * @param request - Enthält `linkId`, `accept` (boolean) und bei Annahme `gdprConsent` (boolean).
 * @returns Objekt mit `success` und neuem `status`.
 */
export const respondToCoachLinkRequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { linkId, accept, gdprConsent } = request.data || {};
  if (typeof linkId !== "string" || !linkId.trim() || typeof accept !== "boolean") {
    throw new HttpsError("invalid-argument", "linkId and accept are required.");
  }

  const db = admin.firestore();
  const linkRef = db.collection("coachLinks").doc(linkId.trim());
  const linkDoc = await linkRef.get();
  if (!linkDoc.exists) {
    throw new HttpsError("not-found", "Link request not found.");
  }

  const linkData = linkDoc.data()!;
  if (linkData.athleteId !== uid) {
    throw new HttpsError("permission-denied", "Only the athlete can respond to this request.");
  }

  const coachId = linkData.coachId as string;
  if (!accept) {
    await linkRef.update({
      status: "REVOKED",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, status: "REVOKED" };
  }

  if (gdprConsent !== true) {
    throw new HttpsError("invalid-argument", "Explicit GDPR consent is required to accept.");
  }

  const initialPermissions = {
    calendar: true,
    activities: true,
    health: false,
    bodyWeightAndNotes: false,
  };

  await linkRef.update({
    status: "ACTIVE",
    permissions: initialPermissions,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // DSGVO-Einwilligung, Coach-Zuordnung und Storage-Zugriffsarray am Athletenprofil dokumentieren
  const userRef = db.collection("users").doc(uid);
  await userRef.set({
    coachId,
    authorizedCoachIds: admin.firestore.FieldValue.arrayUnion(coachId),
    consents: {
      coachSharing: {
        at: admin.firestore.FieldValue.serverTimestamp(),
        version: "v1",
        coachId,
        permissions: initialPermissions,
      },
    },
  }, { merge: true });

  await userRef.collection("consents").add({
    type: "COACH_LINK_ACCEPTED",
    coachId,
    permissions: initialPermissions,
    version: "v1",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Bestehende Aktivitäten und Trainingspläne für den neuen Coach freischalten
  await setCoachIdOnQuery(
    db.collection("activities").where("athleteId", "==", uid),
    coachId
  );
  await setCoachIdOnQuery(
    db.collection("plannedWorkouts").where("athleteId", "==", uid),
    coachId
  );

  return { success: true, status: "ACTIVE", coachId };
});

/**
 * Konfiguriert die CORS-Policy (GET, HEAD, PUT, POST, OPTIONS) auf dem
 * ORBIT Firebase Cloud Storage Bucket (`orbit-app-mvp.firebasestorage.app`),
 * sodass Flutter Web (Safari, Chrome) `.FIT`-Dateien ohne CORS-Blockade
 * hoch- und herunterladen kann.
 *
 * @param request - Erfordert einen authentifizierten Aufrufer mit Rolle `TRAINER` oder Admin.
 * @returns Statusobjekt mit dem konfigurierten Bucket-Namen.
 */
export const ensureStorageCors = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const db = admin.firestore();
  const userSnap = await db.collection("users").doc(uid).get();
  const userData = userSnap.data();
  if (userData?.role !== "TRAINER" && userData?.isAdmin !== true) {
    throw new HttpsError("permission-denied", "Only trainers or admins can sync storage CORS.");
  }

  // Feste, DSGVO- und Web-kompatible CORS-Policy gemäß cors.json anwenden
  const bucket = admin.storage().bucket("orbit-app-mvp.firebasestorage.app");
  await bucket.setCorsConfiguration([
    {
      origin: ["*"],
      method: ["GET", "HEAD", "PUT", "POST", "OPTIONS"],
      responseHeader: [
        "Content-Type",
        "Authorization",
        "Content-Length",
        "User-Agent",
        "x-goog-resumable",
        "X-Firebase-Storage-Version",
        "X-Firebase-Storage-XSRF",
      ],
      maxAgeSeconds: 3600,
    },
  ]);

  return { success: true, bucket: bucket.name };
});

/**
 * Lädt die originale Trainingsdatei (`.fit` / `.fit.gz` / `.tcx` / `.gpx`) einer Aktivität
 * sicher über das Admin SDK für den Athleten selbst oder einen aktiv per DSGVO
 * autorisierten Coach herunter. Umgeht Cross-Service-IAM- oder CORS-Einschränkungen im Browser.
 *
 * @param request - Enthält `activityId` der gewünschten Aktivität.
 * @returns Objekt mit `found` (boolean), `base64` (Dateibytes), `storagePath` und `extension`.
 */
export const downloadActivityFit = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const rawActivityId = request.data?.activityId;
  const activityId = typeof rawActivityId === "string" ? rawActivityId.trim() : "";
  if (!activityId) {
    throw new HttpsError("invalid-argument", "activityId is required.");
  }

  const db = admin.firestore();
  const actSnap = await db.collection("activities").doc(activityId).get();
  if (!actSnap.exists) {
    throw new HttpsError("not-found", "Activity not found.");
  }

  const actData = actSnap.data()!;
  const athleteId = typeof actData.athleteId === "string" ? actData.athleteId : "";
  if (!athleteId) {
    throw new HttpsError("failed-precondition", "Activity has no athleteId.");
  }

  // Strenge Autorisierungsprüfung: Entweder Athlet selbst oder aktiv freigegebener Coach
  if (callerUid !== athleteId) {
    const linkSnap = await db.collection("coachLinks").doc(`${athleteId}_${callerUid}`).get();
    const linkData = linkSnap.data();
    const isAuthorizedCoach =
      linkSnap.exists &&
      linkData?.status === "ACTIVE" &&
      linkData?.permissions?.activities === true;
    if (!isAuthorizedCoach) {
      throw new HttpsError("permission-denied", "No active coach permission for this athlete.");
    }
  }

  // Kandidaten-Pfade in Storage priorisiert prüfen (.fit / .fit.gz vor evtl. rawFilePath)
  const rawFilePath = typeof actData.rawFilePath === "string" ? actData.rawFilePath.trim() : "";
  const candidates: string[] = [];
  if (rawFilePath && /\.(fit|tcx|gpx)(\.gz)?$/i.test(rawFilePath)) {
    candidates.push(rawFilePath);
  }
  const canonicalPaths = [
    `users/${athleteId}/rawActivities/${activityId}.fit`,
    `users/${athleteId}/rawActivities/${activityId}.fit.gz`,
    `users/${athleteId}/fit/${activityId}.fit`,
    `users/${athleteId}/fit/${activityId}.fit.gz`,
  ];
  for (const candidate of canonicalPaths) {
    if (!candidates.includes(candidate)) {
      candidates.push(candidate);
    }
  }

  const bucket = admin.storage().bucket();
  for (const path of candidates) {
    try {
      const file = bucket.file(path);
      const [exists] = await file.exists();
      if (!exists) continue;
      const [buffer] = await file.download();
      if (buffer && buffer.length > 0 && buffer.length <= 25 * 1024 * 1024) {
        return {
          found: true,
          storagePath: path,
          base64: buffer.toString("base64"),
        };
      }
    } catch (_) {
      // Nächsten Kandidaten-Pfad prüfen
    }
  }

  return { found: false };
});

