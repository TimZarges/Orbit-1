
import * as fft from "firebase-functions-test";
import { setInitialRole } from "../auth";

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
