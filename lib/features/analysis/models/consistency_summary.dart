/// Auswertung der Trainingskonsistenz und Regelmäßigkeit.
class ConsistencySummary {
  /// Anzahl der aktiven Trainingstage im gewählten Zeitraum.
  final int activeDays;

  /// Gesamttage des Zeitraums (z. B. 7 für Woche, 28 für Monat).
  final int totalDays;

  /// Anzahl der laut Plan vorgesehenen Trainingstage.
  final int plannedDays;

  /// Aktuelle Serie an konsistenten Trainingswochen (mind. 3 Einheiten pro Woche).
  final int streakWeeks;

  const ConsistencySummary({
    required this.activeDays,
    required this.totalDays,
    required this.plannedDays,
    required this.streakWeeks,
  });

  /// Konsistenz-Verhältnis in Prozent (z. B. 4 von 7 Tagen = 57 %).
  int get activePercent {
    if (totalDays <= 0) return 0;
    return ((activeDays / totalDays) * 100).round();
  }

  /// Deutscher Statustext.
  String get statusTextDe {
    if (plannedDays > 0) {
      return '$activeDays von $plannedDays geplanten Tagen absolviert';
    }
    return '$activeDays Trainingstage in den letzten $totalDays Tagen';
  }

  /// Englischer Statustext.
  String get statusTextEn {
    if (plannedDays > 0) {
      return '$activeDays of $plannedDays planned days completed';
    }
    return '$activeDays training days in the last $totalDays days';
  }
}
