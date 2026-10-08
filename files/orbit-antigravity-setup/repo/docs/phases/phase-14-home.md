# Phase 14: Home-Dashboard („Heute")

**Branch:** `feature/phase-14-home` · **Voraussetzungen:** Phase 07 (Tagesform), 08 (Plan), 10 (Karten), 12 (Vorschläge), 13 (Chat-Badge) · **Risiko:** mittel

## Ziel
Der Tab **Heute** ist der Start- und Lieblingsort: Auf einen Blick, *was steht heute an, wie geht es mir, was ist neu, was ist zu tun*. Wenig, aber aussagekräftig, und er passt sich an Stufe, Datenlage und Rolle des Nutzers an.

## Vorher lesen
`AGENTS.md`, `docs/DESIGN.md` (§2 Daily Ring auf Navy-Hero-Card, §7, §7a, §8), Karten-Bausteine aus Phase 07 und 10, Phase-08-Plan.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Inhalts- und Prioritätskonzept:** Welche Karten erscheinen wann (neuer Nutzer ohne Daten, Demo, normaler Betrieb, mit/ohne Trainer, Wettkampfwoche), maximal **4 Karten oberhalb der Falz**, Reihenfolge nach Relevanz. Skizzen je Zustand in `DECISIONS.md`.
2. **STOPP 1 [RISIKO-MITTEL]:** Layout-Skizzen und Prioritätsregeln zeigen. Ich gebe frei.
3. **`HomeCardResolver`** (reine Funktion, getestet): Eingabe Zustand (Daten, Plan, Stufe, Trainer, Vorschläge, ungelesen, Hinweise), Ausgabe geordnete Kartenliste. Tests für alle Zustände aus Aufgabe 1.
4. **Hero-Karte (Navy):** Daily Ring in Volt (Track in hellem Navy), Mitte zeigt Ist-Belastung heute im Verhältnis zum Plan (bei Ruhetag „Ruhetag", ohne Plan Bezug zur typischen Tagesbelastung), Animation mit „Animationen reduzieren"-Respekt, **Textäquivalent** für Screenreader, nie nur Farbe. Darunter nächstes/heutiges Training mit Sportfarbe, Dauer, Kurzbeschreibung und Aktion „Details".
5. **Weitere Karten** (Bausteine wiederverwenden): Form-Ampel (Phase 10), Tagesform (07), letzte Aktivität mit Link zur Analyse, **Wettkampf-Countdown** (Wochen/Tage bis zum Ziel, wenn gesetzt, neutral formuliert), **Zu erledigen** (Training zuordnen aus Phase 08, Schwellenwert-Vorschlag aus 12, Import-Fortschritt/Backfill aus 06, ausstehende Trainer-Anfrage), ungelesene Chat-Nachricht (nur mit Trainer), Demo-Banner, Hinweis „Benachrichtigungen aktivieren" (kontextbezogen, abweisbar).
6. **Datenzugriff:** Eine **gebündelte** Abfrage-Schicht (Aggregate, nächste 7 Tage Plan, letzte Aktivität, Status-Dokumente), keine Abfrage pro Karte ohne Not, Caching über Provider, Pull-to-Refresh. Reads pro Öffnung zählen und dokumentieren.
7. **Zustände:** Skeleton-Loader je Karte (Karten laden unabhängig, kein Blockieren), Fehler je Karte mit Wiederholen, gestaltete Empty States, Offline-/Netzwerkfehler freundlich.
8. **Wettkampfziel bearbeiten** direkt aus der Karte (Name, Datum, Typ), Verknüpfung zum Profil.
9. **Rolle Trainer:** Der erste Tab ist „Athleten" (Phase 02/15), es gibt **kein** Trainer-Home in dieser Phase. Dokumentiere das und stelle sicher, dass die Navigation es sauber trägt.
10. **Barrierefreiheit und Mobile:** Textskalierung 1,3, Kontrast, Tippflächen, Daumenbereich, Tablet-Layout (zwei Spalten ab Medium).
11. Lokalisierung, Galerie, **Golden Tests** je Zustand und Stufe (neu, Demo, normal, mit Trainer, Fehler).

## STOPP-Punkte
- **STOPP 1 [RISIKO-MITTEL]** nach Aufgabe 1 (Layouts und Prioritäten)

## Nicht-Ziele
Trainer-Home, Widgets für den Android-Startbildschirm, personalisierbare Home-Anordnung, Gamification (Streaks, Abzeichen).

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün, `HomeCardResolver` für jeden Zustand getestet
- [ ] Golden Tests grün, Ring-Berechnung getestet (Ruhetag, über Plan, ohne Plan)
- [ ] Reads pro Home-Öffnung dokumentiert und innerhalb des Budgets (Wert in `DECISIONS.md`)
- [ ] Widget-Tests: Karten laden unabhängig, Fehler einer Karte blockiert andere nicht
### Manuell (ich)
- [ ] Auf dem Gerät: Start wirkt ruhig und klar, wichtigste Info ohne Scrollen sichtbar
- [ ] Neuer Account (leer), Demo-Account und echter Account durchspielen
- [ ] Ring, Countdown und Texte (de/en) fühlen sich stimmig an

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`.
