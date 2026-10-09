/**
 * Berechnet Normalized Power (NP), Intensity Factor (IF) und TSS.
 * 
 * NP: 30-Sekunden gleitender Mittelwert -> 4. Potenz -> Durchschnitt -> 4. Wurzel.
 * IF: NP / FTP
 * TSS: (Dauer_s * NP * IF) / (FTP * 3600) * 100
 */
export function calculatePowerMetrics(powerData: number[], ftp: number) {
  if (!powerData || powerData.length === 0 || ftp <= 0) {
    return { np: 0, iff: 0, tss: 0 };
  }

  const duration = powerData.length; // 1 data point per second
  
  let np = 0;
  if (duration < 30) {
    // Zu kurz für 30s-Glättung, Durchschnitt verwenden
    const sum = powerData.reduce((a, b) => a + b, 0);
    np = sum / duration;
  } else {
    let sum4 = 0;
    for (let i = 29; i < duration; i++) {
      let rollSum = 0;
      for (let j = 0; j < 30; j++) {
        rollSum += powerData[i - j];
      }
      const avg30 = rollSum / 30;
      sum4 += Math.pow(avg30, 4);
    }
    const count = duration - 29;
    np = Math.pow(sum4 / count, 0.25);
  }

  const iff = np / ftp;
  const tss = (duration * np * iff) / (ftp * 3600) * 100;

  return { np, iff, tss };
}
