# Prompts für alle Phasen (zum Kopieren)

Jede Phase hat eine fertige Phasendatei (`docs/phases/phase-NN-*.md`). Du startest sie mit einem **Skill-Befehl**. Dieser Abschnitt sagt dir je Phase: **was du vorher bereitstellen musst**, **welche Startnachricht** du schreibst, **was du danach manuell testest** und **welche Dateien du mir zum Review in den Claude-Chat gibst**.

## So benutzt du die Datei
1. **Neue Unterhaltung** in Antigravity starten (eine pro Phase).
2. Befehl wählen: `/phase-start NN` (Standard, hält an jedem STOPP) **oder** `/phase-run NN` (Autopilot, Checkpoints statt Stopps).
3. Die **Kontextzeile** der Phase darunter ausfüllen und mitschicken.
4. Nach dem Lauf: „Danach manuell testen" abarbeiten, `docs/CHECKPOINTS.md` lesen (zuerst `RISIKO-HOCH`), PR prüfen, mergen.

## Allgemeine Startnachricht (Vorlage)
```
/phase-run NN
Kontext: <Merge-Stand: alles bis Phase NN-1 gemergt | Branch feature/phase-… noch nicht gemergt>. <Besonderheiten der Phase, siehe unten>.
Meine Anmerkungen aus dem letzten Review: <keine | …>.
Führe zuerst den Plan-Check der Phasendatei gegen den Code durch. Halte dich an AGENTS.md. Am Ende Abschlussbericht mit „Bitte zuerst prüfen".
```
Für den Standardmodus `/phase-run` durch `/phase-start` ersetzen und die letzte Zeile weglassen.

## Empfohlener Rhythmus (Review-Gates)
| Block | Phasen | Danach |
|---|---|---|
| A: Fundament und Sicherheit | 00 → 01 → 02 | **Review-Runde 1** (Rules, Datenmodell, Zugriffskonzept) |
| B: Daten rein | 03 → 04 → 05 | **Review-Runde 2** (Aktivitätsmodell, Formeln, Stichprobe der Zahlen) |
| C: Anbindung | 06 → 07 | **Review-Runde 3** (Garmin-Fakten, Health-Texte) |
| D: Planung | 08 → 09 | Review-Runde 4 (Zuordnung, Parser) |
| E: Analyse | 10 → 11 → 12 | Review-Runde 5 (Wortlaut, Performance, Methoden) |
| F: Kommunikation | 13 | Review-Runde 6 (Chat-Rules, Push) |
| G: Veredelung | 14 → 15 | Review-Runde 7 |
| H: Release | 16 | Freigabe |

**Review im Claude-Chat:** Füge mir die unter „Review-Paket" genannten Dateien ein, ich prüfe sie aus Sicht von Entwicklung, Sicherheit und UX.

---

## Phase 00: Fundament, Audit, Design-System, Spikes
**Risiko:** mittel · **Phasendatei:** `docs/phases/phase-00-*.md`

**Vorab (nur du):**
- Package-ID festlegen (z. B. `de.deinname.orbit`)
- Firebase `orbit-dev`/`orbit-prod` in `europe-west3` anlegen und `flutterfire configure` ausführen **oder** bewusst Emulator-only starten
- Android-Emulator oder Gerät startklar, Berechtigungen aus `02_PERMISSIONS.md` gesetzt, `git tag pre-autopilot`

**Startnachricht:**
```
/phase-run 00
Kontext: Package-ID: <…>. Firebase: <orbit-dev angelegt und konfiguriert | Emulator-only>. Gerät: <Emulator | echtes Gerät>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] App startet als `dev`-Flavor, Navigation in **beiden** Rollen (Debug-Schalter)
- [ ] Design wirkt wie das bisherige (Navy/Volt, Inter)
- [ ] **Chart-Spike auf dem Gerät messen** (Profile-Mode), Ergebnis dem Agenten mitteilen

**Review-Paket für den Claude-Chat:** docs/AUDIT.md; docs/DECISIONS.md; docs/ARCHITECTURE.md; pubspec.yaml; lib/core/design/ (Farben, Theme)

---

## Phase 01: Auth, Onboarding, Rollen, Rules, Datenschutz-Basis
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-01-*.md`

**Vorab (nur du):**
- Firebase-Auth-Anbieter aktivieren: Google, E-Mail/Passwort
- SHA-1/SHA-256 (Debug) in Firebase eintragen
- App Check (Play Integrity) und Debug-Token einrichten
- AV-Vertrag mit Google (Firebase) prüfen

