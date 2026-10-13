import 'package:cloud_firestore/cloud_firestore.dart';

/// Bestwerte eines Athleten für eine Sportart (`users/{uid}/bests/{sport}`).
class ActivityBests {
  final String sport;
  final Map<int, double> allTimeMmp;
  final Map<int, double> seasonMmp;
  final Map<int, double> allTimePace;
  final Map<int, double> seasonPace;
  final DateTime? updatedAt;

  const ActivityBests({
    required this.sport,
    this.allTimeMmp = const {},
    this.seasonMmp = const {},
    this.allTimePace = const {},
    this.seasonPace = const {},
    this.updatedAt,
  });

  factory ActivityBests.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final sport = doc.id;

    final allMmp = <int, double>{};
    if (data['allTimeMmp'] is Map) {
      (data['allTimeMmp'] as Map).forEach((k, v) {
        final sec = int.tryParse(k.toString());
        if (sec != null && v is num) {
          allMmp[sec] = v.toDouble();
        }
      });
    }

    final seasMmp = <int, double>{};
    if (data['seasonMmp'] is Map) {
      (data['seasonMmp'] as Map).forEach((k, v) {
        final sec = int.tryParse(k.toString());
        if (sec != null && v is num) {
          seasMmp[sec] = v.toDouble();
        }
      });
    }

    return ActivityBests(
      sport: sport,
      allTimeMmp: allMmp,
      seasonMmp: seasMmp,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allTimeMmp': allTimeMmp.map((k, v) => MapEntry(k.toString(), v)),
      'seasonMmp': seasonMmp.map((k, v) => MapEntry(k.toString(), v)),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
