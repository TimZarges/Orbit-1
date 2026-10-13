# Release-Checkliste & Betriebshandbuch (Launch-Readiness v1.0)

> Verbindliche Checkliste vor jedem Release und Anleitung für den produktiven Betrieb von ORBIT.

---

## 1. Pre-Flight Checkliste (Vor dem Release-Build)

- [x] **Code & Analyse:** `flutter analyze` fehlerfrei, null Warnungen.
- [x] **Unit & Domain Tests:** Alle Tests grün (Metriken, Resolver, Grid-Controller, Lokalisierung).
- [x] **Sicherheits-Audit:** Keine Geheimnisse, Keys oder Secrets im Code (`docs/release/SECURITY_AUDIT.md`).
- [x] **Firestore & Storage Rules:** Strikte Regeln für alle Collections aktiv, Client-Schreibschutz für Admin-Felder bewiesen (`docs/RULES_TESTPLAN.md`).
- [x] **Datenschutz & Recht:** Datenschutzerklärung (`docs/PRIVACY.md`), Löschseite (`web/delete-account.html`), Data Safety (`docs/release/DATA_SAFETY.md`).
- [x] **Android Build-Konfiguration:**
  - `applicationId`: `app.orbit.training`
  - `minSdk`: Mindestversion unterstützt
  - `targetSdk`: Aktuelle Android-Version
  - `isMinifyEnabled`: Proguard/R8 aktiv mit `proguard-rules.pro`
  - `key.properties`: Upload-Schlüssel vorhanden (außerhalb von Git)

---

## 2. Firestore Datensicherung & Point-in-Time Recovery (PITR)

### 2.1 PITR aktivieren (Schutz vor versehentlichem Datenverlust)
Im Terminal (Google Cloud CLI):
```bash
gcloud firestore databases update \
  --project=orbit-app-prod \
  --database="(default)" \
  --point-in-time-recovery-enable
```
*Vorteil:* Ermöglicht die minutengenaue Wiederherstellung des Datenbankzustands der letzten 7 Tage.

### 2.2 Tägliches Cloud Storage Backup (Cron Job)
Export aller Firestore Collections in einen gesicherten Backup-Bucket:
```bash
gcloud firestore export gs://orbit-firestore-backups-prod \
  --project=orbit-app-prod
```

---

## 3. Monitoring & Alarmschwellen (Cloud Logging / Firebase)

1. **Functions-Fehlerrate:**
   - Metrik: `cloudfunctions.googleapis.com/function/execution_count` mit `status != 'ok'`.
   - Alert: Schwellenwert > 1% Fehler über einen 5-Minuten-Zeitraum.
2. **Kosten- & Quotenüberwachung:**
   - Budget-Warnung bei 50%, 80% und 100% des Monatsbudgets (GCP Billing Console).
3. **App Check Monitoring:**
   - Überwachung abgelehnter oder unauthentifizierter Anfragen in der Firebase Console.
4. **Crash-Monitoring:**
   - Firebase Crashlytics Velocity Alert: Benachrichtigung bei neuen Abstürzen, die mehr als 1% der aktiven Sitzungen betreffen.

---

## 4. Rollback-Plan bei kritischen Fehlern

Falls nach einem Release in Produktion ein kritischer Fehler auftritt:

1. **Mobile App (Android Play Store):**
   - In der Google Play Console: Im Release-Dashboard die Freigabe des problematischen Tracks sofort pausieren (*Rollout anhalten*).
   - Hotfix-Branch erstellen (`fix/hotfix-1.0.1`), Versionsnummer in `pubspec.yaml` erhöhen und Notfall-Release mit 100% Rollout hochladen.
2. **Cloud Functions Backend:**
   - Rollback auf vorherige Revision per Google Cloud Console oder CLI:
     ```bash
     firebase deploy --only functions
     ```
3. **Firestore Security Rules:**
   - Regeln können ohne App-Update innerhalb von Sekunden über `firebase deploy --only firestore:rules` auf den vorherigen Stand zurückgesetzt werden.
