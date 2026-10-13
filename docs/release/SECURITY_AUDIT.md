# Sicherheits-Audit & Schutzkonzept (Release-Readiness v1.0)

> Stand: 2026-10-13 · Projekt: ORBIT · Region: `europe-west3` (Frankfurt)

---

## 1. Geheimnis- und Token-Audit (Secret Scan)

| Prüfung | Methode | Ergebnis | Status |
|---|---|---|---|
| **API-Keys & Secrets** | Regex-Scan nach AWS, GitHub, GCP Private Keys, OAuth Secrets | Keine privaten Schlüssel oder Secrets im Repository gefunden. | **BESTANDEN** |
| **Client-Schlüssel** | `firebase_options_dev.dart` | Enthält ausschließlich öffentliche Firebase Client API-Keys (durch Rules & App Check geschützt). | **BESTANDEN** |
| **OAuth & Provider Tokens** | `functions/src/` & Storage | Tokens liegen ausschließlich serverseitig in Google Cloud Secret Manager und Firestore `users/{uid}/private/*` (Client-Zugriff durch Rules komplett gesperrt). | **BESTANDEN** |
| **Keystore & Signaturschlüssel** | `.gitignore` & Dateisuche | `*.jks`, `*.keystore`, `key.properties` sind in `.gitignore` ausgeschlossen. | **BESTANDEN** |

---

## 2. Autorisierungs- & Zugriffsmodell (Firestore & Storage)

### 2.1 Firestore Security Rules
- **Standard:** „Deny all" als Grundsatz.
- **Rollen-Schutz:** Felder wie `role`, `coachId`, `trainerVerified` sind für Clients in `users/{uid}` unbeschreibbar.
- **Granulare Trainer-Rechte:** Zugriff auf Athletendaten erfordert einen aktiven Link (`coachLinks/{athleteId}_{coachId}`) und spezifische Flags:
  - `permissions.calendar == true` für geplante Einheiten
  - `permissions.activities == true` für absolvierte Aktivitäten & Aggregationen
  - `permissions.health == true` für sensible Gesundheitsdaten (Ruhepuls, HRV, Schlaf)
- **DoS- & Injektionsschutz:**
  - Zeichenkettenlängen begrenzt (z. B. Titel $\le 200$, Text $\le 2000$).
  - Schlüsselanzahl in Dokumenten begrenzt (`keys().size() <= 50`).
  - Statusübergänge formal eingeschränkt (z. B. Schwellenwert-Vorschläge nur `ACCEPTED`/`REJECTED` durch den Athleten).

### 2.2 Storage Security Rules
- Pfade sind strikt auf authentifizierte Nutzer und deren eigene Ordner beschränkt (`users/{uid}/fit/*`, `users/{uid}/streams/*`).
- Chat-Anhänge (`chats/{chatId}/images/*`, `files/*`) sind auf Teilnehmer des jeweiligen Chats beschränkt.
- Strikte Größen- und MIME-Type-Limits:
  - Bilder: $\le 10\text{ MB}$, Content-Type `image/.*`
  - Dateien: $\le 25\text{ MB}$
  - FIT-Dateien: $\le 20\text{ MB}$

---

## 3. App Check Staged-Rollout-Plan

Zur Abwehr von DoS-Angriffen, Credential-Stuffing und Bots auf Firestore, Storage und Cloud Functions:

```
[Phase 1: Monitoring] (Launch-Woche)
  ├── Android: Play Integrity Provider einrichten
  ├── Web: reCAPTCHA Enterprise Site-Key hinterlegen
  ├── Firebase Console: App Check im Modus "Monitoring" aktivieren
  └── Metriken beobachten: Anteil unauthentifizierter Anfragen analysieren

[Phase 2: Staging-Enforcement] (Woche 2)
  ├── Aktivierung im Dev-Projekt
  └── Validierung von CI/CD und Emulator-Bypass (Debug Tokens)

[Phase 3: Production-Enforcement] (Woche 3)
  └── Erzwingung ("Enforce") für Firestore, Storage und Callable Functions
```

---

## 4. Missbrauchsschutz für Cloud Functions

1. **Idempotenz:** Externe Webhook-Ereignisse (Garmin) werden in `webhookEvents/{id}` mit Deduplizierung über `(source, externalId)` verarbeitet.
2. **Kaltstart- und Speicherbegrenzung:**
   - 2nd Gen Cloud Functions in `europe-west3`.
   - Speicherlimitierung (256 MB für Standard-Funktionen, 512 MB für FIT-Parser).
   - Timeouts standardmäßig auf 60 Sekunden begrenzt.
3. **Produktions-Schutz für Seed-Skripte:**
   - Skripte wie `seed_coach_athletes.ts` brechen bei `NODE_ENV === 'production'` sofort mit einer Fehlermeldung ab.

---

## 5. Kostenabschätzung und Budget-Alarme

### 5.1 Read/Write-Budget pro Hauptscreen
- **Home („Heute"):** $\le 4$ Reads pro Öffnung (Tagesaggregat, 1 geplantes Workout, 1 Aktivität, Profil).
- **Kalender:** 7–31 Reads für Monatssicht mit Caching.
- **Coach Dashboard:** O(1) Reads über `coachDashboard/{coachId}/athletes` (1 Read pro Athlet statt 4–8 Reads).

### 5.2 Empfohlene Budget-Alarme (GCP Console)
In der Google Cloud Console unter *Billing $\rightarrow$ Budgets & Alerts* folgende Schwellenwerte einrichten:
- **50% des Monatsbudgets (z. B. 25 €):** Warn-E-Mail an Entwickler.
- **80% des Monatsbudgets (z. B. 40 €):** Warn-E-Mail mit Dringlichkeitsstufe.
- **100% des Monatsbudgets (z. B. 50 €):** Benachrichtigung zur Quotenprüfung.
