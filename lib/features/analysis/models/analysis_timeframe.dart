/// Zeiträume für die Trainingsanalyse im Analyse-Tab.
enum AnalysisTimeframe {
  /// Letzte 7 Tage bzw. aktuelle Woche (Mo–So)
  week,

  /// Letzte 28 Tage bzw. aktueller Monat
  month,

  /// Letzte 12 Wochen bzw. Saison
  season,
}

extension AnalysisTimeframeX on AnalysisTimeframe {
  String get labelDe {
    switch (this) {
      case AnalysisTimeframe.week:
        return 'Woche';
      case AnalysisTimeframe.month:
        return 'Monat';
      case AnalysisTimeframe.season:
        return 'Saison';
    }
  }

  String get labelEn {
    switch (this) {
      case AnalysisTimeframe.week:
        return 'Week';
      case AnalysisTimeframe.month:
        return 'Month';
      case AnalysisTimeframe.season:
        return 'Season';
    }
  }
}
