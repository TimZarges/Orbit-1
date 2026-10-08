# Phase 16: Qualität, Datenschutz-Abschluss, Release

**Branch:** `feature/phase-16-release` · **Voraussetzungen:** alle vorherigen Phasen (mindestens 00–14) · **Risiko:** hoch (Recht, Sicherheit, Veröffentlichung)

## Ziel
Die App ist **release-reif für Android** (interner Test bis Produktion): geprüft, schnell, sicher, barrierearm, mit abgeschlossener Datenschutz-Dokumentation und vollständigen Store-Unterlagen. iOS ist sauber vorbereitet.

## Vorher lesen
`AGENTS.md`, `docs/PRIVACY.md`, `docs/MANUAL_STEPS.md`, `docs/PROGRESS.md`, `docs/CHECKPOINTS.md` (alle offenen `RISIKO-HOCH`-Einträge), alle `DECISIONS.md`-Einträge zu Rules, Datenschutz und Performance.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Restschulden abbauen:** Alle offenen `RISIKO-HOCH`-Checkpoints, `TODO(manual)`-Stellen (Suche im Code) und „VORLÄUFIG"-Markierungen (ORBIT Score) auflisten und je Punkt **fix / bewusst akzeptiert / blockiert (manuell)** entscheiden. Ergebnis in `docs/release/OPEN_ITEMS.md`.
2. **Testlücken schließen:** Coverage-Berichte (Flutter und Functions), Lücken in Kernlogik (Metriken, Zuordnung, Parser, Rules) füllen. **Integrationstests** auf dem Android-Emulator für die Kernpfade: Registrierung → Onboarding → Demo/FIT-Import → Kalender → Analyse → Chat. Rules-Testmatrix vollständig (jede Collection × Rolle × Freigabe).
3. **Sicherheits-Review:** Skill `/security-check` über das gesamte Projekt, App-Check-**Erzwingung** staged planen (erst Monitoring, dann Enforcement), Abhängigkeitsprüfung (`npm audit`, `flutter pub outdated`, Lizenzübersicht), Suche nach Geheimnissen (Muster-Suche im Repo und Verlauf), Storage-/Function-Missbrauchsschutz, Kostenabschätzung (Reads/Writes je Hauptscreen, Budgetalarme als manueller Schritt).
4. **STOPP 1 [RISIKO-HOCH]:** Bericht aus Aufgabe 1–3 (offene Punkte, Befunde, Plan zur Behebung). Ich gebe frei, bevor Datenschutz-Texte und Release-Dateien finalisiert werden.
5. **Datenschutz-Dokumentation** (Entwürfe zur **rechtlichen Prüfung**, keine Rechtsberatung): `docs/PRIVACY.md` finalisieren (Datenarten, Zwecke, Rechtsgrundlagen, Empfänger/Auftragsverarbeiter inkl. Google, Garmin, Kartenanbieter, Speicherorte/Region, Fristen, Betroffenenrechte), Verarbeitungsverzeichnis-Entwurf, **DSFA-Entwurf** (Risiken, Maßnahmen), technisch-organisatorische Maßnahmen, Lösch- und Aufbewahrungskonzept, Export-Format, Einwilligungstexte versioniert (de + en), **Web-Seite zur Konto-/Datenlöschung** (statischer Entwurf für Hosting, wird von Play verlangt), Impressum-Vorlage, Entwurf der **Play-„Data Safety"-Angaben** (`docs/release/DATA_SAFETY.md`).
6. **Crash-Reporting und Logging:** Opt-in-Verhalten verifizieren (Standard aus), keine personenbezogenen Daten/Tokens in Logs und Berichten (Test + Suche), Analyse-SDKs nur mit Einwilligung (oder gar keine).
7. **Performance-Review:** Startzeit, Jank-Profil der Hauptscreens, Speicher bei langen Aktivitäten, Bildgrößen, App-Größe (`flutter build appbundle --analyze-size`), Listener-Lecks, Reads pro Screen. Ergebnisse und Maßnahmen in `docs/release/PERFORMANCE.md`.
8. **Barrierefreiheit:** Screenreader-Durchgang (TalkBack) der Kernpfade, Kontrast (AA), Textskalierung 1,3, Tippflächen, Farbsehschwäche-Simulation der Zonen/Kanäle, Ergebnis in `docs/release/ACCESSIBILITY.md` mit behobenen und bekannten Punkten.
9. **Lokalisierung:** Skript/Test prüft, dass **alle** ARB-Schlüssel in de und en vorhanden sind, Platzhalter stimmen, Pluralformen korrekt, Datums-/Zahlenformate über `intl`. Fehlende Übersetzungen = Testfehler.
10. **Android-Release:** Release-Flavor, **Signierung** (Upload-Key über `key.properties`, nie im Repo), Shrinking/R8-Regeln für Firebase und genutzte Plugins, adaptives App-Icon, Android-12-Splash, **minimale Berechtigungen** (Manifest-Audit), `targetSdk` aktuell, Versionsschema, App-Bundle-Build, Debug-Funktionen (Galerie, Benchmark, Seed, Debug-Rollenschalter) im Release **deaktiviert** (Test).
11. **Store-Unterlagen:** Beschreibungstexte de/en (`docs/release/STORE_LISTING.md`), Screenshot-Plan mit **Demo-Modus-Daten**, Datenschutz-Links, Altersfreigabe-Angaben, Kontaktdaten. Interner Testtrack, Tester-Gruppen, App Distribution (Konsolenschritte als manuelle Liste).
12. **iOS-Vorbereitung** (`docs/release/IOS_PREP.md`): Apple Sign-In (Pflicht bei Google-Login), Capabilities (Push), Entitlements, Info.plist-Texte, Datenschutz-Labels, Build-/Signing-Schritte. Nicht bauen, nur dokumentieren.
13. **Betrieb:** Monitoring und Alarme (Functions-Fehler, Kosten, Auth-Missbrauch) als Anleitung, Firestore-Backup/Wiederherstellung (PITR/Export) als Anleitung, Rollback-Plan, Release-Checkliste `docs/release/CHECKLIST.md`.
14. **Garmin-Produktionsprüfung vorbereiten:** Demo-Zugang, Screenshots, Branding-/Quellenangabe-Checkliste gemäß verifizierter Garmin-Vorgaben (`docs/release/GARMIN_REVIEW.md`).
15. **Projekt-Doku:** `README.md` neu (Einrichtung, Starten, Testen, Emulator, Deploy, Struktur), `docs/ARCHITECTURE.md` aktualisieren, `PROGRESS.md` abschließen.
16. **STOPP 2 [RISIKO-HOCH]:** Abschlussbericht und Release-Freigabe-Checkliste. Veröffentlichung geschieht **nur durch mich**.

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 3 (Restschulden, Testlücken, Sicherheitsbefunde)
- **STOPP 2 [RISIKO-HOCH]** am Ende (Release-Freigabe)

