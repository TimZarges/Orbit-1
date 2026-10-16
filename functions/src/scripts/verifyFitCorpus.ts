import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";
import { performance } from "perf_hooks";
import { parseActivityBuffer } from "../import/activityParser";
import { calculatePowerMetrics, calculateSkibaWPrimeBal } from "../metrics/power";
import { calculateAerobicDecoupling } from "../metrics/decoupling";
import { detectAutoIntervals } from "../metrics/intervals";
import { calculateRunningMetrics } from "../metrics/running";
import { calculateSwimMetrics } from "../metrics/swimming";

export interface FileProcessingResult {
  filePath: string;
  fileName: string;
  fileSizeBytes: number;
  duplicateHash: string;
  isDuplicate: boolean;
  success: boolean;
  durationMs: number;
  sport?: string;
  subSport?: string;
  samplesCount?: number;
  metricsComputed?: {
    tss?: number;
    np?: number;
    wPrimeBalMin?: number;
    decouplingPercent?: number;
    intervalsCount?: number;
    sTss?: number;
    rTss?: number;
  };
  error?: string;
}

export interface CorpusVerificationReport {
  corpusPath: string;
  totalFiles: number;
  successfulFiles: number;
  corruptOrFailedFiles: number;
  duplicateFilesCount: number;
  totalDurationMs: number;
  avgDurationPerFileMs: number;
  filesPerSecond: number;
  totalSamplesProcessed: number;
  sportsBreakdown: Record<string, number>;
  formatBreakdown: Record<string, number>;
  failedDetails: { fileName: string; error: string }[];
  markdownReport: string;
}

/**
 * Scannt ein Verzeichnis rekursiv nach .fit, .tcx, .gpx (inkl. .gz).
 */
export function findActivityFiles(dirPath: string): string[] {
  const results: string[] = [];
  if (!fs.existsSync(dirPath)) return results;

  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      results.push(...findActivityFiles(fullPath));
    } else if (entry.isFile()) {
      const lower = entry.name.toLowerCase();
      if (
        lower.endsWith(".fit") ||
        lower.endsWith(".fit.gz") ||
        lower.endsWith(".tcx") ||
        lower.endsWith(".tcx.gz") ||
        lower.endsWith(".gpx") ||
        lower.endsWith(".gpx.gz")
      ) {
        results.push(fullPath);
      }
    }
  }
  return results;
}

/**
 * Verarbeitet eine einzelne Aktivitätsdatei durch Parser und Metrik-Engine.
 */
export async function processSingleFile(
  filePath: string,
  seenHashes: Set<string>
): Promise<FileProcessingResult> {
  const fileName = path.basename(filePath);
  const start = performance.now();
  let fileSizeBytes = 0;
  let hash = "";

  try {
    const buffer = fs.readFileSync(filePath);
    fileSizeBytes = buffer.length;
    hash = crypto.createHash("sha256").update(buffer).digest("hex");
    const isDuplicate = seenHashes.has(hash);
    seenHashes.add(hash);

    // 1. Parsing
    const parsed = await parseActivityBuffer(buffer, fileName);
    const sport = (parsed.sport || "OTHER").toUpperCase();
    const samplesCount = parsed.streams?.time?.length || 0;

    const metricsComputed: FileProcessingResult["metricsComputed"] = {};

    // 2. Metrik-Engine Ausführung je nach Streams
    const powerStream = (parsed.streams?.power || []).map((p) => p || 0);
    const hrStream = (parsed.streams?.heartRate || []).map((h) => h || 0);

    const hasPower = powerStream.some((w) => w > 0);
    const hasHr = hrStream.some((h) => h > 0);

    if (hasPower) {
      const pMetrics = calculatePowerMetrics(powerStream, 250);
      metricsComputed.tss = pMetrics.tss;
      metricsComputed.np = pMetrics.np;

      const wBal = calculateSkibaWPrimeBal(powerStream, 250, 20000);
      metricsComputed.wPrimeBalMin = Math.round(wBal.minWPrimeBalJoules);

      if (hasHr && powerStream.length >= 600) {
        const dec = calculateAerobicDecoupling(powerStream, hrStream, 250);
        metricsComputed.decouplingPercent = dec.decouplingPercent;
      }

      const intervals = detectAutoIntervals(powerStream, 250, 30, 0.9, hrStream);
      metricsComputed.intervalsCount = intervals.length;
    } else if (sport === "RUN") {
      const dist = parsed.distanceM || 0;
      const dur = parsed.durationSec || 1;
      const speedStream = (parsed.streams?.speed || []).map((s) => s || 0);
      const altStream = parsed.streams?.altitude || [];
      const runM = calculateRunningMetrics(
        speedStream.length > 0 ? speedStream : [dist / dur],
        altStream,
        300
      );
      metricsComputed.rTss = runM.rTSS;
    } else if (sport === "SWIM") {
      const dist = parsed.distanceM || 0;
      const dur = parsed.durationSec || 1;
      const swimM = calculateSwimMetrics(dist, dur, 100);
      metricsComputed.sTss = swimM.sTSS;
    }

    const durationMs = performance.now() - start;
    return {
      filePath,
      fileName,
      fileSizeBytes,
      duplicateHash: hash,
      isDuplicate,
      success: true,
      durationMs,
      sport,
      subSport: parsed.subSport,
      samplesCount,
      metricsComputed,
    };
  } catch (err: any) {
    const durationMs = performance.now() - start;
    return {
      filePath,
      fileName,
      fileSizeBytes,
      duplicateHash: hash,
      isDuplicate: false,
      success: false,
      durationMs,
      error: err?.message || String(err),
    };
  }
}

