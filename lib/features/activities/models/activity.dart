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

class ActivityMetrics {
  final double? tss;
  final double? np;
  final double? iff;
  final double? vi;
  final double? ef;
  final double? aerobicDecouplingPercent;
  final String? decouplingClassification;
  final double? brickPaceDropSecPerKm;
  final double? cpWatts;
  final double? wPrimeKj;
  final String? quality;

  ActivityMetrics({
    this.tss,
    this.np,
    this.iff,
    this.vi,
    this.ef,
    this.aerobicDecouplingPercent,
    this.decouplingClassification,
    this.brickPaceDropSecPerKm,
    this.cpWatts,
    this.wPrimeKj,
    this.quality,
  });

  factory ActivityMetrics.fromMap(Map<String, dynamic> map) {
    return ActivityMetrics(
      tss: (map['tss'] as num?)?.toDouble(),
      np: (map['np'] as num?)?.toDouble() ??
          (map['normalizedPowerW'] as num?)?.toDouble(),
      iff: (map['intensityFactor'] as num?)?.toDouble() ??
          (map['if'] as num?)?.toDouble(),
      vi: (map['vi'] as num?)?.toDouble() ??
          (map['variabilityIndex'] as num?)?.toDouble(),
      ef: (map['ef'] as num?)?.toDouble() ??
          (map['efficiencyFactor'] as num?)?.toDouble(),
      aerobicDecouplingPercent:
          (map['aerobicDecouplingPercent'] as num?)?.toDouble(),
      decouplingClassification: map['decouplingClassification'] as String?,
      brickPaceDropSecPerKm: (map['brickPaceDropSecPerKm'] as num?)?.toDouble(),
      cpWatts: (map['cpWatts'] as num?)?.toDouble(),
      wPrimeKj: (map['wPrimeKj'] as num?)?.toDouble(),
      quality: map['quality'] as String?,
    );
  }
}

class ActivityLapData {
  final int lapIndex;
  final int startSec;
  final int durationSec;
  final double distanceM;
  final double? avgWatts;
  final double? npWatts;
  final double? avgHr;
  final double? avgCadence;
  final double? avgSpeedMps;
  final double? avgPaceSecPerKm;
  final double? efficiencyFactor;
  final bool isAutoInterval;

  ActivityLapData({
    required this.lapIndex,
    this.startSec = 0,
    required this.durationSec,
    this.distanceM = 0.0,
    this.avgWatts,
    this.npWatts,
    this.avgHr,
    this.avgCadence,
    this.avgSpeedMps,
    this.avgPaceSecPerKm,
    this.efficiencyFactor,
    this.isAutoInterval = false,
  });

  factory ActivityLapData.fromMap(Map<String, dynamic> map,
      {int index = 1, bool isAuto = false}) {
    final dur = (map['durationSec'] as num?)?.toInt() ?? 0;
    final dist = (map['distanceM'] as num?)?.toDouble() ?? 0.0;
    final w = (map['avgWatts'] as num?)?.toDouble() ??
        (map['avgPowerW'] as num?)?.toDouble() ??
        (map['avgValue'] as num?)?.toDouble();
    final np = (map['npWatts'] as num?)?.toDouble() ??
        (map['normalizedPowerW'] as num?)?.toDouble() ??
        (map['npValue'] as num?)?.toDouble();
    final hr = (map['avgHr'] as num?)?.toDouble() ??
        (map['avgHeartRate'] as num?)?.toDouble();
    final cad = (map['avgCadence'] as num?)?.toDouble();
    final spd = (map['avgSpeedMps'] as num?)?.toDouble();
    final pace = (map['avgPaceSecPerKm'] as num?)?.toDouble() ??
        (spd != null && spd > 0 ? 1000.0 / spd : null);
    final ef = (map['efficiencyFactor'] as num?)?.toDouble() ??
        (w != null && hr != null && hr > 0 ? w / hr : null);

    return ActivityLapData(
      lapIndex: (map['lapIndex'] as num?)?.toInt() ??
          (map['index'] as num?)?.toInt() ??
          index,
      startSec: (map['startSec'] as num?)?.toInt() ?? 0,
      durationSec: dur,
      distanceM: dist,
      avgWatts: w,
      npWatts: np,
      avgHr: hr,
      avgCadence: cad,
      avgSpeedMps: spd,
      avgPaceSecPerKm: pace,
      efficiencyFactor: ef,
      isAutoInterval: isAuto || (map['isAutoInterval'] as bool? ?? false),
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

/// Repräsentiert eine importierte oder aufgezeichnete Trainingseinheit.
///
/// Enthält alle Basis- und Zusammenfassungswerte, Laps/Intervalle, wissenschaftliche
/// Berechnungen (NP, IF, TSS, W'bal, Decoupling) sowie den Storage-Pfad zur archivierten
/// Originaldatei ([rawFilePath]).
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
  final ActivityMetrics? metrics;
  final List<ActivityLapData>? laps;
  final List<ActivityLapData>? autoIntervals;
  final ActivityProcessing? processing;
  final List<dynamic>? segments;
  final String? plannedWorkoutId;
  final String? matchStatus;

  /// Optionaler Cloud-Storage-Pfad zur unveränderten Originaldatei (z. B. .fit, .tcx).
  final String? rawFilePath;

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
    this.metrics,
    this.laps,
    this.autoIntervals,
    this.processing,
    this.segments,
    this.plannedWorkoutId,
    this.matchStatus,
    this.rawFilePath,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) =>
      Activity.fromDocument(doc);

  factory Activity.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    ActivityMetrics? metrics;
    if (data['metrics'] != null) {
      metrics =
          ActivityMetrics.fromMap(data['metrics'] as Map<String, dynamic>);
    }

    List<ActivityLapData>? laps;
    if (data['laps'] is List) {
      final list = data['laps'] as List<dynamic>;
      laps = list.asMap().entries.map((e) {
        return ActivityLapData.fromMap(
          e.value as Map<String, dynamic>,
          index: e.key + 1,
          isAuto: false,
        );
      }).toList();
    }

    List<ActivityLapData>? autoIntervals;
    if (data['autoIntervals'] is List) {
      final list = data['autoIntervals'] as List<dynamic>;
      autoIntervals = list.asMap().entries.map((e) {
        return ActivityLapData.fromMap(
          e.value as Map<String, dynamic>,
          index: e.key + 1,
          isAuto: true,
        );
      }).toList();
    }

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
      metrics: metrics,
      laps: laps,
      autoIntervals: autoIntervals,
      processing: data['processing'] != null
          ? ActivityProcessing.fromMap(
              data['processing'] as Map<String, dynamic>)
          : null,
      segments: (data['segments'] as List<dynamic>?)
          ?.map((e) => ActivitySegment.fromMap(e as Map<String, dynamic>))
          .toList(),
      plannedWorkoutId: data['plannedWorkoutId'] as String?,
      matchStatus: data['matchStatus'] as String?,
      rawFilePath: data['rawFilePath'] as String?,
    );
  }
}
