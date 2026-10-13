import 'package:cloud_firestore/cloud_firestore.dart';

/// Wettkampfziel eines Athleten.
class RaceGoal {
  final String title;
  final String date; // Format: YYYY-MM-DD
  final String? distance; // z. B. "Olympisch", "Mitteldistanz", "Langdistanz", "Marathon"
  final String? targetTime; // z. B. "4:30:00"

  const RaceGoal({
    required this.title,
    required this.date,
    this.distance,
    this.targetTime,
  });

  factory RaceGoal.fromMap(Map<String, dynamic> map) {
    return RaceGoal(
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      distance: map['distance'] as String?,
      targetTime: map['targetTime'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      if (distance != null) 'distance': distance,
      if (targetTime != null) 'targetTime': targetTime,
    };
  }

  /// Berechnet verbleibende Tage bis zum Wettkampf.
  int get daysRemaining {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return 0;
      final target = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
