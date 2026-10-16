import { calculatePowerMetrics } from "./power";

/**
 * Automatische Intervall-Erkennung (Auto-Lap Detection) aus Leistungs- oder Geschwindigkeits-Streams.
 * 
 * Erkennt zusammenhängende Belastungsplateaus (z.B. >= 90 % FTP über >= 30s)
 * und berechnet Durchschnittsleistung, NP, mittlere Herzfrequenz und EF pro Intervall.
 */

export interface DetectedInterval {
  intervalIndex: number;
  startSec: number;
  endSec: number;
  durationSec: number;
  avgValue: number;
  npValue: number;
  avgHr?: number;
  ef?: number;
  intensityPercent: number;
}

/**
 * Erkennt Belastungsintervalle im Sekunden-Stream.
 */
export function detectAutoIntervals(
  values: number[],
  threshold: number,
  minDurationSec = 30,
  minIntensityFactor = 0.90,
  heartRates?: number[]
): DetectedInterval[] {
  if (!values || values.length === 0 || threshold <= 0) {
    return [];
  }

  const targetFloor = threshold * minIntensityFactor;
  const intervals: DetectedInterval[] = [];

  let inInterval = false;
  let startIdx = 0;
  let dropoutCounter = 0;
  const maxDropoutSec = 5;

  for (let i = 0; i < values.length; i++) {
    const v = values[i] || 0;

    if (v >= targetFloor) {
      if (!inInterval) {
        inInterval = true;
        startIdx = i;
        dropoutCounter = 0;
      } else {
        dropoutCounter = 0; // Dropout zurücksetzen
      }
    } else {
      if (inInterval) {
        dropoutCounter++;
        // Wenn der Dropout länger als 5s anhält, ist das Intervall beendet
        if (dropoutCounter > maxDropoutSec || i === values.length - 1) {
          const endIdx = i - dropoutCounter;
          const duration = endIdx - startIdx + 1;

          if (duration >= minDurationSec) {
            const intervalSlice = values.slice(startIdx, endIdx + 1);
            const hrSlice = heartRates ? heartRates.slice(startIdx, endIdx + 1) : undefined;

            const powerRes = calculatePowerMetrics(intervalSlice, threshold);
            const avgVal = powerRes.avgPower;
            const npVal = powerRes.np;

            let avgHr: number | undefined;
            let ef: number | undefined;

            if (hrSlice && hrSlice.length > 0) {
              const hrSum = hrSlice.reduce((a, b) => a + (b || 0), 0);
              const validHrCount = hrSlice.filter((h) => h > 0).length;
              if (validHrCount > 0) {
                avgHr = Math.round(hrSum / validHrCount);
                if (avgHr > 0) {
                  ef = Number((npVal / avgHr).toFixed(2));
                }
              }
            }

            intervals.push({
              intervalIndex: intervals.length + 1,
              startSec: startIdx,
              endSec: endIdx,
              durationSec: duration,
              avgValue: Math.round(avgVal),
              npValue: Math.round(npVal),
              avgHr,
              ef,
              intensityPercent: Math.round((avgVal / threshold) * 100),
            });
          }

          inInterval = false;
          dropoutCounter = 0;
        }
      }
    }
  }

  // Falls das letzte Intervall bis zum Ende durchging
  if (inInterval) {
    const endIdx = values.length - 1 - dropoutCounter;
    const duration = endIdx - startIdx + 1;
    if (duration >= minDurationSec) {
      const intervalSlice = values.slice(startIdx, endIdx + 1);
      const powerRes = calculatePowerMetrics(intervalSlice, threshold);
      intervals.push({
        intervalIndex: intervals.length + 1,
        startSec: startIdx,
        endSec: endIdx,
        durationSec: duration,
        avgValue: Math.round(powerRes.avgPower),
        npValue: Math.round(powerRes.np),
        intensityPercent: Math.round((powerRes.avgPower / threshold) * 100),
      });
    }
  }

  return intervals;
}
