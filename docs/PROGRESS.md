# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 13 (Abgeschlossen) -> Phase 14 (Home & Dashboard)
- Branch: feature/phase-13-chat-push

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
- Phase 10 (Analyse einfach – Ampel, Wochenbelastung, Erfahrungsstufen): Abgeschlossen
- Phase 11 (Analyse Cockpit – Telemetrie, Karte, Power-Kurve): Abgeschlossen
- Phase 12 (Leistungsdiagnostik & Schwellenwert-Erkennung): Abgeschlossen
- Phase 13 (Chat und Push-Benachrichtigungen):
  - Datenmodell & Security Rules (`chats/{athleteId}_{coachId}`, Subcollection `messages`, `state`):
    - Teilnehmer-Validierung über `isChatParticipant(chatId)`.
    - Schreibzugriff für Nachrichten erfordert aktiven Chat (`isChatActive(chatId)` blockiert nach Widerruf).
    - Nachrichten-Updates ausschließlich für Soft-Delete durch den Sender (`status == 'DELETED'`), Hard-Delete strikt gesperrt.
    - Storage Rules (`storage.rules`): Bildanhänge $\le 10\text{ MB}$, Dokumente $\le 25\text{ MB}$.
  - Aktivitäts-Sharing (`ActivityShareSnapshot`):
    - Übertragen einer Momentaufnahme absolvierter Trainingseinheiten im Chat ohne Erhöhung von Datenzugriffsrechten.
  - Push-Infrastruktur & Cloud Functions (`functions/src/chat/` & `notifications/`):
    - Trigger `onMessageCreated` aktualisiert `lastMessage` und `unreadCount` transaktional.
    - Datensparsamer Multicast-Versand via FCM ohne sensible Gesundheitsdaten oder Nachrichtentexte.
    - Automatische Unterdrückung während konfigurierter Ruhezeiten (`settings.quietHours`).
    - Automatische Bereinigung ungültiger/abgemeldeter Endgeräte-Tokens (`users/{uid}/devices`).
  - Mobile UI & Routing:
    - `ChatScreen` mit Echtzeit-Stream, Paginierung, Datumstrennern, Eingabeleiste und Soft-Delete.
    - `ChatListScreen` für Trainer-Postfach mit Suche und Unread-Zählern.
    - Aufklärungsdialog vor Push-Berechtigungsanfrage (`NotificationService`).
    - Erweiterung der Widget-Galerie (`/gallery`) und Integration im Coach-Tab sowie Dashboard.

## Offen / in Arbeit
- Phase 14: Home (Heute-Tab, Tageszusammenfassung, Quick Actions, Feedback)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.



