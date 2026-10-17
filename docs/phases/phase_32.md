# PHASE 32 — Zwei globale Coach-Modi (Einfach/Datei-Download vs. Analyse) & Header-Benachrichtigungsglocke

## Modus & Zielsetzung
- **Modus:** AUTONOMER BETRIEB (Google Pixel 10 Pro via USB / `adb`)
- **Ziel:** Entflechtung der Kommunikation (Header-Mitteilungszentrale vs. Coach-Chat) und Einführung zweier globaler Betriebsmodi für Trainer inklusive Originaldateien-Archivierung und -Download.

---

## Arbeitspakete

### 32.1 Header-Benachrichtigungsglocke vs. „Coach“-Tab
1. **Header-Mitteilungszentrale:**
   - Umbau des Chat-Icons oben rechts in der App-Bar zu einer **Glocke (`Icons.notifications`) mit Ungelesen-Badge**.
   - Eingang aller System-Mitteilungen:
     - Erkennung neuer Schwellenwerte / PRs
     - Abschluss von Garmin-Synchronisationen
     - Trainer-Aktivitäten (neues Workout eingeplant, Training kommentiert)
2. **Coach-Tab:**
   - Bündelung des direkten 1:1-Austauschs zwischen Athlet und Trainer ausschließlich im unteren Tab **„Coach“**.

### 32.2 Original-Datei-Archivierung
1. **Sichere Speicherung:**
   - Bei jedem Upload oder Garmin-Import wird die unveränderte Originaldatei (`.fit`, `.tcx`, `.gpx`) in Cloud Storage archiviert:
     - Pfad: `users/{uid}/rawActivities/{activityId}.fit` (region: `europe-west3`).
2. **Zugriffsschutz:**
   - Abgesichert durch Cloud Storage Rules: Zugriff nur für den Athleten selbst sowie für verbundene Trainer mit aktiver Freigabe.

### 32.3 Zwei globale Ansichtsmodi für den Coach
1. **Globaler Modus-Umschalter für Trainer (nicht pro Athlet einzeln, sondern zentral):**
   - **Modus 1 — „Einfach (Übersicht & Originaldatei-Download)“:**
     - Schlanke Athleten-Übersicht mit Fokus auf Kernfakten (Sportart, Dauer, Distanz, Ø HF, Ø Watt).
     - Prominenter **Direkt-Download-Button für die Originaldatei** (`.fit`/`.tcx`) pro Einheit zur Weiterverarbeitung in externer Spezialsoftware (WKO5, GoldenCheetah, etc.).
   - **Modus 2 — „Analyse (Volles Cockpit)“:**
     - Volles ORBIT-Erlebnis: Bei aktiver Freigabe Einsicht in alle Gesundheitsdaten, 3 Ringe, Leistungskurven, Intervall-Splits und Tiefentelemetrie.

---

## Verifikation & Nachweise
- Screenshot der Glocken-Mitteilungszentrale mit Badge.
- Nachweis der Originaldatei-Archivierung in Cloud Storage (`europe-west3`).
- Screenshot der beiden Coach-Modi auf dem Tablet/Web und Smartphone.
