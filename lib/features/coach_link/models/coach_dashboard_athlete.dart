import 'package:cloud_firestore/cloud_firestore.dart';

/// Status der physiologischen Form im Dashboard
enum CoachAthleteFormStatus {
  optimal,
  wellLoaded,
  caution,
  fresh,
  building,
}

/// Aggregiertes Athleten-Dokument für das Trainer-Dashboard (`coachDashboard/{coachId}/athletes/{athleteId}`).
class CoachDashboardAthlete {
  final String athleteId;
  final String coachId;
  final String name;
  final String? avatarUrl;
  final String sport;
  final CoachAthleteFormStatus formStatus;
  final int ctl;
  final int atl;
  final int tsb;
  final int compliance7d;
  final int actualLoad7d;
  final int plannedLoad7d;
  final int unreadMessagesCount;
  final int pendingProposalsCount;
  final Map<String, dynamic>? latestActivity;
  final Map<String, dynamic>? raceGoal;
  final String? alert; // z.B. 'NO_ACTIVITY_7D' oder 'LOAD_SPIKE'
  final DateTime? updatedAt;

  const CoachDashboardAthlete({
    required this.athleteId,
    required this.coachId,
    required this.name,
    this.avatarUrl,
    required this.sport,
    required this.formStatus,
    required this.ctl,
    required this.atl,
    required this.tsb,
    required this.compliance7d,
    required this.actualLoad7d,
    required this.plannedLoad7d,
    this.unreadMessagesCount = 0,
    this.pendingProposalsCount = 0,
    this.latestActivity,
    this.raceGoal,
    this.alert,
    this.updatedAt,
  });

  factory CoachDashboardAthlete.fromMap(String id, Map<String, dynamic> map) {
    CoachAthleteFormStatus parseForm(String? status) {
      switch (status) {
        case 'wellLoaded':
          return CoachAthleteFormStatus.wellLoaded;
        case 'caution':
          return CoachAthleteFormStatus.caution;
        case 'fresh':
          return CoachAthleteFormStatus.fresh;
        case 'building':
          return CoachAthleteFormStatus.building;
        case 'optimal':
        default:
          return CoachAthleteFormStatus.optimal;
      }
    }

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return CoachDashboardAthlete(
      athleteId: map['athleteId'] as String? ?? id,
      coachId: map['coachId'] as String? ?? '',
      name: map['name'] as String? ?? 'Athlet',
      avatarUrl: map['avatarUrl'] as String?,
      sport: map['sport'] as String? ?? 'TRIATHLON',
      formStatus: parseForm(map['formStatus'] as String?),
      ctl: (map['ctl'] as num?)?.toInt() ?? 0,
      atl: (map['atl'] as num?)?.toInt() ?? 0,
      tsb: (map['tsb'] as num?)?.toInt() ?? 0,
      compliance7d: (map['compliance7d'] as num?)?.toInt() ?? 100,
      actualLoad7d: (map['actualLoad7d'] as num?)?.toInt() ?? 0,
      plannedLoad7d: (map['plannedLoad7d'] as num?)?.toInt() ?? 0,
      unreadMessagesCount: (map['unreadMessagesCount'] as num?)?.toInt() ?? 0,
      pendingProposalsCount:
          (map['pendingProposalsCount'] as num?)?.toInt() ?? 0,
      latestActivity: map['latestActivity'] != null
          ? Map<String, dynamic>.from(map['latestActivity'] as Map)
          : null,
      raceGoal: map['raceGoal'] != null
          ? Map<String, dynamic>.from(map['raceGoal'] as Map)
          : null,
      alert: map['alert'] as String?,
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory CoachDashboardAthlete.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CoachDashboardAthlete.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'athleteId': athleteId,
      'coachId': coachId,
      'name': name,
      'avatarUrl': avatarUrl,
      'sport': sport,
      'formStatus': formStatus.name,
      'ctl': ctl,
      'atl': atl,
      'tsb': tsb,
      'compliance7d': compliance7d,
      'actualLoad7d': actualLoad7d,
      'plannedLoad7d': plannedLoad7d,
      'unreadMessagesCount': unreadMessagesCount,
      'pendingProposalsCount': pendingProposalsCount,
      if (latestActivity != null) 'latestActivity': latestActivity,
      if (raceGoal != null) 'raceGoal': raceGoal,
      if (alert != null) 'alert': alert,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get formStatusLabelDe {
    switch (formStatus) {
      case CoachAthleteFormStatus.optimal:
        return 'Optimal';
      case CoachAthleteFormStatus.wellLoaded:
        return 'Gut belastet';
      case CoachAthleteFormStatus.caution:
        return 'Überlastungswarnung';
      case CoachAthleteFormStatus.fresh:
        return 'Sehr frisch';
      case CoachAthleteFormStatus.building:
        return 'Aufbau';
    }
  }

  String? get alertLabelDe {
    switch (alert) {
      case 'NO_ACTIVITY_7D':
        return '7 Tage inaktiv';
      case 'LOAD_SPIKE':
        return 'Starker Belastungssprung';
      default:
        return null;
    }
  }
}
