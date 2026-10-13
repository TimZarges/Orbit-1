import * as admin from "firebase-admin";

/**
 * Sendet eine sparsame System-Benachrichtigung an einen Athleten (z. B. neuer Schwellenwert-Vorschlag oder geplantes Workout).
 */
export async function sendSystemNotification({
  recipientId,
  title,
  body,
  category,
  dataPayload,
}: {
  recipientId: string;
  title: string;
  body: string;
  category: "workout" | "diagnostics" | "summary";
  dataPayload: Record<string, string>;
}): Promise<void> {
  const db = admin.firestore();

  const userDoc = await db.collection("users").doc(recipientId).get();
  if (!userDoc.exists) return;
  const userData = userDoc.data()!;

  // Einstellung für Kategorie prüfen
  const notifications = userData.settings?.notifications ?? {};
  if (notifications[category] === false) return;

  // Geräte laden
  const devicesSnap = await db.collection("users").doc(recipientId).collection("devices").get();
  if (devicesSnap.empty) return;

  const tokens: string[] = [];
  devicesSnap.forEach((d) => {
    const t = d.data().fcmToken as string;
    if (t) tokens.push(t);
  });
  if (tokens.length === 0) return;

  const messagePayload: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title,
      body,
    },
    data: {
      ...dataPayload,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "normal",
      notification: {
        channelId: category === "workout" ? "workout_reminders" : "diagnostics",
      },
    },
  };

  try {
    await admin.messaging().sendEachForMulticast(messagePayload);
  } catch (_) {
    // Fehler fangen
  }
}
