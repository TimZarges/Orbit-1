# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 09 (Abgeschlossen) -> Phase 10 (Auswertungen & Trainingsanalyse)
- Branch: feature/phase-09-workout-builder

## Fertig
- Phase 00 (Foundation): Abgeschlossen
- Phase 01 (Auth & Onboarding): Abgeschlossen
- Phase 02 (Trainer-Verknüpfung): Abgeschlossen
- Phase 03 (Profil, Einstellungen, Schwellenwerte): Abgeschlossen
- Phase 04 (Aktivitäts-Import): Abgeschlossen
- Phase 05 (Metrik-Kern): Abgeschlossen
- Phase 06 (Garmin-Connector): Abgeschlossen
- Phase 07 (Gesundheitsdaten & Daily Metrics): Abgeschlossen
- Phase 08 (Kalender und Soll-Ist-Abgleich): Abgeschlossen
- Phase 09 (Workout Builder und Vorlagenbibliothek):
  - Domänenmodell Schema v1 (`WorkoutStructure`, `StepBlock`, `RepeatBlock`, `WorkoutTarget`, `WorkoutIntensity`, `WorkoutCadence`) mit SI-Einheiten, Validierung (Tiefe ≤ 3, Blöcke ≤ 200) und `migrateStructure` umgesetzt.
  - Textsyntax-Parser (`WorkoutParser`) und Formatter (`WorkoutFormatter`) mit Zeichenspannen, Typografie-Normalisierung (`’` / `”`), Round-Trip-Konsistenz und Kurzformen (`8x100m CSS / 20"`) implementiert.
  - Berechnungs-Engine (`WorkoutCalculator`) für Gesamtdauer, Distanz, Zonenverteilung, Belastung (ORBIT Score / TSS) und Annahmen-Dokumentation (CSS, Schwellenpace).
  - Performante Live-Profilgrafik (`WorkoutProfileChart`) mit `CustomPainter`, Zonenfarben, Mindestbreite für ultrakurze Schritte und `Semantics` für Barrierefreiheit.
  - Interaktiver mobiler Workout-Builder (`WorkoutBuilderScreen`) mit Syntax-Chips, Fehleranzeige und bidirektional synchronisiertem Bottom-Sheet-Editor (`WorkoutBlockEditorSheet`) inkl. Undo/Redo.
  - Firestore Security Rules für `workoutTemplates` durch den Spezialisten `firestore-rules-author` erstellt (Schutz vor Ownership-Hijacking, DoS/Größenprüfung, Trainer-Sharing über `coachLinks`).
  - Vorlagenbibliothek (`WorkoutTemplateLibraryScreen`) mit Suche, Sportart- und Favoriten-Filter sowie 20 eigenständigen Triathlon-Startvorlagen (`TemplateSeedData`).
  - Nahtlose Kalender-Verknüpfung: Entkoppeltes Einplanen per Kopieren der Struktur, Aktivierung der Einstiege im Schnelleingabe-Dialog und Mini-Zonenprofil auf den Kalender-Karten.

## Offen / in Arbeit
- Phase 10: Auswertungen und Trainingsanalyse (Aktivitäts-Detailansicht, Telemetrie-Streams, Zonenverteilung, Rundenanalyse)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.



