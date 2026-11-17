
import * as fft from "firebase-functions-test";
import axios from "axios";
import { setInitialRole, deregisterGarminUserIfConnected } from "../auth";

jest.mock("axios");
const mockedAxios = axios as jest.Mocked<typeof axios>;

const testEnv = fft();

describe("setInitialRole", () => {
  let wrapped: any;

  beforeAll(() => {
    wrapped = testEnv.wrap(setInitialRole);
  });

  afterAll(() => {
    testEnv.cleanup();
  });

  it("should fail if user is not authenticated", async () => {
    try {
      await wrapped({ data: { role: "ATHLETE" }, auth: null });
      fail("Should have thrown an error");
    } catch (e: any) {
      expect(e.code).toBe("unauthenticated");
    }
  });

  it("should fail if role is invalid", async () => {
    try {
      
      await wrapped({ data: { role: "ADMIN" }, auth: { uid: "test1", token: {} } });

      fail("Should have thrown an error");
    } catch (e: any) {
      expect(e.code).toBe("invalid-argument");
    }
  });

  // Weitere Tests erfordern einen laufenden Emulator für Firestore/Auth.
  // Das prüfen wir später im Emulator-Run.
});

describe("deregisterGarminUserIfConnected", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  function createFakeDb(docs: Record<string, any>) {
    const deletedPaths: string[] = [];
    const updatedPaths: Array<{ path: string; payload: any }> = [];

    const makeDocRef = (path: string): any => ({
      path,
      get: async () => ({
        exists: docs[path] !== undefined,
        data: () => docs[path],
      }),
      delete: async () => {
        deletedPaths.push(path);
      },
      update: async (payload: any) => {
        updatedPaths.push({ path, payload });
      },
    });

    const makeCollectionRef = (colPath: string): any => ({
      doc: (id: string) => makeDocRef(`${colPath}/${id}`),
      where: () => ({
        get: async () => ({
          empty: true,
          docs: [],
        }),
      }),
    });

    const fakeDb: any = {
      collection: (name: string) => ({
        doc: (id: string) => ({
          ...makeDocRef(`${name}/${id}`),
          collection: (sub: string) => makeCollectionRef(`${name}/${id}/${sub}`),
        }),
        where: () => ({
          get: async () => ({
            empty: true,
            docs: [],
          }),
        }),
      }),
      batch: () => ({
        delete: jest.fn(),
        commit: async () => undefined,
      }),
    };

    return { fakeDb, deletedPaths, updatedPaths };
  }

  it("ruft offizielle Garmin-Deregistrierung auf und löscht garminUsers sowie Token-Dokumente", async () => {
    mockedAxios.delete.mockResolvedValueOnce({ status: 204 });
    const { fakeDb, deletedPaths, updatedPaths } = createFakeDb({
      "users/u1/private/integrations": {
        garmin: {
          oauthToken: "tok_1",
          oauthTokenSecret: "sec_1",
          garminUserId: "g_abc",
        },
      },
      "users/u1/integrationStatus/garmin": { garminUserId: "g_abc" },
      "users/u1/integrations/garmin": { garminUserId: "g_abc" },
    });

    const res = await deregisterGarminUserIfConnected(fakeDb, "u1", {
      key: "ck",
      secret: "cs",
    });

    expect(res.attemptedApiDeregister).toBe(true);
    expect(res.deletedGarminIds).toEqual(["g_abc"]);
    expect(mockedAxios.delete).toHaveBeenCalledWith(
      "https://apis.garmin.com/wellness-api/rest/user/registration",
      expect.objectContaining({
        headers: expect.objectContaining({
          Authorization: expect.stringContaining("OAuth "),
        }),
      })
    );
    expect(deletedPaths).toContain("garminUsers/g_abc");
    expect(deletedPaths).toContain("users/u1/integrations/garmin");
    expect(deletedPaths).toContain("users/u1/integrationStatus/garmin");
    expect(updatedPaths[0]?.path).toBe("users/u1/private/integrations");
  });

  it("blockiert Kontolöschung nicht, falls die externe Garmin-API fehlschlägt", async () => {
    mockedAxios.delete.mockRejectedValueOnce(new Error("Garmin 503"));
    const warnSpy = jest.spyOn(console, "warn").mockImplementation(() => undefined);
    const { fakeDb, deletedPaths } = createFakeDb({
      "users/u2/private/integrations": {
        garmin: {
          oauthToken: "tok_2",
          oauthTokenSecret: "sec_2",
          garminUserId: "g_xyz",
        },
      },
    });

    const res = await deregisterGarminUserIfConnected(fakeDb, "u2", {
      key: "ck",
      secret: "cs",
    });

    expect(res.attemptedApiDeregister).toBe(true);
    expect(deletedPaths).toContain("garminUsers/g_xyz");
    expect(warnSpy).toHaveBeenCalled();
    warnSpy.mockRestore();
  });
});
