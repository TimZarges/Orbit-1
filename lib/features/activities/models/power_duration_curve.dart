/// Einzelner Datenpunkt auf der Power-Duration-Kurve (Mean-Maximal-Power).
class PowerDurationPoint {
  /// Dauer in Sekunden (z. B. 5, 60, 300, 1200, 3600).
  final int durationSec;

  /// Beste Durchschnittsleistung dieser Aktivität über diese Dauer in Watt.
  final double activityWatts;

  /// Saison-Bestleistung über diese Dauer in Watt.
  final double? seasonBestWatts;

  /// Allzeit-Bestleistung über diese Dauer in Watt.
  final double? allTimeBestWatts;

  const PowerDurationPoint({
    required this.durationSec,
    required this.activityWatts,
    this.seasonBestWatts,
    this.allTimeBestWatts,
  });

  /// Gibt an, ob dieser Wert einen neuen Allzeit-Rekord darstellt.
  bool get isAllTimePR =>
      allTimeBestWatts != null && activityWatts > allTimeBestWatts! && activityWatts > 0;

  /// Gibt an, ob dieser Wert einen neuen Saison-Rekord darstellt.
  bool get isSeasonPR =>
      !isAllTimePR && seasonBestWatts != null && activityWatts > seasonBestWatts! && activityWatts > 0;

  /// Lesbare Dauer (z. B. „5s", „1m", „5m", „20m", „1h").
  String get formattedDuration {
    if (durationSec < 60) {
      return '${durationSec}s';
    } else if (durationSec < 3600) {
      final m = durationSec ~/ 60;
      final s = durationSec % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    } else {
      final h = durationSec ~/ 3600;
      final m = (durationSec % 3600) ~/ 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
  }
}

/// Vollständige Power-Duration-Kurve einer Aktivität im Vergleich zu Referenzwerten.
class PowerDurationCurve {
  final List<PowerDurationPoint> points;

  const PowerDurationCurve({required this.points});

  /// Gibt an, ob in dieser Einheit mindestens ein neuer persönlicher Rekord aufgestellt wurde.
  bool get hasPR => points.any((p) => p.isAllTimePR || p.isSeasonPR);

  /// Anzahl neuer Allzeit-Bestwerte.
  int get prCount => points.where((p) => p.isAllTimePR).length;
}