/**
 * Führt den Stresstest für alle Dateien in einem Ordner durch und generiert den Bericht.
 */
export async function verifyCorpus(dirPath: string): Promise<CorpusVerificationReport> {
  const files = findActivityFiles(dirPath);
  const seenHashes = new Set<string>();
  const results: FileProcessingResult[] = [];

  const overallStart = performance.now();
  for (const file of files) {
    const res = await processSingleFile(file, seenHashes);
    results.push(res);
  }
  const totalDurationMs = performance.now() - overallStart;

  const successfulFiles = results.filter((r) => r.success).length;
  const corruptOrFailedFiles = results.filter((r) => !r.success).length;
  const duplicateFilesCount = results.filter((r) => r.isDuplicate).length;
  const totalSamplesProcessed = results.reduce((acc, r) => acc + (r.samplesCount || 0), 0);

  const sportsBreakdown: Record<string, number> = {};
  const formatBreakdown: Record<string, number> = {};

  for (const r of results) {
    if (r.sport) {
      sportsBreakdown[r.sport] = (sportsBreakdown[r.sport] || 0) + 1;
    }
    const ext = path.extname(r.fileName).toUpperCase() || "UNKNOWN";
    formatBreakdown[ext] = (formatBreakdown[ext] || 0) + 1;
  }

  const failedDetails = results
    .filter((r) => !r.success)
    .map((r) => ({ fileName: r.fileName, error: r.error || "Unbekannter Fehler" }));

  const avgDurationPerFileMs = files.length > 0 ? totalDurationMs / files.length : 0;
  const filesPerSecond = totalDurationMs > 0 ? (files.length / (totalDurationMs / 1000)) : 0;

  // Markdown-Report zusammenstellen
  const markdown = [
    `# ORBIT FIT/TCX/GPX Korpus-Verifikationsbericht`,
    ``,
    `**Geprüfter Ordner:** \`${dirPath}\``,
    `**Datum:** ${new Date().toISOString()}`,
    ``,
    `## Zusammenfassung`,
    `| Kennzahl | Wert |`,
    `| :--- | :--- |`,
    `| **Gesamtzahl Dateien** | ${files.length} |`,
    `| **Erfolgreich verarbeitet** | ${successfulFiles} (${files.length > 0 ? ((successfulFiles / files.length) * 100).toFixed(1) : 0} %) |`,
    `| **Abgefangene/Korrupte Dateien** | ${corruptOrFailedFiles} |`,
    `| **Erkannte Duplikate (Hash-Kollision)** | ${duplicateFilesCount} |`,
    `| **Gesamtdauer** | ${(totalDurationMs / 1000).toFixed(2)} s (${totalDurationMs.toFixed(0)} ms) |`,
    `| **Durchschnitt pro Datei** | ${avgDurationPerFileMs.toFixed(2)} ms |`,
    `| **Durchsatz** | **${filesPerSecond.toFixed(1)} Dateien/s** |`,
    `| **Verarbeitete 1Hz-Samples** | ${totalSamplesProcessed.toLocaleString()} |`,
    ``,
    `## Aufteilung nach Sportarten`,
    `| Sportart | Anzahl |`,
    `| :--- | :--- |`,
    ...Object.entries(sportsBreakdown).map(([sport, count]) => `| ${sport} | ${count} |`),
    ``,
    `## Aufteilung nach Dateiformaten`,
    `| Format | Anzahl |`,
    `| :--- | :--- |`,
    ...Object.entries(formatBreakdown).map(([fmt, count]) => `| ${fmt} | ${count} |`),
    ``,
  ];

  if (failedDetails.length > 0) {
    markdown.push(
      `## Details zu abgefangenen Fehlern / korrupten Dateien`,
      `| Dateiname | Grund (sauber abgefangen) |`,
      `| :--- | :--- |`,
      ...failedDetails.map((f) => `| \`${f.fileName}\` | ${f.error} |`),
      ``
    );
  } else {
    markdown.push(`## Fehlerprotokoll`, `*Keine Fehler. Alle Dateien wurden 100 % fehlerfrei verarbeitet.*`, ``);
  }

  const markdownReport = markdown.join("\n");

  return {
    corpusPath: dirPath,
    totalFiles: files.length,
    successfulFiles,
    corruptOrFailedFiles,
    duplicateFilesCount,
    totalDurationMs,
    avgDurationPerFileMs,
    filesPerSecond,
    totalSamplesProcessed,
    sportsBreakdown,
    formatBreakdown,
    failedDetails,
    markdownReport,
  };
}

// CLI-Einstiegspunkt
if (require.main === module) {
  const targetDir = process.argv[2] || path.resolve(__dirname, "../../../testvectors/fit");
  console.log(`\n================================================================`);
  console.log(`🚀 ORBIT Korpus-Stresstest gestartet...`);
  console.log(`📁 Zielordner: ${targetDir}`);
  console.log(`================================================================\n`);

  verifyCorpus(targetDir)
    .then((report) => {
      console.log(report.markdownReport);
      if (process.argv.includes("--save-report")) {
        const outPath = path.resolve(process.cwd(), "corpus-report.md");
        fs.writeFileSync(outPath, report.markdownReport, "utf-8");
        console.log(`\n📄 Markdown-Bericht gespeichert unter: ${outPath}`);
      }
    })
    .catch((err) => {
      console.error("❌ Kritischer Fehler beim Korpus-Test:", err);
      process.exit(1);
    });
}
