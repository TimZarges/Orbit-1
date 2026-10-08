---
trigger: glob
globs: "firestore.rules, storage.rules, firestore.indexes.json, functions/**/*.ts, lib/data/**/*.dart, test/rules/**"
description: "Datenmodell-, Zugriffs- und Sicherheitsregeln für Firestore, Storage, Rules und Cloud Functions in ORBIT."
---

# Daten- und Sicherheitsregeln (Kurzfassung)

**Vor Arbeit an Daten/Rules/Functions vollständig lesen:** @docs/DATA_MODEL.md

1. **Geplant ≠ absolviert:** `plannedWorkouts` und `activities` sind getrennte Collections, gegenseitig verknüpft. Ein Import überschreibt nie einen Plan.
2. **Zeit:** immer `startTimeUtc` + `utcOffsetMinutes` + `localDate`. Aggregation läuft über `localDate`.
3. **Zeitreihen** nie ins Firestore-Dokument, sondern heruntergesampelt in Storage.
4. **Serverseitige Felder** (nie vom Client schreibbar): `role`, `coachId`, `trainerVerified`, `metrics`, `metricsVersion`, Verknüpfungsstatus.
5. **Coach-Zugriff** über denormalisiertes `coachId` (gepflegt per Function) und `coachLinks/{athleteId}_{coachId}`. Rules filtern nicht, deshalb Abfrage `where coachId == uid`. Jede Zugriffsentscheidung wird per **Emulator-Test** bewiesen.
6. **Rules:** Standard „deny all". `users/{uid}/private/*` und `webhookEvents` für Clients komplett gesperrt.
7. **Schwellenwerte mit Historie:** Aktivitäten speichern `thresholdsSnapshot` und `metricsVersion`. Schwellenwert-Änderungen wirken nur zukünftig, Neuberechnung nur explizit (`recomputeMetrics`).
8. **Secrets** nur im Secret Manager, nie im Repo, nie im Log. Keine Gesundheitsdaten in Logs oder Push-Texten.
9. Änderungen am Datenmodell nur mit Eintrag in `docs/DECISIONS.md` und Aktualisierung von `docs/DATA_MODEL.md`.
