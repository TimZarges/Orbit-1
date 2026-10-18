import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import * as zlib from "zlib";
import * as crypto from "crypto";
import { XMLParser } from "fast-xml-parser";

export interface ActivityLap {
  index: number;
  startTimeUtcSec: number;
  durationSec: number;
  distanceM: number;
  avgHr?: number;
  maxHr?: number;
  avgPowerW?: number;
  maxPowerW?: number;
  avgCadence?: number;
  avgSpeedMps?: number;
  elevationGainM?: number;
}

export interface ActivityStreams {
  version: number;
  sampleRateSec: number;
  length: number;
  time: (number | null)[];
  heartRate: (number | null)[];
  power: (number | null)[];
  cadence: (number | null)[];
  speed: (number | null)[];
  altitude: (number | null)[];
  positionLat: (number | null)[];
  positionLng: (number | null)[];
  temperature: (number | null)[];
  coreTemperature: (number | null)[];
  leftRightBalance: (number | null)[];
  stanceTime: (number | null)[];
  verticalOscillation: (number | null)[];
  stepLength: (number | null)[];
}

export interface ParsedActivityData {
  sport: string;
  subSport?: string;
  title: string;
  startTimeUtcSec: number;
  utcOffsetMinutes: number;
  localDate: string;
  durationSec: number;
  distanceM: number;
  summary: {
    avgHr?: number;
    maxHr?: number;
    avgPowerW?: number;
    maxPowerW?: number;
    avgCadence?: number;
    elevationGainM?: number;
    avgPaceSecPerKm?: number;
    steps?: number;
  };
  laps: ActivityLap[];
  streams: ActivityStreams;
}

/**
 * Erkennt automatisch das Format (.fit, .tcx, .gpx, inkl. .gz-Kompression)
 * und parst alle Zeitreihen (1Hz) sowie Summenwerte.
 */
export async function parseActivityBuffer(
  buffer: Buffer,
  hintFileName = ""
): Promise<ParsedActivityData> {
  // 1. Gzip-Dekomprimierung falls komprimiert
  let rawBuffer = buffer;
  if (
    (buffer.length >= 2 && buffer[0] === 0x1f && buffer[1] === 0x8b) ||
    hintFileName.endsWith(".gz")
  ) {
    rawBuffer = zlib.gunzipSync(buffer);
  }

  // 2. Format erkennen
  const isFit = isFitBuffer(rawBuffer, hintFileName);
  if (isFit) {
    return parseFitFile(rawBuffer);
  }

  const contentStr = rawBuffer.toString("utf-8");
  if (contentStr.includes("<TrainingCenterDatabase") || hintFileName.endsWith(".tcx")) {
    return parseTcxFile(contentStr);
  }

  if (contentStr.includes("<gpx") || hintFileName.endsWith(".gpx")) {
    return parseGpxFile(contentStr);
  }

  throw new Error("Unbekanntes oder nicht unterstütztes Aktivitätsformat (erwartet: .fit, .tcx, .gpx)");
}

function isFitBuffer(buf: Buffer, hint: string): boolean {
  if (hint.endsWith(".fit")) return true;
  if (buf.length >= 14) {
    const tag = buf.toString("ascii", 8, 12);
    if (tag === ".FIT") return true;
  }
  return false;
}

/**
 * Parst FIT-Dateien über das offizielle @garmin/fitsdk
 */