## Nicht-Ziele
Tatsächliche Veröffentlichung/Upload in Stores, iOS-Build, neue Features, rechtliche Endabnahme der Datenschutztexte (das ist eine externe Prüfung).

## Abnahme
### Automatisch prüfbar
- [ ] `flutter analyze`, alle Flutter- und Functions-Tests, Rules-Testmatrix und Integrationstests grün
- [ ] Lokalisierungs-Vollständigkeitstest grün (de/en)
- [ ] Release-Build (App-Bundle) baut, Debug-Features im Release nicht erreichbar (Test)
- [ ] Keine Geheimnisse im Repo/Verlauf (Muster-Suche), `npm audit` ohne kritische Befunde oder dokumentiert akzeptiert
- [ ] `docs/release/*` vollständig, `OPEN_ITEMS.md` ohne unentschiedene Punkte
### Manuell (ich)
- [ ] Datenschutz-Texte/DSFA mit Fachperson geprüft, Impressum und Löschseite live
- [ ] Release-Signierung eingerichtet, interner Testtrack läuft mit echten Testern, Push und Login im Release-Build geprüft
- [ ] TalkBack-Stichprobe, Performance-Stichprobe auf zwei Geräten
- [ ] Garmin-Review (falls gewünscht) eingereicht, Store-Einträge geprüft

## Dokumentation am Ende
`PROGRESS.md` (Projekt abgeschlossen bis Release), `DECISIONS.md`, `MANUAL_STEPS.md`, `docs/release/*`.
