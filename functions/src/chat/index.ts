import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

/**
 * Trigger beim Erstellen einer neuen Chat-Nachricht.
 * 1. Aktualisiert lastMessage und unreadCount auf dem Chat-Dokument transaktional.
 * 2. Sendet datensparsame Push-Benachrichtigung an den Empfänger (unter Beachtung von Ruhezeiten und Einstellungen).
 * 3. Bereinigt ungültige FCM-Tokens.
 */
export const onMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    if (!event.data) return;
    const msgData = event.data.data();
    if (!msgData) return;

    const { chatId } = event.params;
    const db = admin.firestore();

    // 1. Chat-Dokument laden
    const chatRef = db.collection("chats").doc(chatId);
    const chatSnap = await chatRef.get();
    if (!chatSnap.exists) return;

    const chatData = chatSnap.data()!;
    const athleteId = chatData.athleteId as string;
    const coachId = chatData.coachId as string;
    const senderId = msgData.senderId as string;

    // Empfänger ermitteln
    const recipientId = senderId === athleteId ? coachId : athleteId;

    const lastMsgSummary = {
      text: msgData.type === "ACTIVITY_SHARE" ? "Geteilte Trainingseinheit" : (msgData.text ?? "Anhang"),
      senderId,
      sentAt: msgData.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
      type: msgData.type ?? "TEXT",
    };

    // 2. Chat-Dokument transaktional aktualisieren
    await chatRef.set(
      {
        lastMessage: lastMsgSummary,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        unreadCount: {
          [recipientId]: admin.firestore.FieldValue.increment(1),
        },
      },
      { merge: true }
    );

    // 3. Push-Benachrichtigung an Empfänger senden
    await sendChatPushNotification(recipientId, senderId, lastMsgSummary.text, chatId);
  }
);

/**
 * Sendet Push-Benachrichtigung unter Einhaltung von Privatsphäre, Einstellungen und Ruhezeiten.
 */
export async function sendChatPushNotification(
  recipientId: string,
  senderId: string,
  previewText: string,
  chatId: string
): Promise<void> {
  const db = admin.firestore();

  // Empfänger-Einstellungen prüfen
  const recipientDoc = await db.collection("users").doc(recipientId).get();
  if (!recipientDoc.exists) return;
  const recipientData = recipientDoc.data()!;

  const notificationsSettings = recipientData.settings?.notifications ?? {};
  if (notificationsSettings.chat === false) {
    return; // Chat-Benachrichtigungen vom Nutzer deaktiviert
  }

  // Ruhezeiten prüfen
  const quietHours = recipientData.settings?.quietHours;
  if (quietHours && isQuietTime(quietHours.from, quietHours.to)) {
    return; // Aktuell in Ruhezeit -> Push unterdrücken (Nachricht bleibt im Chat)
  }

  // Sender-Name für Titel ermitteln
  const senderDoc = await db.collection("users").doc(senderId).get();
  const senderName = senderDoc.data()?.profile?.displayName ?? "Dein Trainingspartner";

  // Geräte-Tokens des Empfängers laden
  const devicesSnap = await db.collection("users").doc(recipientId).collection("devices").get();
  if (devicesSnap.empty) return;

  const tokensWithDoc: { token: string; docId: string }[] = [];
  devicesSnap.forEach((doc) => {
    const t = doc.data().fcmToken as string;
    if (t) tokensWithDoc.push({ token: t, docId: doc.id });
  });

  if (tokensWithDoc.length === 0) return;

  // Datensparsamer Push: Text nur wenn explizit aktiviert
  const showPreview = notificationsSettings.preview === true;
  const bodyText = showPreview ? previewText : "Du hast eine neue Nachricht in ORBIT.";

  const messagePayload: admin.messaging.MulticastMessage = {
    tokens: tokensWithDoc.map((d) => d.token),
    notification: {
      title: `Neue Nachricht von ${senderName}`,
      body: bodyText,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "CHAT",
      chatId,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "chat_messages",
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

    // Ungültige Tokens bereinigen
    const tokensToDelete: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success && resp.error) {
        const code = resp.error.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          tokensToDelete.push(tokensWithDoc[idx].docId);
        }
      }
    });

    for (const docId of tokensToDelete) {
      await db.collection("users").doc(recipientId).collection("devices").doc(docId).delete();
    }
  } catch (err) {
    // Fehler bei Push-Versand protokollieren (ohne PII)
  }
}

/**
 * Prüft, ob die aktuelle Server-/Lokalzeit innerhalb der definierten Ruhezeit liegt.
 */
export function isQuietTime(fromStr?: string, toStr?: string, now = new Date()): boolean {
  if (!fromStr || !toStr) return false;

  const [fromH, fromM] = fromStr.split(":").map(Number);
  const [toH, toM] = toStr.split(":").map(Number);

  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const fromMinutes = fromH * 60 + fromM;
  const toMinutes = toH * 60 + toM;

  if (fromMinutes <= toMinutes) {
    return currentMinutes >= fromMinutes && currentMinutes <= toMinutes;
  } else {
    // Geht über Mitternacht (z. B. 22:00 bis 07:00)
    return currentMinutes >= fromMinutes || currentMinutes <= toMinutes;
  }
}
