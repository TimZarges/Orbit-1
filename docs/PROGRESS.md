# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 05
- Branch: feature/phase-05-metrics-core

## Fertig
- Phase 00 (Foundation): Abgeschlossen
- Phase 01 (Auth & Onboarding): Abgeschlossen
- Phase 02 (Trainer-Verknüpfung): Abgeschlossen
- Phase 03 (Profil, Einstellungen, Schwellenwerte): Abgeschlossen
- Phase 04 (Aktivitäts-Import): Abgeschlossen
- Phase 05 (Metrik-Kern):
  - Methodenwahl dokumentiert (NP, TSS, CTL/ATL, Zonen).
  - Testvektoren etabliert (JSON-Dateien für Backend und Dart geteilt).
  - TypeScript-Funktionen für Rad-Leistung (NP/IF/TSS), Load (EMA) und Zonen implementiert und unit-getestet.
  - Dart-Vorschau-Funktionen (`LoadPreview`) implementiert und getestet.
  - ORBIT Score definiert (`docs/ORBIT_SCORE.md`).
  - Trigger `onActivityWritten` und Callable `recomputeMetrics` als Stubs implementiert.

## Offen / in Arbeit
- Phase 06: Garmin-Connector

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.