**Startnachricht:**
```
/phase-run 01
Kontext: Auth-Anbieter sind aktiviert: <ja | nein>. SHA-Fingerprints eingetragen: <ja | nein>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Google-Login und E-Mail-Registrierung auf echtem Gerät
- [ ] Onboarding fühlt sich kurz und klar an (de + en)
- [ ] Konto löschen und Datenexport in der Dev-Umgebung
- [ ] Datenschutz-Platzhaltertexte inhaltlich prüfen

**Review-Paket für den Claude-Chat:** firestore.rules; storage.rules; test/rules/*; functions/src/auth/*; docs/PRIVACY.md

---

## Phase 02: Trainer-Verknüpfung, Freigaben, Athleten-Kontext
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-02-*.md`

**Vorab (nur du):**
- Zwei Testkonten (Athlet, Trainer) und zwei Geräte/Emulator-Instanzen

**Startnachricht:**
```
/phase-run 02
Kontext: Testkonten: <Athlet: …, Trainer: …>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Einladung per Code/QR, Annahme, Freigaben ändern, Widerruf (zwei Geräte)
- [ ] Freigaben-Texte sind für Laien verständlich
- [ ] Athleten-Kontext-Kopfbereich ist unmissverständlich

**Review-Paket für den Claude-Chat:** firestore.rules + Rules-Tests (coachLinks, invites); functions/src/coach/*; Athleten-Kontext-Provider; docs/DECISIONS.md (Zugriffsmodell)

---

## Phase 03: Profil, Einstellungen, Schwellenwerte
**Risiko:** mittel · **Phasendatei:** `docs/phases/phase-03-*.md`

**Vorab (nur du):**
- Keine besonderen Vorbereitungen

**Startnachricht:**
```
/phase-run 03
Kontext: Bekannte eigene Schwellenwerte zum Testen: <FTP, Schwellen-HF, CSS, …>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Profil und Foto ändern, Sprache sofort umschalten, imperiale Einheiten
- [ ] Erklärtexte verständlich, Zonen stimmen mit meiner Erwartung
- [ ] Einwilligung widerrufen: Konsequenz verständlich

**Review-Paket für den Claude-Chat:** training_zones_model.dart + Tests; Schätzformeln; TermResolver + Tests; docs/DECISIONS.md (Zonenmodell)

---

## Phase 04: Aktivitäts-Import (FIT, Parser, Demo-Modus)
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-04-*.md`

**Vorab (nur du):**
- 2–3 eigene FIT-Dateien (Rad, Lauf, Schwimmen) bereitstellen, GPS-Start/Ziel vorher unkenntlich machen, nach `testvectors/fit/`
- Referenzwerte der Einheiten aus Garmin Connect notieren

**Startnachricht:**
```
/phase-run 04
Kontext: FIT-Dateien liegen in testvectors/fit/: <ja | nein>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Eigene FIT-Datei hochladen: Werte stimmen mit der Uhr überein
- [ ] Demo-Modus an/aus, Liste/Detail fühlen sich gut an
- [ ] Fehlerfall (kaputte Datei) verständlich erklärt

