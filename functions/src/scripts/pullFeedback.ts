import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";
import axios from "axios";

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  try {
    admin.initializeApp({ projectId: "orbit-app-mvp" });
  } catch (e) {
    // Ignore init errors if ADC is not present
  }
}

interface FeedbackItem {
  id: string;
  ticketId: string;
  category: string;
  status: string;
  userId: string;
  createdAt: any;
  diagnostics?: any;
  description: string;
}

function unwrapFirestoreFields(fields: Record<string, any>): any {
  const result: Record<string, any> = {};
  for (const [key, val] of Object.entries(fields)) {
    if ("stringValue" in val) result[key] = val.stringValue;
    else if ("booleanValue" in val) result[key] = val.booleanValue;
    else if ("integerValue" in val) result[key] = parseInt(val.integerValue, 10);
    else if ("doubleValue" in val) result[key] = parseFloat(val.doubleValue);
    else if ("timestampValue" in val) result[key] = new Date(val.timestampValue);
    else if ("mapValue" in val) result[key] = unwrapFirestoreFields(val.mapValue.fields || {});
    else if ("arrayValue" in val) result[key] = (val.arrayValue.values || []).map((v: any) => unwrapFirestoreFields({ val: v }).val);
  }
  return result;
}

/**
 * CLI-Skript: pullFeedback.ts (Phase 28.2).
 *
 * Zieht alle Feedback- und Bug-Meldungen aus Firestore (`betaFeedback`)
 * und synchronisiert sie automatisch in `docs/beta/BUGS.md`.
 */
async function pullFeedback(): Promise<void> {
  console.log("Synchronisiere Beta-Feedback aus Firestore...");
  const items: FeedbackItem[] = [];

  try {
    const db = admin.firestore();
    const snapshot = await db
      .collection("betaFeedback")
      .orderBy("createdAt", "desc")
      .get();

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      items.push({
        id: doc.id,
        ticketId: data.ticketId || `#ORB-${doc.id.substring(0, 6)}`,
        category: data.category || "UNBEKANNT",
        status: data.status || "OPEN",
        userId: data.userId || "anonym",
        createdAt: data.createdAt,
        diagnostics: data.diagnostics || {},
        description: data.description || "",
      });
    });
  } catch (adminErr) {
    console.warn("Firebase Admin SDK Abfrage fehlgeschlagen, versuche Firebase CLI Token Fallback...", (adminErr as Error).message);
    const configPath = path.join(os.homedir(), ".config/configstore/firebase-tools.json");
    if (fs.existsSync(configPath)) {
      const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"));
      const token = cfg.tokens?.access_token;
      if (token) {
        const url = "https://firestore.googleapis.com/v1/projects/orbit-app-mvp/databases/(default)/documents/betaFeedback";
        const response = await axios.get(url, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const docs = response.data.documents || [];
        docs.forEach((doc: any) => {
          const docId = doc.name.split("/").pop();
          const data = unwrapFirestoreFields(doc.fields || {});
          items.push({
            id: docId,
            ticketId: data.ticketId || `#ORB-${docId.substring(0, 6)}`,
            category: data.category || "UNBEKANNT",
            status: data.status || "OPEN",
            userId: data.userId || "anonym",
            createdAt: data.createdAt,
            diagnostics: data.diagnostics || {},
            description: data.description || "",
          });
        });
        // Sort descending by createdAt
        items.sort((a, b) => {
          const timeA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
          const timeB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
          return timeB - timeA;
        });
      }
    }
  }

  console.log(`${items.length} Feedback-Einträge gefunden.`);

  const bugsPath = path.resolve(__dirname, "../../../docs/beta/BUGS.md");
  let bugsContent = fs.readFileSync(bugsPath, "utf8");

  const sectionHeader = "## 4. Live gemeldete Beta-Feedback- & Bug-Tickets (Automatisch synchronisiert)";

  let generatedMarkdown = `${sectionHeader}\n\n`;
  generatedMarkdown += `> Zuletzt aktualisiert per \`npm --prefix functions run feedback:pull\`: ${new Date().toISOString()}\n\n`;

  if (items.length === 0) {
    generatedMarkdown += `*Aktuell liegen keine offenen Beta-Feedback-Tickets vor.*\n`;
  } else {
    generatedMarkdown += `| Ticket-ID | Kategorie | Status | Melder (User-ID) | Datum | Gerät / Version | Beschreibung |\n`;
    generatedMarkdown += `| :--- | :--- | :---: | :--- | :--- | :--- | :--- |\n`;

    items.forEach((item) => {
      const ticketId = item.ticketId;
      const category = item.category;
      const status = item.status;
      const userId = (item.userId || "anonym").substring(0, 8) + "...";
      const dateStr = item.createdAt
        ? new Date(item.createdAt.toDate ? item.createdAt.toDate() : item.createdAt).toLocaleString("de-DE")
        : "unbekannt";
      const diag = item.diagnostics || {};
      const deviceStr = diag.deviceInfo ? `${diag.deviceInfo} (${diag.appVersion || ""})` : "–";
      const cleanDesc = (item.description || "").replace(/\r?\n/g, " ").replace(/\|/g, "\\|").substring(0, 120);

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
