import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";

export interface QuietHoursConfig {
  start?: string; // z. B. "22:00"
  end?: string;   // z. B. "07:00"
  timezone?: string; // Standard: "Europe/Berlin"
  enabled?: boolean;
}

/**
 * Prüft, ob der aktuelle Zeitpunkt innerhalb der konfigurierten Ruhezeiten (Quiet Hours) liegt.
 * Standardmäßig 22:00 Uhr bis 07:00 Uhr (Europe/Berlin).
 */
export function isQuietTime(
  config?: QuietHoursConfig,
  currentDate = new Date()
): boolean {
  if (!config || config.enabled === false) {
    return false;
  }

  const startStr = config?.start || "22:00";
  const endStr = config?.end || "07:00";
  const timezone = config?.timezone || "Europe/Berlin";

  try {
    // Aktuelle Uhrzeit in der Ziel-Zeitzone ermitteln
    const formatter = new Intl.DateTimeFormat("en-GB", {
      timeZone: timezone,
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
    const parts = formatter.formatToParts(currentDate);
    const hour = parseInt(parts.find((p) => p.type === "hour")?.value || "0", 10);
    const minute = parseInt(parts.find((p) => p.type === "minute")?.value || "0", 10);
    const currentMinutes = hour * 60 + minute;

    const [startH, startM] = startStr.split(":").map((v) => parseInt(v, 10));
    const [endH, endM] = endStr.split(":").map((v) => parseInt(v, 10));
    const startMinutes = startH * 60 + startM;
    const endMinutes = endH * 60 + endM;

    if (startMinutes > endMinutes) {
      // Über Mitternacht (z. B. 22:00 bis 07:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // Innerhalb eines Kalendertags (z. B. 13:00 bis 15:00)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  } catch (_) {
    return false;
  }
}

/**
 * Sendet eine datenschutzkonforme Push-Benachrichtigung an einen Athleten oder Trainer.
 * Beachtet:
 * 1. Nutzer-Opt-in je Kategorie (`settings.notifications[category]`)
 * 2. Ruhezeiten (`isQuietTime`)
 * 3. ORBIT Branding: Icon `ic_stat_orbit`, Akzentfarbe `#001F47`
 * 4. Keine sensiblen Gesundheitsdaten (Art. 9 DSGVO) im sichtbaren Push-Text
 */
export async function sendSystemNotification({
  recipientId,
  title,
  body,
  category,
  dataPayload = {},
  bypassQuietTime = false,
}: {
  recipientId: string;
  title: string;
  body: string;
  category: "workout" | "diagnostics" | "summary" | "chat" | "threshold";
  dataPayload?: Record<string, string>;
  bypassQuietTime?: boolean;
}): Promise<{ sent: boolean; reason?: string; tokenCount?: number }> {
  const db = admin.firestore();

  const userDoc = await db.collection("users").doc(recipientId).get();
  if (!userDoc.exists) {
    return { sent: false, reason: "USER_NOT_FOUND" };
  }
  const userData = userDoc.data()!;

  // 1. Kategorie-Opt-in prüfen
  const notifications = userData.settings?.notifications ?? {};
  if (notifications[category] === false) {
    return { sent: false, reason: "OPT_OUT_CATEGORY" };
  }

  // 2. Ruhezeiten prüfen
  const quietHours = userData.settings?.quietHours as QuietHoursConfig | undefined;
  if (!bypassQuietTime && isQuietTime(quietHours)) {
    return { sent: false, reason: "QUIET_HOURS_ACTIVE" };
  }

  // 3. Geräte-Tokens laden
  const devicesSnap = await db
    .collection("users")
    .doc(recipientId)
    .collection("devices")
    .get();

  if (devicesSnap.empty) {
    return { sent: false, reason: "NO_REGISTERED_DEVICES" };
  }

  const tokens: string[] = [];
  devicesSnap.forEach((d) => {
    const t = d.data().fcmToken as string;
    if (t && typeof t === "string" && !tokens.includes(t)) {
      tokens.push(t);
    }
  });

  if (tokens.length === 0) {
    return { sent: false, reason: "NO_VALID_TOKENS" };
  }

  // 4. Multicast Payload mit ORBIT Statusleisten-Icon & Navy-Farbe
  const messagePayload: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title,
      body,
    },
    data: {
      ...dataPayload,
      category,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "normal",
      notification: {
        channelId: "orbit_notifications",
        icon: "ic_stat_orbit",
        color: "#001F47",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(messagePayload);
    return { sent: true, tokenCount: response.successCount };
  } catch (error: any) {
    return { sent: false, reason: error?.message || "MESSAGING_ERROR" };
  }
}

/**
 * Push bei abgeschlossener Aktivitäts-Analyse.
 */
export async function sendActivityAnalyzedPush({
  recipientId,
  activityId,
  sport,
  tss,
  bestWatt,
  bypassQuietTime,
}: {
  recipientId: string;
  activityId: string;
  sport: string;
  tss: number;
  bestWatt?: number;
  bypassQuietTime?: boolean;
}): Promise<void> {
  const sportLabel = sport === "BIKE" ? "Radtraining" : sport === "RUN" ? "Lauftraining" : "Training";
  const bestText = bestWatt ? ` Neue 5-Min-Bestleistung: ${bestWatt} W!` : "";
  const title = `Dein ${sportLabel} ist analysiert`;
  const body = `Einheit (${Math.round(tss)} TSS) verarbeitet.${bestText} Tippe hier für das Analyse-Cockpit.`;

  await sendSystemNotification({
    recipientId,
    title,
    body,
    category: "workout",
    bypassQuietTime,
    dataPayload: {
      type: "ACTIVITY",
      activityId,
      route: `/activities/${activityId}`,
    },
  });
}

/**
 * Push bei neuem Workout oder Plan-Update durch den Trainer.
 */
export async function sendWorkoutUpdatePush({
  recipientId,
  workoutId,
  title,
  date,
  coachName,
  bypassQuietTime,
}: {
  recipientId: string;
  workoutId: string;
  title: string;
  date: string;
  coachName?: string;
  bypassQuietTime?: boolean;
}): Promise<void> {
  const coachLabel = coachName ? `Trainer ${coachName}` : "Dein Trainer";
  const pushTitle = "Trainingsplan aktualisiert";
  const body = `${coachLabel} hat deine Einheit „${title}“ für ${date} geplant.`;

  await sendSystemNotification({
    recipientId,
    title: pushTitle,
    body,
    category: "workout",
    bypassQuietTime,
    dataPayload: {
      type: "WORKOUT",
      workoutId,
      route: "/calendar",
    },
  });
}

/**
 * Push bei erkanntem Schwellenwert-Anstieg (z. B. neue FTP oder Critical Power).
 */
export async function sendThresholdSuggestionPush({
  recipientId,
  oldFtp,
  newFtp,
  bypassQuietTime,
}: {
  recipientId: string;
  oldFtp: number;
  newFtp: number;
  bypassQuietTime?: boolean;
}): Promise<void> {
  const diff = newFtp - oldFtp;
  const title = "Neuer FTP-Vorschlag erkannt";
  const body = `Aus deiner MMP-Kurve: ${newFtp} W (+${diff} W). Jetzt in deinem Profil übernehmen?`;

  await sendSystemNotification({
    recipientId,
    title,
    body,
    category: "threshold",
    bypassQuietTime,
    dataPayload: {
      type: "THRESHOLD",
      newFtp: newFtp.toString(),
      route: "/thresholds",
    },
  });
}

/**
 * Scheduled Cloud Function: Morgendliches Recovery- & Trainings-Briefing (täglich 07:30 Uhr).
 */
export const sendMorningRecoveryBriefing = onSchedule(
  {
    schedule: "30 7 * * *",
    timeZone: "Europe/Berlin",
    region: "europe-west3",
  },
  async () => {
    const db = admin.firestore();
    const usersSnap = await db.collection("users").get();

    for (const doc of usersSnap.docs) {
      const uid = doc.id;
      const data = doc.data();

      // Prüfen, ob Benachrichtigungen für Summary aktiv sind
      if (data.settings?.notifications?.summary === false) {
        continue;
      }

      await sendSystemNotification({
        recipientId: uid,
        title: "Guten Morgen aus dem ORBIT",
        body: "Dein Erholungs-Score und deine Tagesempfehlung stehen bereit. Schau dir dein heutiges Ziel an.",
        category: "summary",
        dataPayload: {
          type: "HEALTH",
          route: "/health",
        },
      });
    }
  }
);

/**
 * Scheduled Cloud Function: Wöchentlicher Sonntags-Report (Sonntag 19:00 Uhr).
 */
export const sendWeeklySummaryNotification = onSchedule(
  {
    schedule: "0 19 * * 0",
    timeZone: "Europe/Berlin",
    region: "europe-west3",
  },
  async () => {
    const db = admin.firestore();
    const usersSnap = await db.collection("users").get();

    for (const doc of usersSnap.docs) {
      const uid = doc.id;
      const data = doc.data();

      if (data.settings?.notifications?.summary === false) {
        continue;
      }

      await sendSystemNotification({
        recipientId: uid,
        title: "Dein ORBIT Wochenrückblick",
        body: "Die Trainingswoche ist abgeschlossen! Überprüfe deine TSS, Belastungszonen und deine Formkurve.",
        category: "summary",
        dataPayload: {
          type: "SUMMARY",
          route: "/analysis",
        },
      });
    }
  }
);

/**
 * Callable Function zum Testen von Push-Benachrichtigungen und Deep Links.
 */
export const sendTestPushNotification = onCall(
  { region: "europe-west3" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const category = (request.data?.category || "workout") as
      | "workout"
      | "diagnostics"
      | "summary"
      | "chat"
      | "threshold";
    const title = request.data?.title || "ORBIT Test-Benachrichtigung";
    const body = request.data?.body || "Dies ist eine Testnachricht mit dem ORBIT Statusleisten-Icon.";
    const route = request.data?.route || "/";

    return await sendSystemNotification({
      recipientId: uid,
      title,
      body,
      category,
      dataPayload: {
        type: "TEST",
        route,
      },
      bypassQuietTime: true,
    });
  }
);
