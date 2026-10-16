/**
 * ORBIT Journal-Korrelations-Engine (Punkt f).
 * Berechnet ab N >= 14 Tagen statistische Zusammenhänge zwischen Alltagsfaktoren
 * und vegetativen Biomarkern (HRV, Ruhepuls, Tiefschlaf, Erholung).
 */

import { CorrelationInsight, JournalData, JournalTag } from "./types";

export interface CorrelationInputRecord {
  date: string;
  journal?: JournalData;
  hrvMs?: number;
  restingHrBpm?: number;
  deepSleepMinutes?: number;
  recoveryScore?: number;
}

const TAG_LABELS: Record<JournalTag, { de: string; en: string }> = {
  lateCaffeine: { de: "spätem Koffein", en: "late caffeine" },
  alcohol: { de: "Alkohol", en: "alcohol" },
  muscleSoreness: { de: "Muskelkater", en: "muscle soreness" },
  highStress: { de: "hohem Alltagsstress", en: "high daily stress" },
  poorFeeling: { de: "schlechtem Wohlbefinden", en: "poor feeling" },
  goodHydration: { de: "guter Hydration", en: "good hydration" },
  lateMeal: { de: "später Mahlzeit", en: "late meal" },
  travelAltitude: { de: "Reise / Höhe", en: "travel / altitude" },
};

/**
 * Analysiert Verhaltensfaktoren und ermittelt statistisch bedeutsame Korrelationen.
 */
