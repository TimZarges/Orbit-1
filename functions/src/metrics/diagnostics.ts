import * as admin from "firebase-admin";

export type ThresholdType = "FTP" | "LTHR" | "THRESHOLD_PACE" | "CSS";
export type ConfidenceLevel = "HIGH" | "MEDIUM" | "LOW";

export interface ThresholdProposalResult {
  hasProposal: boolean;
  type?: ThresholdType;
  sport?: string;
  proposedValue?: number;
  currentValue?: number;
  delta?: number;
  deltaPercent?: number;
  confidence?: ConfidenceLevel;
  basis?: string[];
  explanationDe?: string;
  explanationEn?: string;
  reasonForNoProposal?: string;
}

/**
 * Schätzt FTP aus 20-Minuten-Leistungsdaten (MMP 1200s).
 */
export function estimateFtp(
  twentyMinMmp: number,
  normalizedPower: number,
  currentFtp?: number,
  dateStr = new Date().toISOString().split("T")[0]
): ThresholdProposalResult {
  if (twentyMinMmp < 50 || twentyMinMmp > 600) {
    return {
      hasProposal: false,
      reasonForNoProposal: "20-Minuten-Leistung außerhalb des plausiblen Bereichs (50–600 W).",
    };
  }

  const vi = normalizedPower > 0 ? normalizedPower / twentyMinMmp : 1.0;
  if (vi > 1.15) {
    return {
      hasProposal: false,
      reasonForNoProposal: "Pacing zu ungleichmäßig (VI > 1.15).",
    };
  }

  const calculatedFtp = Math.round(twentyMinMmp * 0.95);
  let delta = 0;
  let deltaPercent = 0;

  if (currentFtp && currentFtp > 0) {
    delta = calculatedFtp - currentFtp;
    deltaPercent = Number(((delta / currentFtp) * 100).toFixed(1));

    if (Math.abs(delta) < 3 && Math.abs(deltaPercent) < 1.5) {
      return {
        hasProposal: false,
        reasonForNoProposal: "Änderung unter der Relevanzschwelle (< 3 W und < 1.5 %).",
      };
    }
  }

  const confidence: ConfidenceLevel = vi <= 1.05 ? "HIGH" : vi <= 1.12 ? "MEDIUM" : "LOW";
  const sign = delta >= 0 ? "+" : "";

  return {
    hasProposal: true,
    type: "FTP",
    sport: "BIKE",
    proposedValue: calculatedFtp,
    currentValue: currentFtp,
    delta,
    deltaPercent,
    confidence,
    basis: [
      `20-Minuten-Bestwert: ${Math.round(twentyMinMmp)} W am ${dateStr}`,
      `Pacing-Gleichmäßigkeit: VI = ${vi.toFixed(2)}`,
    ],
    explanationDe: currentFtp
      ? `Basierend auf deinem 20-Minuten-Bestwert von ${Math.round(twentyMinMmp)} W ergibt sich ein neuer FTP von ${calculatedFtp} W (${sign}${delta} W, ${sign}${deltaPercent} %).`
      : `Basierend auf deinem 20-Minuten-Bestwert von ${Math.round(twentyMinMmp)} W wird ein Einstiegs-FTP von ${calculatedFtp} W empfohlen.`,
    explanationEn: currentFtp
      ? `Based on your 20-min peak of ${Math.round(twentyMinMmp)} W, your estimated FTP is ${calculatedFtp} W (${sign}${delta} W).`
      : `Based on your 20-min peak of ${Math.round(twentyMinMmp)} W, an initial FTP of ${calculatedFtp} W is suggested.`,
  };
}

/**
 * Schätzt LTHR und Schwellenpace aus 30-Minuten-Testlauf.
 */
