import '../../races/models/race.dart';

/// Wettkampfziel eines Athleten (A-, B- oder C-Priorität).
class RaceGoal {
  final String? id;
  final String title;
  final String date; // Format: YYYY-MM-DD
  final String?
      distance; // z. B. "Olympisch", "Mitteldistanz", "Langdistanz", "Marathon"
  final String? targetTime; // z. B. "4:30:00"
  final String priority; // 'A', 'B', 'C'
  final String sport; // 'BIKE', 'RUN', 'SWIM', 'TRIATHLON', 'OTHER'
  final int? targetPowerWatts;
  final String? notes;

  const RaceGoal({
    this.id,
    required this.title,
    required this.date,
    this.distance,
    this.targetTime,
    this.priority = 'A',
    this.sport = 'TRIATHLON',
    this.targetPowerWatts,
    this.notes,
  });

  bool get isARace => priority.toUpperCase() == 'A';
  bool get isBRace => priority.toUpperCase() == 'B';
  bool get isCRace => priority.toUpperCase() == 'C';

  String get priorityLabel {
    switch (priority.toUpperCase()) {
      case 'A':
        return 'A-Hauptwettkampf';
      case 'B':
        return 'B-Vorbereitung';
      case 'C':
        return 'C-Trainingswettkampf';
      default:
        return 'A-Hauptwettkampf';
    }
  }

  factory RaceGoal.fromMap(Map<String, dynamic> map, {String? id}) {
    return RaceGoal(
      id: id ?? map['id'] as String?,
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      distance: map['distance'] as String? ?? map['distanceLabel'] as String?,
      targetTime: map['targetTime'] as String?,
      priority: (map['priority'] as String? ?? 'A').toUpperCase(),
      sport: (map['sport'] as String? ?? 'TRIATHLON').toUpperCase(),
      targetPowerWatts: map['targetPowerWatts'] as int?,
      notes: map['notes'] as String?,
    );
  }

  factory RaceGoal.fromRace(Race race) {
    return RaceGoal(
      id: race.id,
      title: race.title,
      date: race.date,
      distance: race.distanceLabel,
      targetTime: race.formattedTargetTime,
      priority: race.priorityCode,
      sport: race.sport,
      targetPowerWatts: race.targetPowerWatts,
      notes: race.notes,
    );
  }

  Race toRace({required String userId}) {
    RacePriority prio;
    switch (priority.toUpperCase()) {
      case 'B':
        prio = RacePriority.b;
        break;
      case 'C':
        prio = RacePriority.c;
        break;
      case 'A':
      default:
        prio = RacePriority.a;
        break;
    }

    int? seconds;
    if (targetTime != null) {
      final parts = targetTime!.split(':');
      if (parts.length == 3) {
        seconds = (int.tryParse(parts[0]) ?? 0) * 3600 +
            (int.tryParse(parts[1]) ?? 0) * 60 +
            (int.tryParse(parts[2]) ?? 0);
      } else if (parts.length == 2) {
        seconds =
            (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      }
    }

    return Race(
      id: id ?? '',
      userId: userId,
      title: title,
      date: date,
      sport: sport,
      distanceLabel: distance,
      priority: prio,
      targetTimeSec: seconds,
      targetPowerWatts: targetPowerWatts,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'date': date,
      if (distance != null) 'distance': distance,
      if (distance != null) 'distanceLabel': distance,
      if (targetTime != null) 'targetTime': targetTime,
      'priority': priority.toUpperCase(),
      'sport': sport.toUpperCase(),
      if (targetPowerWatts != null) 'targetPowerWatts': targetPowerWatts,
      if (notes != null) 'notes': notes,
    };
  }

  /// Berechnet verbleibende Tage bis zum Wettkampf.
  int get daysRemaining {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return 0;
      final target = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return target.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Formatierte Anzeige von Wochen und Tagen.
  String get formattedCountdown {
    final days = daysRemaining;
    if (days < 0) return 'Wettkampf beendet';
    if (days == 0) return 'Heute ist Wettkampftag!';
    if (days == 1) return 'Morgen ist Wettkampftag!';

    final weeks = days ~/ 7;
    final remainingDays = days % 7;
    if (weeks > 0 && remainingDays > 0) {
      return 'Noch $weeks ${weeks == 1 ? "Woche" : "Wochen"} und $remainingDays ${remainingDays == 1 ? "Tag" : "Tage"}';
    } else if (weeks > 0) {
      return 'Noch $weeks ${weeks == 1 ? "Woche" : "Wochen"}';
    } else {
      return 'Noch $days Tage';
    }
  }
}
