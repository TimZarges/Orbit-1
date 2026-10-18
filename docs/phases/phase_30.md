# PHASE 30 — Kalender-Neubau, Visueller Block-Workout-Builder, Echt-Watt/Pace-Umrechnung & Soll/Ist-Erfüllungs-Ampel

## Modus & Zielsetzung
- **Modus:** AUTONOMER BETRIEB (Google Pixel 10 Pro via USB / `adb`)
- **Ziel:** Komplette Überarbeitung des Trainingskalenders und des Workout-Builders nach den Vorgaben aus `Orbit Test Bug.pdf`. Intuitive Touch-Bedienung auf dem Smartphone, visuelle Blockprofile und automatischer Soll/Ist-Vergleich.

---

## Arbeitspakete

### 30.1 Tab-Umbenennung & Kalender-Darstellung
- [x] **Navigations-Tab:**
  - Umbenennung des unteren Navigations-Tabs von „Plan“ in **„Kalender“** (inkl. Kalender-Icon).
- [x] **Kontrast- und Layout-Reparatur:**
  - Beseitigung von Dunkelblau auf Dunkelblau. Das aktuelle Datum (z. B. „Samstag, 17.10.“) wird prominent in Volt `#CDFB17` bzw. hellem Kontrast hervorgehoben.
  - Behebung abgeschnittener Texte unter der „Wochensoll“-Karte.
  - **Echtzeit-Reaktivität:** Neu erstellte oder verschobene Einheiten erscheinen **sofort ohne App-Neustart** im Kalender und auf dem „Heute“-Screen.
- [x] **Monatsansicht:**
  - Visualisierung jedes Kalendertages:
    - **Leere Kreise (`○`)**: Geplante, noch nicht absolvierte Trainingseinheiten.
    - **Ausgefüllte Punkte (`●`)**: Erfolgreich absolvierte Einheiten.
    - Farbkodierung nach Disziplin/Sportart (Rad: Cyan/Volt, Lauf: Orange/Volt, Schwimmen: Blau, Kraft: Violett) analog zur Analyse-Verteilung.

### 30.2 Workout-Builder (Visuell auf Smartphone vs. Text im Web)
- [x] **Plattform-spezifische Eingabe:**
  - **Smartphone:** Ausschließliche Bedienung per Klick mit visuellen Blöcken (kein manueller Text-Parser auf dem Touchscreen).
  - **Web (`/app`):** Zusätzlicher schneller Text-Editor für Trainer und Desktop-Nutzer.
- [x] **Die 5 Kern-Blocktypen:**
  - *Aufwärmen (Warmup)*
  - *Aktives Intervall (Active Work)*
  - *Erholung / Pause (Recovery)*
  - *Wiederholungs-Schleife (Repeat Loop, z. B. 4x)*
  - *Ausrollen / Abwärmen (Cooldown)*
  - Intuitive, stimmige Farb- und Symbol-Kodierung nach Intensität (z. B. Volt/Orange für Arbeit, Blau/Cyan für Erholung).
- [x] **Vorlagen vs. Tages-Kommentare:**
  - **Titel & feste Beschreibung:** Bleiben dauerhaft am Workout erhalten (beim Speichern als Vorlage, Verschieben oder Zuweisen an andere Athleten).
  - **Tages-Kommentarfunktion (Feed):** Ein an genau dieses Datum und diese Ausführung gebundener Kommentar-Feed für Pre-Workout-Hinweise und Athlet-Trainer-Feedback.

### 30.3 Visuelle Block-Darstellung & Automatische Schwellenwert-Umrechnung
- [x] **Visuelles Block-Profil:**
  - Darstellung geplanter Einheiten als strukturierte Balkengrafik (Block-Profil) auf dem **„Heute“-Screen** und in der Kalender-Detailansicht.
- [x] **Dynamische Umrechnung auf den aktuellen Leistungsstand:**
  - Planung erfolgt relativ in **% des Schwellenwerts** (z. B. `95–100 % FTP` oder `90 % Schwellenpace`).
  - Die App rechnet diese Werte live anhand der Schwellenwerte des Athleten (aus Diagnostik / Auto-Erkennung) um und zeigt neben der Zone die konkreten Zielwerte an:
    - Beispiel Rad: *„4x 4 Min @ 95–100 % (320–337 W)“*
    - Beispiel Lauf: *„6x 1000m @ 95 % (4:05 min/km)“*
    - Beispiel HF: Pulsbereich in Schlägen/Minute.

### 30.4 Automatischer Soll/Ist-Abgleich (Erfüllungs-Ampel)
- [x] **Matching-Algorithmus:**
  - Erkennt bei Upload oder Garmin-Sync automatisch die am besten zum geplanten Tagestraining passende Einheit derselben Sportart.
  - Vergleicht Dauer, Belastung (ORBIT Load / TSS) und Intensität.
- [x] **Erfüllungs-Ampel:**
  - **🟢 Grün (Perfekt / fast perfekt erfüllt):** Abweichung $\le 15\,\%$.
  - **🟡 Gelb (Größere Abweichung):** Abweichung zwischen $15\,\%$ und $35\,\%$.
  - **🔴 Rot (Extreme Abweichung oder nicht absolviert):** Abweichung $> 35\,\%$ oder Einheit nicht durchgeführt.
  - **Wichtig:** Status Rot für nicht absolvierte Einheiten wird erst **am Folgetag ab 00:00 Uhr** gesetzt, niemals während des laufenden Tages.

---

## Verifikation & Nachweise
- Reaktivitätstest: Workout planen und sofortiges Erscheinen im Kalender prüfen.
- Visuelles Profil auf „Heute“ per Screenshot nachweisen.
- Soll/Ist-Ampel-Unit-Tests und Live-Ansicht auf dem Pixel 10 Pro.
