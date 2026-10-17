import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * CLI-Skript: pullFeedback.ts (Phase 28.2).
 *
 * Zieht alle Feedback- und Bug-Meldungen aus Firestore (`betaFeedback`)
 * und synchronisiert sie automatisch in `docs/beta/BUGS.md`.
 */
async function pullFeedback(): Promise<void> {
  console.log("Synchronisiere Beta-Feedback aus Firestore...");
  const db = admin.firestore();

  const snapshot = await db
    .collection("betaFeedback")
    .orderBy("createdAt", "desc")
    .get();

  console.log(`${snapshot.size} Feedback-Einträge gefunden.`);

  const bugsPath = path.resolve(__dirname, "../../../docs/beta/BUGS.md");
  let bugsContent = fs.readFileSync(bugsPath, "utf8");

  const sectionHeader = "## 4. Live gemeldete Beta-Feedback- & Bug-Tickets (Automatisch synchronisiert)";

  let generatedMarkdown = `${sectionHeader}\n\n`;
  generatedMarkdown += `> Zuletzt aktualisiert per \`npm --prefix functions run feedback:pull\`: ${new Date().toISOString()}\n\n`;

  if (snapshot.empty) {
    generatedMarkdown += `*Aktuell liegen keine offenen Beta-Feedback-Tickets vor.*\n`;
  } else {
    generatedMarkdown += `| Ticket-ID | Kategorie | Status | Melder (User-ID) | Datum | Gerät / Version | Beschreibung |\n`;
    generatedMarkdown += `| :--- | :--- | :---: | :--- | :--- | :--- | :--- |\n`;

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      const ticketId = data.ticketId || `#ORB-${doc.id.substring(0, 6)}`;
      const category = data.category || "UNBEKANNT";
      const status = data.status || "OPEN";
      const userId = (data.userId || "anonym").substring(0, 8) + "...";
      const dateStr = data.createdAt
        ? new Date(data.createdAt.toDate ? data.createdAt.toDate() : data.createdAt).toLocaleString("de-DE")
        : "unbekannt";
      const diag = data.diagnostics || {};
      const deviceStr = diag.deviceInfo ? `${diag.deviceInfo} (${diag.appVersion || ""})` : "–";
      const cleanDesc = (data.description || "").replace(/\r?\n/g, " ").replace(/\|/g, "\\|").substring(0, 120);

      const statusBadge =
        status === "RESOLVED"
          ? "🟢 Behoben"
          : status === "IN_PROGRESS"
          ? "🟡 In Arbeit"
          : "🔴 Offen";

      generatedMarkdown += `| **${ticketId}** | \`${category}\` | ${statusBadge} | \`${userId}\` | ${dateStr} | ${deviceStr} | ${cleanDesc} |\n`;
    });
  }

  // Update or append section in BUGS.md
  if (bugsContent.includes(sectionHeader)) {
    const parts = bugsContent.split(sectionHeader);
    const beforeSection = parts[0];
    bugsContent = `${beforeSection.trimEnd()}\n\n${generatedMarkdown}\n`;
  } else {
    bugsContent = `${bugsContent.trimEnd()}\n\n---\n\n${generatedMarkdown}\n`;
  }

  fs.writeFileSync(bugsPath, bugsContent, "utf8");
  console.log(`Erfolgreich synchronisiert nach: ${bugsPath}`);
}

pullFeedback()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Fehler beim Synchronisieren des Beta-Feedbacks:", err);
    process.exit(1);
  });
