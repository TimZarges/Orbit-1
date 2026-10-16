import 'package:cloud_firestore/cloud_firestore.dart';

enum RacePriority {
  a, // Hauptwettkampf (Volt #CDFB17)
  b, // Vorbereitungswettkampf (Cyan #00D2FF)
  c, // Trainingswettkampf (Weiß #FFFFFF)
}

/// Repräsentiert einen geplanten Wettkampf in der Saisonplanung des Athleten.
class Race {
  final String id;
  final String userId;
  final String title;
  final String date; // YYYY-MM-DD
  final String sport; // BIKE, RUN, SWIM, TRIATHLON, OTHER
  final String? distanceLabel; // z. B. "Mitteldistanz", "Olympisch", "Marathon"
  final RacePriority priority;
  final int? targetTimeSec;
  final int? targetPowerWatts;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Race({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    this.sport = 'TRIATHLON',
    this.distanceLabel,
    this.priority = RacePriority.a,
    this.targetTimeSec,
    this.targetPowerWatts,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// String-Darstellung der Priorität ('A', 'B', 'C')
  String get priorityCode {
    switch (priority) {
      case RacePriority.a:
        return 'A';
      case RacePriority.b:
        return 'B';
      case RacePriority.c:
        return 'C';
    }
  }

  /// Menschenlesbares Label der Priorität
  String get priorityLabel {
    switch (priority) {
      case RacePriority.a:
        return 'A-Hauptwettkampf';
      case RacePriority.b:
        return 'B-Vorbereitung';
      case RacePriority.c:
        return 'C-Trainingsrennen';
    }
  }

  /// Verbleibende Tage bis zum Wettkampf.
  int get daysRemaining {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return 0;
      final target = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return target.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Formatierter Countdown für die Benutzeroberfläche.
  String get formattedCountdown {
    final days = daysRemaining;
    if (days < 0) return 'Wettkampf beendet';
    if (days == 0) return 'Heute ist Renntag!';
    if (days == 1) return 'Morgen ist Renntag!';

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

  /// Formatierte Zielzeit (z. B. "4:30:00" oder "38:45")
  String? get formattedTargetTime {
    if (targetTimeSec == null || targetTimeSec! <= 0) return null;
    final h = targetTimeSec! ~/ 3600;
    final m = (targetTimeSec! % 3600) ~/ 60;
    final s = targetTimeSec! % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      return '$m:${s.toString().padLeft(2, '0')}';
    }
  }

  factory Race.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Race.fromMap(data, id: doc.id);
  }

  factory Race.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final prioStr = (map['priority'] as String? ?? 'A').toUpperCase();
    RacePriority prio;
    if (prioStr == 'B') {
      prio = RacePriority.b;
    } else if (prioStr == 'C') {
      prio = RacePriority.c;
    } else {
      prio = RacePriority.a;
    }

    DateTime? created;
    if (map['createdAt'] is Timestamp) {
      created = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      created = DateTime.tryParse(map['createdAt']);
    }

    DateTime? updated;
    if (map['updatedAt'] is Timestamp) {
      updated = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updated = DateTime.tryParse(map['updatedAt']);
    }

    return Race(
      id: id.isNotEmpty ? id : (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      sport: (map['sport'] as String? ?? 'TRIATHLON').toUpperCase(),
      distanceLabel:
          map['distanceLabel'] as String? ?? map['distance'] as String?,
      priority: prio,
      targetTimeSec: map['targetTimeSec'] as int?,
      targetPowerWatts: map['targetPowerWatts'] as int?,
      notes: map['notes'] as String?,
      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'date': date,
      'sport': sport,
      if (distanceLabel != null) 'distanceLabel': distanceLabel,
      'priority': priorityCode,
      if (targetTimeSec != null) 'targetTimeSec': targetTimeSec,
      if (targetPowerWatts != null) 'targetPowerWatts': targetPowerWatts,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
