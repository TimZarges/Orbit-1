# Requirements: Projekt ORBIT

> Bereinigte Fassung (ersetzt `requierment.md`). Stand der Entscheidungen: siehe `docs/DECISIONS.md`.

## 1. Vision
ORBIT ist eine Trainingsplattform für Ausdauersportler, vor allem Triathleten (Schwimmen, Rad, Lauf; zusätzlich Kraft). Sie vereint wissenschaftliche Analyse (Ref: Golden Cheetah, nur Funktionsidee) mit einer intuitiven Oberfläche (Ref: Apple Fitness) und ist funktional an Plattformen wie MATS angelehnt (nur Funktionsideen, nichts übernehmen).
Zielgruppe: Athleten und Trainer mit Leistungsanspruch. Hobbysportler dürfen sich nicht überfordert fühlen (Erfahrungsstufen, Progressive Disclosure).

## 2. Rollen
- `ATHLETE` (Standard): importiert Training, plant, analysiert, kommuniziert mit dem Trainer (optional).
- `TRAINER`: verwaltet verknüpfte Athleten, plant für sie, analysiert, chattet. Desktop-Erlebnis ist hier besonders wichtig und anpassbar.
- Jeder User hat ein `role`-Feld, nur serverseitig setzbar. Der Trainer sieht nur freigegebene Daten verknüpfter Athleten.

## 3. Plattform und Technik
- Flutter (Android > iOS > Web/Desktop), Mobile-First. Kein Offline-Modus.
- Firebase (Auth, Firestore, Storage, Functions, FCM, App Check, Crashlytics), EU-Region.
- Sprachen: Deutsch (Standard), Englisch (umschaltbar in den Einstellungen).
- DSGVO-orientiert (Gesundheitsdaten, Einwilligung, Löschung, Export).
- Kein Bezahlmodell im MVP.

## 4. Funktionen (Priorität)
**Hoch:** (1) Import von Trainings- und Health-Daten (Garmin zuerst, plus FIT-Upload, Anbieter später erweiterbar) · (2) Kalender mit Soll-Ist-Abgleich · (3) Workout Builder und Vorlagenbibliothek · (4) Trainings- und Leistungsanalyse/Diagnostik · (5) Chat Athlet↔Trainer mit Push.
**Danach:** Home-Dashboard (Daily Ring, Form, nächstes Training), Coach-Desktop (mehrere Athleten, anpassbar), weitere Anbieter (Strava u. a.).
**Nicht im MVP:** Bezahlmodell/Stripe, Offline-Modus, KI-Coach.

## 5. Kernanforderungen im Detail
- **Login:** Google, E-Mail/Passwort (verifiziert); Apple Sign-In mit iOS-Start nachziehen.
- **Onboarding (kurz):** Rolle, Sportart(en), Erfahrungsstufe, optional Wettkampfziel mit Datum, danach „Garmin verbinden / FIT importieren / Demo ansehen". Schwellenwerte werden später aus Daten geschätzt oder im Profil eingetragen.
- **Trainer-Verknüpfung:** per Einladung (Code/Link/QR), Annahme durch den Athleten, granulare Freigaben (Kalender, Aktivitäten, Health), jederzeit widerrufbar.
- **Kalender:** Wochen-, Monats-, Listenansicht. Geplant vs. absolviert automatisch zugeordnet. Verschieben mobil über Schnellaktionen/Datumsauswahl, später Drag & Drop (Desktop).
- **Workout Builder:** Blockbasiert, verschachtelte Wiederholungen, Ziele je Sportart (Zone, % FTP, % Schwellen-HF, Pace, Schwimm-Pace/100 m), Text-Kurzeingabe mit Live-Vorschau, Vorlagenbibliothek.
- **Analyse:** zwei Ebenen (einfach/Detail), Kennzahlen laut `docs/specs/METRICS.md`, Cockpit-Charts mit Scrubbing und Kartenbezug, Diagnostik mit Schwellenwert-Vorschlägen (Nutzer bestätigt).
- **Chat:** 1:1, Echtzeit, Anhänge (Bild/Datei/Aktivität), Push, Gelesen-Status.
- **Demo-Modus:** nutzersichtbar, mit realistischen Beispielaktivitäten (auch für Reviews bei Garmin und App-Stores).

## 6. Design
Siehe `docs/DESIGN.md`. Navigation rollenabhängig mit 4 Tabs, Profil hinter dem Avatar.
