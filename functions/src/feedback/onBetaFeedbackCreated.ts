import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

/**
 * Cloud Function Trigger: onBetaFeedbackCreated (Phase 28.2).
 *
 * Lauscht auf `betaFeedback/{reportId}`:
 * 1. Vergibt eine fortlaufende Ticket-ID (z. B. `#ORB-042`) per atomarer Firestore-Transaktion.
 * 2. Setzt den Status auf "OPEN" und speichert die Ticket-ID im Dokument.
 * 3. Verschickt eine Admin-Benachrichtigung an alle registrierten Admins.
 */
export const onBetaFeedbackCreated = onDocumentCreated(
  {
    document: "betaFeedback/{reportId}",
    region: "europe-west3",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Keine Daten im Snapshot vorhanden.");
      return;
    }

    const reportId = event.params.reportId;
    const data = snapshot.data();
    const db = admin.firestore();

    logger.info(`Neues Beta-Feedback eingegangen: ${reportId}`, { category: data.category });

    try {
      // 1. Fortlaufende Ticket-ID generieren via Transaktion
      const counterRef = db.collection("counters").doc("betaFeedback");
      let ticketId = "";

      await db.runTransaction(async (transaction) => {
        const counterDoc = await transaction.get(counterRef);
        let nextCount = 1;
        if (counterDoc.exists) {
          nextCount = ((counterDoc.data()?.count as number) || 0) + 1;
        }

        transaction.set(
          counterRef,
          {
            count: nextCount,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        ticketId = `#ORB-${String(nextCount).padStart(3, "0")}`;

        // 2. Report mit Ticket-ID und Initialstatus aktualisieren
        transaction.update(snapshot.ref, {
          ticketId,
          status: data.status || "OPEN",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      logger.info(`Ticket-ID erfolgreich zugewiesen: ${ticketId} für ${reportId}`);

      // 3. Admin-Benachrichtigung versenden (Admins suchen)
      const adminUsersSnapshot = await db
        .collection("users")
        .where("role", "==", "ADMIN")
        .get();

      if (!adminUsersSnapshot.empty) {
        const title = `Neues Feedback: ${ticketId}`;
        const descriptionPreview = (data.description || "").substring(0, 100);
        const body = `[${data.category || "FEEDBACK"}] ${descriptionPreview}`;

        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminId = adminDoc.id;
          const devicesSnapshot = await db
            .collection("users")
            .doc(adminId)
            .collection("devices")
            .get();

          const tokens: string[] = [];
          devicesSnapshot.forEach((doc) => {
            const token = doc.data().fcmToken;
            if (token) tokens.push(token);
          });

          if (tokens.length > 0) {
            await admin.messaging().sendEachForMulticast({
              tokens,
              notification: { title, body },
              data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                route: `/admin/feedback`,
                ticketId,
                reportId,
              },
            });
            logger.info(`Admin-Push an ${adminId} (${tokens.length} Devices) gesendet.`);
          }
        }
      }
    } catch (err) {
      logger.error(`Fehler bei der Zuweisung der Ticket-ID für ${reportId}:`, err);
    }
  }
);
