# Phase 13: Chat und Push-Benachrichtigungen

**Branch:** `feature/phase-13-chat-push` · **Voraussetzungen:** Phase 02 (Verknüpfung, Coach-Tab), 04 (Aktivitäten zum Teilen) · **Risiko:** hoch (Rules, Datenschutz, Push)

## Ziel
Athlet und Trainer chatten in Echtzeit, teilen Bilder, Dateien und Aktivitäten und werden zuverlässig, aber sparsam benachrichtigt. Der Datenzugriff bleibt strikt an die Freigaben gebunden, das Teilen ändert daran nichts.

## Vorher lesen
`AGENTS.md`, `docs/DATA_MODEL.md` (`chats`, `messages`, Ergänzungen: `state`, `devices`, `notificationState`), `docs/DESIGN.md` (§8 Push-Rechte), Phase-02-Verknüpfungslogik, `.agents/rules/data-and-security.md`.

**Plan-Check (immer zuerst):** Prüfe diese Phasendatei gegen den tatsächlichen Code, `docs/DECISIONS.md` und `docs/CHECKPOINTS.md`. Weicht der Stand ab (andere Struktur, geänderte Entscheidung, bereits Erledigtes), passe die Phasendatei an, vermerke es in `docs/CHECKPOINTS.md` und arbeite erst dann.

