import {
  initializeTestEnvironment,
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import * as fs from "fs";
import * as path from "path";

describe("Firestore Security Rules Tests (RULES_TESTPLAN.md)", () => {
  let testEnv: RulesTestEnvironment;

  beforeAll(async () => {
    const rulesPath = path.resolve(__dirname, "../../../firestore.rules");
    const rules = fs.readFileSync(rulesPath, "utf8");

    testEnv = await initializeTestEnvironment({
      projectId: "orbit-rules-test",
      firestore: {
        rules,
        host: "127.0.0.1",
        port: 8081,
      },
    });
  });

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  // ===============================================================
  // 1. Default Deny & Private Subcollections
  // ===============================================================
  describe("1. Default Deny & Private Subcollections", () => {
    it("verweigert Zugriff auf unbekannte Collections an der Wurzel", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      await assertFails(aliceDb.collection("unknownCollection").doc("doc1").get());
      await assertFails(aliceDb.collection("unknownCollection").doc("doc1").set({ foo: "bar" }));
    });

    it("sperrt private Subcollections users/{uid}/private/* strikt für alle Clients", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      const bobDb = testEnv.authenticatedContext("coachBob").firestore();

      await assertFails(aliceDb.collection("users").doc("alice").collection("private").doc("integrations").get());
      await assertFails(aliceDb.collection("users").doc("alice").collection("private").doc("integrations").set({ token: "secret" }));
      await assertFails(bobDb.collection("users").doc("alice").collection("private").doc("integrations").get());
    });
  });

  // ===============================================================
  // 2. User-Profile & Privilege Escalation Protection
  // ===============================================================
  describe("2. Users Collection & Schutz geschützter Felder", () => {
    it("erlaubt Athleten die Erstellung des eigenen Profils mit Rolle ATHLETE", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      await assertSucceeds(
        aliceDb.collection("users").doc("alice").set({
          uid: "alice",
          email: "alice@example.com",
          role: "ATHLETE",
          coachId: null,
          trainerVerified: false,
        })
      );
    });

    it("blockiert Privilege Escalation bei Profilerstellung (role=TRAINER oder trainerVerified=true)", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      await assertFails(
        aliceDb.collection("users").doc("alice").set({
          uid: "alice",
          role: "TRAINER",
        })
      );
      await assertFails(
        aliceDb.collection("users").doc("alice").set({
          uid: "alice",
          role: "ATHLETE",
          trainerVerified: true,
        })
      );
    });

    it("verhindert Client-Manipulation geschützter Server-Felder (role, coachId, metrics)", async () => {
      // Vorab via Admin anlegen
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("users").doc("alice").set({
          uid: "alice",
          email: "alice@example.com",
          role: "ATHLETE",
          coachId: null,
          trainerVerified: false,
          metrics: { orbitScore: 75 },
        });
      });

      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Erlaubtes Update (z. B. Einstellungen)
      await assertSucceeds(
        aliceDb.collection("users").doc("alice").update({
          "settings.language": "de",
        })
      );

      // Verbotenes Update: Rolle ändern
      await assertFails(
        aliceDb.collection("users").doc("alice").update({
          role: "TRAINER",
        })
      );

      // Verbotenes Update: coachId direkt vom Client setzen
      await assertFails(
        aliceDb.collection("users").doc("alice").update({
          coachId: "hackerCoach",
        })
      );

      // Verbotenes Update: metrics manipulieren
      await assertFails(
        aliceDb.collection("users").doc("alice").update({
          "metrics.orbitScore": 100,
        })
      );
    });

    it("gewährleistet Datentrennung: Bob darf Alices Profil nicht lesen", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("users").doc("alice").set({
          uid: "alice",
          email: "alice@example.com",
          role: "ATHLETE",
        });
      });

      const bobDb = testEnv.authenticatedContext("coachBob").firestore();
      const unauthDb = testEnv.unauthenticatedContext().firestore();

      await assertFails(bobDb.collection("users").doc("alice").get());
      await assertFails(unauthDb.collection("users").doc("alice").get());
    });
  });

  // ===============================================================
  // 3. Trainer-Verknüpfung, Granulare Freigaben & DSGVO-Sofortentzug (17.3)
  // ===============================================================
  describe("3. Trainer-Freigaben & Sofortiger Zugriffsverlust nach Trennung", () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();

        // Nutzer anlegen
        await adminDb.collection("users").doc("alice").set({ uid: "alice", role: "ATHLETE" });
        await adminDb.collection("users").doc("coachBob").set({ uid: "coachBob", role: "TRAINER" });

        // Aktiver Coach-Link mit activities + calendar, aber KEIN health
        await adminDb.collection("coachLinks").doc("alice_coachBob").set({
          athleteId: "alice",
          coachId: "coachBob",
          status: "ACTIVE",
          permissions: {
            calendar: true,
            activities: true,
            health: false,
          },
        });

        // Aktivität von Alice
        await adminDb.collection("activities").doc("act1").set({
          athleteId: "alice",
          coachId: "coachBob",
          title: "Morgenlauf",
        });

        // Trainingsplan von Alice
        await adminDb.collection("plannedWorkouts").doc("plan1").set({
          athleteId: "alice",
          coachId: "coachBob",
          createdBy: "alice",
          title: "Intervalltraining",
        });

        // Gesundheitsdaten von Alice (Art. 9 DSGVO)
        await adminDb.collection("users").doc("alice").collection("dailyMetrics").doc("2026-10-14").set({
          restingHrBpm: 52,
          hrvMs: 65,
        });

        // Vorberechnetes Aggregat
        await adminDb.collection("users").doc("alice").collection("aggregates").doc("2026-10-14").set({
          dailyLoad: 80,
          ctl: 60,
        });

        // Getrenntes Template
        await adminDb.collection("workoutTemplates").doc("tpl1").set({
          ownerId: "coachBob",
          visibility: "SHARED_WITH_MY_ATHLETES",
          title: "FTP-Test Einheit",
        });
      });
    });

    it("erlaubt Coach Bob Lesezugriff auf Aktivitäten bei aktivem Link mit activities=true", async () => {
      const bobDb = testEnv.authenticatedContext("coachBob").firestore();
      await assertSucceeds(bobDb.collection("activities").doc("act1").get());
    });

    it("verweigert Coach Bob Lesezugriff auf Gesundheitsdaten (Art. 9), solange health=false ist", async () => {
      const bobDb = testEnv.authenticatedContext("coachBob").firestore();
      await assertFails(
        bobDb.collection("users").doc("alice").collection("dailyMetrics").doc("2026-10-14").get()
      );
    });

    it("erlaubt Lesezugriff auf Gesundheitsdaten, sobald health=true erteilt wird", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("coachLinks").doc("alice_coachBob").update({
          "permissions.health": true,
        });
      });

      const bobDb = testEnv.authenticatedContext("coachBob").firestore();
      await assertSucceeds(
        bobDb.collection("users").doc("alice").collection("dailyMetrics").doc("2026-10-14").get()
      );
    });

    it("DSGVO-Verifikation: Sofortiger Zugriffsverlust nach Trennung (status=REVOKED)", async () => {
      // Trainer trennen (Link-Status auf REVOKED setzen)
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("coachLinks").doc("alice_coachBob").update({
          status: "REVOKED",
        });
      });

      const bobDb = testEnv.authenticatedContext("coachBob").firestore();

      // Bob darf die Aktivität NICHT MEHR lesen, selbst wenn coachId noch auf dem Dokument steht!
      await assertFails(bobDb.collection("activities").doc("act1").get());

      // Bob darf den Trainingsplan NICHT MEHR lesen
      await assertFails(bobDb.collection("plannedWorkouts").doc("plan1").get());

      // Bob darf Tagesaggregate NICHT MEHR lesen
      await assertFails(
        bobDb.collection("users").doc("alice").collection("aggregates").doc("2026-10-14").get()
      );

      // Bob darf Gesundheitsdaten NICHT MEHR lesen
      await assertFails(
        bobDb.collection("users").doc("alice").collection("dailyMetrics").doc("2026-10-14").get()
      );

      // Alice verliert den Zugriff auf geteilte Templates des Trainers nach Trennung
      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      await assertFails(aliceDb.collection("workoutTemplates").doc("tpl1").get());
    });
  });

  // ===============================================================
  // 4. Aggregat- und Bestwerte-Schutz (Nur Cloud Functions)
  // ===============================================================
  describe("4. Striktes Client-Schreibverbot für Aggregate und Bestwerte", () => {
    it("blockiert alle Client-Writes auf users/{uid}/aggregates/{date}", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      const bobDb = testEnv.authenticatedContext("coachBob").firestore();

      await assertFails(
        aliceDb.collection("users").doc("alice").collection("aggregates").doc("2026-10-14").set({
          ctl: 100,
        })
      );
      await assertFails(
        bobDb.collection("users").doc("alice").collection("aggregates").doc("2026-10-14").set({
          ctl: 100,
        })
      );
    });

    it("blockiert alle Client-Writes auf users/{uid}/bests/{sport}", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      await assertFails(
        aliceDb.collection("users").doc("alice").collection("bests").doc("cycling").set({
          mmp20m: 350,
        })
      );
    });
  });

  // ===============================================================
  // 5. Schwellenwert-Vorschläge & Kalender (Phase 08 & 12)
  // ===============================================================
  describe("5. Schwellenwert-Vorschläge & Kalender-Rechte", () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection("coachLinks").doc("alice_coachBob").set({
          athleteId: "alice",
          coachId: "coachBob",
          status: "ACTIVE",
          permissions: { calendar: true, activities: true, health: false },
        });
      });
    });

    it("erlaubt Trainer das Anlegen von PENDING-Vorschlägen mit gültigen Sportarten", async () => {
      const bobDb = testEnv.authenticatedContext("coachBob").firestore();
      await assertSucceeds(
        bobDb.collection("users").doc("alice").collection("thresholdProposals").doc("prop1").set({
          proposedBy: "coachBob",
          status: "PENDING",
          sport: "RUN",
          proposedValue: 280,
          type: "FTP",
          notes: "Starke Leistungssteigerung",
        })
      );
    });

    it("verweigert Trainer Identitätsfälschung oder das direkte Setzen von ACCEPTED", async () => {
      const bobDb = testEnv.authenticatedContext("coachBob").firestore();

      // Falscher Sender
      await assertFails(
        bobDb.collection("users").doc("alice").collection("thresholdProposals").doc("prop2").set({
          proposedBy: "alice",
          status: "PENDING",
          sport: "RUN",
          proposedValue: 280,
        })
      );

      // Verbotenes Vorschreiben von ACCEPTED
      await assertFails(
        bobDb.collection("users").doc("alice").collection("thresholdProposals").doc("prop3").set({
          proposedBy: "coachBob",
          status: "ACCEPTED",
          sport: "RUN",
          proposedValue: 280,
        })
      );
    });

    it("erlaubt Athleten die Annahme/Ablehnung ohne Manipulation der Messwerte", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("users").doc("alice").collection("thresholdProposals").doc("prop1").set({
          proposedBy: "coachBob",
          status: "PENDING",
          sport: "RUN",
          proposedValue: 280,
          type: "FTP",
        });
      });

      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Erlaubt: Status auf ACCEPTED
      await assertSucceeds(
        aliceDb.collection("users").doc("alice").collection("thresholdProposals").doc("prop1").update({
          status: "ACCEPTED",
        })
      );

      // Verboten: Wert von 280 auf 350 hochdrehen
      await assertFails(
        aliceDb.collection("users").doc("alice").collection("thresholdProposals").doc("prop1").update({
          status: "ACCEPTED",
          proposedValue: 350,
        })
      );
    });
  });

  // ===============================================================
  // 6. Chat & Messaging (Phase 13)
  // ===============================================================
  describe("6. Chat-Sicherheit & Verbot von Hard-Deletes", () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("chats").doc("alice_coachBob").set({
          athleteId: "alice",
          coachId: "coachBob",
          participants: ["alice", "coachBob"],
          status: "ACTIVE",
        });
        await context.firestore().collection("chats").doc("alice_coachBob").collection("messages").doc("m1").set({
          senderId: "alice",
          type: "TEXT",
          status: "SENT",
          text: "Hallo Trainer",
        });
      });
    });

    it("erlaubt Teilnehmern das Senden und Soft-Delete eigener Nachrichten", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Neue Nachricht senden
      await assertSucceeds(
        aliceDb.collection("chats").doc("alice_coachBob").collection("messages").doc("m2").set({
          senderId: "alice",
          type: "TEXT",
          status: "SENT",
          text: "Wie war das Training?",
        })
      );

      // Eigenes Soft-Delete
      await assertSucceeds(
        aliceDb.collection("chats").doc("alice_coachBob").collection("messages").doc("m1").update({
          status: "DELETED",
          text: "",
        })
      );
    });

    it("verweigert Hard-Deletes (.delete()) auf Chatnachrichten strikt", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      const bobDb = testEnv.authenticatedContext("coachBob").firestore();

      await assertFails(
        aliceDb.collection("chats").doc("alice_coachBob").collection("messages").doc("m1").delete()
      );
      await assertFails(
        bobDb.collection("chats").doc("alice_coachBob").collection("messages").doc("m1").delete()
      );
    });

    it("sperrt unbeteiligte Dritte (Eve) komplett aus dem Chat aus", async () => {
      const eveDb = testEnv.authenticatedContext("eve").firestore();

      await assertFails(eveDb.collection("chats").doc("alice_coachBob").get());
      await assertFails(
        eveDb.collection("chats").doc("alice_coachBob").collection("messages").doc("m1").get()
      );
      await assertFails(
        eveDb.collection("chats").doc("alice_coachBob").collection("messages").doc("m3").set({
          senderId: "eve",
          type: "TEXT",
          status: "SENT",
          text: "Spam",
        })
      );
    });
  });
});
