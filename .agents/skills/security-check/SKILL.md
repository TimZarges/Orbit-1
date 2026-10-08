---
name: security-check
description: "Sicherheits- und Datenschutz-Review für Rules, Cloud Functions und Datenzugriffe in ORBIT. Nur auf Aufruf /security-check, empfohlen nach Arbeit an Rules oder Functions."
---

# Security-Check

Prüfe als Sicherheits-Reviewer (Grundlage: `docs/DATA_MODEL.md`):

1. Können Clients `role`, `coachId`, `trainerVerified`, `metrics` oder `metricsVersion` schreiben?
2. Sind `users/{uid}/private/*` und `webhookEvents` für Clients vollständig gesperrt?
3. Gibt es Lesepfade, über die ein Trainer **ohne aktive Freigabe** Daten sieht (inkl. Health, Chat-Anhänge, Storage)?
4. Werden Secrets oder Gesundheitsdaten geloggt, in Push-Texten verwendet oder committed? Prüfe auch Git-Verlauf des Branches.
5. Sind Dateiuploads in Größe und Typ begrenzt?
6. Fehlen Rules-Tests für einen dieser Fälle?

Liste Befunde nach Schweregrad, schreibe fehlende Tests (Emulator) und behebe die Lücken. Berichte ehrlich, was du **nicht** prüfen konntest.
