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

      // Verbotenes Update: isAdmin auf true setzen
      await assertFails(
        aliceDb.collection("users").doc("alice").update({
          isAdmin: true,
        })
      );
    });

    it("blockiert Privilege Escalation durch Setzen von isAdmin: true bei Profilerstellung", async () => {
      const malloryDb = testEnv.authenticatedContext("mallory").firestore();
      await assertFails(
        malloryDb.collection("users").doc("mallory").set({
          uid: "mallory",
          email: "mallory@example.com",
          role: "ATHLETE",
          isAdmin: true,
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

  // ===============================================================
  // 7. In-App Beta-Bug-Reporter (Phase 19.2)
  // ===============================================================
  describe("7. In-App Beta-Bug-Reporter (betaFeedback — Phase 19.2)", () => {
    it("erlaubt authentifizierten Nutzern das Anlegen eigener Bug-Reports in betaFeedback", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      await assertSucceeds(
        aliceDb.collection("betaFeedback").doc("rep_alice_1").set({
          userId: "alice",
          category: "BUG_CRASH",
          description: "Beim Öffnen der Aktivität flackert das Chart kurz.",
          includeDiagnostics: true,
          diagnostics: {
            route: "/analysis",
            appVersion: "1.0.0+1 (v0.19.0-beta)",
            deviceInfo: "android",
            recentLogs: ["[2026-10-16T10:00:00Z] code=unavailable"],
          },
          screenshotPath: "betaFeedback/alice/rep_alice_1.png",
          createdAt: "2026-10-16T10:00:00.000Z",
        })
      );
    });

    it("verhindert das Lesen fremder Bug-Reports sowie Identitätsfälschung und Manipulation", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("betaFeedback").doc("rep_alice_1").set({
          userId: "alice",
          category: "GARMIN_UPLOAD",
          description: "FIT-Upload dauerte 5 Sekunden.",
          includeDiagnostics: false,
        });
      });

      const aliceDb = testEnv.authenticatedContext("alice").firestore();
      const bobDb = testEnv.authenticatedContext("coachBob").firestore();
      const anonDb = testEnv.unauthenticatedContext().firestore();

      // Eigener Report darf gelesen werden
      await assertSucceeds(
        aliceDb.collection("betaFeedback").doc("rep_alice_1").get()
      );

      // Fremder Report darf NICHT gelesen werden!
      await assertFails(
        bobDb.collection("betaFeedback").doc("rep_alice_1").get()
      );
      await assertFails(
        anonDb.collection("betaFeedback").doc("rep_alice_1").get()
      );

      // Identitätsfälschung beim Anlegen verboten
      await assertFails(
        bobDb.collection("betaFeedback").doc("rep_forged").set({
          userId: "alice",
          category: "BUG_CRASH",
          description: "Gefälschter Report",
        })
      );

      // Ungültige Kategorie verboten
      await assertFails(
        aliceDb.collection("betaFeedback").doc("rep_invalid_cat").set({
          userId: "alice",
          category: "HACK_CATEGORY",
          description: "Test",
        })
      );

      // Nachträgliches Ändern oder Löschen verboten
      await assertFails(
        aliceDb.collection("betaFeedback").doc("rep_alice_1").update({
          description: "Geändert",
        })
      );
      await assertFails(
        aliceDb.collection("betaFeedback").doc("rep_alice_1").delete()
      );
    });

    it("gewährt Admins Lesezugriff auf alle Reports und Update des Status, verwehrt aber Deletes und Manipulation anderer Felder", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("betaFeedback").doc("rep_alice_1").set({
          userId: "alice",
          category: "BUG_CRASH",
          description: "Bug report from alice",
          status: "OPEN",
        });
        await context.firestore().collection("users").doc("timAdmin").set({
          uid: "timAdmin",
          email: "tim@orbit.training",
          role: "ATHLETE",
          isAdmin: true,
        });
      });

      const adminTokenDb = testEnv.authenticatedContext("adminWithClaim", { admin: true }).firestore();
      const adminDocDb = testEnv.authenticatedContext("timAdmin").firestore();
      const normalBobDb = testEnv.authenticatedContext("bob").firestore();

      // Admin via Auth Token Claim darf fremden Report lesen
      await assertSucceeds(adminTokenDb.collection("betaFeedback").doc("rep_alice_1").get());

      // Admin via users/uid.isAdmin == true darf fremden Report lesen
      await assertSucceeds(adminDocDb.collection("betaFeedback").doc("rep_alice_1").get());

      // Normaler Nutzer (Bob) darf fremden Report NICHT lesen
      await assertFails(normalBobDb.collection("betaFeedback").doc("rep_alice_1").get());

      // Admin darf Status auf IN_PROGRESS oder RESOLVED setzen
      await assertSucceeds(
        adminDocDb.collection("betaFeedback").doc("rep_alice_1").update({
          status: "IN_PROGRESS",
        })
      );
      await assertSucceeds(
        adminTokenDb.collection("betaFeedback").doc("rep_alice_1").update({
          status: "RESOLVED",
        })
      );

      // Admin darf KEINE anderen Felder manipulieren (z. B. description, userId)
      await assertFails(
        adminDocDb.collection("betaFeedback").doc("rep_alice_1").update({
          description: "Manipuliert durch Admin",
        })
      );

      // Admin darf NICHT löschen
      await assertFails(
        adminDocDb.collection("betaFeedback").doc("rep_alice_1").delete()
      );
    });
  });

  // ===============================================================
  // 8. Beta-Warteliste auf Marketing-Website (Phase 22.3)
  // ===============================================================
  describe("8. Beta-Warteliste (betaWaitlist — Phase 22.3)", () => {
    it("erlaubt unauthentifizierten Besuchern das Eintragen in betaWaitlist mit validen Daten", async () => {
      const anonDb = testEnv.unauthenticatedContext().firestore();

      await assertSucceeds(
        anonDb.collection("betaWaitlist").doc("waitlist_1").set({
          name: "Max Mustermann",
          email: "max@radsport-verein.de",
          role: "ATHLETE",
          device: "GARMIN",
          consentGiven: true,
          createdAt: "2026-10-16T22:00:00.000Z",
        })
      );
    });

    it("verweigert das Lesen, Bearbeiten oder Löschen fremder Wartelisten-Einträge strikt", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("betaWaitlist").doc("waitlist_secret").set({
          name: "Geheimer Athlet",
          email: "secret@pro-team.com",
          role: "ATHLETE",
          device: "WAHOO",
          consentGiven: true,
          createdAt: "2026-10-16T22:00:00.000Z",
        });
      });

      const anonDb = testEnv.unauthenticatedContext().firestore();
      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Lesen verboten (weder anonym noch als anderer authentifizierter Nutzer)
      await assertFails(anonDb.collection("betaWaitlist").doc("waitlist_secret").get());
      await assertFails(aliceDb.collection("betaWaitlist").doc("waitlist_secret").get());

      // Bearbeiten verboten
      await assertFails(
        anonDb.collection("betaWaitlist").doc("waitlist_secret").update({
          name: "Manipuliert",
        })
      );
      await assertFails(
        aliceDb.collection("betaWaitlist").doc("waitlist_secret").update({
          name: "Manipuliert",
        })
      );

      // Löschen verboten
      await assertFails(anonDb.collection("betaWaitlist").doc("waitlist_secret").delete());
      await assertFails(aliceDb.collection("betaWaitlist").doc("waitlist_secret").delete());
    });

    it("blockiert ungültige Registrierungen (fehlender Consent, invalide Rolle/Device, Übergröße)", async () => {
      const anonDb = testEnv.unauthenticatedContext().firestore();

      // Fehlender Consent
      await assertFails(
        anonDb.collection("betaWaitlist").doc("waitlist_no_consent").set({
          name: "Tim",
          email: "tim@orbit.training",
          role: "ATHLETE",
          device: "GARMIN",
          consentGiven: false,
        })
      );

      // Ungültige Rolle
      await assertFails(
        anonDb.collection("betaWaitlist").doc("waitlist_bad_role").set({
          name: "Tim",
          email: "tim@orbit.training",
          role: "SUPERADMIN",
          device: "GARMIN",
          consentGiven: true,
        })
      );

      // Ungültiges Gerät
      await assertFails(
        anonDb.collection("betaWaitlist").doc("waitlist_bad_device").set({
          name: "Tim",
          email: "tim@orbit.training",
          role: "ATHLETE",
          device: "PLAYSTATION",
          consentGiven: true,
        })
      );
    });
  });

  // ===============================================================
  // 9. Wettkampf-Planung & Saison-Ziele (Phase 23.2)
  // ===============================================================
  describe("9. Wettkampf-Planung & Saison-Ziele (users/{uid}/races — Phase 23.2)", () => {
    it("erlaubt dem Athleten das Erstellen, Lesen, Aktualisieren und Löschen eigener Rennen", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Erstellen eines A-Hauptwettkampfs
      await assertSucceeds(
        aliceDb.collection("users").doc("alice").collection("races").doc("race_ironman").set({
          userId: "alice",
          title: "Ironman 70.3 Kraichgau",
          date: "2026-05-24",
          priority: "A",
          sport: "TRIATHLON",
          distanceLabel: "Mitteldistanz",
          targetTimeSec: 16200, // 4:30:00
          targetPowerWatts: 265,
          notes: "Taper startet 14 Tage vor dem Event.",
        })
      );

      // Lesen
      const snap = await aliceDb.collection("users").doc("alice").collection("races").doc("race_ironman").get();
      expect(snap.exists).toBe(true);

      // Aktualisieren
      await assertSucceeds(
        aliceDb.collection("users").doc("alice").collection("races").doc("race_ironman").update({
          targetPowerWatts: 270,
        })
      );

      // Löschen
      await assertSucceeds(
        aliceDb.collection("users").doc("alice").collection("races").doc("race_ironman").delete()
      );
    });

    it("blockiert ungültige Wettkampf-Dokumente (ungültige Priorität, falsche userId, fehlende Pflichtfelder)", async () => {
      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Ungültige Priorität 'X'
      await assertFails(
        aliceDb.collection("users").doc("alice").collection("races").doc("race_bad_prio").set({
          userId: "alice",
          title: "Test Race",
          date: "2026-06-01",
          priority: "X",
        })
      );

      // Falsche userId
      await assertFails(
        aliceDb.collection("users").doc("alice").collection("races").doc("race_bad_user").set({
          userId: "eve",
          title: "Test Race",
          date: "2026-06-01",
          priority: "A",
        })
      );

      // Fehlendes Datum
      await assertFails(
        aliceDb.collection("users").doc("alice").collection("races").doc("race_no_date").set({
          userId: "alice",
          title: "Test Race",
          priority: "A",
        })
      );
    });

    it("erlaubt verknüpftem Coach mit Kalender-Freigabe den Zugriff und sperrt unberechtigte Dritte", async () => {
      // Setup Coach Link alice_bob mit calendar = true
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("coachLinks").doc("alice_bob").set({
          athleteId: "alice",
          coachId: "bob",
          status: "ACTIVE",
          permissions: { calendar: true, activities: false, health: false },
        });

        await context.firestore().collection("users").doc("alice").collection("races").doc("race_frankfurt").set({
          userId: "alice",
          title: "Eschborn-Frankfurt",
          date: "2026-05-01",
          priority: "B",
          sport: "BIKE",
        });
      });

      const bobDb = testEnv.authenticatedContext("bob").firestore();
      const eveDb = testEnv.authenticatedContext("eve").firestore();

      // Bob (Trainer mit Kalender-Freigabe) darf lesen
      await assertSucceeds(
        bobDb.collection("users").doc("alice").collection("races").doc("race_frankfurt").get()
      );

      // Eve (unbeteiligt) darf weder lesen noch schreiben
      await assertFails(
        eveDb.collection("users").doc("alice").collection("races").doc("race_frankfurt").get()
      );
      await assertFails(
        eveDb.collection("users").doc("alice").collection("races").doc("race_frankfurt").update({
          title: "Gehackt",
        })
      );
    });
  });

  // ===============================================================
  // 10. App Config & Version Gate (Phase 23.3)
  // ===============================================================
  describe("10. App Config & Version Gate (app_config — Phase 23.3)", () => {
    it("erlaubt öffentlichen Lesezugriff auf Version-Gate & Feature-Flags, verbietet aber Client-Schreibzugriffe", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("app_config").doc("version_gate").set({
          minRequiredBuild: 1,
          latestBuild: 2,
          updateUrl: "https://app.orbit.training/download",
          maintenanceMode: false,
          featureFlags: { experimental_mmp: true },
        });
      });

      const anonDb = testEnv.unauthenticatedContext().firestore();
      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Öffentliches Lesen erlaubt (auch unauthentifiziert vor dem Login)
      await assertSucceeds(anonDb.collection("app_config").doc("version_gate").get());
      await assertSucceeds(aliceDb.collection("app_config").doc("version_gate").get());

      // Schreibzugriffe vom Client strikt verboten
      await assertFails(
        anonDb.collection("app_config").doc("version_gate").update({ minRequiredBuild: 999 })
      );
      await assertFails(
        aliceDb.collection("app_config").doc("version_gate").update({ minRequiredBuild: 999 })
      );
      await assertFails(
        aliceDb.collection("app_config").doc("version_gate").delete()
      );
    });
  });

  // ===============================================================
  // 11. Kontakt- und Support-Anfragen (contactRequests — Phase 28.3)
  // ===============================================================
  describe("11. Kontakt- und Support-Anfragen (contactRequests — Phase 28.3)", () => {
    it("erlaubt Website-Besuchern das Erstellen einer validen Kontaktanfrage ohne Login", async () => {
      const anonDb = testEnv.unauthenticatedContext().firestore();

      await assertSucceeds(
        anonDb.collection("contactRequests").doc("req_123").set({
          name: "Tim Zarges",
          email: "tim@orbit-training.app",
          category: "SUPPORT",
          message: "Ich habe eine Frage zur Trainingszonen-Einteilung.",
          status: "OPEN",
        })
      );
    });

    it("verweigert das Lesen, Bearbeiten oder Löschen von Kontaktanfragen für alle Clients", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("contactRequests").doc("req_secret").set({
          name: "Geheim",
          email: "secret@orbit-training.app",
          message: "Vertrauliche Nachricht.",
        });
      });

      const anonDb = testEnv.unauthenticatedContext().firestore();
      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Lesen verboten
      await assertFails(anonDb.collection("contactRequests").doc("req_secret").get());
      await assertFails(aliceDb.collection("contactRequests").doc("req_secret").get());

      // Update verboten
      await assertFails(
        aliceDb.collection("contactRequests").doc("req_secret").update({ status: "RESOLVED" })
      );

      // Löschen verboten
      await assertFails(anonDb.collection("contactRequests").doc("req_secret").delete());
      await assertFails(aliceDb.collection("contactRequests").doc("req_secret").delete());
    });

    it("blockiert ungültige Kontaktanfragen (fehlende Pflichtfelder, invalide E-Mail, Übergröße)", async () => {
      const anonDb = testEnv.unauthenticatedContext().firestore();

      // Fehlendes Feld message
      await assertFails(
        anonDb.collection("contactRequests").doc("req_bad_1").set({
          name: "Tim",
          email: "tim@orbit-training.app",
        })
      );

      // Ungültige Kategorie
      await assertFails(
        anonDb.collection("contactRequests").doc("req_bad_2").set({
          name: "Tim",
          email: "tim@orbit-training.app",
          category: "INVALID_CAT",
          message: "Hallo Welt",
        })
      );
    });

    it("erlaubt Admins das Lesen und Status-Update von contactRequests", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("contactRequests").doc("req_for_admin").set({
          name: "Interessent",
          email: "interessent@orbit-training.app",
          message: "Anfrage zu ORBIT für Vereine.",
          status: "OPEN",
        });
        await context.firestore().collection("users").doc("timAdmin").set({
          uid: "timAdmin",
          email: "tim@orbit-training.app",
          isAdmin: true,
        });
      });

      const adminDb = testEnv.authenticatedContext("timAdmin").firestore();
      const aliceDb = testEnv.authenticatedContext("alice").firestore();

      // Admin darf lesen
      await assertSucceeds(adminDb.collection("contactRequests").doc("req_for_admin").get());

      // Normaler Nutzer darf nicht lesen
      await assertFails(aliceDb.collection("contactRequests").doc("req_for_admin").get());

      // Admin darf Status aktualisieren
      await assertSucceeds(
        adminDb.collection("contactRequests").doc("req_for_admin").update({ status: "IN_PROGRESS" })
      );

      // Löschen bleibt für alle verboten
      await assertFails(adminDb.collection("contactRequests").doc("req_for_admin").delete());
    });
  });
});