export function estimateRunThresholds(
  last20MinAvgHr: number,
  thirtyMinAvgPaceSec: number,
  hrStdDev = 3.0,
  currentLthr?: number,
  currentPaceSec?: number,
  dateStr = new Date().toISOString().split("T")[0]
): { lthr: ThresholdProposalResult; pace: ThresholdProposalResult } {
  // LTHR
  let lthrResult: ThresholdProposalResult;
  if (last20MinAvgHr < 120 || last20MinAvgHr > 215 || hrStdDev > 8.0) {
    lthrResult = {
      hasProposal: false,
      reasonForNoProposal: "Herzfrequenz unplausibel oder schwankte zu stark.",
    };
  } else {
    const calcLthr = Math.round(last20MinAvgHr);
    let delta = 0;
    let deltaPct = 0;
    if (currentLthr && currentLthr > 0) {
      delta = calcLthr - currentLthr;
      deltaPct = Number(((delta / currentLthr) * 100).toFixed(1));
    }

    if (currentLthr && Math.abs(delta) < 2) {
      lthrResult = {
        hasProposal: false,
        reasonForNoProposal: "Herzfrequenzänderung unter Relevanzschwelle (< 2 bpm).",
      };
    } else {
      const conf: ConfidenceLevel = hrStdDev <= 4.0 ? "HIGH" : "MEDIUM";
      const sign = delta >= 0 ? "+" : "";
      lthrResult = {
        hasProposal: true,
        type: "LTHR",
        sport: "RUN",
        proposedValue: calcLthr,
        currentValue: currentLthr,
        delta,
        deltaPercent: deltaPct,
        confidence: conf,
        basis: [
          `30-Minuten-Lauftest am ${dateStr}`,
          `Puls letzte 20 Min: ${calcLthr} bpm`,
        ],
        explanationDe: `Aus deinem Testlauf ergibt sich eine Schwellen-HF von ${calcLthr} bpm (${sign}${delta} bpm).`,
        explanationEn: `Estimated LTHR is ${calcLthr} bpm (${sign}${delta} bpm).`,
      };
    }
  }

  // Pace
  let paceResult: ThresholdProposalResult;
  if (thirtyMinAvgPaceSec < 150 || thirtyMinAvgPaceSec > 600) {
    paceResult = {
      hasProposal: false,
      reasonForNoProposal: "Pace außerhalb des plausiblen Bereichs.",
    };
  } else {
    let delta = 0;
    let deltaPct = 0;
    if (currentPaceSec && currentPaceSec > 0) {
      delta = thirtyMinAvgPaceSec - currentPaceSec;
      deltaPct = Number(((delta / currentPaceSec) * 100).toFixed(1));
    }

    if (currentPaceSec && Math.abs(delta) < 5) {
      paceResult = {
        hasProposal: false,
        reasonForNoProposal: "Pace-Änderung unter Relevanzschwelle (< 5 s/km).",
      };
    } else {
      const conf: ConfidenceLevel = hrStdDev <= 4.0 ? "HIGH" : "MEDIUM";
      const m = Math.floor(thirtyMinAvgPaceSec / 60);
      const s = Math.round(thirtyMinAvgPaceSec % 60);
      const paceStr = `${m}:${s.toString().padStart(2, "0")} min/km`;
      paceResult = {
        hasProposal: true,
        type: "THRESHOLD_PACE",
        sport: "RUN",
        proposedValue: thirtyMinAvgPaceSec,
        currentValue: currentPaceSec,
        delta,
        deltaPercent: deltaPct,
        confidence: conf,
        basis: [`30-Minuten-Lauftest am ${dateStr}`, `Durchschnittstempo: ${paceStr}`],
        explanationDe: `Aus deinem Testlauf ergibt sich eine Schwellenpace von ${paceStr}.`,
        explanationEn: `Estimated threshold pace is ${paceStr}.`,
      };
    }
  }

  return { lthr: lthrResult, pace: paceResult };
}

/**
 * Schätzt CSS aus 400m- und 200m-Zeiten.
 */
