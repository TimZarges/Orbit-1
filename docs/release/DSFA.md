# Datenschutz-Folgenabschätzung (DSFA) & TOMs

> Entwurf gemäß Art. 35 DSGVO (Datenschutz-Folgenabschätzung) und Art. 32 DSGVO (Technisch-organisatorische Maßnahmen) für die ORBIT Trainingsplattform.
> **Hinweis:** Entwurf zur Vorbereitung der finalen Prüfung durch einen Datenschutzbeauftragten oder Fachanwalt.

---

## 1. Systematische Beschreibung der Verarbeitung

### 1.1 Verarbeitungszweck
ORBIT dient der sportwissenschaftlichen Trainingssteuerung, Leistungsdiagnostik und Erholungsanalyse für Triathleten und Ausdauersportler sowie deren Trainer.

### 1.2 Verarbeitete Datenkategorien (Art. 9 DSGVO)
- **Gesundheitsbezogene Telemetrie:** Herzfrequenzkurven, Ruhepuls (RHR), Herzfrequenzvariabilität (HRV rMSSD), Schlafdauer und Schlaf-Phasen.
- **Leistungsdaten:** Wattkurven (Rad), Schwellenpace (Lauf), Critical Swim Speed (CSS), Laktatschwellen-Schätzungen.
- **GPS- & Geodaten:** Streckenverläufe, Höhenprofile, Geschwindigkeit.

### 1.3 Datenflüsse & Schnittstellen
1. **Athlet & App:** Lokale Eingabe, FIT-Dateiupload oder automatischer Sync via Garmin Connect API.
2. **Backend (Google Cloud / Firebase):** Verarbeitungsregion Frankfurt (`europe-west3`).
3. **Trainer-Zugriff:** Lesender Zugriff nur nach separater, granularer Berechtigung durch den Athleten.

---

## 2. Notwendigkeit und Verhältnismäßigkeit

- **Rechtsgrundlage:** Ausdrückliche Einwilligung (Art. 9 Abs. 2 lit. a DSGVO) vor Beginn jeglicher Gesundheitsdatenverarbeitung.
- **Zweckbindung:** Ausschließlich zur individuellen Trainings- und Erholungssteuerung; keine Weitergabe an Versicherer, Werbenetzwerke oder Datenbroker.
- **Datensparsamkeit:**
  - Zeitreihen-Streams werden serverseitig heruntergesampelt (1 Hz) in Storage abgelegt; Hauptdokumente in Firestore bleiben frei von Roh-Telemetrie.
  - Push-Benachrichtigungen transportieren keine Gesundheitswerte.
  - Kartenkacheln externer Anbieter erfordern gesondertes Opt-in.

---

## 3. Risikobewertung & Abhilfemaßnahmen

| Identifiziertes Risiko | Eintrittswahrscheinlichkeit / Schwere | Schutz- und Abhilfemaßnahmen in ORBIT |
|---|---|---|
| **Unbefugter Zugriff auf sensible Gesundheitsdaten durch fremde Trainer** | Niedrig / Hoch | Firestore Security Rules erzwingen Link-Prüfung (`coachLinks/{athleteId}_{coachId}`) und Schalter `permissions.health == true`. Unberechtigte Anfragen werden server-seitig mit `PERMISSION_DENIED` abgewiesen. |
| **Profilbildung / unbemerkte Datenweitergabe** | Sehr niedrig / Hoch | Keine Einbindung von Third-Party Tracking- oder Werbe-SDKs. Keine Weitergabe an Werbenetzwerke. |
| **Verfälschung von Schwellenwerten / Fehlsteuerung des Trainings** | Mittel / Mittel | Pacing- und Variabilitätsindex-Filter bei Schätzmethoden. Trainer kann Vorschläge nur mit Status `PENDING` einreichen; Übernahmeentscheidung liegt ausnahmslos beim Athleten. |
| **Verlust der Datenhoheit bei Kontoschließung** | Niedrig / Mittel | In-App-Löschung (Art. 17) und Datenexport (Art. 20) als maschinenlesbares JSON. Statische Löschseite für Web-Nutzer ohne App. |

---

## 4. Technisch-organisatorische Maßnahmen (TOMs gem. Art. 32 DSGVO)

1. **Pseudonymisierung & Verschlüsselung:**
   - Verschlüsselung *in transit* (TLS 1.3) und *at rest* (AES-256 in Firestore & Google Cloud Storage).
   - OAuth-Tokens und API-Secrets liegen im Google Cloud Secret Manager (streng getrennt von App-Daten).
2. **Vertraulichkeit (Zugriffskontrolle):**
   - Granulare Firestore & Storage Security Rules nach dem Least-Privilege-Prinzip.
   - Admin-Rollen und Berechtigungs-Flags (`role`, `coachId`) können nicht vom Client modifiziert werden.
3. **Integrität & Belastbarkeit:**
   - 2nd Gen Cloud Functions in der EU (`europe-west3`).
   - Idempotente Webhook-Verarbeitung mit Deduplizierung.
4. **Wiederherstellbarkeit:**
   - Automatisierte Backups und Point-in-Time Recovery (PITR) für Firestore.
