# Datenschutzerklärung ORBIT (Entwurf v0)

**Hinweis:** Dies ist ein technischer Platzhalter für die Entwicklung. Keine Rechtsberatung! Eine formelle Datenschutz-Folgenabschätzung (DSFA) gemäß Art. 35 DSGVO für Gesundheitsdaten ist vor Launch zwingend erforderlich.

## 1. Verantwortlicher
[Name des Betreibers]
[Adresse]

## 2. Datenarten und Zwecke
Wir verarbeiten folgende Daten:
- **Kontodaten:** E-Mail-Adresse (zur Authentifizierung).
- **Profildaten:** Name, Erfahrungsstufe, Wettkampfziele (zur Personalisierung der App).
- **Gesundheits- und Trainingsdaten (Art. 9 DSGVO):** Herzfrequenz, Leistungsdaten (Watt), Schlafdaten, HRV. **Zweck:** Berechnung von Trainingsbelastung (CTL/ATL), Ermüdung und Empfehlungen.
- **Telemetriedaten:** Absturzberichte via Firebase Crashlytics (anonymisiert, nur nach Opt-in).

## 3. Rechtsgrundlagen
- **Gesundheitsdaten:** Ausdrückliche Einwilligung (Art. 9 Abs. 2 lit. a DSGVO). Ohne diese Einwilligung können die Kernfunktionen der App nicht genutzt werden.
- **Sonstige Daten:** Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO) und berechtigtes Interesse (Art. 6 Abs. 1 lit. f DSGVO).

## 4. Speicherdauer und Löschung
Daten werden gespeichert, solange das Konto existiert. Du kannst dein Konto und alle damit verbundenen Daten jederzeit in der App löschen. Ein Export im JSON-Format steht bereit.

## 5. Auftragsverarbeiter und Datentransfer
Wir nutzen Google Cloud (Firebase) als Hosting-Dienstleister. Die Datenverarbeitung findet ausschließlich in der Region `europe-west3` (Frankfurt) statt.