export function estimateCss(
  t400Seconds: number,
  t200Seconds: number,
  currentCssPaceSec?: number,
  dateStr = new Date().toISOString().split("T")[0]
): ThresholdProposalResult {
  if (t400Seconds <= 0 || t200Seconds <= 0 || t400Seconds <= t200Seconds) {
    return {
      hasProposal: false,
      reasonForNoProposal: "Ungültige oder unplausible Zeiten für CSS-Test.",
    };
  }

  const calcCssPaceSec = (t400Seconds - t200Seconds) / 2.0;
  if (calcCssPaceSec < 45 || calcCssPaceSec > 240) {
    return {
      hasProposal: false,
      reasonForNoProposal: "CSS-Pace außerhalb des plausiblen Bereichs (0:45–4:00 min/100m).",
    };
  }

  let delta = 0;
  let deltaPercent = 0;
  if (currentCssPaceSec && currentCssPaceSec > 0) {
    delta = calcCssPaceSec - currentCssPaceSec;
    deltaPercent = Number(((delta / currentCssPaceSec) * 100).toFixed(1));

    if (Math.abs(delta) < 1.0) {
      return {
        hasProposal: false,
        reasonForNoProposal: "CSS-Änderung unter Relevanzschwelle (< 1.0 s/100m).",
      };
    }
  }

  const m = Math.floor(calcCssPaceSec / 60);
  const s = Math.round(calcCssPaceSec % 60);
  const cssStr = `${m}:${s.toString().padStart(2, "0")} min/100m`;

  return {
    hasProposal: true,
    type: "CSS",
    sport: "SWIM",
    proposedValue: calcCssPaceSec,
    currentValue: currentCssPaceSec,
    delta,
    deltaPercent,
    confidence: "HIGH",
    basis: [
      `400m/200m Test am ${dateStr}`,
      `T400 = ${t400Seconds}s, T200 = ${t200Seconds}s`,
    ],
    explanationDe: `Aus deinem 400m/200m-Test ergibt sich eine neue CSS von ${cssStr}.`,
    explanationEn: `Estimated CSS from your 400m/200m test is ${cssStr}.`,
  };
}

/**
 * Erzeugt einen Vorschlag in Firestore, falls noch kein identischer Vorschlag offen ist.
 */
export async function createThresholdProposalIfNew(
  uid: string,
  result: ThresholdProposalResult
): Promise<void> {
  if (!result.hasProposal || !result.type || !result.proposedValue) return;

  const db = admin.firestore();
  const proposalsCol = db.collection("users").doc(uid).collection("thresholdProposals");

  // Dubletten-Prüfung: Gibt es bereits einen offenen PENDING Vorschlag für denselben Typ?
  const existingPending = await proposalsCol
    .where("type", "==", result.type)
    .where("status", "==", "PENDING")
    .get();

  for (const doc of existingPending.docs) {
    const data = doc.data();
    // Wenn der vorgeschlagene Wert nahezu identisch ist (Diff < 1), erzeugen wir keinen neuen
    if (Math.abs((data.proposedValue ?? 0) - result.proposedValue) < 1.0) {
      return; // Bereits vorhanden
    }
    // Veraltete Vorschläge ablaufen lassen
    await doc.ref.update({ status: "EXPIRED" });
  }

  const now = new Date();
  const expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); // 30 Tage

  await proposalsCol.add({
    athleteId: uid,
    sport: result.sport ?? "OTHER",
    type: result.type,
    proposedValue: result.proposedValue,
    currentValue: result.currentValue ?? null,
    delta: result.delta ?? 0,
    deltaPercent: result.deltaPercent ?? 0,
    confidence: result.confidence ?? "MEDIUM",
    basis: result.basis ?? [],
    explanationDe: result.explanationDe ?? "",
    explanationEn: result.explanationEn ?? "",
    status: "PENDING",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
  });
}