async function parseFitFile(buffer: Buffer): Promise<ParsedActivityData> {
  const { Decoder, Stream } = await import("@garmin/fitsdk");
  const stream = Stream.fromBuffer(new Uint8Array(buffer));
  const decoder = new Decoder(stream);

  if (!decoder.isFIT()) {
    throw new Error("Ungültige FIT-Datei");
  }

  const { messages, errors } = decoder.read({
    convertDateTimesToDates: false,
    applyScaleAndOffset: true,
    expandComponents: true,
    mergeHeartRates: true,
  });

  if (errors.length > 0) {
    logger.warn("FIT parsing warnings/errors:", errors);
  }

  const session = messages.sessionMesgs?.[0];
  if (!session) {
    throw new Error("Keine Session-Daten in der FIT-Datei gefunden");
  }

  const FIT_EPOCH_S = 631065600;
  const startTimeUtcSec = ((session.startTime as number) || 0) + FIT_EPOCH_S;
  const date = new Date(startTimeUtcSec * 1000);
  const localDate = date.toISOString().split("T")[0];
  const utcOffsetMinutes = 0;

  let sport = "OTHER";
  const rawSport = typeof session.sport === "string" ? session.sport.toLowerCase() : session.sport;
  if (rawSport === 1 || rawSport === "running" || rawSport === "run") {
    sport = "RUN";
  } else if (rawSport === 2 || rawSport === "cycling" || rawSport === "biking" || rawSport === "bike") {
    sport = "BIKE";
  } else if (rawSport === 5 || rawSport === "swimming" || rawSport === "swim") {
    sport = "SWIM";
  } else if (rawSport === 11 || rawSport === "training" || rawSport === "strength_training" || rawSport === "fitness_equipment") {
    sport = "STRENGTH";
  }

  const durationSec = Math.ceil((session.totalTimerTime as number) || (session.totalElapsedTime as number) || 0);
  const distanceM = Math.round((session.totalDistance as number) || 0);

  const streams = initStreams(durationSec);
  const records = messages.recordMesgs || [];

  for (const r of records) {
    if (!r.timestamp) continue;
    const t = (r.timestamp as number) + FIT_EPOCH_S;
    const offset = t - startTimeUtcSec;

    if (offset >= 0 && offset < durationSec * 2) {
      expandStreamsTo(streams, offset);

      streams.heartRate[offset] = (r.heartRate as number) ?? null;
      streams.power[offset] = (r.power as number) ?? null;
      streams.cadence[offset] = (r.cadence as number) ?? null;
      streams.speed[offset] = (r.enhancedSpeed as number) ?? (r.speed as number) ?? null;
      streams.altitude[offset] = (r.enhancedAltitude as number) ?? (r.altitude as number) ?? null;

      if (r.positionLat) streams.positionLat[offset] = (r.positionLat as number) * (180.0 / 2147483648.0);
      if (r.positionLong) streams.positionLng[offset] = (r.positionLong as number) * (180.0 / 2147483648.0);

      streams.temperature[offset] = (r.temperature as number) ?? null;
      streams.coreTemperature[offset] = (r.coreTemperature as number) ?? null;
      streams.leftRightBalance[offset] = (r.leftRightBalance as number) ?? null;
      streams.stanceTime[offset] = (r.stanceTime as number) ?? null;
      streams.verticalOscillation[offset] = (r.verticalOscillation as number) ?? null;
      streams.stepLength[offset] = (r.stepLength as number) ?? null;
    }
  }

  streams.length = streams.time.length;

  const rawFitLaps = messages.lapMesgs || [];
  const fitLaps: ActivityLap[] = rawFitLaps.map((lap: any, idx: number) => ({
    index: idx + 1,
    startTimeUtcSec: ((lap.startTime as number) || (session.startTime as number) || 0) + FIT_EPOCH_S,
    durationSec: Math.round((lap.totalTimerTime as number) || (lap.totalElapsedTime as number) || 0),
    distanceM: Math.round((lap.totalDistance as number) || 0),
    avgHr: lap.avgHeartRate as number | undefined,
    maxHr: lap.maxHeartRate as number | undefined,
    avgPowerW: lap.avgPower as number | undefined,
    maxPowerW: lap.maxPower as number | undefined,
    avgCadence: lap.avgCadence as number | undefined,
    avgSpeedMps: (lap.enhancedAvgSpeed as number | undefined) ?? (lap.avgSpeed as number | undefined),
    elevationGainM: lap.totalAscent as number | undefined,
  }));

  if (fitLaps.length === 0) {
    fitLaps.push({
      index: 1,
      startTimeUtcSec,
      durationSec,
      distanceM,
      avgHr: session.avgHeartRate as number | undefined,
      maxHr: session.maxHeartRate as number | undefined,
      avgPowerW: session.avgPower as number | undefined,
      maxPowerW: session.maxPower as number | undefined,
      avgCadence: session.avgCadence as number | undefined,
      avgSpeedMps: session.avgSpeed as number | undefined,
      elevationGainM: session.totalAscent as number | undefined,
    });
  }

  return {
    sport,
    title: `Import ${sport}`,
    startTimeUtcSec,
    utcOffsetMinutes,
    localDate,
    durationSec,
    distanceM,
    summary: {
      avgHr: session.avgHeartRate as number | undefined,
      maxHr: session.maxHeartRate as number | undefined,
      avgPowerW: session.avgPower as number | undefined,
      maxPowerW: session.maxPower as number | undefined,
      avgCadence: session.avgCadence as number | undefined,
      elevationGainM: session.totalAscent as number | undefined,
      avgPaceSecPerKm: session.avgSpeed ? Math.round(1000 / (session.avgSpeed as number)) : undefined,
    },
    laps: fitLaps,
    streams,
  };
}

