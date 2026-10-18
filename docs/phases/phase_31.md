# PHASE 31 — Garmin-Daten-Empfang reparieren, Karten (Hell/Dunkel + Volt-Linie), Neue Leistungstests & PR-Datenbank

## Modus & Zielsetzung
- **Modus:** AUTONOMER BETRIEB (Google Pixel 10 Pro via USB / `adb`)
- **Ziel:** Vollständige Behebung des Garmin-Datenempfangs, Karten-Visualisierung mit leuchtender Volt-Linie und Hell/Dunkel-Modus, Erweiterung der Diagnostik-Standardtests und Einführung einer vollwertigen PR-Datenbank inkl. Leistungskurven.

---

## Arbeitspakete

### 31.1 Garmin-Synchronisation & Live-Aktivitätsdaten
- [x] **Cloud-Log-Audit:**
  - Analyse der Cloud-Function-Logs (`garminAuthCallback`, `garminWebhook`, `requestGarminBackfill`).
  - Prüfung, warum nach erfolgreichem OAuth-Login keine Einheiten in Firestore hinterlegt wurden (Untersuchung von Push-Payload vs. Ping-`callbackURL`, Endpunkt-Registrierung bei Garmin und Backfill-Chunks).
- [x] **Robuster Pull-/Backfill-Mechanismus:**
  - Automatischer Sync-Fallback bei Verbindungsaufbau inklusive sichtbarem Sync-Status in der App.
- [x] **Reale Test-Aktivitäten:**
  - Bereitstellung und Import realer Test-Aktivitäten (Rad & Lauf mit GPS, Watt, HF, Trittfrequenz) auf dem Test-Account, sodass auf dem Smartphone sofort echte Einheiten mit GPS-Karten und Telemetriekurven verfügbar sind.

### 31.2 GPS-Aktivitätskarte: Leuchtende Volt-Strecke & Hell/Dunkel-Toggle
- [x] **Strecken-Visualisierung:**
  - Standardmäßige Darstellung des Tracks als leuchtende `#CDFB17` Volt-Linie mit dunkler `#001F47` Kontur (Outlined Polyline) für maximalen Kontrast auf allen Untergründen.
  - Umschalter für Heatmap- bzw. Zonen-Färbung (nach Watt, Puls oder Pace).
- [x] **Karten-Stil:**
  - Direkter Toggle auf der Karte zwischen **Heller Karte (Topografie / OSM-Standard für Lesbarkeit bei Sonnenlicht)** und **Dunkler Cockpit-Karte (Dark Tile Server)**.

### 31.3 Leistungsdiagnostik: Kontrast-Korrektur & Neue Standard-Tests
- [x] **UI-Reparatur:**
  - Beseitigung schlechter Kontraste und abgeschnittener Texte auf den 3 Tabs (*Rad*, *Lauf*, *Schwimmen*).
- [x] **Zwei neue Standard-Testprotokolle:**
  - **Radfahren:** **Stufentest (Ramp Test)**:
    - Start bei 100 Watt, Steigerung alle 30 Sekunden um +25 Watt bis zur subjektiven Erschöpfung.
    - Automatische Berechnung von $MAP$ (Maximum Aerobic Power) und $\text{FTP} \approx 0{,}75 \times \text{beste 1-Min-Leistung}$.
  - **Laufen:** **5-Minuten-All-Out-Test**:
    - Maximale Distanz über 5 Minuten zur Ermittlung von $\text{vVO}_2\text{max}$ und Schwellenpace.

### 31.4 PR-Datenbank & Leistungskurven (Power / Pace Duration Curve)
- [x] **Persönliche Bestleistungen (PR-Tracking):**
  - Rad: Watt & W/kg über `5s, 15s, 30s, 1m, 3m, 5m, 10m, 20m, 60m, 90m, 180m`.
  - Lauf: Beste Zeiten über `400m, 1km, 3km, 5km, 10km, Halbmarathon, Marathon`.
  - Schwimmen: `100m, 200m, 400m, 800m, 1500m`.
  - Filterung nach **Overall (All-Time)**, **Aktuellem Jahr (z. B. 2026)** und **Freiem Datumszeitraum**.
- [x] **Leistungskurven-Vergleich:**
  - Interaktive Power-Duration-Kurve im Analyse-Tab.
  - In jeder Einzelaktivität: Direktes Overlay der Einheiten-Kurve gegen die PR-Referenzkurve des gewählten Zeitraums.

---

## Verifikation & Nachweise
- Cloud-Log-Nachweis der Garmin-Behebung.
- Screenshot der Volt-Strecke auf heller und dunkler Karte.
- Screenshot der Diagnostik mit Ramp-Test und 5-Minuten-All-Out-Test.
- Screenshot der PR-Datenbank und Leistungskurve auf dem Pixel 10 Pro.
