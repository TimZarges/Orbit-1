/**
 * Berechnet die prozentuale Verteilung der Werte in vordefinierten Zonen (z.B. HF oder Leistung).
 */
export function calculateZoneDistribution(values: number[], zoneLimits: number[]): number[] {
  // zoneLimits = [140, 155, 170, 185] entspricht 5 Zonen (Z1..Z5)
  // Z1: < 140, Z2: 140-155, Z3: 155-170, Z4: 170-185, Z5: > 185
  const distribution = new Array(zoneLimits.length + 1).fill(0);
  if (values.length === 0) return distribution;

  for (const v of values) {
    let placed = false;
    for (let i = 0; i < zoneLimits.length; i++) {
      if (v < zoneLimits[i]) {
        distribution[i]++;
        placed = true;
        break;
      }
    }
    if (!placed) {
      distribution[zoneLimits.length]++;
    }
  }

  // Prozentual
  const total = values.length;
  for (let i = 0; i < distribution.length; i++) {
    distribution[i] = (distribution[i] / total) * 100;
  }
  return distribution;
}
