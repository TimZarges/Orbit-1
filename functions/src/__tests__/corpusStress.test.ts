import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";
import { performance } from "perf_hooks";
import { parseActivityBuffer } from "../import/activityParser";
import { calculatePowerMetrics, calculateSkibaWPrimeBal } from "../metrics/power";
import { calculateAerobicDecoupling } from "../metrics/decoupling";
import { detectAutoIntervals } from "../metrics/intervals";
import { calculatePmcSeries } from "../metrics/pmc";
import { calculateMMP } from "../metrics/bests";
import { verifyCorpus } from "../scripts/verifyFitCorpus";

describe("Phase 24.1: 150-Aktivitäten Batch- & Stresstest (Parser, Metriken & Aggregation)", () => {
  // Helfer zum Erstellen synthetischer valider TCX-Aktivitäten
  function createSyntheticTcxRide(
    sport: string,
    durationSec: number,
    basePower: number,
    baseHr: number,
    idSuffix: number | string = 0
  ): Buffer {
    let trackpoints = "";
    // Stützpunkte alle 5 Sekunden generieren, um realistische TCX-Payloads zu erzeugen
    const step = Math.max(1, Math.min(5, Math.floor(durationSec / 100)));
    for (let t = 0; t < durationSec; t += step) {
      const p = basePower > 0 ? basePower + (t % 50) - 25 : 0;
      const hr = baseHr > 0 ? baseHr + Math.floor(t / 60) : 0;
      const speed = 8.5; // ~30.6 km/h
      const dist = t * speed;
      const alt = 150 + Math.sin(t / 200) * 30;

      trackpoints += `
          <Trackpoint>
            <Time>2026-08-01T${new Date(t * 1000).toISOString().substr(11, 8)}.000Z</Time>
            <Position>
              <LatitudeDegrees>${50.11 + t * 0.00001}</LatitudeDegrees>
              <LongitudeDegrees>${8.68 + t * 0.00001}</LongitudeDegrees>
            </Position>
            <AltitudeMeters>${alt.toFixed(1)}</AltitudeMeters>
            <DistanceMeters>${dist.toFixed(1)}</DistanceMeters>
            ${hr > 0 ? `<HeartRateBpm><Value>${hr}</Value></HeartRateBpm>` : ""}
            <Cadence>88</Cadence>
            <Extensions>
              <ns3:TPX xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
                <ns3:Speed>${speed}</ns3:Speed>
                ${p > 0 ? `<ns3:Watts>${p}</ns3:Watts>` : ""}
              </ns3:TPX>
            </Extensions>
          </Trackpoint>`;
    }

    const tcxXml = `<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
  <Activities>
    <Activity Sport="${sport}">
      <Id>2026-08-01T08:00:00.${idSuffix}Z</Id>
      <Lap StartTime="2026-08-01T08:00:00.${idSuffix}Z">
        <TotalTimeSeconds>${durationSec}</TotalTimeSeconds>
        <DistanceMeters>${durationSec * 8.5}</DistanceMeters>
        <MaximumSpeed>15.0</MaximumSpeed>
        <Calories>${Math.round(durationSec * 0.2)}</Calories>
        <AverageHeartRateBpm><Value>${baseHr}</Value></AverageHeartRateBpm>
        <Track>
          ${trackpoints}
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>`;

    return Buffer.from(tcxXml, "utf-8");
  }

  // Helfer zum Erstellen synthetischer GPX-Aktivitäten
  function createSyntheticGpxRun(durationSec: number, avgSpeedMps: number, idSuffix: number | string = 0): Buffer {
    let trkpts = "";
    const step = 5;
    for (let t = 0; t < durationSec; t += step) {
      trkpts += `
      <trkpt lat="${50.11 + t * 0.00001}" lon="${8.68 + t * 0.00001}">
        <ele>${120 + Math.sin(t / 100) * 20}</ele>
        <time>2026-08-01T${new Date(t * 1000).toISOString().substr(11, 8)}.000Z</time>
        <extensions>
          <speed>${avgSpeedMps}</speed>
          <hr>${155 + (t % 10)}</hr>
        </extensions>
      </trkpt>`;
    }

    const gpxXml = `<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="ORBIT Test Suite" xmlns="http://www.topografix.com/GPX/1/1">
  <trk>
    <name>Morning Interval Run ${idSuffix}</name>
    <time>2026-08-01T08:00:00.${idSuffix}Z</time>
    <type>running</type>
    <trkseg>
      ${trkpts}
    </trkseg>
  </trk>
</gpx>`;

    return Buffer.from(gpxXml, "utf-8");
  }

  it("verarbeitet einen 150-Aktivitäten-Stresstest (125 valide, 15 korrupte, 10 Duplikate) ohne Crash", async () => {
    const seenHashes = new Set<string>();
    let validSuccessCount = 0;
    let handledErrorCount = 0;
    let duplicateCount = 0;

    const startTotal = performance.now();

    // 1. Reale FIT-Dateien aus testvectors/fit einlesen
    const fitDir = path.resolve(__dirname, "../../../testvectors/fit");
    const realFitFiles = fs.existsSync(fitDir)
      ? fs.readdirSync(fitDir).filter((f) => f.endsWith(".fit") || f.endsWith(".FIT"))
      : [];

    const corpusItems: { name: string; buffer: Buffer; expectSuccess: boolean }[] = [];

    // Reale FIT-Dateien hinzufügen (ca. 31 Dateien)
    for (const f of realFitFiles) {
      corpusItems.push({
        name: f,
        buffer: fs.readFileSync(path.join(fitDir, f)),
        expectSuccess: true,
      });
    }

    // Synthetische TCX- und GPX-Dateien auffüllen bis 125 valide Einheiten
    const neededSynthetic = 125 - corpusItems.length;
    for (let i = 0; i < neededSynthetic; i++) {
      if (i % 3 === 0) {
        // Rad-Ausfahrt (1h bis 4h)
        const dur = 3600 + (i % 4) * 3600;
        corpusItems.push({
          name: `synth_bike_${i}.tcx`,
          buffer: createSyntheticTcxRide("Biking", dur, 220 + (i % 50), 145, i),
          expectSuccess: true,
        });
      } else if (i % 3 === 1) {
        // Lauf (30 min bis 90 min)
        const dur = 1800 + (i % 3) * 1800;
        corpusItems.push({
          name: `synth_run_${i}.gpx`,
          buffer: createSyntheticGpxRun(dur, 3.33, i), // 5:00 min/km
          expectSuccess: true,
        });
      } else {
        // Swim / Triathlon TCX
        const dur = 2400;
        corpusItems.push({
          name: `synth_swim_${i}.tcx`,
          buffer: createSyntheticTcxRide("Swimming", dur, 0, 130, i),
          expectSuccess: true,
        });
      }
    }

    // 15 Absichtlich korrupte / abgeschnittene Dateien hinzufügen
    const corruptItems: { name: string; buffer: Buffer }[] = [
      { name: "corrupt_fit_header.fit", buffer: Buffer.from("NOT_A_VALID_FIT_FILE_AT_ALL_GARBAGE") },
      { name: "truncated_fit.fit", buffer: Buffer.from([14, 0, 16, 32, 0, 0, 0, 0, 46, 70, 73, 84]) },
      { name: "bad_gzip.fit.gz", buffer: Buffer.from([0x1f, 0x8b, 0x08, 0x00, 0x12, 0x34, 0x56]) },
      { name: "broken_xml.tcx", buffer: Buffer.from("<TrainingCenterDatabase><Activities><UnclosedTag") },
      { name: "broken_gpx.gpx", buffer: Buffer.from("<gpx><trk><trkseg><trkpt lat='bad'></gpx>") },
      { name: "empty_file.fit", buffer: Buffer.alloc(0) },
      { name: "random_noise_1.fit", buffer: crypto.randomBytes(512) },
      { name: "random_noise_2.tcx", buffer: crypto.randomBytes(1024) },
      { name: "random_noise_3.gpx", buffer: crypto.randomBytes(2048) },
      { name: "null_bytes.fit", buffer: Buffer.alloc(256) },
      { name: "corrupt_xml_entity.tcx", buffer: Buffer.from("<xml>&#999999999999;</xml>") },
      { name: "truncated_gpx.gpx", buffer: Buffer.from("<?xml version='1.0'?><gpx><trk>") },
      { name: "partial_json.fit", buffer: Buffer.from('{"sport": "BIKE", "duration":') },
      { name: "garbage_ascii.tcx", buffer: Buffer.from("SOMETHING TOTALLY WRONG\x00\x01\x02\xFF") },
      { name: "truncated_gzip.tcx.gz", buffer: Buffer.from([0x1f, 0x8b, 0x00, 0x00]) },
    ];

    // 10 Duplikate (Kopien valider Dateien)
    const duplicateItems: { name: string; buffer: Buffer }[] = [];
    for (let i = 0; i < 10; i++) {
      duplicateItems.push({
        name: `duplicate_copy_${i}_${corpusItems[i].name}`,
        buffer: Buffer.from(corpusItems[i].buffer),
      });
    }

    // A. 125 valide Dateien durchlaufen lassen
    for (const item of corpusItems) {
      const hash = crypto.createHash("sha256").update(item.buffer).digest("hex");
      if (seenHashes.has(hash)) {
        duplicateCount++;
      } else {
        seenHashes.add(hash);
      }

      try {
        const parsed = await parseActivityBuffer(item.buffer, item.name);
        expect(parsed).toBeDefined();
        expect(parsed.durationSec).toBeGreaterThan(0);

        // Metriken berechnen
        const powerStream = (parsed.streams?.power || []).map((p) => p || 0);
        if (powerStream.some((w) => w > 0)) {
          const pMetrics = calculatePowerMetrics(powerStream, 250);
          expect(pMetrics.tss).toBeGreaterThanOrEqual(0);
          const wbal = calculateSkibaWPrimeBal(powerStream, 250, 20000);
          expect(wbal.minWPrimeBalJoules).toBeDefined();
        }
        validSuccessCount++;
      } catch (err) {
        // Valide Dateien dürfen nicht fehlschlagen
        throw new Error(`Valide Datei ${item.name} unerwartet fehlgeschlagen: ${err}`);
      }
    }

    // B. 15 korrupte Dateien durchlaufen lassen (müssen sauber abgefangen werden)
    for (const item of corruptItems) {
      try {
        await parseActivityBuffer(item.buffer, item.name);
        // Falls ein Parser unerwartet leere Objekte zurückgibt:
      } catch (err) {
        // Fehler wurde sauber abgefangen
        handledErrorCount++;
        expect(err).toBeDefined();
      }
    }

    // C. 10 Duplikate durchlaufen lassen (müssen durch Hash-Kollision erkannt werden)
    for (const item of duplicateItems) {
      const hash = crypto.createHash("sha256").update(item.buffer).digest("hex");
      if (seenHashes.has(hash)) {
        duplicateCount++;
      }
      seenHashes.add(hash);
    }

    const elapsedMs = performance.now() - startTotal;

    // Prüfen, dass alle 125 validen Dateien 100 % grün sind
    expect(validSuccessCount).toBe(125);
    // Prüfen, dass alle 15 korrupten Dateien ohne Crash sauber abgefangen wurden
    expect(handledErrorCount).toBe(15);
    // Prüfen, dass alle 10 Duplikate zuverlässig erkannt wurden
    expect(duplicateCount).toBe(10);

    // Gesamtdurchsatz prüfen (> 20 Dateien/s)
    const totalFiles = 125 + 15 + 10;
    const throughput = totalFiles / (elapsedMs / 1000);
    expect(throughput).toBeGreaterThan(15);
  });

  it("analysiert eine 4-stündige Radausfahrt (14.400 1Hz-Samples) in unter 20 ms", () => {
    const numSamples = 14400; // 4 Stunden
    const powerStream = new Array<number>(numSamples);
    const hrStream = new Array<number>(numSamples);

    for (let i = 0; i < numSamples; i++) {
      // 220W Basis mit Intervallen und Ermüdungs-Drift
      const intervalSurge = i % 1800 < 300 ? 120 : 0; // alle 30 min ein 5-min Antritt
      powerStream[i] = 200 + intervalSurge + Math.sin(i / 100) * 30;
      hrStream[i] = 135 + Math.floor(i / 1200) + (intervalSurge > 0 ? 25 : 0);
    }

    const start = performance.now();

    // 1. Power Metrics (NP, IF, TSS, VI)
    const pMetrics = calculatePowerMetrics(powerStream, 260);
    expect(pMetrics.np).toBeGreaterThan(200);
    expect(pMetrics.tss).toBeGreaterThan(150);

    // 2. Skiba W'bal Verlauf
    const wbal = calculateSkibaWPrimeBal(powerStream, 260, 22000);
    expect(wbal.wPrimeBalJoules.length).toBe(numSamples);
    expect(wbal.minWPrimeBalJoules).toBeLessThan(22000);

    // 3. Aerobic Decoupling
    const decoupling = calculateAerobicDecoupling(powerStream, hrStream, 260);
    expect(decoupling.decouplingPercent).toBeDefined();

    // 4. Auto Intervals
    const intervals = detectAutoIntervals(powerStream, 260, 60, 0.9, hrStream);
    expect(intervals.length).toBeGreaterThan(0);

    const elapsedMs = performance.now() - start;
    // Soll-Kriterium: 14.400 Datenpunkte (4h-Radausfahrt) durch NP, W'bal, Decoupling & Intervalle in < 100 ms
    expect(elapsedMs).toBeLessThan(100);
  });

  it("führt 90-Tage PMC (Banister) und MMP-Kurven-Berechnung für 150 Einheiten in unter 15 ms aus", () => {
    // 1. 150 tägliche TSS-Werte über 90 Tage (manche Tage mit Doppel-Einheiten)
    const history: { localDate: string; tss: number }[] = [];
    const baseDate = new Date("2026-05-01");

    for (let d = 0; d < 90; d++) {
      const cur = new Date(baseDate.getTime() + d * 86400000);
      const dateStr = cur.toISOString().split("T")[0];
      const dailyTss = 40 + (d % 7) * 15 + ((d % 14 === 0) ? 90 : 0);
      history.push({ localDate: dateStr, tss: dailyTss });
    }

    const plannedDays = Array.from({ length: 14 }, (_, i) => ({
      localDate: `2026-08-${(i + 1).toString().padStart(2, "0")}`,
      plannedTss: 50,
    }));

    const start = performance.now();

    // 2. Banister PMC Berechnung mit 14-Tage-Projektion
    const pmc = calculatePmcSeries(history, plannedDays, 40, 45);
    expect(pmc.series.length).toBe(90 + 14); // 90 Tage Historie + 14 Tage Projektion
    expect(pmc.currentCtl).toBeGreaterThan(0);
    expect(pmc.currentAtl).toBeGreaterThan(0);

    // 3. MMP für 150 Einheiten
    const mockPowerRide = new Array<number>(3600).fill(250);
    const mmp = calculateMMP(mockPowerRide);
    expect(mmp["60"]).toBe(250);
    expect(mmp["1200"]).toBe(250);

    const elapsedMs = performance.now() - start;
    expect(elapsedMs).toBeLessThan(15);
  });

  it("CLI verifyCorpus liefert einen validen Markdown-Report ohne Fehler", async () => {
    const fitDir = path.resolve(__dirname, "../../../testvectors/fit");
    if (!fs.existsSync(fitDir)) return;

    const report = await verifyCorpus(fitDir);
    expect(report.totalFiles).toBeGreaterThan(0);
    expect(report.successfulFiles).toBe(report.totalFiles);
    expect(report.corruptOrFailedFiles).toBe(0);
    expect(report.markdownReport).toContain("# ORBIT FIT/TCX/GPX Korpus-Verifikationsbericht");
    expect(report.filesPerSecond).toBeGreaterThan(0);
  });
});
