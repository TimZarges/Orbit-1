import 'package:cloud_firestore/cloud_firestore.dart';

class ActivitySegment {
  final String sport;
  final double durationSec;
  final double distanceM;

  ActivitySegment({
    required this.sport,
    required this.durationSec,
    required this.distanceM,
  });

  factory ActivitySegment.fromMap(Map<String, dynamic> map) {
    return ActivitySegment(
      sport: map['sport'] as String? ?? 'OTHER',
      durationSec: (map['durationSec'] as num?)?.toDouble() ?? 0.0,
      distanceM: (map['distanceM'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ActivitySummary {
  final double? avgHr;
  final double? maxHr;
  final double? avgPowerW;
  final double? maxPowerW;
  final double? avgCadence;
  final double? elevationGainM;
  final double? avgPaceSecPerKm;

  ActivitySummary({
    this.avgHr,
    this.maxHr,
    this.avgPowerW,
    this.maxPowerW,
    this.avgCadence,
    this.elevationGainM,
    this.avgPaceSecPerKm,
  });

  factory ActivitySummary.fromMap(Map<String, dynamic> map) {
    return ActivitySummary(
      avgHr: (map['avgHr'] as num?)?.toDouble(),
      maxHr: (map['maxHr'] as num?)?.toDouble(),
      avgPowerW: (map['avgPowerW'] as num?)?.toDouble(),
      maxPowerW: (map['maxPowerW'] as num?)?.toDouble(),
      avgCadence: (map['avgCadence'] as num?)?.toDouble(),
      elevationGainM: (map['elevationGainM'] as num?)?.toDouble(),
      avgPaceSecPerKm: (map['avgPaceSecPerKm'] as num?)?.toDouble(),
    );
  }
}

class ActivityProcessing {
  final String state;
  final String? errorCode;

  ActivityProcessing({required this.state, this.errorCode});

  factory ActivityProcessing.fromMap(Map<String, dynamic> map) {
    return ActivityProcessing(
      state: map['state'] as String? ?? 'FAILED',
      errorCode: map['errorCode'] as String?,
    );
  }
}

class Activity {
  final String id;
  final String athleteId;
  final DateTime startTimeUtc;
  final String localDate;
  final String sport;
  final String title;
  final double durationSec;
  final double distanceM;
  final ActivitySummary? summary;
  final ActivityProcessing? processing;
  final List<ActivitySegment>? segments;

  Activity({
    required this.id,
    required this.athleteId,
    required this.startTimeUtc,
    required this.localDate,
    required this.sport,
    required this.title,
    required this.durationSec,
    required this.distanceM,
    this.summary,
    this.processing,
    this.segments,
  });

  factory Activity.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      athleteId: data['athleteId'] as String? ?? '',
      startTimeUtc:
          (data['startTimeUtc'] as Timestamp?)?.toDate() ?? DateTime.now(),
      localDate: data['localDate'] as String? ?? '',
      sport: data['sport'] as String? ?? 'OTHER',
      title: data['title'] as String? ?? 'Activity',
      durationSec: (data['durationSec'] as num?)?.toDouble() ?? 0,
      distanceM: (data['distanceM'] as num?)?.toDouble() ?? 0,
      summary: data['summary'] != null
          ? ActivitySummary.fromMap(data['summary'] as Map<String, dynamic>)
          : null,
      processing: data['processing'] != null
          ? ActivityProcessing.fromMap(
              data['processing'] as Map<String, dynamic>)
          : null,
      segments: (data['segments'] as List<dynamic>?)
          ?.map((e) => ActivitySegment.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