**Review-Paket für den Claude-Chat:** docs/DATA_MODEL.md (activities); functions/src/import/*; storage.rules + Rules-Tests; Parser-Tests, Streams-Format

---

## Phase 05: Metrik-Kern (Berechnung, Aggregation, ORBIT Score)
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-05-*.md`

**Vorab (nur du):**
- Vergleichswerte einer echten Einheit (NP, TSS, IF) aus Garmin Connect/anderer Software notieren

**Startnachricht:**
```
/phase-run 05
Kontext: Vergleichswerte: <…>. Methodenpapier-Freigabe erfolgt nach dem Entwurf. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Stichprobe NP/TSS mit meinen Vergleichswerten
- [ ] Methodenpapier gelesen und freigegeben
- [ ] ORBIT-Score-Entwurf bewertet (bleibt vorläufig)

**Review-Paket für den Claude-Chat:** docs/DECISIONS.md (Methodenpapier); functions/src/metrics/*; testvectors/*.json; docs/ORBIT_SCORE.md

---

## Phase 06: Garmin-Connector
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-06-*.md`

**Vorab (nur du):**
- **Garmin-Entwicklerzugang freigegeben** (sonst Mock-Modus, die Phase ist trotzdem ausführbar)
- Secrets im Secret Manager, Webhook-URLs im Garmin-Portal, `assetlinks.json` gehostet
- Eigenes Garmin-Konto zum Testen
- `read_url(developer.garmin.com)` erlaubt

**Startnachricht:**
```
/phase-run 06
Kontext: Garmin-Zugang: <freigegeben | nicht freigegeben, Mock-Modus>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Eigenes Garmin-Konto verbinden, echte Aktivität erscheint, Werte stimmen
- [ ] Backfill der letzten Wochen, Trennen und erneutes Verbinden
- [ ] Datenfrage beim Trennen verständlich

**Review-Paket für den Claude-Chat:** docs/specs/GARMIN.md (verifizierter Stand); functions/src/providers/garmin/*; Webhook-Code; Rules (private/*, integrationStatus)

---

## Phase 07: Health-Daten
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-07-*.md`

**Vorab (nur du):**
- Garmin-Konto mit Health-Daten oder Demo-Modus

**Startnachricht:**
```
/phase-run 07
Kontext: Health-Datenquelle: <Garmin live | Demo>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Tagesform-Karte wirkt verständlich und beruhigend, nicht alarmierend
- [ ] Texte (de/en) freigegeben
- [ ] Health-Freigabe für Trainer umschalten, Wirkung beobachten

**Review-Paket für den Claude-Chat:** Tagesform-Texte (ARB); Basislinien-Logik + Tests; Rules dailyMetrics

---

## Phase 08: Kalender und Soll-Ist-Abgleich
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-08-*.md`

**Vorab (nur du):**
- Trainer-Testkonto mit verknüpftem Athleten

**Startnachricht:**
```
/phase-run 08
Kontext: Testkonten: <Athlet, Trainer>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Woche planen, Aktivität importieren, Zuordnung und Abweichungstext prüfen
- [ ] Als Trainer im Athleten-Kalender planen, Athlet sieht es
- [ ] Bottom Sheets mit dem Daumen angenehm bedienbar

**Review-Paket für den Claude-Chat:** matchActivityToPlan + Tests; Rules plannedWorkouts; docs/DECISIONS.md (Zuordnungsregeln)

---

## Phase 09: Workout Builder und Vorlagenbibliothek
**Risiko:** mittel bis hoch · **Phasendatei:** `docs/phases/phase-09-*.md`

**Vorab (nur du):**
- Zehn eigene typische Einheiten als Testfälle notieren (Rad, Lauf, Schwimmen)

**Startnachricht:**
```
/phase-run 09
Kontext: Meine Testeinheiten: <Liste>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Zehn Einheiten in Text und im Editor bauen: schnell und fehlerarm?
- [ ] Bedienung auf dem Handy (Tastatur, Bottom Sheets)
- [ ] Startbibliothek inhaltlich geprüft

**Review-Paket für den Claude-Chat:** docs/specs/WORKOUT_SYNTAX.md; Parser/Formatter + Tests; Startbibliothek-Dateien

---

## Phase 10: Analyse einfach
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-10-*.md`

**Vorab (nur du):**
- Demo-Daten oder mindestens 6 Wochen eigene Daten

**Startnachricht:**
```
/phase-run 10
Kontext: Datenbasis: <Demo | eigene Daten>. ORBIT Score freigegeben: <nein>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Aussagen stimmen mit meinem Gefühl überein, verstehen Einsteiger sie?
- [ ] Texte (de/en) freigegeben
- [ ] Scrollen, Zeitraumwechsel, Info-Sheets flüssig

**Review-Paket für den Claude-Chat:** Ampel-Logik + Tests; ARB-Texte; Golden-Bilder (3 Stufen)

---

## Phase 11: Analyse Cockpit
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-11-*.md`

**Vorab (nur du):**
- Mittelklasse-Android-Gerät für Performance-Messung (Profile-Mode)
- Ggf. Konto/Key beim gewählten Kartenanbieter

**Startnachricht:**
```
/phase-run 11
Kontext: Messgerät: <Modell>. Kartenanbieter-Zugang: <ja | nein>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Messung: flüssig bei 2-h-Aktivität, kein Jank beim Scrubbing
- [ ] Long-Press- und Querformat-Scrubbing, HUD verdeckt nichts
- [ ] Karten-Einwilligungstext geprüft

**Review-Paket für den Claude-Chat:** docs/DECISIONS.md (Chart, Karte); Benchmark-Protokoll; Stream-Aufbereitung + Tests; docs/PRIVACY.md (Karte)

---

## Phase 12: Leistungsdiagnostik
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-12-*.md`

**Vorab (nur du):**
- Mindestens 8–12 Wochen eigene Daten mit Leistung/HF (oder Demo für den Funktionstest)

**Startnachricht:**
```
/phase-run 12
Kontext: Datenbasis: <Demo | eigene Daten>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Vorschläge mit meinen früheren Tests und meinem Gefühl vergleichen
- [ ] Texte, Warn- und Testhinweise (de/en) geprüft
- [ ] Neuberechnung einer Beispielspanne beobachten

**Review-Paket für den Claude-Chat:** Methodenpapier (DECISIONS); Schätzfunktionen + Tests; Rules thresholdProposals

---

## Phase 13: Chat und Push
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-13-*.md`

**Vorab (nur du):**
- FCM im Dev-Projekt aktiv
- Zwei echte Geräte
- Ggf. Cloud Scheduler (Blaze) aktivieren

**Startnachricht:**
```
/phase-run 13
Kontext: FCM-Konfiguration: <ja | nein>. Geräte: <2 echte Geräte | Emulator>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] **Push auf echtem Gerät** (App im Hintergrund und beendet)
- [ ] Berechtigungsdialog im Kontext, Channels in den Systemeinstellungen
- [ ] Ruhezeiten und Schalter, Tippen auf Push öffnet den richtigen Chat

**Review-Paket für den Claude-Chat:** firestore/storage rules (Chat) + Tests; functions/src/chat/*; Push-Entscheidungslogik + Tests

---

## Phase 14: Home (Heute)
**Risiko:** mittel · **Phasendatei:** `docs/phases/phase-14-*.md`

**Vorab (nur du):**
- Drei Testkonten: leer, Demo, echt

**Startnachricht:**
```
/phase-run 14
Kontext: Testkonten: <leer, Demo, echt>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Start wirkt ruhig und klar, wichtigste Info ohne Scrollen
- [ ] Ring, Countdown, Texte (de/en) stimmig
- [ ] Alle drei Konten durchspielen

**Review-Paket für den Claude-Chat:** HomeCardResolver + Tests; Golden-Bilder; DECISIONS (Reads-Budget)

---

## Phase 15: Coach-Desktop und Web
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-15-*.md`

**Vorab (nur du):**
- Desktop-Browser
- Optional Hosting-Projekt/Domain
- 25+ Test-Athleten über das Seed-Skript (Emulator/Dev)

**Startnachricht:**
```
/phase-run 15
Kontext: Hosting: <Firebase Hosting | nur lokal>. Seed ausgeführt: <ja | nein>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Dashboard lädt zügig, Tabelle und Raster flüssig bei 25+ Athleten
- [ ] Drag & Drop und Massenzuweisung fühlen sich effizient an
- [ ] Chrome/Firefox/Safari und mobiler Browser geprüft

**Review-Paket für den Claude-Chat:** coachDashboard-Functions + Rules; Massenzuweisung-Logik; DECISIONS (Web, App Check Web)

---

## Phase 16: Qualität, Datenschutz-Abschluss, Release
**Risiko:** hoch · **Phasendatei:** `docs/phases/phase-16-*.md`

**Vorab (nur du):**
- Play-Console-Konto, Upload-Key (`key.properties`)
- Fachperson für Datenschutz/DSFA
- Impressum-Angaben, Domain für die Löschseite

**Startnachricht:**
```
/phase-run 16
Kontext: Play-Console: <ja | nein>. Fachperson: <ja | nein>. Meine Anmerkungen aus dem letzten Review: <keine | …>.
```

**Danach manuell testen:**
- [ ] Datenschutz-Texte/DSFA mit Fachperson geprüft, Impressum und Löschseite live
- [ ] Interner Testtrack mit echten Testern, Push und Login im Release-Build
- [ ] TalkBack- und Performance-Stichprobe auf zwei Geräten

**Review-Paket für den Claude-Chat:** docs/release/OPEN_ITEMS.md; docs/PRIVACY.md; Sicherheitsbericht; docs/release/*

---

## Wenn eine Phase abbricht oder der Agent zu viel baut
- **Abbruch/zu lang:** `/phase-finish`, neue Unterhaltung, `/resume-phase`.
- **Zu viel gebaut:** `/scope-check`.
- **Design-Abweichung:** `/design-check`. **Sicherheitszweifel:** `/security-check`.
- **Phase zu groß:** `/split-phase NN`.
- **Fehler gefunden:** `/bugfix <Beschreibung>`.
