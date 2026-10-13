# Datenschutzerklärung ORBIT (Entwurf v0)

**Hinweis:** Dies ist ein technischer Platzhalter für die Entwicklung. Keine Rechtsberatung! Eine formelle Datenschutz-Folgenabschätzung (DSFA) gemäß Art. 35 DSGVO für Gesundheitsdaten ist vor Launch zwingend erforderlich.

## 1. Verantwortlicher
[Name des Betreibers]
[Adresse]

## 2. Datenarten und Zwecke
Wir verarbeiten folgende Daten:
- **Kontodaten:** E-Mail-Adresse (zur Authentifizierung).
- **Profildaten:** Name, Erfahrungsstufe, Wettkampfziele (zur Personalisierung der App).
- **Gesundheits- und Trainingsdaten (Art. 9 DSGVO):** Herzfrequenz, Leistungsdaten (Watt), GPS-Tracks, Ruhepuls, Herzfrequenzvariabilität (HRV rMSSD), Schlafdauer und Schlaf-Score (`users/{uid}/dailyMetrics/{localDate}`).
  - **Zweck:** Berechnung von Trainingsbelastung (CTL/ATL, ORBIT Score), Ermittlung der persönlichen 28-Tage-Basislinie und sachliche Einordnung der Tagesform.
  - **Keine Diagnosen:** Die Daten werden ausschließlich für sportwissenschaftliche Trainingssteuerung und Erholungsauswertung genutzt. Es finden keine medizinischen Diagnosen oder Heilsversprechen statt.
- **Weitergabe an Trainer:** Eine Einsichtnahme durch verknüpfte Trainer in Gesundheitsdaten (Ruhepuls, HRV, Schlaf) erfolgt **ausschließlich nach ausdrücklicher, gesonderter Freigabe** (`permissions.health == true`). Diese Freigabe kann vom Athleten jederzeit mit sofortiger Wirkung widerrufen werden.
- **Telemetriedaten:** Absturzberichte via Firebase Crashlytics (anonymisiert, nur nach Opt-in). Keine Gesundheitsdaten oder personenbezogenen Daten in Logs oder Push-Benachrichtigungen.

## 3. Rechtsgrundlagen
- **Gesundheitsdaten:** Ausdrückliche Einwilligung (Art. 9 Abs. 2 lit. a DSGVO) mit protokolliertem Zeitstempel und Version. Ohne diese Einwilligung werden keine Gesundheitsdaten verarbeitet.
- **Sonstige Daten:** Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO) und berechtigtes Interesse (Art. 6 Abs. 1 lit. f DSGVO).

## 4. Speicherdauer, Datenübertragbarkeit und Löschung
- **Löschung (Art. 17 DSGVO):** Ein Nutzer kann sein Konto und alle zugehörigen Daten (einschließlich aller `dailyMetrics`, `activities`, Schwellenwerte und Authentifizierungsdaten) jederzeit über die Funktion „Konto löschen“ vollständig und unwiderruflich entfernen.
- **Datenübertragbarkeit (Art. 20 DSGVO):** Ein vollständiger Export aller gespeicherten Profildaten, Trainings- und Gesundheitsdaten steht über die Funktion „Daten exportieren“ im maschinenlesbaren JSON-Format zur Verfügung.

## 5. Auftragsverarbeiter und Datentransfer
Wir nutzen Google Cloud (Firebase) als Hosting-Dienstleister. Die Datenverarbeitung findet ausschließlich in der Region `europe-west3` (Frankfurt) statt.

## 6. Kartendienste und externe Kacheln (DSGVO Art. 6 Abs. 1 lit. a)
- **Vektor-Streckenführung:** Die interaktive Visualisierung absolvierter GPS-Streckenführungen erfolgt standardmäßig rein clientseitig (Offline / Vektor-Rendering). Hierbei werden keinerlei Daten oder IP-Adressen an externe Server übertragen.
- **Externe Umgebungskarten (Kacheln):** Das Nachladen detaillierter Kartengrundlagen von Drittanbietern (z. B. OpenStreetMap / CARTO) erfordert eine ausdrückliche Opt-In-Einwilligung im Cockpit („Kartenkacheln laden“), da hierbei die IP-Adresse des Endgeräts verarbeitet wird. Die Einwilligung kann in den Einstellungen jederzeit widerrufen werden.

