import {
  mapGarminSport,
  garminWebhook,
  hasInlineSummaryData,
  resolveGarminWebhookItems,
  extractGarminStreamsAndLaps,
  handleGarminActivity,
} from "../import/garmin/webhook";
import {
  buildBackfillChunks,
  executeGarminBackfill,
  MAX_BACKFILL_CHUNK_DAYS,
} from "../import/garmin/backfill";
import * as admin from "firebase-admin";
import axios from "axios";
import * as crypto from "crypto";
import * as zlib from "zlib";

jest.mock("axios");
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe("Garmin Webhook, 3x30d Backfill Chunking, Ping/Push & ActivityDetails Streams", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("mappt Garmin Sportarten korrekt auf ORBIT Enums", () => {
    expect(mapGarminSport("CYCLING")).toEqual({ sport: "BIKE" });
    expect(mapGarminSport("ROAD_BIKING")).toEqual({ sport: "BIKE" });
    expect(mapGarminSport("RUNNING")).toEqual({ sport: "RUN" });
    expect(mapGarminSport("TRAIL_RUNNING")).toEqual({ sport: "RUN" });
    expect(mapGarminSport("LAP_SWIMMING")).toEqual({ sport: "SWIM", subSport: "POOL" });
    expect(mapGarminSport("OPEN_WATER_SWIMMING")).toEqual({ sport: "SWIM", subSport: "OPEN_WATER" });
    expect(mapGarminSport("STRENGTH_TRAINING")).toEqual({ sport: "STRENGTH" });
    expect(mapGarminSport("TRIATHLON")).toEqual({ sport: "MULTISPORT" });
    expect(mapGarminSport("UNKNOWN_SPORT")).toEqual({ sport: "OTHER" });
    expect(mapGarminSport(undefined)).toEqual({ sport: "OTHER" });
  });

  it("erzeugt deterministische Duplikat-Hashes für Aktivitäten", () => {
    const uid = "athlete_123";
    const startTimeSec = 1718000000;
    const durationSec = 3600;
    const sport = "BIKE";

    const hash1 = crypto
      .createHash("sha256")
      .update(`${uid}_${startTimeSec}_${durationSec}_${sport}`)
      .digest("hex");

    const hash2 = crypto
      .createHash("sha256")
      .update(`${uid}_${startTimeSec}_${durationSec}_${sport}`)
      .digest("hex");

    expect(hash1).toBe(hash2);
    expect(hash1).toHaveLength(64);
  });

  it("garminWebhook antwortet sofort mit HTTP 200 auf GET/HEAD Pings", async () => {
    let statusCode = 0;
    let sentData = "";

    const req = {
      method: "GET",
      body: {},
    } as any;

    const res = {
      status: (code: number) => {
        statusCode = code;
        return {
          send: (data: string) => {
            sentData = data;
          },
        };
      },
    } as any;

    await (garminWebhook as any)(req, res);

    expect(statusCode).toBe(200);
    expect(sentData).toBe("OK");
  });

  describe("1. 90-Tage-Backfill in <= 30-Tage-Chunks (backfill.ts)", () => {
    it("teilt 90 Tage exakt in 3 separate 30-Tage-Zeitfenster ([now-30d..now], [now-60d..now-30d], [now-90d..now-60d])", () => {
      const nowSec = 1729000000;
      const thirtyDaysSec = 30 * 24 * 60 * 60;
      const chunks = buildBackfillChunks(nowSec, 90);

      expect(chunks).toHaveLength(3);
      expect(chunks[0]).toEqual({
        startSec: nowSec - thirtyDaysSec,
        endSec: nowSec,
        days: 30,
      });
      expect(chunks[1]).toEqual({
        startSec: nowSec - 2 * thirtyDaysSec,
        endSec: nowSec - thirtyDaysSec,
        days: 30,
      });
      expect(chunks[2]).toEqual({
        startSec: nowSec - 3 * thirtyDaysSec,
        endSec: nowSec - 2 * thirtyDaysSec,
        days: 30,
      });

      for (const c of chunks) {
        expect(c.endSec - c.startSec).toBeLessThanOrEqual(MAX_BACKFILL_CHUNK_DAYS * 86400);
      }
    });

    it("executeGarminBackfill feuert für 90 Tage sequenziell 3 Chunks à 30 Tage ab und akzeptiert HTTP 202 Accepted", async () => {
      const setMock = jest.fn().mockResolvedValue(undefined);
      const getMock = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          garmin: {
            oauthToken: "user_token_123",
            oauthTokenSecret: "user_secret_456",
          },
        }),
      });

      jest.spyOn(admin, "firestore").mockReturnValue({
        collection: jest.fn(() => ({
          doc: jest.fn(() => ({
            collection: jest.fn(() => ({
              doc: jest.fn(() => ({
                get: getMock,
                set: setMock,
              })),
            })),
          })),
        })),
      } as any);

      // Garmin Backfill antwortet mit HTTP 202 Accepted (leerer Body)
      mockedAxios.get.mockResolvedValue({ status: 202, data: "" } as any);

      const nowSec = 1729000000;
      const result = await executeGarminBackfill(
        "uid_athlete_1",
        90,
        { key: "consumer_key", secret: "consumer_secret" },
        { delayMs: 0, nowSec }
      );

      expect(result.success).toBe(true);
      expect(result.chunksRequested).toBe(3);
      expect(result.chunks).toHaveLength(3);
      // 3 Chunks * 8 Endpunkte = 24 Requests
      expect(result.endpointsRequested).toBe(24);
      expect(mockedAxios.get).toHaveBeenCalledTimes(24);

      // Prüfe, dass keines der angefragten Zeitfenster > 30 Tage ist
      for (const call of mockedAxios.get.mock.calls) {
        const url = new URL(call[0]);
        const start = Number(url.searchParams.get("summaryStartTimeInSeconds"));
        const end = Number(url.searchParams.get("summaryEndTimeInSeconds"));
        expect(end - start).toBe(30 * 86400);
      }

      expect(setMock).toHaveBeenCalledWith(
        expect.objectContaining({
          backfill: expect.objectContaining({
            state: "IN_PROGRESS",
            targetDays: 90,
            chunksRequested: 3,
            endpointsRequested: 24,
          }),
        }),
        { merge: true }
      );
    });
  });

  describe("2. Ping (callbackURL) UND Push im Webhook (webhook.ts)", () => {
    it("unterscheidet Push-Items (Inline-Daten) von Ping-Items (callbackURL) und ruft Ping-URLs OAuth-signiert ab", async () => {
      const pushItem = {
        userId: "garmin_u1",
        summaryId: "act_inline_1",
        durationInSeconds: 1800,
        activityType: "RUNNING",
      };
      const pingItem = {
        userId: "garmin_u1",
        callbackURL: "https://apis.garmin.com/wellness-api/rest/activities?uploadStartTimeInSeconds=1700000000&uploadEndTimeInSeconds=1700003600",
      };

      expect(hasInlineSummaryData(pushItem)).toBe(true);
      expect(hasInlineSummaryData(pingItem)).toBe(false);

      // Mock Firestore für getUidForGarminUser + OAuth Token Lookup
      jest.spyOn(admin, "firestore").mockReturnValue({
        collection: jest.fn((colName: string) => {
          if (colName === "garminUsers") {
            return {
              doc: jest.fn(() => ({
                get: jest.fn().mockResolvedValue({
                  exists: true,
                  data: () => ({ uid: "orbit_u1" }),
                }),
              })),
            };
          }
          return {
            doc: jest.fn(() => ({
              collection: jest.fn(() => ({
                doc: jest.fn(() => ({
                  get: jest.fn().mockResolvedValue({
                    exists: true,
                    data: () => ({
                      garmin: {
                        oauthToken: "tok_abc",
                        oauthTokenSecret: "sec_xyz",
                      },
                    }),
                  }),
                })),
              })),
            })),
          };
        }),
      } as any);

      mockedAxios.get.mockResolvedValueOnce({
        status: 200,
        data: [
          {
            summaryId: "act_from_callback_2",
            durationInSeconds: 3600,
            activityType: "CYCLING",
          },
        ],
      } as any);

      const resolved = await resolveGarminWebhookItems(
        [pushItem, pingItem],
        { key: "ckey", secret: "csecret" }
      );

      expect(resolved).toHaveLength(2);
      expect(resolved[0].summaryId).toBe("act_inline_1");
      expect(resolved[1].summaryId).toBe("act_from_callback_2");
      expect(resolved[1].userId).toBe("garmin_u1");
      expect(mockedAxios.get).toHaveBeenCalledWith(
        pingItem.callbackURL,
        expect.objectContaining({
          headers: expect.objectContaining({
            Authorization: expect.stringContaining("OAuth "),
          }),
        })
      );
    });
  });

  describe("3. Sekunden-Streams (samples) & laps aus activityDetails extrahieren und speichern", () => {
    it("extrahiert Watt, HF, Kadenz, Speed, GPS, Höhe, Temperatur und Laps im 1Hz-Stream-Format", async () => {
      const activityDetailPayload = {
        userId: "garmin_u1",
        summaryId: "998877-detail",
        activityId: 998877,
        summary: {
          activityName: "Interval Ride",
          activityType: "ROAD_BIKING",
          startTimeInSeconds: 1718000000,
          startTimeOffsetInSeconds: 7200,
          durationInSeconds: 4,
          distanceInMeters: 40,
        },
        samples: [
          {
            startTimeInSeconds: 1718000000,
            timerDurationInSeconds: 0,
            powerInWatts: 250,
            heartRate: 145,
            bikeCadenceInRPM: 90,
            speedMetersPerSecond: 9.5,
            latitudeInDegree: 50.1109,
            longitudeInDegree: 8.6821,
            elevationInMeters: 110.0,
            airTemperatureCelcius: 21.0,
            leftRightBalance: 51,
          },
          {
            startTimeInSeconds: 1718000002,
            timerDurationInSeconds: 2,
            powerInWatts: 310,
            heartRate: 155,
            bikeCadenceInRPM: 94,
            speedMetersPerSecond: 10.2,
            latitudeInDegree: 50.1115,
            longitudeInDegree: 8.6830,
            elevationInMeters: 114.0,
            airTemperatureCelcius: 21.5,
            leftRightBalance: 49,
          },
        ],
        laps: [
          {
            startTimeInSeconds: 1718000000,
            durationInSeconds: 4,
            distanceInMeters: 40,
            averageHeartRateInBeatsPerMinute: 150,
            averagePowerInWatts: 280,
          },
        ],
      };

      const extracted = extractGarminStreamsAndLaps(activityDetailPayload);

      expect(extracted.streams).not.toBeNull();
      const s = extracted.streams!;
      expect(s.version).toBe(1);
      expect(s.sampleRateSec).toBe(1);
      expect(s.power[0]).toBe(250);
      expect(s.power[1]).toBeNull();
      expect(s.power[2]).toBe(310);
      expect(s.heartRate[0]).toBe(145);
      expect(s.heartRate[2]).toBe(155);
      expect(s.cadence[0]).toBe(90);
      expect(s.cadence[2]).toBe(94);
      expect(s.speed[0]).toBe(9.5);
      expect(s.speed[2]).toBe(10.2);
      expect(s.positionLat[0]).toBeCloseTo(50.1109, 4);
      expect(s.positionLng[2]).toBeCloseTo(8.6830, 4);
      expect(s.altitude[0]).toBe(110.0);
      expect(s.altitude[2]).toBe(114.0);
      expect(s.temperature[0]).toBe(21.0);
      expect(s.leftRightBalance[0]).toBe(51);

      expect(extracted.laps).toHaveLength(1);
      expect(extracted.laps[0]).toMatchObject({
        index: 1,
        durationSec: 4,
        distanceM: 40,
        avgHr: 150,
        avgPowerW: 280,
      });

      expect(extracted.computedSummary).toMatchObject({
        avgHr: 150,
        maxHr: 155,
        avgPowerW: 280,
        maxPowerW: 310,
        avgCadence: 92,
        elevationGainM: 4,
      });

      // Prüfe auch handleGarminActivity (Storage .json.gz + Firestore Document)
      let savedBuffer: Buffer | null = null;
      let savedActivityDoc: Record<string, any> | null = null;

      jest.spyOn(admin, "storage").mockReturnValue({
        bucket: jest.fn(() => ({
          file: jest.fn(() => ({
            save: jest.fn(async (buf: Buffer) => {
              savedBuffer = buf;
            }),
          })),
        })),
      } as any);

      jest.spyOn(admin, "firestore").mockReturnValue({
        collection: jest.fn((colName: string) => {
          if (colName === "garminUsers") {
            return {
              doc: jest.fn(() => ({
                get: jest.fn().mockResolvedValue({
                  exists: true,
                  data: () => ({ uid: "orbit_u1" }),
                }),
              })),
            };
          }
          if (colName === "activities") {
            return {
              where: jest.fn().mockReturnThis(),
              limit: jest.fn().mockReturnThis(),
              get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
              doc: jest.fn(() => ({
                id: "garmin_998877",
                set: jest.fn(async (docData: Record<string, any>) => {
                  savedActivityDoc = docData;
                }),
              })),
            };
          }
          return {
            doc: jest.fn(() => ({
              get: jest.fn().mockResolvedValue({ exists: false, data: () => ({}) }),
              collection: jest.fn(() => ({
                doc: jest.fn(() => ({
                  set: jest.fn().mockResolvedValue(undefined),
                })),
              })),
            })),
          };
        }),
      } as any);

      await handleGarminActivity(activityDetailPayload);

      expect(savedBuffer).not.toBeNull();
      const unzipped = JSON.parse(zlib.gunzipSync(savedBuffer!).toString("utf-8"));
      expect(unzipped.power[0]).toBe(250);
      expect(unzipped.power[2]).toBe(310);

      expect(savedActivityDoc).not.toBeNull();
      expect(savedActivityDoc!.streamsPath).toBe("users/orbit_u1/streams/garmin_998877.json.gz");
      expect(savedActivityDoc!.laps).toHaveLength(1);
    });
  });
});
