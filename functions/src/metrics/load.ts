/**
 * Berechnet CTL und ATL basierend auf exponentiellem gleitendem Durchschnitt (EMA).
 */
export function calculateDailyLoadEMA(prevVal: number, load: number, timeConstant: number): number {
  if (timeConstant <= 0) return load;
  const a = Math.exp(-1 / timeConstant);
  return load * (1 - a) + prevVal * a;
}

export function calculateLoadMetrics(loads: number[], startCtl = 0, startAtl = 0, ctlTc = 42, atlTc = 7) {
  let ctl = startCtl;
  let atl = startAtl;

  for (const load of loads) {
    ctl = calculateDailyLoadEMA(ctl, load, ctlTc);
    atl = calculateDailyLoadEMA(atl, load, atlTc);
  }

  return { ctl, atl, tsb: ctl - atl };
}
