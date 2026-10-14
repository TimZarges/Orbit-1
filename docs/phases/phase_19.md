# PHASE 19 — Onboarding-Redesign, In-App-Beta-Bug-Reporter, Error-UX & Echte Karten

## Modus & Leitplanken
- **Modus:** STANDARDMODUS mit STOPP am Phasenende (RISIKO: MITTEL).
- **Fokus:** Mobile-First UX im ORBIT-Design (`#001F47` Navy, hohe Lesbarkeit, klare Führung).

## Ausgangslage & Ziel
Aus den bisherigen Tests auf dem Smartphone gibt es vier konkrete Schmerzpunkte:
1. Der Onboarding-Prozess ist unübersichtlich und holt neue Nutzer nicht sauber ab.
2. Fehlermeldungen sind technisch/schlecht gelöst; außerdem fehlt für die Beta ein direktes Meldefeld für Bugs.
3. Die Kartenansicht (`telemetry_map_widget.dart:226`) zeichnet nur ein gefälschtes 40px-Canvas-Gitter, weil `flutter_map` fehlt.

## Arbeitspakete

### 19.1 Geführtes Mobile-First Onboarding (Athlet & Coach)
Baue den Onboarding-Flow komplett neu als klaren, motivierenden 4-Schritte-Assistenten mit Fortschrittsbalken:
1. **Rolle & Profil:** Auswahl „Athlet“ oder „Trainer/Coach“, Name, Hauptsportart(en) (Radsport, Laufen, Schwimmen, Triathlon), Einheitensystem (Metrisch).
2. **Physiologische Basiswerte & Zonen (mit Hilfe-Tooltips):**
   - Eingabe von Ruhe-HF, Max-HF, FTP (Watt), Schwellen-Pace und Schwimm-CSS.
   - **Wichtig:** Biete einen Button *„Ich kenne meine Werte noch nicht – automatisch aus meinen ersten Trainings berechnen“* an, damit niemand im Onboarding hängenbleibt!
3. **Datenquelle verbinden:**
   - Karte 1: **Garmin Connect verbinden** (inkl. Direkt-Option „Letzte 90 Tage importieren“).
   - Karte 2: **Erste Trainingsdatei (.fit / .tcx / .gpx) manuell hochladen** (für Wahoo, SRM etc.).
   - Karte 3: *„Später verbinden“*.
4. **Optionaler Coach-Link & Datenschutz:** Einladungscode vom Trainer eingeben (falls vorhanden) + saubere, verständliche DSGVO-Einwilligungen.

### 19.2 Neues Error-Handling & In-App „Beta Bug- & Feedback-Reporter“
1. **Zentraler Error-Mapper (`OrbitErrorHandler`):**
   - Verbanne rohe `FirebaseException`- oder Stacktrace-Strings aus der gesamten UI.
   - Übersetze alle Fehler in verständliche deutsche/englische Nutzerhinweise mit klarer Handlungsoption (z. B. *„Garmin-Server antwortet gerade nicht. Deine Daten gehen nicht verloren.“* + Button *„Erneut versuchen“* oder *„Als Fehler melden“*).
2. **Beta Bug-Reporter (Floating Action / Shake-to-Report / Banner):**
   - Platziere in der Beta-Version ein jederzeit erreichbares **Bug-Report-Icon (Käfer/Megafon-Badge)** in der Top-Bar sowie direkt in jedem Fehler-Banner (*„Problem melden“*).
   - Beim Tippen öffnet sich ein kompaktes Bottom-Sheet:
     - Kategorie: *Bug / Absturz*, *Falsche Berechnung*, *Garmin/Upload-Problem*, *Design/Vorschlag*.
     - Freitextfeld (*„Was ist passiert?“*).
     - Automatischer Anhang (mit Opt-in-Checkbox): Aktuelle Route/Screen, App-Version, Gerätetyp (z. B. Pixel 10 Pro), letzte 20 anonymisierte Log-/Fehlerzeilen und optional ein automatischer Screenshot des aktuellen Screens.
   - Speichere die Meldung in Firestore unter `beta_feedback/{reportId}` (inkl. Storage-Upload für den Screenshot) und zeige dem Nutzer eine Bestätigung.

### 19.3 Echte Kartenkacheln (`flutter_map`) statt Canvas-Fake
1. Füge `flutter_map` und `latlong2` zu `pubspec.yaml` hinzu.
2. Ersetze das 40-Pixel-Canvas-Gitter in `telemetry_map_widget.dart` durch eine echte interaktive Karte:
   - **DSGVO-Opt-in:** Solange der Nutzer den externen Kartenkacheln nicht zugestimmt hat, zeige die GPS-Spur sauber skaliert vor einem edlen dunklen Vektor-Hintergrund mit einem dezenten Overlay-Button *„Kartenansicht aktivieren (lädt Kartenkacheln)“*.
   - **Mit aktivierten Kacheln:** Rendere CartoDB Dark Matter / OpenStreetMap-Kacheln passend zum ORBIT-Theme.
   - Zeichne den GPS-Track farbcodiert (umschaltbar nach **Herzfrequenz-Zone, Watt-Zone oder Pace/Geschwindigkeit**), markiere Start/Ziel sowie Runden-Splits und synchronisiere den Karten-Cursor live beim Finger-Scrubbing über das Höhen-/Watt-Diagramm.

## STOPP-Punkt & Abnahmekriterien
- **STOPP:** Präsentiere Screenshots/Widget-Tests des neuen 4-Schritte-Onboardings, des Bug-Report-Bottom-Sheets und der echten `flutter_map`-Integration.
- Alle Widget-Tests und `flutter analyze` müssen grün sein.
- Nach meiner Freigabe: Commit & Push auf GitHub mit Tag `v0.19.0`.