# PHASE 36 — Login-First, Rollenspezifisches Onboarding (Athlet vs. Coach), E-Mail-Verifikations-Warteraum & Profil-Persistenz

## Modus & Zielsetzung
- **Branch:** `feature/phase-36-login-onboarding-auth`
- **Ziel-Release:** `v0.36.0`
- **Ziel:** Saubere Trennung von Login und Onboarding, Beseitigung von Marken-Redundanzen (kein doppelter ORBIT-Schriftzug), Passwort-Reset & strikte Passwort-Kriterien mit Live-Checklist, dedizierter E-Mail-Verifikations-Warteraum mit Polling, rollenspezifische Onboarding-Pfade für Athleten und Trainer und 100%ige Profil-Persistenz.
- **Status:** **[x] Abgeschlossen & Verifiziert**

---

## Arbeitspakete

### 36.1 Login-First beim App-Start, Kein Doppel-„ORBIT“ & Passwort-Reset
- [x] Unauthentifizierter Start führt direkt auf die Login-Seite (`/login`).
- [x] Prominenter Button „Konto erstellen / Registrieren“ leitet ins Onboarding weiter.
- [x] Entfernung doppelter „ORBIT“-Schriftzüge auf dem Login-Screen und im Header des Dashboards.
- [x] „Passwort vergessen?“ Dialog auf `/login` via `sendPasswordResetEmail` mit verständlicher deutscher Rückmeldung.
- [x] „Passwort ändern“ Dialog in den Einstellungen (Altes Passwort + Neues Passwort 2x validieren).

### 36.2 Doppelte Passwort-Eingabe, 8+ Zeichen Checkliste & E-Mail-Warteraum
- [x] Zweifaches Passwortfeld bei Registrierung (`Passwort` & `Passwort bestätigen`).
- [x] Passwort-Regel: Mindestens 8 Zeichen, min. 1 Großbuchstabe, 1 Kleinbuchstabe, 1 Zahl/Sonderzeichen.
- [x] Visuelle interaktive Live-Abhak-Liste unter dem Passwortfeld.
- [x] `EmailVerificationWaitingScreen`: Nach Registrierung wird Bestätigungs-E-Mail versendet und der Nutzer auf den Lade-/Wartescreen geleitet.
  - [x] Automatisches Polling alle 3 Sekunden per `user.reload()`.
  - [x] Manuelle Buttons: „Jetzt prüfen“, „E-Mail erneut senden“ und „Abmelden“.
  - [x] Erst nach verifizierter E-Mail wird der Zugang zur Haupt-App freigegeben.

### 36.3 Rollenspezifisches Onboarding: Athlet vs. Coach
- [x] Weiche in Schritt 1 nach Rollenauswahl:
  - [x] **Rolle Athlet:** Vor-/Nachname, Profilbild (Kamera/Galerie), Geburtsdatum, Gewicht (kg), Größe (cm), Ruhepuls, Max-Puls, Hauptsportarten, Erfahrungsstufe, Schwellenwerte, Garmin-Connect, Datei-Upload & 6-stelliger Trainer-Code.
  - [x] **Rolle Coach:** Dedizierter Trainer-Fragebogen mit Vor-/Nachname, Profilbild, betreuten Hauptsportarten, **Verein / Team (optional)**, **Coaching-Name / Firma (optional)** und Coach-Modus (*„Einfach & Download“* vs. *„Volle Analyse“*).

### 36.4 Onboarding UI-Fixes, Triathlon-Kombi-Logo & 100 % Profil-Persistenz
- [x] Entfernung störender Checkmark-Bullets hinter Sportart-Icons (`showCheckmark: false`).
- [x] Kombiniertes Triathlon-Piktogramm (`TriathlonCombinedIcon` für Schwimmen/Rad/Lauf).
- [x] Datenschutz-Checkbox mit visueller Warnung (roter Rahmen & Hinweistext) bei Klick ohne Bestätigung.
- [x] Feststehender Navigations-Button in der `bottomNavigationBar` („Weiter“ bzw. „Jetzt registrieren“).
- [x] Garantierte Persistenz aller Onboarding-Felder inkl. Profilbild in Firestore (`users/{uid}`) und Cloud Storage (`users/{uid}/profile.jpg`) sowie sofortige Anzeige im Profil.

### 36.5 Abschluss & Hardware-Verifikation
- [x] `flutter analyze --no-pub` & Tests fehlerfrei.
- [x] Build & Installation auf Google Pixel 10 Pro via `adb install -r`.
- [x] Screenshot-Nachweise: Login, Passwort-Checklist, Email-Warteraum, Coach-Onboarding.
- [x] Merge in `main`, Tag `v0.36.0` setzen und pushen.
