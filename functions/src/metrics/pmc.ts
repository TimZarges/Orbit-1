import { calculateDailyLoadEMA } from "./load";

/**
 * Performance Management Chart (PMC nach Banister et al. 1975).
 * 
 * Berechnet chronische Belastung (CTL, 42d), akute Belastung (ATL, 7d),
 * Trainingsbelastungsbalance (TSB = CTL_gestern - ATL_gestern),
 * 7-Tage-Ramp-Rate und 14-Tage-Zukunftsprojektion.
 */

export interface PmcDayPoint {
  localDate: string; // "YYYY-MM-DD"
  tss: number;
  ctl: number;
  atl: number;
  tsb: number;
  rampRate7d?: number;
  isProjected: boolean;
}

export interface PmcCalculationResult {
  series: PmcDayPoint[];
  currentCtl: number;
  currentAtl: number;
  currentTsb: number;
  rampRate7d: number;
  rampRateAlert: boolean;
  projectedCtlIn14d: number;
  projectedTsbIn14d: number;
}

/**
 * Berechnet das PMC über eine historische Datenserie und projiziert 14 Tage in die Zukunft.
 */
export function calculatePmcSeries(
  history: { localDate: string; tss: number }[],
  plannedDays?: { localDate: string; plannedTss: number }[],
  initialCtl = 0,
  initialAtl = 0
): PmcCalculationResult {
  const sortedHistory = [...history].sort((a, b) => a.localDate.localeCompare(b.localDate));

  let ctl = initialCtl;
  let atl = initialAtl;
  const series: PmcDayPoint[] = [];

  for (let i = 0; i < sortedHistory.length; i++) {
    const entry = sortedHistory[i];
    const tsb = ctl - atl; // TSB basiert auf der Balance des Vortags

    ctl = calculateDailyLoadEMA(ctl, entry.tss, 42);
    atl = calculateDailyLoadEMA(atl, entry.tss, 7);

    // 7-Tage Ramp Rate: CTL(heute) - CTL(vor 7 Tagen)
    let rampRate7d: number | undefined;
    if (series.length >= 7) {
      rampRate7d = Number((ctl - series[series.length - 7].ctl).toFixed(1));
    }

    series.push({
      localDate: entry.localDate,
      tss: Math.round(entry.tss),
      ctl: Number(ctl.toFixed(1)),
      atl: Number(atl.toFixed(1)),
      tsb: Number(tsb.toFixed(1)),
      rampRate7d,
      isProjected: false,
    });
  }

  const currentCtl = Number(ctl.toFixed(1));
  const currentAtl = Number(atl.toFixed(1));
  const currentTsb = Number((ctl - atl).toFixed(1));

  const lastRampRate = series.length > 0 && series[series.length - 1].rampRate7d !== undefined
    ? series[series.length - 1].rampRate7d!
    : 0;

  const rampRateAlert = lastRampRate > 7.0;

  // 14-Tage-Projektion
  let projCtl = ctl;
  let projAtl = atl;

  if (plannedDays && plannedDays.length > 0) {
    const sortedPlanned = [...plannedDays].sort((a, b) => a.localDate.localeCompare(b.localDate));
    for (const p of sortedPlanned.slice(0, 14)) {
      const tsb = projCtl - projAtl;
      projCtl = calculateDailyLoadEMA(projCtl, p.plannedTss, 42);
      projAtl = calculateDailyLoadEMA(projAtl, p.plannedTss, 7);

      let rampRate7d: number | undefined;
      if (series.length >= 7) {
        rampRate7d = Number((projCtl - series[series.length - 7].ctl).toFixed(1));
      }

      series.push({
        localDate: p.localDate,
        tss: Math.round(p.plannedTss),
        ctl: Number(projCtl.toFixed(1)),
        atl: Number(projAtl.toFixed(1)),
        tsb: Number(tsb.toFixed(1)),
        rampRate7d,
        isProjected: true,
      });
    }
  }

  return {
    series,
    currentCtl,
    currentAtl,
    currentTsb,
    rampRate7d: lastRampRate,
    rampRateAlert,
    projectedCtlIn14d: Number(projCtl.toFixed(1)),
    projectedTsbIn14d: Number((projCtl - projAtl).toFixed(1)),
  };
}
