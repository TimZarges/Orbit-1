# Fortschritt

> Wird am Ende jeder Phase von Antigravity aktualisiert (`/phase-finish`). Kurz und ehrlich halten.

## Aktuell
- Phase: 12 (Abgeschlossen) -> Phase 13 (Kommunikation & Benachrichtigungen)
- Branch: feature/phase-12-diagnostics

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
- Phase 09 (Workout Builder und Vorlagenbibliothek): Abgeschlossen
- Phase 10 (Analyse einfach – Ampel, Wochenbelastung, Erfahrungsstufen): Abgeschlossen
- Phase 11 (Analyse Cockpit – Telemetrie, Karte, Power-Kurve): Abgeschlossen
- Phase 12 (Leistungsdiagnostik & Schwellenwert-Erkennung):
  - Schätzmethoden je Sportart (`lib/features/diagnostics/domain/` & `functions/src/metrics/diagnostics.ts`):
    - Rad: $0.95 \times \text{MMP}_{20\text{m}}$ mit Variabilitätsindex-Gating ($\text{VI} \le 1.05$ High, $1.05 < \text{VI} \le 1.12$ Medium, $> 1.15$ verworfen).
    - Lauf: 30m Friel-Test mit LTHR (letzte 20m) und Schwellenpace, Prüfung auf stabiles HF-Plateau ($\text{StdDev} \le 4.0\text{ bpm}$).
    - Schwimmen: 400m / 200m CSS-Test mit Berechnung der $\text{Pace}_{\text{CSS}} = (T_{400} - T_{200})/2$.
    - Mindestdifferenzen ($\ge 3\text{ W}$, $\ge 2\text{ bpm}$, $\ge 5\text{ s/km}$, $\ge 1.0\text{ s/100m}$) verhindern Spam-Vorschläge bei insignifikanten Schwankungen.
  - Vorschlagsmodell & Firestore Security Rules (`users/{uid}/thresholdProposals/{id}`):
    - Clients dürfen ausschließlich das Feld `status` auf `ACCEPTED` oder `REJECTED` aktualisieren (`isValidThresholdProposalUpdate`).
    - Lesezugriff für Athlet und Trainer mit `permissions.activities == true`.
    - Neuer Schwellenwert gilt ab heute (`effectiveFrom = heute`), Historie bleibt standardmäßig unverändert.
  - Transparenz & Bestätigung:
    - „Warum?" Bottom-Sheet (`ThresholdExplanationSheet`) mit Datenpunkten, Konfidenz-Einordnung und Limitationen.
    - Dialog (`RecomputeConfirmationDialog`) mit optionaler historischer Neuberechnung (`recomputeMetrics`).
  - Geführte Feldtests (`GuidedTestCard`) für Rad, Lauf und Schwimmen mit 1-Klick-Einplanung im Kalender.
  - Vollständiger Diagnostik-Screen (`DiagnosticsScreen`) mit Sportarten-Tabs, Verlaufsdiagramm (`ThresholdHistoryChart`) und Schwellenwert-Historie.
  - Verknüpfung im Analyse-Tab (`ThresholdProgressCard`) mit Benachrichtigungs-Badge bei neuen Vorschlägen und im Dashboard-Avatarmenü.
  - Erweiterung der Widget-Galerie (`/gallery`) und umfassende Unit-Tests.

## Offen / in Arbeit
- Phase 13: Kommunikation & Benachrichtigungen (Chat, Aktivitäts-Share, FCM-Push, ruhige Stunden)

## Bekannte Probleme
- `build_runner` Konflikte durch `analyzer` Abhängigkeiten: Wir nutzen derzeit manuelle Models anstelle von `freezed`.