/**
 * Parst Garmin Training Center XML (.tcx) Dateien (z. B. Wahoo, Garmin, Polar).
 */
function parseTcxFile(xmlContent: string): ParsedActivityData {
  const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: "@_",
    removeNSPrefix: false,
    parseTagValue: true,
  });

  const parsed = parser.parse(xmlContent);
  const tc = parsed.TrainingCenterDatabase || parsed;
  const activities = tc.Activities?.Activity;
  const activity = Array.isArray(activities) ? activities[0] : activities;

  if (!activity) {
    throw new Error("Keine Aktivität in TCX-Datei gefunden");
  }

  // Sport ermitteln
  const rawSport = (activity["@_Sport"] || "Other").toUpperCase();
  let sport = "OTHER";
  if (rawSport.includes("BIK") || rawSport.includes("CYCL")) sport = "BIKE";
  else if (rawSport.includes("RUN")) sport = "RUN";
  else if (rawSport.includes("SWIM")) sport = "SWIM";

  // Laps extrahieren
  const rawLaps = activity.Lap;
  const laps = Array.isArray(rawLaps) ? rawLaps : (rawLaps ? [rawLaps] : []);

  let totalTimeSec = 0;
  let totalDistanceM = 0;
  let firstTimeStr = activity.Id;

  // Trackpoints aggregieren
  interface RawTcxPoint {
    time: number;
    hr?: number;
    cadence?: number;
    watts?: number;
    speed?: number;
    altitude?: number;
    lat?: number;
    lng?: number;
  }

  const points: RawTcxPoint[] = [];
  const parsedLaps: ActivityLap[] = [];

  for (let lapIdx = 0; lapIdx < laps.length; lapIdx++) {
    const lap = laps[lapIdx];
    const lapTimeSec = Number(lap.TotalTimeSeconds || 0);
    const lapDistM = Number(lap.DistanceMeters || 0);
    totalTimeSec += lapTimeSec;
    totalDistanceM += lapDistM;

    const lapStartStr = lap["@_StartTime"] || firstTimeStr;
    const lapStartSec = lapStartStr ? Math.floor(new Date(lapStartStr).getTime() / 1000) : 0;

    parsedLaps.push({
      index: lapIdx + 1,
      startTimeUtcSec: isNaN(lapStartSec) ? 0 : lapStartSec,
      durationSec: Math.round(lapTimeSec),
      distanceM: Math.round(lapDistM),
      avgHr: lap.AverageHeartRateBpm?.Value !== undefined ? Number(lap.AverageHeartRateBpm.Value) : undefined,
      maxHr: lap.MaximumHeartRateBpm?.Value !== undefined ? Number(lap.MaximumHeartRateBpm.Value) : undefined,
      avgCadence: lap.Cadence !== undefined ? Number(lap.Cadence) : undefined,
    });

    const tracks = lap.Track;
    const trackList = Array.isArray(tracks) ? tracks : (tracks ? [tracks] : []);

    for (const track of trackList) {
      const rawPoints = track.Trackpoint;
      const pointList = Array.isArray(rawPoints) ? rawPoints : (rawPoints ? [rawPoints] : []);

      for (const pt of pointList) {
        if (!pt.Time) continue;
        if (!firstTimeStr) firstTimeStr = pt.Time;

        const timeSec = Math.floor(new Date(pt.Time).getTime() / 1000);
        if (isNaN(timeSec)) continue;

        const hr = pt.HeartRateBpm?.Value !== undefined ? Number(pt.HeartRateBpm.Value) : undefined;
        const cadence = pt.Cadence !== undefined ? Number(pt.Cadence) : undefined;
        const altitude = pt.AltitudeMeters !== undefined ? Number(pt.AltitudeMeters) : undefined;
        const lat = pt.Position?.LatitudeDegrees !== undefined ? Number(pt.Position.LatitudeDegrees) : undefined;
        const lng = pt.Position?.LongitudeDegrees !== undefined ? Number(pt.Position.LongitudeDegrees) : undefined;

        // Extensions (Garmin Watts / TPX)
        let watts: number | undefined;
        let speed: number | undefined;

        const extensions = pt.Extensions;
        if (extensions) {
          const tpx = extensions["ns3:TPX"] || extensions.TPX || extensions;
          if (tpx["ns3:Watts"] !== undefined) watts = Number(tpx["ns3:Watts"]);
          else if (tpx.Watts !== undefined) watts = Number(tpx.Watts);

          if (tpx["ns3:Speed"] !== undefined) speed = Number(tpx["ns3:Speed"]);
          else if (tpx.Speed !== undefined) speed = Number(tpx.Speed);
        }

        points.push({ time: timeSec, hr, cadence, watts, speed, altitude, lat, lng });
      }
    }
  }

  if (points.length === 0 && totalTimeSec === 0) {
    throw new Error("TCX-Datei enthält weder Trackpoints noch Laps");
  }

  points.sort((a, b) => a.time - b.time);
  const startTimeUtcSec = points.length > 0 ? points[0].time : Math.floor(new Date(firstTimeStr).getTime() / 1000);
  const durationSec = Math.max(Math.ceil(totalTimeSec), points.length > 0 ? points[points.length - 1].time - startTimeUtcSec : 0);

  const localDate = new Date(startTimeUtcSec * 1000).toISOString().split("T")[0];
  const streams = initStreams(durationSec);

  let hrSum = 0;
  let hrCount = 0;
  let maxHr = 0;
  let powerSum = 0;
  let powerCount = 0;
  let maxPower = 0;
  let cadSum = 0;
  let cadCount = 0;
  let elevationGain = 0;
  let prevAlt: number | null = null;

  for (const pt of points) {
    const offset = pt.time - startTimeUtcSec;
    if (offset >= 0 && offset < durationSec * 2) {
      expandStreamsTo(streams, offset);

      if (pt.hr !== undefined) {
        streams.heartRate[offset] = pt.hr;
        hrSum += pt.hr;
        hrCount++;
        if (pt.hr > maxHr) maxHr = pt.hr;
      }
      if (pt.watts !== undefined) {
        streams.power[offset] = pt.watts;
        powerSum += pt.watts;
        powerCount++;
        if (pt.watts > maxPower) maxPower = pt.watts;
      }
      if (pt.cadence !== undefined) {
        streams.cadence[offset] = pt.cadence;
        cadSum += pt.cadence;
        cadCount++;
      }
      if (pt.speed !== undefined) streams.speed[offset] = pt.speed;
      if (pt.altitude !== undefined) {
        streams.altitude[offset] = pt.altitude;
        if (prevAlt !== null && pt.altitude > prevAlt) {
          elevationGain += (pt.altitude - prevAlt);
        }
        prevAlt = pt.altitude;
      }
      if (pt.lat !== undefined) streams.positionLat[offset] = pt.lat;
      if (pt.lng !== undefined) streams.positionLng[offset] = pt.lng;
    }
  }

  streams.length = streams.time.length;

  return {
    sport,
    title: `Import ${sport} (TCX)`,
    startTimeUtcSec,
    utcOffsetMinutes: 0,
    localDate,
    durationSec,
    distanceM: Math.round(totalDistanceM),
    summary: {
      avgHr: hrCount > 0 ? Math.round(hrSum / hrCount) : undefined,
      maxHr: maxHr > 0 ? maxHr : undefined,
      avgPowerW: powerCount > 0 ? Math.round(powerSum / powerCount) : undefined,
      maxPowerW: maxPower > 0 ? maxPower : undefined,
      avgCadence: cadCount > 0 ? Math.round(cadSum / cadCount) : undefined,
      elevationGainM: elevationGain > 0 ? Math.round(elevationGain) : undefined,
      avgPaceSecPerKm: totalDistanceM > 0 && durationSec > 0 ? Math.round((durationSec / totalDistanceM) * 1000) : undefined,
    },
    laps: parsedLaps,
    streams,
  };
}

