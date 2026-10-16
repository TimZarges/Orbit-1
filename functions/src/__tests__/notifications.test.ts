import {
  isQuietTime,
  sendSystemNotification,
  sendActivityAnalyzedPush,
  sendWorkoutUpdatePush,
  sendThresholdSuggestionPush,
} from "../notifications";
import * as admin from "firebase-admin";

jest.mock("firebase-admin", () => {
  const mockSendEachForMulticast = jest.fn();
  const mockGetDoc = jest.fn();
  const mockGetCollection = jest.fn();

  return {
    firestore: jest.fn(() => ({
      collection: jest.fn((colName: string) => ({
        doc: jest.fn((docId: string) => ({
          get: mockGetDoc,
          collection: jest.fn((subCol: string) => ({
            get: mockGetCollection,
          })),
        })),
        get: jest.fn().mockResolvedValue({ docs: [] }),
      })),
    })),
    messaging: jest.fn(() => ({
      sendEachForMulticast: mockSendEachForMulticast,
    })),
    _mockGetDoc: mockGetDoc,
    _mockGetCollection: mockGetCollection,
    _mockSendEachForMulticast: mockSendEachForMulticast,
  };
});

describe("Phase 23.1: Push Notifications & Quiet Time Unit Tests", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("isQuietTime", () => {
    it("returns false if config is undefined or enabled is false", () => {
      expect(isQuietTime(undefined)).toBe(false);
      expect(isQuietTime({ enabled: false, start: "22:00", end: "07:00" })).toBe(false);
    });

    it("correctly handles window across midnight (22:00 to 07:00)", () => {
      // 23:15 UTC = 00:15 or 01:15 in Berlin (Quiet)
      const lateNight = new Date("2026-10-15T22:30:00Z");
      expect(isQuietTime({ start: "22:00", end: "07:00", timezone: "UTC" }, lateNight)).toBe(true);

      // 03:00 UTC (Quiet)
      const deepNight = new Date("2026-10-15T03:00:00Z");
      expect(isQuietTime({ start: "22:00", end: "07:00", timezone: "UTC" }, deepNight)).toBe(true);

      // 14:00 UTC (Active time / Not Quiet)
      const daytime = new Date("2026-10-15T14:00:00Z");
      expect(isQuietTime({ start: "22:00", end: "07:00", timezone: "UTC" }, daytime)).toBe(false);
    });

    it("correctly handles daytime quiet window (e.g. Siesta 13:00 to 15:00)", () => {
      const during = new Date("2026-10-15T14:00:00Z");
      expect(isQuietTime({ start: "13:00", end: "15:00", timezone: "UTC" }, during)).toBe(true);

      const after = new Date("2026-10-15T16:00:00Z");
      expect(isQuietTime({ start: "13:00", end: "15:00", timezone: "UTC" }, after)).toBe(false);
    });
  });

  describe("sendSystemNotification", () => {
    const { _mockGetDoc, _mockGetCollection, _mockSendEachForMulticast } = admin as any;

    it("aborts when user document does not exist", async () => {
      _mockGetDoc.mockResolvedValueOnce({ exists: false });

      const res = await sendSystemNotification({
        recipientId: "nonexistent",
        title: "Test",
        body: "Test Body",
        category: "workout",
      });

      expect(res.sent).toBe(false);
      expect(res.reason).toBe("USER_NOT_FOUND");
      expect(_mockSendEachForMulticast).not.toHaveBeenCalled();
    });

    it("aborts when user has opted out of category", async () => {
      _mockGetDoc.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          settings: {
            notifications: {
              workout: false,
            },
          },
        }),
      });

      const res = await sendSystemNotification({
        recipientId: "user123",
        title: "Workout",
        body: "Body",
        category: "workout",
      });

      expect(res.sent).toBe(false);
      expect(res.reason).toBe("OPT_OUT_CATEGORY");
      expect(_mockSendEachForMulticast).not.toHaveBeenCalled();
    });

    it("aborts during quiet hours when bypassQuietTime is false", async () => {
      _mockGetDoc.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          settings: {
            notifications: { workout: true },
            quietHours: {
              start: "00:00",
              end: "23:59", // Always quiet for test
              enabled: true,
            },
          },
        }),
      });

      const res = await sendSystemNotification({
        recipientId: "user123",
        title: "Workout",
        body: "Body",
        category: "workout",
        bypassQuietTime: false,
      });

      expect(res.sent).toBe(false);
      expect(res.reason).toBe("QUIET_HOURS_ACTIVE");
      expect(_mockSendEachForMulticast).not.toHaveBeenCalled();
    });

    it("sends successfully with ORBIT icon and Navy accent color", async () => {
      _mockGetDoc.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          settings: {
            notifications: { workout: true },
            quietHours: { enabled: false },
          },
        }),
      });

      _mockGetCollection.mockResolvedValueOnce({
        empty: false,
        forEach: (cb: any) => {
          cb({ data: () => ({ fcmToken: "fcm_token_pixel_10_pro" }) });
        },
      });

      _mockSendEachForMulticast.mockResolvedValueOnce({ successCount: 1 });

      const res = await sendSystemNotification({
        recipientId: "user123",
        title: "Dein Radtraining ist analysiert",
        body: "Einheit (84 TSS) verarbeitet. Tippe hier für das Analyse-Cockpit.",
        category: "workout",
        dataPayload: { activityId: "act_456" },
      });

      expect(res.sent).toBe(true);
      expect(res.tokenCount).toBe(1);

      expect(_mockSendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          tokens: ["fcm_token_pixel_10_pro"],
          notification: {
            title: "Dein Radtraining ist analysiert",
            body: "Einheit (84 TSS) verarbeitet. Tippe hier für das Analyse-Cockpit.",
          },
          android: expect.objectContaining({
            notification: expect.objectContaining({
              icon: "ic_stat_orbit",
              color: "#001F47",
              channelId: "orbit_notifications",
            }),
          }),
          data: expect.objectContaining({
            activityId: "act_456",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          }),
        })
      );
    });
  });

  describe("Push Helpers", () => {
    const { _mockGetDoc, _mockGetCollection, _mockSendEachForMulticast } = admin as any;

    it("sendActivityAnalyzedPush formats body with TSS and Best-Watts", async () => {
      _mockGetDoc.mockResolvedValueOnce({
        exists: true,
        data: () => ({ settings: {} }),
      });
      _mockGetCollection.mockResolvedValueOnce({
        empty: false,
        forEach: (cb: any) => cb({ data: () => ({ fcmToken: "token1" }) }),
      });
      _mockSendEachForMulticast.mockResolvedValueOnce({ successCount: 1 });

      await sendActivityAnalyzedPush({
        recipientId: "ath_1",
        activityId: "act_999",
        sport: "BIKE",
        tss: 92.4,
        bestWatt: 365,
        bypassQuietTime: true,
      });

      expect(_mockSendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: expect.objectContaining({
            title: "Dein Radtraining ist analysiert",
            body: "Einheit (92 TSS) verarbeitet. Neue 5-Min-Bestleistung: 365 W! Tippe hier für das Analyse-Cockpit.",
          }),
          data: expect.objectContaining({
            type: "ACTIVITY",
            activityId: "act_999",
            route: "/activities/act_999",
          }),
        })
      );
    });

    it("sendWorkoutUpdatePush formats coach name and date", async () => {
      _mockGetDoc.mockResolvedValueOnce({
        exists: true,
        data: () => ({ settings: {} }),
      });
      _mockGetCollection.mockResolvedValueOnce({
        empty: false,
        forEach: (cb: any) => cb({ data: () => ({ fcmToken: "token1" }) }),
      });
      _mockSendEachForMulticast.mockResolvedValueOnce({ successCount: 1 });

      await sendWorkoutUpdatePush({
        recipientId: "ath_1",
        workoutId: "plan_123",
        title: "4x4min VO2max Intervalle",
        date: "2026-10-20",
        coachName: "Klaus",
        bypassQuietTime: true,
      });

      expect(_mockSendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: expect.objectContaining({
            title: "Trainingsplan aktualisiert",
            body: "Trainer Klaus hat deine Einheit „4x4min VO2max Intervalle“ für 2026-10-20 geplant.",
          }),
          data: expect.objectContaining({
            type: "WORKOUT",
            workoutId: "plan_123",
            route: "/calendar",
          }),
        })
      );
    });

    it("sendThresholdSuggestionPush includes FTP increment", async () => {
      _mockGetDoc.mockResolvedValueOnce({
        exists: true,
        data: () => ({ settings: {} }),
      });
      _mockGetCollection.mockResolvedValueOnce({
        empty: false,
        forEach: (cb: any) => cb({ data: () => ({ fcmToken: "token1" }) }),
      });
      _mockSendEachForMulticast.mockResolvedValueOnce({ successCount: 1 });

      await sendThresholdSuggestionPush({
        recipientId: "ath_1",
        oldFtp: 275,
        newFtp: 285,
        bypassQuietTime: true,
      });

      expect(_mockSendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: expect.objectContaining({
            title: "Neuer FTP-Vorschlag erkannt",
            body: "Aus deiner MMP-Kurve: 285 W (+10 W). Jetzt in deinem Profil übernehmen?",
          }),
          data: expect.objectContaining({
            type: "THRESHOLD",
            newFtp: "285",
            route: "/thresholds",
          }),
        })
      );
    });
  });
});
