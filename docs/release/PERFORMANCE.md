# Performance-Review & Optimierungsbericht (v1.0)

> Zielwerte: Flüssiges Scrollen (60/120 fps), schnelle App-Starts (< 1.5 s), minimales Datenaufkommen, sparsame Firestore-Reads.

---

## 1. Firestore Read-Budget je Screen

| Screen / Feature | Reads pro Aufruf | Architekturmaßnahme |
|---|---|---|
| **Home („Heute")** | $\le 4$ Reads | Gebündelter `homeDashboardProvider` lädt Tagesaggregat, 1 geplantes Workout, 1 letzte Aktivität und Profil. Riverpod State Caching. |
| **Kalender** | 1 Query ($7$–$31$ Dokumente) | Monatsabfrage mit Firestore-Index `(athleteId, localDate)`. Kein Nachladen beim Tagesscrollen. |
| **Aktivitäts-Cockpit** | 1 Read + Storage Stream | Hauptdokument wird geladen; 1-Hz-Stream (JSON.gz) wird komprimiert aus Storage gestreamt (spart Firestore Dokumentengrößen). |
| **Trainer-Kaderliste** | 1 Query ($N$ Dokumente) | Serverseitig voraggregierte `coachDashboard/{coachId}/athletes` Collection. O(1) Reads für den gesamten Kader statt $N \times 4$ Abfragen. |
| **Chat** | 1 Listener mit Paginierung | `limit(30)` für Initialabfrage, Cursor-basiertes Nachladen älterer Nachrichten. |

---

## 2. Speicher- und Stream-Management

1. **Downsampling auf 1 Hz:**
   - Hohe Sensorfrequenzen (z. B. 10 Hz Powermeter) werden im Cloud Functions FIT-Parser gleichmäßig auf 1-Sekunden-Intervalle heruntergerechnet.
   - Gz-Kompression reduziert die Dateigröße einer 4-stündigen Ausfahrt von ~15 MB auf < 600 KB.
2. **Chart-Rendering (Fl_Chart):**
   - Auf Mobile werden Zeitreihen bei längeren Einheiten (> 2 Stunden) vor dem Rendern im UI aggregiert (Min/Max/Avg Bucketing), um Jank und Speicherüberlauf zu verhindern.
3. **Listener & Memory-Leak-Prävention:**
   - Riverpod `autoDispose` auf temporären Ansichts-Providern stellt sicher, dass Stream-Subscriptions beim Verlassen des Screens automatisch abgeräumt werden.

---

## 3. Web- & Desktop-Performance

1. **CanvasKit vs. HTML Renderer:**
   - Flutter Web nutzt CanvasKit für flüssiges Chart-Rendering und identische Vektorgrafiken wie auf Android/iOS.
2. **Schriftarten:**
   - Lokales Bündeln der System-/Design-Schriftarten (kein Laufzeit-Download von Google Fonts, DSGVO-konform und offline-schnell).
3. **Tastaturbedienung & Fokussierung:**
   - Schnelle Shortcuts (`Cmd+K`, `/`, `?`) ohne Re-Rendering des gesamten DOM-Baums.