/**
 * Parst GPS Exchange Format (.gpx) Dateien (z. B. SRM, Strava, Garmin).
 */
function parseGpxFile(xmlContent: string): ParsedActivityData {
  const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: "@_",
    removeNSPrefix: false,
    parseTagValue: true,
  });

  const parsed = parser.parse(xmlContent);
  const gpx = parsed.gpx || parsed;
  const tracks = gpx.trk;
  const track = Array.isArray(tracks) ? tracks[0] : tracks;

  if (!track) {
    throw new Error("Kein Track (trk) in GPX-Datei gefunden");
  }

  const trackName = track.name || "GPX Aktivität";
  const rawType = (track.type || "Other").toUpperCase();
  let sport = "OTHER";
  if (rawType.includes("CYCL") || rawType.includes("BIK") || trackName.toUpperCase().includes("RIDE") || trackName.toUpperCase().includes("RAD")) {
    sport = "BIKE";
  } else if (rawType.includes("RUN") || trackName.toUpperCase().includes("LAUF")) {
    sport = "RUN";
  }

  const segments = track.trkseg;
  const segList = Array.isArray(segments) ? segments : (segments ? [segments] : []);

  interface RawGpxPoint {
    time: number;
    lat: number;
    lng: number;
    ele?: number;
    hr?: number;
    cadence?: number;
    power?: number;
    temp?: number;
    speed?: number;
  }

  const points: RawGpxPoint[] = [];

  for (const seg of segList) {
    const rawPoints = seg.trkpt;
    const ptList = Array.isArray(rawPoints) ? rawPoints : (rawPoints ? [rawPoints] : []);

    for (const pt of ptList) {
      if (!pt.time) continue;
      const timeSec = Math.floor(new Date(pt.time).getTime() / 1000);
      if (isNaN(timeSec)) continue;

      const lat = Number(pt["@_lat"]);
      const lng = Number(pt["@_lon"]);
      const ele = pt.ele !== undefined ? Number(pt.ele) : undefined;

      let hr: number | undefined;
      let cadence: number | undefined;
      let power: number | undefined;
      let temp: number | undefined;
      let speed: number | undefined;

      // Extensions
      const ext = pt.extensions;
      if (ext) {
        if (ext.power !== undefined) power = Number(ext.power);
        else if (ext["gpxtpx:power"] !== undefined) power = Number(ext["gpxtpx:power"]);
        else if (ext.watts !== undefined) power = Number(ext.watts);

        const tpx = ext["gpxtpx:TrackPointExtension"] || ext.TrackPointExtension || ext;
        if (tpx["gpxtpx:hr"] !== undefined) hr = Number(tpx["gpxtpx:hr"]);
        else if (tpx.hr !== undefined) hr = Number(tpx.hr);

        if (tpx["gpxtpx:cad"] !== undefined) cadence = Number(tpx["gpxtpx:cad"]);
        else if (tpx.cad !== undefined) cadence = Number(tpx.cad);

        if (tpx["gpxtpx:atemp"] !== undefined) temp = Number(tpx["gpxtpx:atemp"]);
        else if (tpx.atemp !== undefined) temp = Number(tpx.atemp);

        if (tpx["gpxtpx:speed"] !== undefined) speed = Number(tpx["gpxtpx:speed"]);
        else if (tpx.speed !== undefined) speed = Number(tpx.speed);
      }

      points.push({ time: timeSec, lat, lng, ele, hr, cadence, power, temp, speed });
    }
  }

  if (points.length === 0) {
    throw new Error("GPX-Datei enthält keine gültigen Trackpoints mit Zeitstempel");
  }

  points.sort((a, b) => a.time - b.time);
  const startTimeUtcSec = points[0].time;
  const durationSec = Math.max(1, points[points.length - 1].time - startTimeUtcSec);
  const localDate = new Date(startTimeUtcSec * 1000).toISOString().split("T")[0];

  const streams = initStreams(durationSec);

  let hrSum = 0;
  let hrCount = 0;
  let maxHr = 0;
  let powerSum = 0;
  let powerCount = 0;
  let maxPower = 0;
  let cadSum = 0;
  let cadCount = 0;
  let elevationGain = 0;
  let prevAlt: number | null = null;
  let totalDistanceM = 0;
  let prevLat: number | null = null;
  let prevLng: number | null = null;

  for (const pt of points) {
    const offset = pt.time - startTimeUtcSec;
    if (offset >= 0 && offset < durationSec * 2) {
      expandStreamsTo(streams, offset);

      streams.positionLat[offset] = pt.lat;
      streams.positionLng[offset] = pt.lng;

      if (prevLat !== null && prevLng !== null) {
        totalDistanceM += haversineDistanceM(prevLat, prevLng, pt.lat, pt.lng);
      }
      prevLat = pt.lat;
      prevLng = pt.lng;

      if (pt.ele !== undefined) {
        streams.altitude[offset] = pt.ele;
        if (prevAlt !== null && pt.ele > prevAlt) {
          elevationGain += (pt.ele - prevAlt);
        }
        prevAlt = pt.ele;
      }
      if (pt.hr !== undefined) {
        streams.heartRate[offset] = pt.hr;
        hrSum += pt.hr;
        hrCount++;
        if (pt.hr > maxHr) maxHr = pt.hr;
      }
      if (pt.power !== undefined) {
        streams.power[offset] = pt.power;
        powerSum += pt.power;
        powerCount++;
        if (pt.power > maxPower) maxPower = pt.power;
      }
      if (pt.cadence !== undefined) {
        streams.cadence[offset] = pt.cadence;
        cadSum += pt.cadence;
        cadCount++;
      }
      if (pt.temp !== undefined) streams.temperature[offset] = pt.temp;
      if (pt.speed !== undefined) streams.speed[offset] = pt.speed;
    }
  }

  streams.length = streams.time.length;

  const avgHr = hrCount > 0 ? Math.round(hrSum / hrCount) : undefined;
  const maxHrVal = maxHr > 0 ? maxHr : undefined;
  const avgPowerW = powerCount > 0 ? Math.round(powerSum / powerCount) : undefined;
  const maxPowerW = maxPower > 0 ? maxPower : undefined;
  const avgCadence = cadCount > 0 ? Math.round(cadSum / cadCount) : undefined;
  const elevationGainM = elevationGain > 0 ? Math.round(elevationGain) : undefined;

  return {
    sport,
    title: trackName,
    startTimeUtcSec,
    utcOffsetMinutes: 0,
    localDate,
    durationSec,
    distanceM: Math.round(totalDistanceM),
    summary: {
      avgHr,
      maxHr: maxHrVal,
      avgPowerW,
      maxPowerW,
      avgCadence,
      elevationGainM,
      avgPaceSecPerKm: totalDistanceM > 0 && durationSec > 0 ? Math.round((durationSec / totalDistanceM) * 1000) : undefined,
    },
    laps: [
      {
        index: 1,
        startTimeUtcSec,
        durationSec,
        distanceM: Math.round(totalDistanceM),
        avgHr,
        maxHr: maxHrVal,
        avgPowerW,
        maxPowerW,
        avgCadence,
        elevationGainM,
      },
    ],
    streams,
  };
}

