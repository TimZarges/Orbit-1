# PHASE 29 — Zentrale Sprach-/Farb-Indizes, Onboarding-First-Flow, Komplettes Profil & Echte Erfahrungsstufen

## Modus & Zielsetzung
- **Modus:** AUTONOMER BETRIEB (Google Pixel 10 Pro via USB / `adb`)
- **Ziel:** Beseitigung aller UX-, Kontrast- und Ablaufprobleme aus dem ersten persönlichen Hardware-Test (`Orbit Test Bug.pdf`). Einführung zentraler Tokens, Onboarding-First ohne Login-Wand, vollständige Profilpflege inkl. Bild und reaktive Erfahrungsstufen.

---

## Arbeitspakete

### 29.1 Zentrale Farb- & Text-Indizes (Keine Hardcodings mehr!)
1. **Zentrale Design-Tokens (`OrbitThemeTokens`):**
   - Vollständige Eliminierung hartcodierter Farbcodes (`#0F172A`, verstreute Hex-Werte, unleserliche Farbpaarungen).
   - Einheitliches Theme-System basierend auf Brand-Navy `#001F47` (`AppColors.navy`), Volt `#CDFB17` (`AppColors.volt`), Karten-Hintergrund `#002A5C` und definierte Statusfarben.
   - Bereinigung des veralteten Versions-Strings (`v0.19.0-beta`) im Bug-Reporter auf dynamische Auslese aus `AppInfo`.
2. **Zentraler Lokalisierungs- / String-Index (`AppStrings`):**
   - Beseitigung aller unübersetzten Roh-Strings in der UI (z. B. `system`, `advanced`, `expert` in den Einstellungen).
   - Einführung von `AppStrings` bzw. sauberen Display-Mappings für alle Enums (Sprache, Einheiten, Themes, Erfahrungsstufen, Disziplinen).

### 29.2 Neuer Onboarding-First-Flow (Ohne Login-Wand beim Erststart!)
1. **Routing- & Einstiegs-Logik (`app_router.dart`):**
   - Erststart ohne existierende Sitzung leitet direkt in das Onboarding (`/onboarding`), statt vor eine Login-Wand.
   - Prominente Abkürzung für bestehende Nutzer (*„Bereits ein Konto? -> Anmelden“*) auf Screen 1 des Onboardings und im Header.
2. **Behebung aller UI- und Overflow-Bugs aus dem Hardware-Test:**
   - Tastatur-Handling auf allen Auth-/Eingabe-Screens: `SingleChildScrollView` mit `viewInsets` zur Beseitigung von `BOTTOM OVERFLOWED BY 38 PIXELS`.
   - Beseitigung schwarzer Sportart-Chips auf dunkelblauem Grund (Volt-/Navy-Kontrast-Chips).
   - Behebung des Wortumbruch-Fehlers bei *„Fortgeschritten“* in den Auswahl-Karten.
3. **Vollständige Datenerfassung im Onboarding:**
   - Abfrage aller sportrelevanten Basisdaten:
     - Rolle: Athlet oder Trainer/Coach
     - Vor- & Nachname
     - **Profilbild (Kamera/Galerie-Upload bzw. Bildauswahl)**
     - Geburtsdatum / Alter
     - Körpergewicht (kg) und Körpergröße (cm)
     - Ruhepuls ($HR_{\text{rest}}$) und Max-Puls ($HR_{\max}$)
     - Hauptsportarten (Rad, Lauf, Schwimmen, Triathlon, Kraft)
     - Erfahrungsstufe (`Einfach`, `Fortgeschritten`, `Experte`)
     - Schwellenwerte (FTP, Schwellenpace, CSS)
4. **Konto-Erstellung im finalen Schritt:**
   - Erst im letzten Schritt trägt der Nutzer E-Mail & Passwort ein.
   - Beim Klick auf „Konto erstellen“ wird das Firebase-Auth-Konto angelegt und **alle eingegebenen Daten samt Profilbild-Referenz direkt im Firestore-Dokument `users/{uid}` persistiert**.
   - Die Daten stehen unmittelbar in [`profile_screen.dart`](file:///Users/timzarges/Desktop/source/Orbit/lib/features/profile/screens/profile_screen.dart) zur Ansicht und Bearbeitung bereit.

### 29.3 Globaler Bug-Käfer (`BetaBugReporterSheet`) von Sekunde 1 an
1. Das Käfer-Icon (`Icons.bug_report`) ist auf **jedem** Screen in der oberen App-Bar erreichbar:
   - Onboarding-Screens
   - Login- & Registrierungs-Screen
   - Dashboard, Kalender, Analyse, Coach-Tab
2. Fester Menüpunkt in den Einstellungen: *„Fehler melden & Verbesserung vorschlagen“*.

### 29.4 Erfahrungsstufen (`Einfach`, `Fortgeschritten`, `Experte`) mit echter Wirkung
1. Die Einstellung steuert die Datendichte und Informationsarchitektur in der gesamten App:
   - **Einfach:** Fokus auf Grundwerte (3 Ringe, Trainingsdauer, Distanz, Ø Puls, Ø Watt/Pace, verbrannte Kalorien). Ausblendung komplexer sportwissenschaftlicher Metriken ($W'\text{bal}$, Aerobic Decoupling, Normbänder $\mu \pm 1\sigma$, CP-Hyperbel).
   - **Fortgeschritten:** Zusätzlich Trainingszonen (Z1–Z7), ORBIT-Belastungspunkte, Intervall-Tabelle und PMC-Trend (Fitness/Ermüdung/Form).
   - **Experte:** Volle wissenschaftliche Telemetrie inkl. $CP$/$W'$, $W'\text{bal}$-Ausschöpfungskurve, Aerobic Decoupling ($EF$, $PW:HR$) und 30-Tage-Normbändern.

---

## Verifikation & Nachweise
- Ausführung auf dem per USB verbundenen Pixel 10 Pro (`58251FDCR00EQ2`).
- Flutter-Tests (100 % bestanden).
- ADB-Screenshots des neuen Onboarding-Flows, des Profils mit Daten und der 3 Erfahrungsstufen-Ansichten in `docs/beta/screenshots/`.
