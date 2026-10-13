# Offene Punkte und Restschulden (Release-Audit v1.0)

> Status-Kategorien:
> - **FIX:** In Phase 16 behoben / implementiert.
> - **BEWUSST AKZEPTIERT:** Für v1.0 Release als architekturelle Vereinfachung akzeptiert (Post-MVP Roadmap).
> - **BLOCKIERT (MANUELL):** Erfordert externe Freigaben, Konsolenzugriffe oder Schlüssel vom Betreiber (siehe `docs/MANUAL_STEPS.md`).

---

## 1. Überprüfung der RISIKO-HOCH Checkpoints aus Phasen 01–15

| Phase | Thema | Risiko | Entscheidung / Status |
|---|---|---|---|
| **Phase 01** | Auth, Rollen-Schreibschutz (`role`, `coachId`) | HOCH | **FIX / BEWIESEN:** Durch `firestore.rules` geschützt. Nur Admin SDK darf Rollen setzen. |
| **Phase 02** | Coach-Verknüpfung & Invites | HOCH | **FIX / BEWIESEN:** `coachLinks` und `invites` durch strikte Security Rules geschützt. Granulare Berechtigungen (`calendar`, `activities`, `health`). |
| **Phase 06** | Garmin Webhook, Secrets & OAuth | HOCH | **BLOCKIERT (MANUELL):** Garmin Production API Antrag & Secret Manager Eintrag erforderlich (siehe `docs/MANUAL_STEPS.md`). Architektur & Code sind vorbereitet. |
| **Phase 07** | Gesundheitsdaten Art. 9 DSGVO & Consent | HOCH | **FIX / BEWIESEN:** Einwilligungs-Protokollierung mit Zeitstempel & Version. `dailyMetrics` nur für Trainer lesbar bei `permissions.health == true`. |
| **Phase 08** | Kalender & Geplante Workouts | HOCH | **FIX / BEWIESEN:** Security Rules schützen `plannedWorkouts`. Nur Trainer mit `permissions.calendar == true` darf planen. Unveränderliche Felder fixiert. |
| **Phase 10** | Aggregates & Lesezugriff für Trainer | HOCH | **FIX / BEWIESEN:** Trainer benötigt `permissions.activities == true`. Client-Schreibzugriff auf `aggregates` strikt `false`. |
| **Phase 11** | Cockpit & Bestwerte (`bests/{sport}`) | HOCH | **FIX / BEWIESEN:** Client-Schreibzugriff gesperrt, serverseitige Pflege. |
| **Phase 12** | Leistungsdiagnostik & Schwellenwerte | HOCH | **FIX / BEWIESEN:** Athleten-Souveränität gewahrt: Nur der Athlet darf Vorschläge akzeptieren (`ACCEPTED`/`REJECTED`). Formeln durch Variabilitätsindex- und Standardabweichungs-Filter abgesichert. |
| **Phase 13** | Chat-Sicherheit, Soft-Delete & Push-Datensparsamkeit | HOCH | **FIX / BEWIESEN:** Strikte Isolation auf Chat-Teilnehmer (`isChatParticipant`). Soft-Delete implementiert. FCM Pushs datensparsam ohne sensible Gesundheitsdaten. |
| **Phase 15** | Coach-Dashboard O(1) & Massenzuweisung | HOCH | **FIX / BEWIESEN:** `coachDashboard/{coachId}/athletes` schützt Quotas. Massenzuweisung validiert Kalender-Berechtigung atomar. |

---

## 2. Code-Fundstellen (`TODO` & `VORLÄUFIG`)

| Datei | Fundstelle | Kategorie | Begründung & Maßnahme |
|---|---|---|---|
| `docs/ORBIT_SCORE.md` | „VORLÄUFIG – nicht freigegeben" | **BEWUSST AKZEPTIERT** | Der ORBIT Score ist eine orientierende Belastungsmetrik (kein Medizinprodukt). In der UI wird transparent die Form-Ampel (Frisch/Optimal/Ermüdet) und der Volt Daily Ring genutzt. Keine Heilsversprechen. |
| `functions/src/import/fitParser.ts` | Sport-Typen Mapping | **FIX** | In Phase 16 behoben: Vollständiges Mapping der Standard FIT Sport-IDs (RUN, BIKE, SWIM, STRENGTH, OTHER). |
| `lib/features/settings/screens/settings_screen.dart` | Zu Datenschutz-Details navigieren | **FIX** | In Phase 16 behoben: Aufruf des `PrivacySettingsSheet` mit Einsicht in DSGVO-Rechte, Datenexport und Kontolöschungs-Link. |
| `lib/features/profile/screens/thresholds_screen.dart` | Neuen Wert erfassen | **FIX** | In Phase 16 behoben: Direkter Dialog zur Schnellerfassung neuer Schwellenwerte mit Gültigkeitsprüfung. |
| `lib/features/coach_link/screens/athlete_coach_tab_screen.dart` | Invite-Code & Link verwalten | **FIX** | In Phase 16 behoben: Dialog zur Invite-Code-Eingabe, Bestätigungsdialog für Widerruf und Umschalten der Berechtigungen verdrahtet. |
| `lib/features/profile/screens/profile_screen.dart` | Profilbild-Upload | **BEWUSST AKZEPTIERT** | V1.0 nutzt Initialen-Avatar & systemgenerierte Icons. Datei-Upload für Cloud Storage ist im Chat bereits erprobt; Profilfoto-Upload ist Post-MVP. |
| `functions/src/metrics/recompute.ts` | Hintergrund-Neuberechnung | **BEWUSST AKZEPTIERT** | On-Demand Neuberechnung via Cloud Tasks ist für v1.0 bei Standard-Historie (< 1 Jahr) ausreichend performant; Cloud Tasks Worker Queue ist für spätere Laststeigerung vorgesehen. |

---

## 3. Manuelle Betreiber-Aufgaben (Auszug aus `docs/MANUAL_STEPS.md`)

1. **Google Play Console:** Dienstkonto für Upload, Inhaltsbewertung, Data Safety Fragebogen (Vorlage in `docs/release/DATA_SAFETY.md`).
2. **App Check:** reCAPTCHA Enterprise für Web und Play Integrity für Android aktivieren.
3. **Garmin Health API:** Production Review einreichen (Checkliste in `docs/release/GARMIN_REVIEW.md`).
4. **Rechtliche Prüfung:** Datenschutzerklärung (`docs/PRIVACY.md`) und Impressum mit Fachanwalt für Sport-/Datenschutzrecht final freigeben.
