# S1: Chart-Performance Spike Analyse

## Optionen
1. **`fl_chart`**
   - **Vorteile:** 
     - Reines Dart, gut in den Widget-Tree integrierbar.
     - Weit verbreitet, gute Community-Unterstützung.
     - Einfaches Theming und Tooltips.
   - **Nachteile:**
     - Bei über 1000 Punkten in einem LineChart sinkt die Performance (Framerate bricht ein, Scrolling stottert), besonders wenn Touch-Interaktionen (Scrubbing) aktiviert sind.
     - Braucht zwingend Datapoint-Downsampling (LTTB-Algorithmus), um 7200 Punkte eines 2h-Workouts flüssig darzustellen.

2. **CustomPainter (Eigenentwicklung)**
   - **Vorteile:**
     - Maximale Performance durch direkten Canvas-Zugriff (`drawPoints` / `drawPath`). 
     - Problemlos 10.000+ Punkte mit 60fps renderbar.
   - **Nachteile:**
     - Viel Boilerplate (Achsen, Labels, Touch-Handling, Tooltips).
     - Aufwendiger zu warten.

## Empfehlung für ORBIT
**Entscheidung:** Wir starten mit **`fl_chart`**, setzen aber zwingend ein **Downsampling** auf maximal 300-500 Punkte pro Chart-Ansicht um (z.B. Largest Triangle Three Buckets - LTTB, serverseitig in den Cloud Functions oder beim Laden im Client). 
**Begründung:** Der Entwicklungsaufwand für einen robusten CustomPainter mit gutem Touch-Scrubbing ist enorm hoch. Da wir ohnehin Metriken serverseitig vorberechnen, können wir die Zeitreihen direkt passend reduziert für das Charting ausliefern. Wenn das Downsampling aktiv ist, bleibt `fl_chart` auch im Profile-Mode flüssig genug für unsere "Cockpit"-Ansicht.
