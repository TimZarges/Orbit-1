import * as admin from "firebase-admin";

export const MMP_DURATIONS_SEC = [1, 5, 15, 30, 60, 120, 300, 600, 1200, 1800, 3600];

/**
 * Berechnet Mean-Maximal-Power für gegebene Dauern.
 */
export function calculateMMP(powerData: number[], durations = MMP_DURATIONS_SEC): Record<string, number> {
  const result: Record<string, number> = {};
  const n = powerData.length;
  if (n === 0) return result;

  for (const d of durations) {
    if (d > n) break;

    let windowSum = 0;
    for (let i = 0; i < d; i++) {
      windowSum += powerData[i];
    }

    let maxAvg = windowSum / d;

    for (let i = d; i < n; i++) {
      windowSum += powerData[i] - powerData[i - d];
      const avg = windowSum / d;
      if (avg > maxAvg) {
        maxAvg = avg;
      }
    }

    result[d.toString()] = Math.round(maxAvg);
  }

  return result;
}

/**
 * Aktualisiert die Allzeit- und Saison-Bestwerte unter users/{uid}/bests/{sport}.
 */
export async function updateSportBests(
  uid: string,
  sport: string,
  activityMmp: Record<string, number>
) {
  if (!uid || !sport || Object.keys(activityMmp).length === 0) return;

  const db = admin.firestore();
  const bestsRef = db.collection("users").doc(uid).collection("bests").doc(sport.toUpperCase());

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(bestsRef);
    const data = doc.data() || {};

    const allTimeMmp: Record<string, number> = data.allTimeMmp || {};
    const seasonMmp: Record<string, number> = data.seasonMmp || {};

    let changed = false;

    for (const [durStr, watts] of Object.entries(activityMmp)) {
      const currentAllTime = allTimeMmp[durStr] || 0;
      if (watts > currentAllTime) {
        allTimeMmp[durStr] = watts;
        changed = true;
      }

      const currentSeason = seasonMmp[durStr] || 0;
      if (watts > currentSeason) {
        seasonMmp[durStr] = watts;
        changed = true;
      }
    }

    if (changed || !doc.exists) {
      transaction.set(bestsRef, {
        allTimeMmp,
        seasonMmp,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  });
}