export function analyzeJournalCorrelations(
  records: CorrelationInputRecord[]
): CorrelationInsight[] {
  // Mindestens 14 Tage Historie erforderlich
  if (records.length < 14) {
    return [];
  }

  const tags: JournalTag[] = [
    "lateCaffeine",
    "alcohol",
    "muscleSoreness",
    "highStress",
    "poorFeeling",
    "goodHydration",
    "lateMeal",
    "travelAltitude",
  ];

  const insights: CorrelationInsight[] = [];

  for (const tag of tags) {
    const withTag = records.filter((r) => r.journal?.[tag] === true);
    const withoutTag = records.filter((r) => r.journal && r.journal[tag] !== true);

    // Mindestens 3 Stichproben in beiden Gruppen
    if (withTag.length < 3 || withoutTag.length < 3) {
      continue;
    }

    const nWith = withTag.length;
    const nWithout = withoutTag.length;
    const label = TAG_LABELS[tag];

    // 1. HRV Analyse
    const hrvWith = withTag.map((r) => r.hrvMs).filter((v): v is number => typeof v === "number" && v > 0);
    const hrvWithout = withoutTag.map((r) => r.hrvMs).filter((v): v is number => typeof v === "number" && v > 0);
    if (hrvWith.length >= 3 && hrvWithout.length >= 3) {
      const avgWith = hrvWith.reduce((a, b) => a + b, 0) / hrvWith.length;
      const avgWithout = hrvWithout.reduce((a, b) => a + b, 0) / hrvWithout.length;
      const delta = +(avgWith - avgWithout).toFixed(1);
      const pct = +((delta / avgWithout) * 100).toFixed(1);

      if (Math.abs(delta) >= 3.0) {
        const sign = delta > 0 ? "+" : "";
        const deVerb = delta > 0 ? "stieg" : "sank";
        const enVerb = delta > 0 ? "increased" : "dropped";

        insights.push({
          tag,
          sampleSizeWithTag: nWith,
          sampleSizeWithoutTag: nWithout,
          metric: "hrv",
          delta,
          percentChange: pct,
          insightDe: `An Tagen mit ${label.de} ${deVerb} deine HRV im Schnitt um ${Math.abs(delta)} ms (${sign}${pct} %).`,
          insightEn: `On days with ${label.en}, your HRV ${enVerb} by ${Math.abs(delta)} ms on average (${sign}${pct}%).`,
        });
      }
    }

    // 2. Ruhepuls Analyse
    const rhrWith = withTag.map((r) => r.restingHrBpm).filter((v): v is number => typeof v === "number" && v > 0);
    const rhrWithout = withoutTag.map((r) => r.restingHrBpm).filter((v): v is number => typeof v === "number" && v > 0);
    if (rhrWith.length >= 3 && rhrWithout.length >= 3) {
      const avgWith = rhrWith.reduce((a, b) => a + b, 0) / rhrWith.length;
      const avgWithout = rhrWithout.reduce((a, b) => a + b, 0) / rhrWithout.length;
      const delta = +(avgWith - avgWithout).toFixed(1);
      const pct = +((delta / avgWithout) * 100).toFixed(1);

      if (Math.abs(delta) >= 1.5) {
        const sign = delta > 0 ? "+" : "";
        const deVerb = delta > 0 ? "erhöhte sich" : "sank";
        const enVerb = delta > 0 ? "increased" : "decreased";

        insights.push({
          tag,
          sampleSizeWithTag: nWith,
          sampleSizeWithoutTag: nWithout,
          metric: "rhr",
          delta,
          percentChange: pct,
          insightDe: `An Tagen mit ${label.de} ${deVerb} dein Ruhepuls um ${Math.abs(delta)} bpm (${sign}${pct} %).`,
          insightEn: `On days with ${label.en}, your resting heart rate ${enVerb} by ${Math.abs(delta)} bpm (${sign}${pct}%).`,
        });
      }
    }

    // 3. Tiefschlaf Analyse
    const deepWith = withTag.map((r) => r.deepSleepMinutes).filter((v): v is number => typeof v === "number" && v >= 0);
    const deepWithout = withoutTag.map((r) => r.deepSleepMinutes).filter((v): v is number => typeof v === "number" && v >= 0);
    if (deepWith.length >= 3 && deepWithout.length >= 3) {
      const avgWith = deepWith.reduce((a, b) => a + b, 0) / deepWith.length;
      const avgWithout = deepWithout.reduce((a, b) => a + b, 0) / deepWithout.length;
      const delta = Math.round(avgWith - avgWithout);
      const pct = Math.round((delta / (avgWithout || 1)) * 100);

      if (Math.abs(delta) >= 10) {
        const sign = delta > 0 ? "+" : "";
        const deAdverb = delta > 0 ? "länger" : "kürzer";
        const enAdverb = delta > 0 ? "longer" : "shorter";

        insights.push({
          tag,
          sampleSizeWithTag: nWith,
          sampleSizeWithoutTag: nWithout,
          metric: "deepSleep",
          delta,
          percentChange: pct,
          insightDe: `An Tagen mit ${label.de} war dein Tiefschlaf im Schnitt ${Math.abs(delta)} Min. ${deAdverb} (${sign}${pct} %).`,
          insightEn: `On days with ${label.en}, your deep sleep was ${Math.abs(delta)} min ${enAdverb} on average (${sign}${pct}%).`,
        });
      }
    }

    // 4. Erholungs-Score
    const recWith = withTag.map((r) => r.recoveryScore).filter((v): v is number => typeof v === "number" && v >= 0);
    const recWithout = withoutTag.map((r) => r.recoveryScore).filter((v): v is number => typeof v === "number" && v >= 0);
    if (recWith.length >= 3 && recWithout.length >= 3) {
      const avgWith = recWith.reduce((a, b) => a + b, 0) / recWith.length;
      const avgWithout = recWithout.reduce((a, b) => a + b, 0) / recWithout.length;
      const delta = Math.round(avgWith - avgWithout);
      const pct = Math.round((delta / (avgWithout || 1)) * 100);

      if (Math.abs(delta) >= 5) {
        const sign = delta > 0 ? "+" : "";
        const deAdj = delta > 0 ? "besser" : "niedriger";
        const enAdj = delta > 0 ? "higher" : "lower";

        insights.push({
          tag,
          sampleSizeWithTag: nWith,
          sampleSizeWithoutTag: nWithout,
          metric: "recovery",
          delta,
          percentChange: pct,
          insightDe: `Mit ${label.de} lag dein Erholungs-Score im Schnitt ${Math.abs(delta)} Punkte ${deAdj} (${sign}${pct} %).`,
          insightEn: `With ${label.en}, your recovery score was ${Math.abs(delta)} points ${enAdj} on average (${sign}${pct}%).`,
        });
      }
    }
  }

  return insights;
}
