# Phase 02: Trainer-Verknüpfung, Freigaben, Athleten-Kontext

**Branch:** `feature/phase-02-coach-link` · **Voraussetzungen:** Phase 01 abgeschlossen

## Ziel
Athlet und Trainer können sich verbinden (Einladung, Annahme, Freigaben, Widerruf). Der Trainer sieht seine Athleten und kann Screens im **Athleten-Kontext** öffnen. Die Zugriffsmodell-Entscheidung (denormalisiertes `coachId`) ist per Emulator-Test bewiesen. Damit sind alle späteren Features von Anfang an trainerfähig.

## Vorher lesen
`AGENTS.md`, `docs/DATA_MODEL.md` (Grundprinzip 5, `coachLinks`, `invites`), `docs/DESIGN.md` §7 (Navigation, Coach-Tab).

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Zugriffsmodell prüfen:** Bestätige das Konzept `coachId` + `coachLinks/{athleteId}_{coachId}` gegen Firestore-Rules-Einschränkungen (Rules filtern nicht, `get()`-Grenzen bei Listenabfragen). Schreibe die minimalen Beweis-Tests zuerst: Trainer fragt `where coachId == uid` ab und sieht nur freigegebene Dokumente, fremde nicht. Weiche nur mit Begründung ab.
2. **STOPP 1 [RISIKO-HOCH]:** Ergebnis + endgültiges Zugriffsmodell, Rules-Entwurf für `coachLinks`, `invites`, Health-Subcollection (via `get()` auf Link-Dokument). Ich gebe frei.
3. **Cloud Functions (alle Schreibvorgänge serverseitig):**
   - `createInvite` (Trainer): Code/Link/QR-Inhalt, Ablauf, `maxUses`.
   - `redeemInvite` (Athlet): legt `coachLinks` an (`ACTIVE`, Standard-Freigaben `calendar: true, activities: true, health: false`), setzt `users/{athlete}.coachId` und `consents.coachSharing`. Annahme nur durch aktive Aktion des Athleten, nie automatisch.
   - `updatePermissions` (Athlet): ändert Freigaben, pflegt `coachId` auf bestehenden `activities`/`plannedWorkouts` (Freigabe entfernt → `null`, wieder erteilt → gesetzt). Batch-sicher, idempotent.
   - `revokeLink` (Athlet und Trainer): Status `REVOKED`, `coachId` überall auf `null`, Chat bleibt erhalten, aber ohne Zugriff auf Daten.
   - Trigger zur Pflege von `coachId` bei neu angelegten Dokumenten (Grundlage für spätere Phasen).
4. **Athlet-UI (Tab „Coach"):** Ohne Trainer: gestalteter Empty State „Trainer einladen / Einladungscode eingeben" (Code manuell oder QR-Scan). Mit Trainer: Trainer-Karte, **Freigaben-Schalter** je Bereich (Kalender, Aktivitäten, Health) mit verständlicher Erklärung, Verknüpfung lösen (mit Bestätigung). Chat-Einstieg als Platzhalter (kommt in Phase 13).
5. **Trainer-UI (Tab „Athleten"):** Einladung erzeugen (Code kopieren, QR anzeigen, Link teilen). Athletenliste (Name, Foto, Status, Erfahrungsstufe, Wettkampfziel), Suchfeld. Tippen öffnet den **Athleten-Kontext**: ein Wrapper, der `athleteId` für alle Kind-Screens bereitstellt, mit klarem Kopfbereich „Du siehst: <Name>" und Zurück-Aktion. Inhalte sind vorerst Platzhalter-Screens (Kalender/Analyse). Wichtig: die Architektur muss das später ohne Umbau tragen.
6. **`athleteId`-Provider** (Riverpod o. ä.): liefert eigene ID oder die des betrachteten Athleten. Lint/Test-Hinweis oder Code-Review-Regel: kein direkter Zugriff auf `currentUser.uid` in Feature-Screens (nur im Provider).
7. **Rules und Tests** für alle neuen Fälle: Trainer sieht nur verknüpfte Athleten, nur freigegebene Bereiche, nicht mehr nach Widerruf, Athlet kann Freigaben ändern, Fremde nichts; `coachLinks`/`invites` nur über Functions schreibbar; abgelaufene/übernutzte Einladung abgelehnt.
8. Lokalisierung (de + en). Push bei Verknüpfung folgt in Phase 13.

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 1 (Zugriffsmodell bewiesen, Rules-Entwurf)
- **STOPP 2 [RISIKO-MITTEL]** nach Aufgabe 5: Kurzbericht und Screenshots/Beschreibung der Flows

## Nicht-Ziele
Chat, Plan-/Aktivitäts-Inhalte, Push, mehrere Trainer pro Athlet (genau ein Trainer pro Athlet im MVP), Trainer-Verifizierung.

## Abnahme
### Automatisch prüfbar
- [ ] `flutter analyze`, `flutter test` grün, Functions-Tests grün
- [ ] Rules-Tests (Emulator) grün für alle Fälle aus Aufgabe 7, Beweis-Tests aus Aufgabe 1 enthalten
- [ ] Function-Tests: Einladung → Annahme → Freigaben ändern → Widerruf, inkl. `coachId`-Pflege auf Testdokumenten
- [ ] Widget-Tests: Coach-Tab Empty State, Athleten-Kontext-Wrapper stellt die richtige `athleteId` bereit
### Manuell (ich)
- [ ] Mit zwei Test-Konten (Athlet, Trainer) auf zwei Geräten/Emulatoren: Einladung per Code/QR, Annahme, Freigaben, Widerruf
- [ ] Freigaben-Texte sind für Laien verständlich
- [ ] Athleten-Kontext-Kopfbereich ist unmissverständlich (man sieht klar, wessen Daten man betrachtet)

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `DATA_MODEL.md` (falls angepasst), `MANUAL_STEPS.md`.
