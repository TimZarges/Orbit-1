# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 10 (Abgeschlossen) -> Phase 11 (Analyse Cockpit & Telemetrie)
- Branch: feature/phase-10-analysis-simple

## Fertig
- Phase 00 (Foundation): Abgeschlossen
- Phase 01 (Auth & Onboarding): Abgeschlossen
- Phase 02 (Trainer-Verknüpfung): Abgeschlossen
- Phase 03 (Profil, Einstellungen, Schwellenwerte): Abgeschlossen
- Phase 04 (Aktivitäts-Import): Abgeschlossen
- Phase 05 (Metrik-Kern): Abgeschlossen
- Phase 06 (Garmin-Connector): Abgeschlossen
- Phase 07 (Gesundheitsdaten & Daily Metrics): Abgeschlossen
- Phase 08 (Kalender und Soll-Ist-Abgleich): Abgeschlossen
- Phase 09 (Workout Builder und Vorlagenbibliothek): Abgeschlossen
- Phase 10 (Analyse einfach – Ampel, Wochenbelastung, Erfahrungsstufen):
  - Form-Ampel-Domänenlogik (`FormCalculator`, `FormTrafficLight`) mit individuellem TSB/CTL-Verhältnis, 21-Tage-Mindestdatenprüfung, Mindest-CTL (10.0), transparentem Datenbasis-Nachweis und 4 physiologischen Zuständen (`veryTired`, `wellLoaded`, `balanced`, `fresh`).
  - Progressive Disclosure nach Erfahrungsstufe (§7a DESIGN.md):
    - *Einfach:* Form-Ampel, Wochenbelastung vs. Plan (Ist/Soll-Balken mit Erfüllungsgrad und Klartext), Konsistenz-Karte (aktive Tage & Streaks).
    - *Fortgeschritten:* Zusätzlich Sportartenverteilung (horizontaler Stapelbalken statt Torte), Zonenverteilung (Z1–Z7 mit barrierefreien Labels und Farbsehschwäche-Schutz), 8-Wochen-Belastungstrend.
    - *Experte:* Zusätzlich CTL/ATL/TSB-Linienchart und Schwellenwerte-Übersicht (Fachbegriffe: CTL, ATL, TSB, TSS).
  - Umfassende Barrierefreiheit: Alle Kennzahlen mit Info-Icon und modalem Erklärungsblatt (`AnalysisInfoSheet`), Zonen Z3/Z4/Z5 mit klaren Labels (nie nur Farbe), Semantics-Labels für Screenreader.
  - Tab „Analyse" als vollwertiger 3. Tab in die Hauptnavigation der Athleten eingebunden (`Heute`, `Plan`, `Analyse`, `Coach`).
  - Coach- & Athleten-Kontext: Header mit Athleten-Name wenn durch Trainer aufgerufen.
  - Firestore Security Rules: Coach-Lesezugriff auf vorberechnete Tagesaggregate (`users/{userId}/aggregates/{date}`) unter Schutz von `coachLinks.permissions.activities == true` durch den Spezialisten `firestore-rules-author` umgesetzt und im Testplan dokumentiert.
  - Aktivitätsdetailansicht (`ActivityDetailScreen`) aufgewertet: Sportartspezifische Einheiten über `TermResolver`, Zonenstreifen, Plan-Verknüpfungs-Badge und Platzhalter für das Cockpit in Phase 11.
  - Deterministsiche 12-Wochen-Demo-Aggregate für Empty States und Präsentationszwecke (`AnalysisRepository.generateDemoAggregates`).
  - Aktualisierung der Widget-Galerie (`/gallery`) um alle 7 Analyse-Karten.

## Offen / in Arbeit
- Phase 11: Analyse Cockpit (Detaillierte Telemetrie-Streams, Kartensynchronisation, LTTB-Downsampling, Rundenanalyse, Power-Duration-Kurve)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.



