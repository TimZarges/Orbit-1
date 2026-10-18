# PHASE 38 — Global greifbarer Bug-Käfer, Metrisches 24h-Datumsformat (`DD.MM.YYYY`), Mitteilungs-Routing, Nutzer-Beta-Inbox, App-Icon-Präzision & Cleanup

## Modus & Zielsetzung
- **Branch:** `feature/phase-38-global-ux-cleanup`
- **Ziel-Release:** `v0.38.0`
- **Ziel:** Global greifbarer Bug-Käfer als Top-Level-Overlay im `MaterialApp.builder` (selbst über geöffneten Modal-Sheets bedienbar), durchgängiges Datumsformat `DD.MM.YYYY` mit 24h-Uhrzeit via `OrbitDateFormatter`, kartengefasste Mitteilungszentrale mit verlässlichem Deep-Link-Routing, Beta-Feedback-Statusansicht für Tester, Widget-Galerie-Entfernung, DSGVO-Kontolöschung mit Auto-Logout und pixelgenaue Zentrierung des App-Icon-Satelliten.
- **Status:** **[x] Abgeschlossen**

---

## Arbeitspakete

### 38.1 Global greifbarer Bug-Käfer (Top-Level Overlay über Modal-Sheets)
- [x] Integration des Bug-Käfers als verschiebbarer/fester Top-Level Overlay im `MaterialApp.builder` mit höchster Z-Index-Priorität.
- [x] Ermöglicht das Melden von Bugs und automatische Screenshot-Erstellung auch bei geöffnetem Modal-Bottom-Sheet (Workout-Detail, Benachrichtigungen, Builder).
- [x] Bug-Käfer bleibt in AppBar des Kalenders und allen Kern-Screens konsistent erreichbar.

### 38.2 Universal-Datumsformat (`DD.MM.YYYY`) & 24h-Uhrzeit via `OrbitDateFormatter`
- [x] Vollständige Ablösung von ISO-Datumsstrings (`2026-10-18`) in der UI.
- [x] Zentrale Formatierung über `OrbitDateFormatter` gekoppelt an lokale Geräte-Zeitzone.
- [x] Konsistentes deutsches Anzeigeformat: `DD.MM.YYYY` (z. B. `18.10.2026`) und 24h-Zeit (`19:06 Uhr`).

### 38.3 Mitteilungszentrale: Einheitliche Umrandung & Deep-Link-Routing
- [x] Kartendesign: Jede Mitteilung erhält eine saubere Umrandung (`Border.all`: ungelesen `#CDFB17` Volt 1.5px, gelesen `Colors.white24` 1.0px).
- [x] Robustes Routing: Klick markiert als gelesen, schließt modal `Navigator.of(context).pop()` und navigiert via Root-Context zielgenau zur verknüpften Route (Aktivität, Kalender, Diagnostik, Coach).

### 38.4 Nutzer-Beta-Feedback-Inbox („Meine Meldungen“ + Live-Status)
- [x] Dedizierte Ansicht für Tester: „Meine gemeldeten Tickets“.
- [x] Echtzeit-Stream aller eigenen Meldungen mit Ticket-ID (`#ORB-xxx`), Kategorie, Datum (`DD.MM.YYYY • HH:mm`) und aktuellem Bearbeitungsstatus (`🟢 Offen`, `🟡 In Arbeit`, `✅ Gelöst`).

### 38.5 Widget-Galerie-Cleanup, DSGVO-Kontolöschung & App-Icon-Präzision
- [x] Restlose Löschung der veralteten Widget-Galerie (Datei, Route und Menüpunkte).
- [x] DSGVO-Kontolöschung: Ausführung der Löschroutine, zwingender Aufruf von `authService.signOut()` und Weiterleitung auf `/login`.
- [x] Präzise Zentrierung des Satelliten-Punkts im App-Icon: Exakter Mittelpunkt in der Öffnung des Volt-Bogens ohne Berührung der Enden.

### 38.6 Abschluss & Hardware-Verifikation
- [x] `flutter analyze --no-pub` & Tests fehlerfrei.
- [x] Build & Installation auf Google Pixel 10 Pro via `adb install -r`.
- [x] Screenshot-Nachweise: Globaler Bug-Käfer über geöffnetem Sheet, Mitteilungen mit Rahmen, Nutzer-Inbox, zentriertes App-Icon.
- [x] Merge in `main`, Tag `v0.38.0` setzen und pushen.
