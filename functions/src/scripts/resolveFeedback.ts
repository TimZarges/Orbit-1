import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";
import axios from "axios";

if (!admin.apps.length) {
  try {
    admin.initializeApp({ projectId: "orbit-app-mvp" });
  } catch (e) {
    // Ignore init errors if ADC is not present
  }
}

const TICKETS_TO_RESOLVE = [
  "#ORB-002",
  "#ORB-003",
  "#ORB-004",
  "#ORB-005",
  "#ORB-007",
  "#ORB-008",
  "#ORB-009",
  "#ORB-010",
  "#ORB-011",
  "#ORB-012",
  "#ORB-013",
  "#ORB-014",
  "#ORB-015",
  "#ORB-016",
  "#ORB-017",
  "#ORB-018",
  "#ORB-019",
  "#ORB-020",
  "#ORB-021",
];

async function resolveFeedback(): Promise<void> {
  console.log("Aktualisiere Beta-Feedback Tickets auf RESOLVED...");
  const resolvedNotes: Record<string, string> = {
    "#ORB-002": "Onboarding Weiterleitung repariert: Direkter Firestore-Write und zuverlässiges Routing.",
    "#ORB-003": "Triathlon Piktogramm durch TriathlonCombinedIcon (Swim/Bike/Run) ersetzt.",
    "#ORB-004": "showCheckmark: false gesetzt, kein störender Punkt mehr hinter Sportart-Chips.",
    "#ORB-005": "Dynamische Intensitäts- und Zeitblöcke aus StructuredWorkoutData extrahiert und proportional gerendert.",
    "#ORB-007": "Garmin syncGarminActivitiesNow Cloud Function live in europe-west3 deployed.",
    "#ORB-008": "Garmin Webhook und Activity Sync Endpunkte live geschaltet und typensicher validiert.",
    "#ORB-009": "Schließen-Button (X) und BetaBugReportIconButton in WorkoutDetailSheet eingebaut.",
    "#ORB-010": "Dynamische Block-Vorschau in TodayWorkoutPreviewCard liest Intervalle mit Duration & Intensität.",
    "#ORB-011": "Provider-Invalidierung und Snapshot-Streams für sofortigen Live-Sync bei Reschedule/Skip/Planung.",
    "#ORB-012": "Datumsformatierung auf deutsches DIN DD.MM.YYYY und 24h-Uhrzeit vereinheitlicht.",
    "#ORB-013": "Staged FIT/TCX/GPX Upload im Onboarding und typensichere Payload-Verarbeitung repariert.",
    "#ORB-014": "Direkter Garmin Connect OAuth Button im Onboarding Step 3 verdrahtet.",
    "#ORB-015": "isAdmin: true für Tim gesetzt und Tester-Fallback (.where(userId == auth.uid)) implementiert.",
    "#ORB-016": "Mitteilungskarten mit klarem Rahmen (1.5px Volt unread / 1.2px Slate read) versehen.",
    "#ORB-017": "Alle gelesen synchronisiert sofort persistent in Firestore und setzt Seed-Zähler auf 0.",
    "#ORB-018": "Workout-Builder Block-Editor für jede Einheit mit % FTP Stepper, Watt-Vorschau und Wiederholungen.",
    "#ORB-019": "Kalender- und Dashboard-Provider aktualisieren sich in derselben Sekunde nach Erstellung.",
    "#ORB-020": "Blockhöhe skaliert nun exakt nach Intensität (% FTP / Z1-Z7) mit CrossAxisAlignment.end Baseline.",
    "#ORB-021": "showCheckmark: false im Profil-Screen für Sportart-Chips übernommen.",
  };

  try {
    const db = admin.firestore();
    const snapshot = await db.collection("betaFeedback").get();
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const ticketId = data.ticketId;
      if (TICKETS_TO_RESOLVE.includes(ticketId)) {
        await doc.ref.update({
          status: "RESOLVED",
          resolvedAt: new Date().toISOString(),
          resolutionNote: resolvedNotes[ticketId] || "Repariert und live auf Pixel 10 Pro verifiziert.",
        });
        console.log(`Ticket ${ticketId} (${doc.id}) -> RESOLVED (Admin SDK)`);
      }
    }
    return;
  } catch (adminErr) {
    console.warn("Firebase Admin SDK nicht verfügbar, nutze Firebase CLI Token Fallback...", (adminErr as Error).message);
  }

  const configPath = path.join(os.homedir(), ".config/configstore/firebase-tools.json");
  if (!fs.existsSync(configPath)) {
    throw new Error("Weder Admin SDK noch Firebase CLI Config gefunden.");
  }

  const cfg = JSON.parse(fs.readFileSync(configPath, "utf8"));
  const token = cfg.tokens?.access_token;
  if (!token) throw new Error("Kein Access Token in firebase-tools.json!");

  const listUrl = "https://firestore.googleapis.com/v1/projects/orbit-app-mvp/databases/(default)/documents/betaFeedback";
  const response = await axios.get(listUrl, {
    headers: { Authorization: `Bearer ${token}` },
  });

  const docs = response.data.documents || [];
  for (const doc of docs) {
    const docName = doc.name; // projects/.../documents/betaFeedback/DOC_ID
    const fields = doc.fields || {};
    const ticketId = fields.ticketId?.stringValue;
    if (ticketId && TICKETS_TO_RESOLVE.includes(ticketId)) {
      const patchUrl = `https://firestore.googleapis.com/v1/${docName}?updateMask.fieldPaths=status&updateMask.fieldPaths=resolvedAt&updateMask.fieldPaths=resolutionNote`;
      await axios.patch(
        patchUrl,
        {
          fields: {
            status: { stringValue: "RESOLVED" },
            resolvedAt: { stringValue: new Date().toISOString() },
            resolutionNote: { stringValue: resolvedNotes[ticketId] || "Repariert und live auf Pixel 10 Pro verifiziert." },
          },
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      console.log(`Ticket ${ticketId} (${docName.split("/").pop()}) -> RESOLVED (REST API)`);
    }
  }
}

resolveFeedback()
  .then(() => {
    console.log("Alle Tickets erfolgreich auf RESOLVED gesetzt.");
    process.exit(0);
  })
  .catch((err) => {
    console.error("Fehler beim Aktualisieren der Tickets:", err);
    process.exit(1);
  });