/**
 * Prüft, ob für den Athleten eine aktive Trainer-Verknüpfung mit Aktivitäten-Freigabe existiert.
 */
export async function getActiveCoachIdForActivities(uid: string): Promise<string | null> {
  try {
    const db = admin.firestore();
    const userDoc = await db.collection("users").doc(uid).get();
    const coachId = userDoc.data()?.coachId;
    if (!coachId || typeof coachId !== "string") return null;

    const linkDoc = await db.collection("coachLinks").doc(`${uid}_${coachId}`).get();
    if (!linkDoc.exists) return null;
    const linkData = linkDoc.data();
    if (linkData?.status === "ACTIVE" && linkData?.permissions?.activities === true) {
      return coachId;
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * Universeller Import- und Speicherablauf für .fit, .tcx und .gpx.
 * Komprimiert Streams als .json.gz in Storage und legt Activity in Firestore ab.
 * Erkennt Duplikate per Hash aus (athleteId, startTime, duration, sportType).
 */
export async function parseActivityAndSave(
  uid: string,
  activityId: string,
  buffer: Buffer,
  source: "FIT_UPLOAD" | "TCX_UPLOAD" | "GPX_UPLOAD" | "GARMIN" | "DEMO",
  originalFileName = ""
): Promise<{ activityId: string; isDuplicate: boolean }> {
  const parsed = await parseActivityBuffer(buffer, originalFileName);

  const db = admin.firestore();

  // 1. Duplikat-Hash berechnen: sha256(athleteId_startTime_duration_sport)
  const duplicateHash = crypto
    .createHash("sha256")
    .update(`${uid}_${parsed.startTimeUtcSec}_${Math.round(parsed.durationSec)}_${parsed.sport}`)
    .digest("hex");

  // Prüfung auf bestehendes Duplikat in Firestore
  const duplicateQuery = await db.collection("activities")
    .where("athleteId", "==", uid)
    .where("duplicateHash", "==", duplicateHash)
    .limit(1)
    .get();

  let targetActivityId = activityId;
  let isDuplicate = false;

  if (!duplicateQuery.empty) {
    targetActivityId = duplicateQuery.docs[0].id;
    isDuplicate = true;
    logger.info(`Duplikat erkannt für Aktivität ${targetActivityId} (Hash: ${duplicateHash})`);
  }

  // 2. Streams als GZIP in Storage speichern
  const streamJson = JSON.stringify(parsed.streams);
  const streamGz = zlib.gzipSync(Buffer.from(streamJson, "utf-8"));

  const bucket = admin.storage().bucket();
  const streamsPath = `users/${uid}/streams/${targetActivityId}.json.gz`;
  const streamFile = bucket.file(streamsPath);

  await streamFile.save(streamGz, {
    contentType: "application/gzip",
    metadata: { contentEncoding: "gzip" },
  });

  // 2b. Unveränderte Originaldatei in Cloud Storage archivieren (AGENTS.md Regel 32.2)
  const ext = originalFileName.toLowerCase().endsWith(".tcx") || originalFileName.toLowerCase().endsWith(".tcx.gz")
    ? "tcx"
    : originalFileName.toLowerCase().endsWith(".gpx") || originalFileName.toLowerCase().endsWith(".gpx.gz")
    ? "gpx"
    : "fit";
  const rawFilePath = `users/${uid}/rawActivities/${targetActivityId}.${ext}`;
  const rawFile = bucket.file(rawFilePath);
  await rawFile.save(buffer, {
    contentType: "application/octet-stream",
    metadata: {
      originalFileName,
      uploadedAt: new Date().toISOString(),
      athleteId: uid,
      activityId: targetActivityId,
    },
  });

  // Aktiven Coach mit Aktivitäten-Berechtigung ermitteln
  const activeCoachId = await getActiveCoachIdForActivities(uid);

  // 3. Aktivitäts-Dokument in Firestore anlegen/aktualisieren
  const activityData: Record<string, any> = {
    athleteId: uid,
    coachId: activeCoachId,
    startTimeUtc: Timestamp.fromMillis(parsed.startTimeUtcSec * 1000),
    utcOffsetMinutes: parsed.utcOffsetMinutes,
    localDate: parsed.localDate,
    sport: parsed.sport,
    title: parsed.title,
    source,
    externalId: targetActivityId,
    duplicateHash,
    durationSec: parsed.durationSec,
    distanceM: parsed.distanceM,
    summary: parsed.summary,
    laps: parsed.laps,
    streamsPath,
    rawFilePath,
    createdAt: FieldValue.serverTimestamp(),
    processing: { state: "READY" },
  };

  if (parsed.subSport) {
    activityData.subSport = parsed.subSport;
  }

  await db.collection("activities").doc(targetActivityId).set(activityData, { merge: true });

  return { activityId: targetActivityId, isDuplicate };
}

/**
 * Abwärtskompatibler Wrapper für parseFitAndSave
 */
export async function parseFitAndSave(
  uid: string,
  activityId: string,
  buffer: Buffer,
  source: "GARMIN" | "FIT_UPLOAD" | "DEMO"
) {
  return parseActivityAndSave(uid, activityId, buffer, source, "activity.fit");
}

// Hilfsfunktionen für Streams (auch für Garmin activityDetails wiederverwendbar)
export function initStreams(lengthSec: number): ActivityStreams {
  return {
    version: 1,
    sampleRateSec: 1,
    length: lengthSec,
    time: [] as (number | null)[],
    heartRate: [] as (number | null)[],
    power: [] as (number | null)[],
    cadence: [] as (number | null)[],
    speed: [] as (number | null)[],
    altitude: [] as (number | null)[],
    positionLat: [] as (number | null)[],
    positionLng: [] as (number | null)[],
    temperature: [] as (number | null)[],
    coreTemperature: [] as (number | null)[],
    leftRightBalance: [] as (number | null)[],
    stanceTime: [] as (number | null)[],
    verticalOscillation: [] as (number | null)[],
    stepLength: [] as (number | null)[],
  };
}

export function expandStreamsTo(streams: ActivityStreams, targetOffset: number) {
  while (streams.time.length <= targetOffset) {
    const idx = streams.time.length;
    streams.time.push(idx);
    streams.heartRate.push(null);
    streams.power.push(null);
    streams.cadence.push(null);
    streams.speed.push(null);
    streams.altitude.push(null);
    streams.positionLat.push(null);
    streams.positionLng.push(null);
    streams.temperature.push(null);
    streams.coreTemperature.push(null);
    streams.leftRightBalance.push(null);
    streams.stanceTime.push(null);
    streams.verticalOscillation.push(null);
    streams.stepLength.push(null);
  }
}

function haversineDistanceM(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