## Aufgaben
1. **Konzept:** `chatId = "{athleteId}_{coachId}"`, Chat-Dokument entsteht **serverseitig** bei aktiver Verknüpfung. Nach `REVOKED`: Chat bleibt für beide **lesbar**, aber **ohne neue Nachrichten** (Vorschlag, in `DECISIONS.md` begründen). Teilen einer Aktivität erzeugt eine **Momentaufnahme** (`activityShare.snapshot` mit Kurzdaten) und gewährt **keinen** zusätzlichen Zugriff, das Detail öffnet nur, wenn die Freigabe es erlaubt.
2. **STOPP 1 [RISIKO-HOCH]:** Rules-Entwurf (Chat, Nachrichten, `state`, Anhänge in Storage inkl. Größen-/Typprüfung über `request.resource`), Verhalten nach Widerruf, Umgang mit Löschen von Nachrichten und Konto. Ich gebe frei.
3. **Daten und Rules:** `chats`, `messages` (Typen `TEXT/IMAGE/FILE/ACTIVITY_SHARE`), `chats/{chatId}/state/{uid}.lastReadAt`. Trigger pflegt `lastMessage`, `updatedAt`, `unread` (transaktional, kein Zähler im Client). Rules-Tests: nur Teilnehmer, nur eigene `senderId`, kein Schreiben nach Widerruf, Anhänge nur im eigenen Chat-Pfad mit Limit (Bilder z. B. ≤ 10 MB, Dateien definiert, erlaubte Typen).
4. **Chat-UI (Athlet):** Im Tab „Coach" der Chat mit dem Trainer (Aufbau in Phase 02 vorbereitet). **Trainer:** Tab „Nachrichten" mit Liste aller Athleten-Chats (Suche, Ungelesen-Badge, letzte Nachricht, Sortierung), Öffnen im Athleten-Kontext möglich.
5. **Konversation:** Echtzeit über Firestore-Stream (`StreamBuilder`/Riverpod-StreamProvider), **Paginierung** (neueste 30, ältere nachladen per Cursor), Datumstrenner, **optimistisches Senden** mit Status (sendet / gesendet / fehlgeschlagen + Wiederholen), saubere Tastatur- und Scroll-Logik (nicht springen, wenn der Nutzer liest; automatisch nach unten nur, wenn er am Ende ist), Gelesen-Status über `lastReadAt` (kein Schreiben je Nachricht), Ungelesen-Badge in der Navigation.
6. **Anhänge:** Bild (Auswahl/Kamera, clientseitig auf z. B. max. 1600 px verkleinert/komprimiert, Vorschau), Datei (z. B. FIT/PDF, Typ- und Größenlimit), Fortschritt und Abbruch. **Aktivität teilen:** Auswahl aus der Aktivitätsliste, Karte mit Kurzdaten im Chat, Tippen öffnet die Analyse, **wenn** erlaubt, sonst freundlicher Hinweis.
7. **Nachricht löschen:** eigene Nachricht entfernen (Soft-Delete: Text/Anhang entfernen, Platzhalter „Nachricht gelöscht"), Anhang auch aus Storage. Tests.
8. **Push-Infrastruktur:** `users/{uid}/devices/{deviceId}` (Token, Plattform, App-Version, Sprache). Token holen, aktualisieren, bei Logout entfernen. **Berechtigung (Android 13+) erst im Kontext anfragen** (z. B. beim ersten Chat oder nach der Verknüpfung), mit Erklärung vorher. **Notification Channels** je Kategorie (Chat, Plan, Aktivität, Zusammenfassung). Deep Links: Tippen auf Push öffnet den richtigen Chat/Screen, auch bei Kaltstart (Tests mit Router).
9. **Versand (Functions):** `onMessageCreated` sendet Push an den **anderen** Teilnehmer, wenn `settings.notifications.chat` an ist. **Datensparsam:** Standard „Neue Nachricht von <Name>" **ohne** Nachrichtentext, Vorschau nur per Einstellung. Ruhezeiten: Pushes werden in der Ruhezeit **unterdrückt** (die Nachricht bleibt im Chat und im Badge). Ungültige Tokens bereinigen. Nachrichtentext, Gesundheitsdaten und Namen sparsam, nie in Logs.
10. **Weitere Pushes (sparsam, einzeln abschaltbar, Standard moderat):** neues vom Trainer geplantes Workout, Erinnerung an die heutige Einheit zur gewählten Uhrzeit, neue Aktivität ausgewertet, Wochenzusammenfassung, Trainer-Verknüpfung (Anfrage angenommen/beendet), neuer Schwellenwert-Vorschlag. **Geplante Pushes** über Scheduler und vorberechnete `nextReminderAtUtc`/`nextWeeklySummaryAtUtc` im Nutzerzeitzonen-Bezug (Sommerzeit-Tests), nicht durch Abfrage aller Nutzer.
11. **Einstellungen verdrahten:** Schalter je Kategorie, Ruhezeiten, Vorschau, Erinnerungszeit (Speicherung aus Phase 03 nutzen).
12. **Tests:** Funktionen mit Mocks (FCM lässt sich im Emulator nicht echt testen): Payload-Bau, Unterdrückung (Ruhezeit, Schalter), Token-Bereinigung, Scheduler-Logik inkl. Zeitzone, Rules-Tests, Widget-Tests der Konversation (Paginierung, Senden, Fehler/Wiederholen), Deep-Link-Routing.
13. Lokalisierung, Galerie, Golden Tests (Konversation, Chat-Liste, leerer Chat, Fehlerzustand, Aktivitätskarte im Chat).

## STOPP-Punkte
- **STOPP 1 [RISIKO-HOCH]** nach Aufgabe 1 (Rules-Konzept, Widerruf, Löschverhalten)

## Nicht-Ziele
Gruppenchats, Sprachnachrichten, Tippindikator, Reaktionen, Nachricht bearbeiten, Web-Push (Phase 15 optional), E-Mail-Benachrichtigungen.

## Abnahme
### Automatisch prüfbar
- [ ] Alle Tests grün, Rules-Tests (Chat, Anhänge, Widerruf, fremder Zugriff)
- [ ] Functions-Tests: Push-Entscheidungslogik (Schalter, Ruhezeit, Token), Scheduler (Zeitzonen, Sommerzeit), Unread-Zähler transaktional
- [ ] Deep-Link-Tests (Warmstart/Kaltstart), Paginierung und Senden/Wiederholen im Widget-Test
- [ ] Keine Nachrichteninhalte oder Gesundheitsdaten in Logs/Push-Text (Suche + Test)
### Manuell (ich)
- [ ] Zwei Konten auf zwei Geräten: Echtzeit, Anhänge, geteilte Aktivität
- [ ] **Push auf echtem Android-Gerät** (App im Hintergrund und beendet), Berechtigungsdialog im Kontext, Channels in den Systemeinstellungen sichtbar
- [ ] Ruhezeiten und Schalter wirken, Tippen auf Push öffnet den richtigen Chat

## Dokumentation am Ende
`PROGRESS.md`, `DECISIONS.md`, `DATA_MODEL.md`, `MANUAL_STEPS.md` (FCM-Konfiguration, ggf. Cloud Scheduler), `docs/PRIVACY.md`.
