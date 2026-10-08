# Phase 01: Auth, Onboarding, Rollen, Rules, Datenschutz-Basis

**Branch:** `feature/phase-01-auth-onboarding` · **Voraussetzungen:** Phase 00 abgeschlossen, Firebase-Projekte, Auth-Anbieter, SHA-Fingerprints (siehe `MANUAL_STEPS.md`)

## Ziel
Nutzer können sich registrieren und anmelden, durchlaufen ein kurzes Onboarding, ihre Rolle wird sicher vergeben, ihre Daten sind durch geprüfte Security-Rules geschützt und die Datenschutz-Grundlagen (Einwilligung, Löschung, Export) funktionieren.

## Vorher lesen
`AGENTS.md`, `docs/DATA_MODEL.md` (users, consents, thresholdHistory), `docs/DESIGN.md` (Onboarding, Erfahrungsstufen), `docs/REQUIREMENTS.md` §5.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Auth:** Google Sign-In und E-Mail/Passwort (mit E-Mail-Verifizierung, Passwort-Reset). Apple Sign-In nur vorbereiten (Code-Struktur), nicht aktivieren. Auth-State-Stream, Redirect-Logik im Router (nicht eingeloggt → Login; eingeloggt ohne Onboarding → Onboarding; sonst Shell).
2. **Onboarding (3–4 kurze Schritte, mobil, Daumenbereich):** (a) Rolle: Athlet / Trainer; (b) Sportart(en) inkl. Schwimmen; (c) **Erfahrungsstufe** Einfach/Fortgeschritten/Experte mit kurzer Erklärung; (d) optional **Wettkampfziel** (Name, Datum, Typ), überspringbar; (e) Abschluss mit First-Run-Optionen „Garmin verbinden (noch nicht verfügbar) / FIT importieren (folgt) / Demo ansehen (folgt)". **Keine Abfrage von Schwellenwerten.** Fortschrittsanzeige, Zurück möglich, Zustand bleibt erhalten.
3. **Rollenvergabe:** Callable Cloud Function `setInitialRole` (setzt `role`, `trainerVerified: false`, Custom Claim). Der Client kann `role`, `coachId`, `trainerVerified` **nicht** schreiben. Nur einmalig nach Registrierung nutzbar. (Echte Trainer-Verifizierung später.)
4. **User-Dokument** gemäß `DATA_MODEL.md` anlegen (Trigger bei Registrierung oder in `setInitialRole`), inkl. `settings.language` aus Gerätesprache (Standard de), `profile.timezone`.
5. **STOPP 1 [RISIKO-HOCH]:** Konkreter Entwurf der **Firestore- und Storage-Rules** für `users`, `thresholdHistory`, `private/*`, `consents` (noch ohne Coach-Zugriff, der kommt in Phase 02) plus Testplan. Ich gebe frei.
6. **Rules + Tests:** Standard „deny all". Rules-Unit-Tests gegen den Emulator (`@firebase/rules-unit-testing`). Pflichtfälle: fremde Daten nicht lesbar/schreibbar, Rolle/`coachId`/`trainerVerified` nicht selbst änderbar, `private/*` nie lesbar, Storage nur eigene Pfade, ohne Login nichts. `firestore.indexes.json` anlegen.
7. **App Check** einbinden (Play Integrity, Debug-Provider in Dev). Erzwingen in Prod erst nach meinem Test (Hinweis in `MANUAL_STEPS.md`).
8. **Datenschutz-Basis:** Screens für Datenschutzerklärung (Platzhaltertext, Version `v0`) und **ausdrückliche Einwilligung** zur Verarbeitung von Gesundheitsdaten (Art. 9 DSGVO) mit Zeitstempel + Version in `consents`. Ohne Einwilligung keine Nutzung der Gesundheits-/Trainingsfeatures (Hinweis statt Absturz). Verständlich formuliert, kein Kleingedrucktes.
9. **Konto löschen** (Callable Function: löscht Auth-Konto, alle Firestore-Daten des Nutzers inkl. Subcollections, Storage-Dateien) und **Datenexport** (JSON-Datei zum Teilen/Speichern). In den Einstellungen erreichbar (Platzhalter-Screen genügt). Beides mit Emulator-Tests.
10. **Crashlytics-Consent:** Opt-in beim Onboarding bzw. in den Einstellungen, Standard aus.
11. **Entwurf `docs/PRIVACY.md`:** Datenarten, Zwecke, Rechtsgrundlagen, Auftragsverarbeiter (Google/Firebase, später Garmin), Speicherorte/Region, Löschfristen, Hinweis auf nötige Datenschutz-Folgenabschätzung (nur Entwurf, keine Rechtsberatung).
12. Lokalisierung: alle neuen Texte de + en.

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 4 (Rules-Entwurf und Testplan)
- **STOPP 2 [RISIKO-HOCH]** nach Aufgabe 9: Kurzbericht, Rules-Tests-Ergebnis

## Nicht-Ziele
Trainer-Verknüpfung und Coach-Zugriff (Phase 02), Profilbearbeitung/Schwellenwerte (Phase 03), Apple Sign-In aktiv, echte Rechtstexte.

## Abnahme
### Automatisch prüfbar
- [ ] `flutter analyze`, `flutter test` grün
- [ ] Rules-Tests (Emulator) grün, inkl. aller Pflichtfälle aus Aufgabe 6
- [ ] Function-Tests: `setInitialRole` (einmalig, ungültige Rolle abgelehnt), Konto löschen entfernt alle Daten, Export enthält Nutzerdaten
- [ ] Widget-Tests: Redirect-Logik (alle 3 Zustände), Onboarding-Navigation
- [ ] Keine Secrets im Diff
### Manuell (ich)
- [ ] Google-Login und E-Mail-Registrierung auf echtem Gerät
- [ ] Onboarding fühlt sich kurz und klar an, Texte verständlich (de und en)
- [ ] Konto löschen und Export funktionieren in der Dev-Umgebung
- [ ] Ich prüfe die Datenschutz-Texte inhaltlich (Platzhalter!)

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `MANUAL_STEPS.md`, `docs/PRIVACY.md`.
