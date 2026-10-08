# Entscheidungen (ADR-Log)

> Jede nicht triviale Entscheidung bekommt einen Eintrag: Datum, Kontext, Entscheidung, Begründung, Alternativen. Neueste oben.

## Vorlage
### YYYY-MM-DD: Titel
- **Kontext:**
- **Entscheidung:**
- **Begründung:**
- **Alternativen:**

---

## Bereits festgelegt (vor Projektstart)
- **Geplant ≠ absolviert:** getrennte Collections `plannedWorkouts` und `activities`, gegenseitig verknüpft.
- **Navigation:** rollenabhängig, 4 Tabs je Rolle, Profil hinter dem Avatar.
- **Erfahrungsstufen** Einfach/Fortgeschritten/Experte steuern Datendichte und Begriffe.
- **Metriken serverseitig**, Dart nur Vorschau, gemeinsame Testvektoren.
- **Coach-Zugriff** über denormalisiertes `coachId`, gepflegt per Function.
- **Webhook-Verarbeitung** über `webhookEvents` + Firestore-Trigger (kein Cloud Tasks im MVP).
- **Login:** Google + E-Mail/Passwort; Apple mit iOS-Start.
- **Score-Name:** „ORBIT Score" (nicht „MATS Score").
- **Tooling: Antigravity.** Zentrale Regeln in `AGENTS.md`, modulare Regeln in `.agents/rules/` (glob/model_decision), wiederverwendbare Abläufe als **Skills** in `.agents/skills/`. Workflows werden nicht genutzt, weil sie laut Antigravity-Doku am 1. November 2026 abgeschaltet werden.
- **Repo ist privat.** `google-services.json` darf (nach Rückfrage im Audit) committet werden. Service-Account-Schlüssel, Keystores, `.env` und Secrets nie.
- **Autopilot-Modus** (`/phase-run`): STOPP-Punkte werden zu Checkpoints in `docs/CHECKPOINTS.md`, Branches werden gestapelt, harte Stopps nur bei Blockern, Irreversiblem, Regelverstoß, Audit-Befund oder wiederholtem Fehler. Zweck: maximale Selbstständigkeit bei sichtbaren Review-Schulden.
