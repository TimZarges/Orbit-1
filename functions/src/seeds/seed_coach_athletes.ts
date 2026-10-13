import * as admin from "firebase-admin";

/**
 * Seed-Skript zur Erzeugung von 25+ Test-Athleten für Last- und Performance-Tests
 * des Coach-Dashboards.
 * 
 * SICHERHEIT: Streng abgesichert gegen Produktiv-Ausführung.
 */
export async function seedCoachAthletes(coachId: string, count = 28): Promise<{ created: number }> {
  // Schutz gegen Ausführung in Produktion
  if (process.env.NODE_ENV === "production" || process.env.GCLOUD_PROJECT?.includes("prod")) {
    throw new Error("ABBRUCH: Seed-Skript darf NIEMALS in der Produktivumgebung ausgeführt werden!");
  }

  const db = admin.firestore();
  const firstNames = ["Lukas", "Julia", "Felix", "Sophie", "Maximilian", "Hannah", "Leon", "Marie", "David", "Laura", "Jonas", "Lena", "Tim", "Sarah", "Paul", "Emma", "Niklas", "Mia", "Moritz", "Anna", "Florian", "Clara", "Simon", "Lara", "Tobias", "Lea", "Jan", "Lisa"];
  const lastNames = ["Weber", "Müller", "Schmidt", "Schneider", "Fischer", "Meyer", "Wagner", "Becker", "Schulz", "Hoffmann", "Schäfer", "Koch", "Bauer", "Richter", "Klein", "Wolf", "Schröder", "Neumann", "Schwarz", "Zimmermann", "Braun", "Krüger", "Hofmann", "Hartmann", "Lange", "Schmitt", "Werner", "Schmitz"];
  const sports = ["TRIATHLON", "RUN", "BIKE", "SWIM"];
  const formStatuses: Array<"wellLoaded" | "optimal" | "caution" | "fresh" | "building"> = [
    "optimal", "wellLoaded", "caution", "fresh", "optimal", "wellLoaded", "building"
  ];

  let createdCount = 0;
  const batch = db.batch();

  for (let i = 0; i < Math.min(count, firstNames.length); i++) {
    const athleteId = `test_athlete_${coachId.slice(0, 5)}_${i + 1}`;
    const name = `${firstNames[i]} ${lastNames[i]}`;
    const sport = sports[i % sports.length];
    const formStatus = formStatuses[i % formStatuses.length];
    const ctl = 35 + (i * 3) % 65;
    const atl = formStatus === "caution" ? ctl + 25 : ctl + ((i % 5) - 2) * 5;
    const tsb = ctl - atl;
    const plannedLoad7d = 250 + (i * 20) % 350;
    const compliance7d = [95, 82, 100, 65, 88, 105, 78, 92, 50, 90][i % 10];
    const actualLoad7d = Math.round((plannedLoad7d * compliance7d) / 100);

    const docRef = db.collection("coachDashboard").doc(coachId).collection("athletes").doc(athleteId);

    const raceDays = 14 + (i * 12) % 180;
    const raceDate = new Date(Date.now() + raceDays * 24 * 60 * 60 * 1000).toISOString().split("T")[0];

    const alertVal = i === 3 ? "NO_ACTIVITY_7D" : i === 7 ? "LOAD_SPIKE" : null;

    batch.set(docRef, {
      athleteId,
      coachId,
      name,
      avatarUrl: null,
      sport,
      formStatus,
      ctl,
      atl,
      tsb,
      compliance7d,
      actualLoad7d,
      plannedLoad7d,
      unreadMessagesCount: i % 4 === 0 ? (i % 3) + 1 : 0,
      pendingProposalsCount: i % 5 === 0 ? 1 : 0,
      latestActivity: {
        date: new Date(Date.now() - (i % 4) * 24 * 60 * 60 * 1000).toISOString().split("T")[0],
        title: `${sport === "BIKE" ? "Grundlagenfahrt" : sport === "RUN" ? "Tempodauerlauf" : "Technikblock"}`,
        sport,
        load: 45 + (i * 7) % 80,
      },
      raceGoal: {
        title: sport === "TRIATHLON" ? "Challenge Roth" : sport === "RUN" ? "Berlin Marathon" : "Cyclassics",
        date: raceDate,
        distance: sport === "TRIATHLON" ? "Langdistanz" : "Marathon",
        daysRemaining: raceDays,
      },
      alert: alertVal,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    createdCount++;
  }

  await batch.commit();
  return { created: createdCount };
}
