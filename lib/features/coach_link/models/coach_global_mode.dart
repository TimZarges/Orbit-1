/// Globale Ansichtsmodi für den Trainer in der ORBIT-Plattform (AGENTS.md Regel 32.3).
enum CoachGlobalMode {
  /// Modus 1 — „Einfach (Übersicht & Originaldatei-Download)“:
  ///
  /// Schlanke Athleten-Übersicht mit Fokus auf Kernfakten (Sportart, Dauer, Distanz, Ø HF, Ø Watt).
  /// Bietet pro Einheit einen prominenten Direkt-Download-Button für die Originaldatei (.fit / .tcx)
  /// zur schnellen Übergabe an externe Spezialsoftware (WKO5, GoldenCheetah, SRM etc.).
  simpleDownload,

  /// Modus 2 — „Analyse (Volles Cockpit)“:
  ///
  /// Volles ORBIT-Erlebnis: Bei aktiver Freigabe Einsicht in alle Gesundheitsdaten, die 3 Ringe,
  /// PMC-Trendverläufe (CTL/ATL/TSB), Power-Duration-Kurven, Intervall-Splits und Tiefentelemetrie.
  fullAnalysis;

  /// Anzeigename für UI-Toggles und SegmentedButtons.
  String get displayName {
    switch (this) {
      case CoachGlobalMode.simpleDownload:
        return 'Einfach & Download';
      case CoachGlobalMode.fullAnalysis:
        return 'Vollanalyse';
    }
  }

  /// Beschreibung des jeweiligen Modus für Tooltips und Erklärungen.
  String get description {
    switch (this) {
      case CoachGlobalMode.simpleDownload:
        return 'Kompakt-Fokus auf Kernwerte & direkten .FIT/.TCX-Download für WKO5/GoldenCheetah.';
      case CoachGlobalMode.fullAnalysis:
        return 'Vollständiges ORBIT-Cockpit mit 3 Ringen, PMC, Kurven und Tiefentelemetrie.';
    }
  }
}
