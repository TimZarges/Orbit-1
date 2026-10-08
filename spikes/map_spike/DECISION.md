# S2: Karten-Spike Analyse

## Optionen
1. **`flutter_map`**
   - **Vorteile:** 
     - Keine Bindung an Google, völlige DSGVO-Konformität möglich (besonders bei Nutzung eines europäischen Tile-Providers oder selbst gehosteter Tiles).
     - Keine Kosten für die Map-Engine selbst (Kosten hängen vom Tile-Provider ab, z.B. Mapbox, Stadia Maps).
     - Sehr gut anpassbar (Dark-Mode Tiles leicht verfügbar).
     - Marker und Polylines sind leichtgewichtig.
   - **Nachteile:**
     - Etwas weniger "flüssig" out-of-the-box im Vergleich zu den nativen SDKs.
     - 3D-Kippung ist eingeschränkt.

2. **`google_maps_flutter`**
   - **Vorteile:**
     - Nutzt das native Google Maps SDK (hervorragende Performance auf Android/iOS).
     - Sehr vertraute User Experience.
   - **Nachteile:**
     - Datenschutz/DSGVO: Das SDK kommuniziert direkt mit Google, IP-Adressen werden weitergegeben. Für eine Health/Sport-App kann das eine hohe Hürde sein (Einwilligungspflicht!).
     - Kosten: Bei vielen Aufrufen kostenpflichtig (obwohl das Free-Tier oft reicht).
     - Customization von Map-Styles (Dark-Mode) ist möglich, aber komplexer via JSON-Styling.

## Empfehlung für ORBIT
**Entscheidung:** Wir verwenden **`flutter_map`** in Kombination mit einem DSGVO-konformen Tile-Provider (z.B. Stadia Maps, Jawg Maps oder OpenStreetMap).
**Begründung:** Als Trainings- und Gesundheits-App ist Datenschutz ein zentrales Versprechen. Der Verzicht auf Google Maps umgeht ein massives DSGVO-Problem. Zudem erlaubt `flutter_map` einfache Custom-Marker und das Styling für unser dunkles "Cockpit". Die Performance ist für das simple Einblenden einer Route (Polyline + synchroner Marker beim Scrubben) absolut ausreichend.
