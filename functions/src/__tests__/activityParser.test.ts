import * as fs from "fs";
import * as path from "path";
import * as zlib from "zlib";
import { parseActivityBuffer } from "../import/activityParser";

describe("Universal Activity Parser (.fit, .tcx, .gpx)", () => {
  const sampleFitPath = path.resolve(__dirname, "../../../testvectors/fit/2026-05-16-12-08-46.fit");

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("parst eine echte FIT-Datei fehlerfrei und liefert 1Hz-Streams", async () => {
    if (!fs.existsSync(sampleFitPath)) {
      console.warn("Testvektor FIT nicht gefunden:", sampleFitPath);
      return;
    }

    const fitBuffer = fs.readFileSync(sampleFitPath);
    const parsed = await parseActivityBuffer(fitBuffer, "activity.fit");

    expect(parsed.sport).toBeDefined();
    expect(parsed.durationSec).toBeGreaterThan(0);
    expect(parsed.startTimeUtcSec).toBeGreaterThan(0);
    expect(parsed.localDate).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(parsed.streams.time.length).toBeGreaterThan(0);
  });

  it("parst eine gestichelte / gzippte FIT-Datei (.fit.gz)", async () => {
    if (!fs.existsSync(sampleFitPath)) return;

    const fitBuffer = fs.readFileSync(sampleFitPath);
    const gzippedBuffer = zlib.gzipSync(fitBuffer);

    const parsed = await parseActivityBuffer(gzippedBuffer, "activity.fit.gz");
    expect(parsed.durationSec).toBeGreaterThan(0);
    expect(parsed.streams.time.length).toBeGreaterThan(0);
  });

  it("parst eine TCX-Datei (Training Center XML) inkl. Herzfrequenz, Leistung und Trittfrequenz", async () => {
    const tcxSample = `<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
  <Activities>
    <Activity Sport="Biking">
      <Id>2026-10-14T08:00:00.000Z</Id>
      <Lap StartTime="2026-10-14T08:00:00.000Z">
        <TotalTimeSeconds>120.0</TotalTimeSeconds>
        <DistanceMeters>1000.0</DistanceMeters>
        <MaximumSpeed>10.0</MaximumSpeed>
        <Calories>40</Calories>
        <AverageHeartRateBpm><Value>140</Value></AverageHeartRateBpm>
        <MaximumHeartRateBpm><Value>155</Value></MaximumHeartRateBpm>
        <Track>
          <Trackpoint>
            <Time>2026-10-14T08:00:00.000Z</Time>
            <Position>
              <LatitudeDegrees>50.1109</LatitudeDegrees>
              <LongitudeDegrees>8.6821</LongitudeDegrees>
            </Position>
            <AltitudeMeters>120.0</AltitudeMeters>
            <DistanceMeters>0.0</DistanceMeters>
            <HeartRateBpm><Value>135</Value></HeartRateBpm>
            <Cadence>85</Cadence>
            <Extensions>
              <ns3:TPX xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
                <ns3:Speed>8.0</ns3:Speed>
                <ns3:Watts>210</ns3:Watts>
              </ns3:TPX>
            </Extensions>
          </Trackpoint>
          <Trackpoint>
            <Time>2026-10-14T08:01:00.000Z</Time>
            <Position>
              <LatitudeDegrees>50.1120</LatitudeDegrees>
              <LongitudeDegrees>8.6840</LongitudeDegrees>
            </Position>
            <AltitudeMeters>125.0</AltitudeMeters>
            <DistanceMeters>500.0</DistanceMeters>
            <HeartRateBpm><Value>145</Value></HeartRateBpm>
            <Cadence>90</Cadence>
            <Extensions>
              <ns3:TPX xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
                <ns3:Speed>8.5</ns3:Speed>
                <ns3:Watts>230</ns3:Watts>
              </ns3:TPX>
            </Extensions>
          </Trackpoint>
        </Track>
      </Lap>
    </Activity>
  </Activities>
</TrainingCenterDatabase>`;

    const tcxBuffer = Buffer.from(tcxSample, "utf-8");
    const parsed = await parseActivityBuffer(tcxBuffer, "ride.tcx");

    expect(parsed.sport).toBe("BIKE");
    expect(parsed.distanceM).toBe(1000);
    expect(parsed.durationSec).toBe(120);
    expect(parsed.summary.avgHr).toBe(140);
    expect(parsed.summary.avgPowerW).toBe(220);
    expect(parsed.summary.maxPowerW).toBe(230);
    expect(parsed.summary.avgCadence).toBe(88);
    expect(parsed.streams.power[0]).toBe(210);
    expect(parsed.streams.power[60]).toBe(230);
  });

  it("parst eine GPX-Datei (GPS Exchange) inkl. Trackpoints, Höhe und Wattwerten", async () => {
    const gpxSample = `<?xml version="1.0" encoding="UTF-8"?>
<gpx creator="SRM / Strava" version="1.1" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">
  <trk>
    <name>Morning Interval Ride</name>
    <type>Cycling</type>
    <trkseg>
      <trkpt lat="50.1109" lon="8.6821">
        <ele>110.0</ele>
        <time>2026-10-14T09:00:00Z</time>
        <extensions>
          <power>250</power>
          <gpxtpx:TrackPointExtension>
            <gpxtpx:hr>142</gpxtpx:hr>
            <gpxtpx:cad>92</gpxtpx:cad>
            <gpxtpx:speed>9.0</gpxtpx:speed>
          </gpxtpx:TrackPointExtension>
        </extensions>
      </trkpt>
      <trkpt lat="50.1150" lon="8.6870">
        <ele>115.0</ele>
        <time>2026-10-14T09:00:30Z</time>
        <extensions>
          <power>290</power>
          <gpxtpx:TrackPointExtension>
            <gpxtpx:hr>158</gpxtpx:hr>
            <gpxtpx:cad>95</gpxtpx:cad>
            <gpxtpx:speed>9.8</gpxtpx:speed>
          </gpxtpx:TrackPointExtension>
        </extensions>
      </trkpt>
    </trkseg>
  </trk>
</gpx>`;

    const gpxBuffer = Buffer.from(gpxSample, "utf-8");
    const parsed = await parseActivityBuffer(gpxBuffer, "ride.gpx");

    expect(parsed.sport).toBe("BIKE");
    expect(parsed.title).toBe("Morning Interval Ride");
    expect(parsed.durationSec).toBe(30);
    expect(parsed.distanceM).toBeGreaterThan(0);
    expect(parsed.summary.avgHr).toBe(150);
    expect(parsed.summary.maxHr).toBe(158);
    expect(parsed.summary.avgPowerW).toBe(270);
    expect(parsed.summary.maxPowerW).toBe(290);
    expect(parsed.streams.power[0]).toBe(250);
    expect(parsed.streams.power[30]).toBe(290);
    expect(parsed.laps).toHaveLength(1);
  });

  it("parseActivityAndSave speichert .fit, .tcx und .gpx inkl. GZIP-Streams, Laps und erkennt Duplikate", async () => {
    const admin = await import("firebase-admin");
    const { parseActivityAndSave } = await import("../import/activityParser");

    const storedActivities: Record<string, any> = {};
    const storedStreams: Record<string, Buffer> = {};

    jest.spyOn(admin, "storage").mockReturnValue({
      bucket: jest.fn(() => ({
        file: jest.fn((p: string) => ({
          save: jest.fn(async (buf: Buffer) => {
            storedStreams[p] = buf;
          }),
        })),
      })),
    } as any);

    jest.spyOn(admin, "firestore").mockReturnValue({
      collection: jest.fn((colName: string) => {
        if (colName === "activities") {
          return {
            where: jest.fn((field: string, _op: string, val: any) => ({
              where: jest.fn((field2: string, _op2: string, val2: any) => ({
                limit: jest.fn(() => ({
                  get: jest.fn(async () => {
                    const matchEntry = Object.entries(storedActivities).find(
                      ([, d]) => d[field] === val && d[field2] === val2
                    );
                    if (!matchEntry) return { empty: true, docs: [] };
                    return {
                      empty: false,
                      docs: [{ id: matchEntry[0], data: () => matchEntry[1] }],
                    };
                  }),
                })),
              })),
            })),
            doc: jest.fn((id: string) => ({
              set: jest.fn(async (data: any) => {
                storedActivities[id] = { ...(storedActivities[id] || {}), ...data };
              }),
            })),
          };
        }
        return {
          doc: jest.fn(() => ({
            get: jest.fn().mockResolvedValue({ exists: false, data: () => ({}) }),
          })),
        };
      }),
    } as any);

    // 1. FIT-Datei speichern
    if (fs.existsSync(sampleFitPath)) {
      const fitBuffer = fs.readFileSync(sampleFitPath);
      const fitRes = await parseActivityAndSave("u_test", "act_fit_1", fitBuffer, "FIT_UPLOAD", "workout.fit");
      expect(fitRes.activityId).toBe("act_fit_1");
      expect(fitRes.isDuplicate).toBe(false);
      expect(storedActivities["act_fit_1"].streamsPath).toBe("users/u_test/streams/act_fit_1.json.gz");
      expect(storedActivities["act_fit_1"].laps.length).toBeGreaterThan(0);

      // Duplikat-Prüfung bei erneutem Upload derselben Einheit
      const dupRes = await parseActivityAndSave("u_test", "act_fit_dup", fitBuffer, "FIT_UPLOAD", "workout.fit");
      expect(dupRes.isDuplicate).toBe(true);
      expect(dupRes.activityId).toBe("act_fit_1");
    }

    // 2. TCX-Datei speichern
    const tcxXml = `<TrainingCenterDatabase><Activities><Activity Sport="Running"><Id>2026-10-15T10:00:00Z</Id><Lap StartTime="2026-10-15T10:00:00Z"><TotalTimeSeconds>60</TotalTimeSeconds><DistanceMeters>250</DistanceMeters><Track><Trackpoint><Time>2026-10-15T10:00:00Z</Time><HeartRateBpm><Value>150</Value></HeartRateBpm></Trackpoint></Track></Lap></Activity></Activities></TrainingCenterDatabase>`;
    const tcxRes = await parseActivityAndSave("u_test", "act_tcx_1", Buffer.from(tcxXml, "utf-8"), "TCX_UPLOAD", "run.tcx");
    expect(tcxRes.activityId).toBe("act_tcx_1");
    expect(storedActivities["act_tcx_1"].sport).toBe("RUN");
    expect(storedActivities["act_tcx_1"].laps).toHaveLength(1);
    expect(storedStreams["users/u_test/streams/act_tcx_1.json.gz"]).toBeDefined();

    // 3. GPX-Datei speichern
    const gpxXml = `<gpx version="1.1"><trk><name>Alpine Ride</name><type>Cycling</type><trkseg><trkpt lat="47.1" lon="11.1"><ele>800</ele><time>2026-10-15T12:00:00Z</time></trkpt><trkpt lat="47.105" lon="11.105"><ele>820</ele><time>2026-10-15T12:01:00Z</time></trkpt></trkseg></trk></gpx>`;
    const gpxRes = await parseActivityAndSave("u_test", "act_gpx_1", Buffer.from(gpxXml, "utf-8"), "GPX_UPLOAD", "ride.gpx");
    expect(gpxRes.activityId).toBe("act_gpx_1");
    expect(storedActivities["act_gpx_1"].sport).toBe("BIKE");
    expect(storedActivities["act_gpx_1"].laps).toHaveLength(1);
    expect(storedStreams["users/u_test/streams/act_gpx_1.json.gz"]).toBeDefined();
  });
});
