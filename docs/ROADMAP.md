# ORBIT Roadmap — Verbindlicher Verweis auf `docs/ROADMAP_V1_TO_V4.md`

> [!IMPORTANT]
> **Einzige verbindliche Quelle (Single Source of Truth):**  
> Die gesamte Produkt- und Versions-Roadmap von **V1.0.0 bis V4.0.0** sowie der detaillierte Phasenplan von **Phase 40 bis Phase 46** sind verbindlich in **[`docs/ROADMAP_V1_TO_V4.md`](ROADMAP_V1_TO_V4.md)** definiert.  
> Den aktuellen Abarbeitungsstand aller Phasen findest du in **[`docs/PROGRESS.md`](PROGRESS.md)** (synchron mit [`PROGRESS.md`](../PROGRESS.md) im Hauptverzeichnis) und die Abnahme-Nachweise in **[`docs/CHECKPOINTS.md`](CHECKPOINTS.md)**.

---

## 1. Kurzübersicht der Versions-Meilensteine (Details in `docs/ROADMAP_V1_TO_V4.md`)

| Version | Fokus & Kern-Umfang | Phasen |
| :--- | :--- | :--- |
| **V1.0.0** | **Core Launch (Datei- & Kalender-Hub, Garmin-Sync, Athlet-Coach-Brücke & `.FIT`-Download)**<br>• COROS-inspirierte Trainings-Vorschaukarte (nicht klickbar in V1.0.0, rechts direkter `.FIT`-Download-Button statt GPX-Grafik).<br>• Heute-Ansicht zeigt ausschließlich absolviertes Training (+ Schnellzugriff Garmin Sync & Datei-Upload).<br>• Kalender zeigt Training in Woche, Monat und Liste.<br>• Onboarding & Profil „Einfach“ für Athlet & Coach inkl. Triathlon, Hell-/Dunkel-Modus (`#F4F6F9` / `#0D0F12`), Sprache DE & EN, Datum `dd.mm.yy` und 24h-Format nach Wohnland.<br>• Coach-Funktionen: Athleten-Verbindung, eigene Coach-Navigation (*Athleten*, *Kalender*, *Profil/Einstellungen*) & `.FIT`-Download.<br>• Volle DE/EU-Rechtskonformität (DSGVO Art. 9 Opt-In, Art. 17 Kontolöschung In-App & Web, Art. 13/14 Datenschutzerklärung & DDG § 5 Impressum). | **Phasen 40–46** (`v0.40.0` bis `v1.0.0`) |
| **V2.0.0** | **Profi-Coaching, Visueller Block-Workout-Builder & Analyse Einfach**<br>• MATS-inspirierter 2D Post-Workout-Puck (Wohlbefinden vs. Intensität) & Athleten-Verfügbarkeitsprofile.<br>• Mobiler Klick-Workout-Builder (`#lit`/`#mit`/`#hit` + Ernährungsvorgaben) & Soll/Ist-Erfüllungs-Ampel.<br>• Klickbare Trainingskarten → Basis-Aktivitätsdetail & Wettkampf-Kalender (A/B/C). | Geparkt in `ReleaseConfig.isV2Enabled` |
| **V3.0.0** | **Wissenschaftliches Telemetrie- & Health-Cockpit**<br>• 1Hz Multi-Stream-Scrubber, NP/Iso-Power, IF, ORBIT Load, VI, EF, Aerobic Decoupling (`Pw:Hr`), Skiba $W'\text{bal}$, MMP Power-Duration-Kurve.<br>• Banister PMC (CTL/ATL/TSB) mit Fitness-Rampenraten (7d, 28d, 90d, 365d).<br>• 3-Ringe Health & Recovery Cockpit, 30d-Baselines ($\mu \pm 1\sigma$), 45s Morgen-Check-in & 2 globale Coach-Modi. | Geparkt in `ReleaseConfig.isV3Enabled` |
| **V3.1.0 / V4.0.0** | **Team-Ökosystem, Drittanbieter-Connectoren & ORBIT KI-Co-Coach**<br>• Wahoo, Polar, Coros, Zwift, Apple Health, Android Health Connect & strukturierter Workout-Export auf Garmin-Uhren.<br>• Vereins-Boards, Trainingslager, Equipment-Tracking & konversationeller AI Co-Coach. | Ausbaustufe nach V3.0.0 |

---

## 2. Historisches Phasen-Archiv (Phasen 00–39)

- **Phasen 00–16:** Fundament & Basis-Architektur (`docs/phases/phase-00-foundation.md` bis `phase-16-release.md`).
- **Phasen 17–24:** Beta-Reparatur, Daten-Pipeline, GoldenCheetah-Formel-Verifikation, Whoop-inspiriertes Health-Cockpit, Web-Plattform & 150-FIT-Stresstest (`docs/phases/phase_17.md` bis `phase_24.md`).
- **Phasen 25–39:** Autonome E2E-Hardware-Audits auf dem Google Pixel 10 Pro, Garmin Live-OAuth & 20 Webhooks, 100 % deutsche Code-Dokumentation (`docs/phases/phase_25.md` bis `phase_39.md`).
- **Ab Phase 40:** Siehe [`docs/ROADMAP_V1_TO_V4.md`](ROADMAP_V1_TO_V4.md) und `docs/phases/phase_40.md` ff.
