import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';

export async function parseFitAndSave(
  uid: string,
  activityId: string,
  buffer: Buffer,
  source: 'GARMIN' | 'FIT_UPLOAD' | 'DEMO'
) {
  // Dynamically import the ESM fitsdk
  const { Decoder, Stream } = await import('@garmin/fitsdk');
  
  const stream = Stream.fromBuffer(new Uint8Array(buffer));
  const decoder = new Decoder(stream);
  
  if (!decoder.isFIT()) {
    throw new Error('Not a valid FIT file');
  }
  
  const { messages, errors } = decoder.read({
    convertDateTimesToDates: false, // We want raw timestamps (seconds since FIT epoch)
    applyScaleAndOffset: true,
    expandComponents: true,
    mergeHeartRates: true
  });
  
  if (errors.length > 0) {
    logger.warn('FIT parsing produced errors', errors);
  }
  
  // Find basic info
  const fileId = messages.fileIdMesgs?.[0];
  const session = messages.sessionMesgs?.[0];
  const records = messages.recordMesgs || [];
  
  if (!session) {
    throw new Error('No session message found in FIT file');
  }

  // FIT epoch is Dec 31, 1989, 00:00:00 UTC (631065600 seconds from Unix epoch)
  const FIT_EPOCH_S = 631065600;
  const startTimeUtcSec = (session.startTime as number) + FIT_EPOCH_S;
  
  // Compute local date & offset
  // We can try to use session.startTime if it's there, but standard FIT timestamps are UTC.
  // We'll calculate a dummy localDate for now since exact tz requires position lookup.
  const date = new Date(startTimeUtcSec * 1000);
  const localDate = date.toISOString().split('T')[0]; 
  const utcOffsetMinutes = 0; // Better: extract from device settings or profile timezone
  
  // Basic mapping
  const sport = 'OTHER'; // TODO: proper mapping based on session.sport
  
  // Collect streams
  const streams = {
    version: 1,
    sampleRateSec: 1,
    length: Math.ceil((session.totalElapsedTime || 0) as number),
    time: [] as (number | null)[],
    heartRate: [] as (number | null)[],
    power: [] as (number | null)[],
    cadence: [] as (number | null)[],
    speed: [] as (number | null)[],
    altitude: [] as (number | null)[],
    positionLat: [] as (number | null)[],
    positionLng: [] as (number | null)[],
    temperature: [] as (number | null)[],
    coreTemperature: [] as (number | null)[]
  };
  
  // Resample at 1Hz
  // To keep it simple, we iterate records. FIT usually logs at 1Hz or Smart Recording.
  // We will build a dense array where index = seconds since startTime.
  if (records.length > 0) {
    for (const r of records) {
      if (!r.timestamp) continue;
      const t = (r.timestamp as number) + FIT_EPOCH_S;
      const offset = t - startTimeUtcSec;
      
      if (offset >= 0 && offset < streams.length * 2) {
        // Expand length if necessary
        while (streams.time.length <= offset) {
          streams.time.push(streams.time.length);
          streams.heartRate.push(null);
          streams.power.push(null);
          streams.cadence.push(null);
          streams.speed.push(null);
          streams.altitude.push(null);
          streams.positionLat.push(null);
          streams.positionLng.push(null);
          streams.temperature.push(null);
          streams.coreTemperature.push(null);
        }
        
        streams.heartRate[offset] = r.heartRate as number ?? null;
        streams.power[offset] = r.power as number ?? null;
        streams.cadence[offset] = r.cadence as number ?? null;
        streams.speed[offset] = r.speed as number ?? null;
        streams.altitude[offset] = r.altitude as number ?? null;
        
        // Convert semicircles to degrees
        if (r.positionLat) streams.positionLat[offset] = (r.positionLat as number) * (180.0 / 2147483648.0);
        if (r.positionLong) streams.positionLng[offset] = (r.positionLong as number) * (180.0 / 2147483648.0);
        
        streams.temperature[offset] = r.temperature as number ?? null;
        streams.coreTemperature[offset] = r.coreTemperature as number ?? null;
      }
    }
  }
  
  // Write streams to storage
  const zlib = await import('zlib');
  const util = await import('util');
  const gzip = util.promisify(zlib.gzip);
  
  const streamJson = JSON.stringify(streams);
  const streamGz = await gzip(streamJson);
  
  const bucket = admin.storage().bucket();
  const streamsPath = `users/${uid}/streams/${activityId}.json.gz`;
  const streamFile = bucket.file(streamsPath);
  await streamFile.save(streamGz, {
    contentType: 'application/gzip',
    metadata: { contentEncoding: 'gzip' }
  });
  
  // Save to Firestore
  const db = admin.firestore();
  
  await db.collection('activities').doc(activityId).set({
    athleteId: uid,
    coachId: null, // Let coach sync function handle it later, or pull from user doc
    startTimeUtc: admin.firestore.Timestamp.fromMillis(startTimeUtcSec * 1000),
    utcOffsetMinutes,
    localDate,
    sport,
    title: 'Imported Activity', // Can be refined
    source,
    externalId: fileId?.serialNumber ? String(fileId.serialNumber) : activityId,
    durationSec: (session.totalTimerTime as number) || (session.totalElapsedTime as number) || 0,
    distanceM: (session.totalDistance as number) || 0,
    summary: {
      avgHr: session.avgHeartRate,
      maxHr: session.maxHeartRate,
      avgPowerW: session.avgPower,
      maxPowerW: session.maxPower,
      avgCadence: session.avgCadence,
      elevationGainM: session.totalAscent,
      avgPaceSecPerKm: session.avgSpeed ? (1000 / (session.avgSpeed as number)) : null,
    },
    streamsPath,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    processing: { state: 'READY' }
  }, { merge: true }); // Merge true to overwrite status
}
