# PHASE 28 — Live-Reparatur der Kernfunktionen + Geschlossener Bug-, Ideen- & Kontakt-Workflow

## Modus & Leitplanken
- **Modus:** STANDARDMODUS (RISIKO: MITTEL — UI/UX Feinschliff, Feedback-Pipeline & Kontakt-Integration).
- **Ziel:** Behebung aller in Phase 25 identifizierten Punkte und Etablierung eines professionellen, geschlossenen Workflows für Beta-Tester (In-App-Tickets mit ID `#ORB-xxx`, Admin-Inbox, CLI-Pull nach `BUGS.md` und offizielle Kontaktwege).

---

## Arbeitspakete

### 28.1 Live-Reparatur der Kernfunktionen (UI/UX aus Phase 25)
1. **Manueller Datei-Upload (.fit / .tcx / .gpx):**
   - Reibungsloser FilePicker-Zugriff auf Android (Berechtigungen, MediaStore/Downloads).
   - Saubere Fortschrittsanzeige und sofortiger Übergang zur Detail-Analyse nach Upload.
2. **Drei-Ringe-Hero-Card & Design:**
   - Exakte Farb- und Kontrastabstimmung auf dem 120-Hz-OLED des Pixel 10 Pro.
   - Dynamischer Belastungs-Zielkorridor und Recovery-Ampel visuell glätten.
3. **Karten & 120-Hz-Touch-Scrubbing:**
   - Entkoppeltes Scrubbing mit `ValueNotifier` für seidig weiche 120 FPS ohne Frame-Drops.
   - GPS-Polyline Darstellung und DSGVO-Kachel-Opt-in prüfen.

### 28.2 Geschlossener Bug-, Ideen- & Support-Workflow
1. **Erweiterung `BetaBugReporterSheet`:**
   - 3 klare Kategorien:
     - 🐛 *Fehler / Bug melden*
     - 💡 *Verbesserungsvorschlag / Idee*
     - ❓ *Frage / Support*
   - Automatische Screenshot-Aufnahme via `RepaintBoundary` und System-Metadaten (App-Version, OS, Gerät).
2. **Backend-Trigger `onBetaFeedbackCreated`:**
   - Lauscht auf `betaFeedback/{reportId}`.
   - Vergibt fortlaufende Ticket-ID (z. B. `#ORB-042`).
   - Sendet sofortige Admin-Push-Benachrichtigung an Tim.
3. **Admin Feedback-Inbox (`/admin/feedback`):**
   - Ansicht für Admin (App & Web) zur Durchsicht aller Meldungen mit Status (`OPEN`, `IN_PROGRESS`, `RESOLVED`).
   - Screenshot-Vorschau und Detail-Logs.
4. **CLI-Pull-Skript (`functions/src/scripts/pullFeedback.ts`):**
   - Aufruf per `npm --prefix functions run feedback:pull`.
   - Zieht alle offenen Reports aus Firestore und aktualisiert automatisch `docs/beta/BUGS.md`.

### 28.3 Offizielle E-Mail-Adressen & Web-Kontaktformular
1. **Zentrale E-Mail-Konfiguration (`core/config/contact_config.dart` & Website):**
   - `support@orbit-training.app` — Allgemeine Fragen & Hilfe.
   - `bugs@orbit-training.app` — Technische Probleme & Abstürze.
   - `feedback@orbit-training.app` — Wünsche, Feature-Ideen & UI-Feedback.
   - `hello@orbit-training.app` — Kooperationen, Vereine & Allgemeines.
   - `privacy@orbit-training.app` — Datenschutz & DSGVO-Anfragen.
2. **Web-Kontakt- & Ideen-Formular (`public/index.html` & `public/help.html`):**
   - Interaktives Formular für Website-Besucher und Beta-Interessenten.
   - Speicherung in Firestore-Collection `contactRequests/{id}` mit serverseitiger Validierung in `firestore.rules`.

---

## STOPP-Punkt 1 (Abnahme Phase 28)
- Vorlage der behobenen UI/UX-Punkte auf dem Pixel 10 Pro.
- Test-Ticket mit `#ORB-xxx` erfolgreich erstellt, in der Admin-Inbox sichtbar und per `feedback:pull` in `BUGS.md` eingetragen.
- Freigabe durch Tim -> Commit & Tag `v0.28.0`.
