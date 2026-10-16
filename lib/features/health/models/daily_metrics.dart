import 'package:cloud_firestore/cloud_firestore.dart';

/// Erholungs-Daten (0–100 %) aus Phase 21.
class RecoveryData {
  final int score;
  final String classification; // 'GREEN' | 'YELLOW' | 'RED'
  final String recommendationDe;
  final String recommendationEn;
  final double? zHrv;
  final double? zRhr;
  final Map<String, double> weightsUsed;

  const RecoveryData({
    required this.score,
    required this.classification,
    required this.recommendationDe,
    required this.recommendationEn,
    this.zHrv,
    this.zRhr,
    this.weightsUsed = const {},
  });

  bool get isGracefulDegradation => (weightsUsed['hrv'] ?? 0) == 0;

  String get sensorsUsedDescription {
    if (isGracefulDegradation) {
      return 'Berechnet aus Ruhepuls & Schlaf (keine nächtliche HRV)';
    }
    return 'Vollständig (HRV, Ruhepuls, Schlaf & Vitalwerte)';
  }

  factory RecoveryData.fromMap(Map<String, dynamic> map) {
    final weightsRaw = map['weightsUsed'] as Map<String, dynamic>? ?? {};
    final weights = weightsRaw.map(
      (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0),
    );

    return RecoveryData(
      score: (map['score'] as num?)?.toInt() ?? 50,
      classification: (map['classification'] as String?) ?? 'YELLOW',
      recommendationDe: (map['recommendationDe'] as String?) ??
          'Solide Grundverfassung. Moderates Training empfohlen.',
      recommendationEn: (map['recommendationEn'] as String?) ??
          'Solid baseline state. Moderate training recommended.',
      zHrv: (map['zHrv'] as num?)?.toDouble(),
      zRhr: (map['zRhr'] as num?)?.toDouble(),
      weightsUsed: weights,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'classification': classification,
      'recommendationDe': recommendationDe,
      'recommendationEn': recommendationEn,
      'zHrv': zHrv,
      'zRhr': zRhr,
      'weightsUsed': weightsUsed,
    };
  }
}

/// Tagesbelastung (0–100) & dynamischer Zielkorridor aus Phase 21.
class StrainData {
  final int score;
  final double trainingTss;
  final double alltagLoad;
  final double totalRawLoad;
  final int targetMin;
  final int targetMax;

  const StrainData({
    required this.score,
    required this.trainingTss,
    required this.alltagLoad,
    required this.totalRawLoad,
    required this.targetMin,
    required this.targetMax,
  });

  factory StrainData.fromMap(Map<String, dynamic> map) {
    final target = map['targetRange'] as Map<String, dynamic>? ?? {};
    return StrainData(
      score: (map['score'] as num?)?.toInt() ?? 0,
      trainingTss: (map['trainingTss'] as num?)?.toDouble() ?? 0.0,
      alltagLoad: (map['alltagLoad'] as num?)?.toDouble() ?? 0.0,
      totalRawLoad: (map['totalRawLoad'] as num?)?.toDouble() ?? 0.0,
      targetMin: (target['min'] as num?)?.toInt() ?? 35,
      targetMax: (target['max'] as num?)?.toInt() ?? 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'trainingTss': trainingTss,
      'alltagLoad': alltagLoad,
      'totalRawLoad': totalRawLoad,
      'targetRange': {
        'min': targetMin,
        'max': targetMax,
      },
    };
  }
}

/// Differenzierter Schlaf-Score & Schlafschuld aus Phase 21.
class SleepScoreData {
  final int score;
  final double needHours;
  final double actualHours;
  final double accumulatedDebtHours;
  final int durationScore;
  final int efficiencyScore;
  final int stagesScore;

  const SleepScoreData({
    required this.score,
    required this.needHours,
    required this.actualHours,
    required this.accumulatedDebtHours,
    required this.durationScore,
    required this.efficiencyScore,
    required this.stagesScore,
  });

  /// Schlafschuld in Minuten
  int get debtMinutes => (accumulatedDebtHours * 60).round();

  /// Schlafbedarf in Sekunden
  int get neededSeconds => (needHours * 3600).round();

  factory SleepScoreData.fromMap(Map<String, dynamic> map) {
    return SleepScoreData(
      score: (map['score'] as num?)?.toInt() ?? 0,
      needHours: (map['needHours'] as num?)?.toDouble() ?? 7.75,
      actualHours: (map['actualHours'] as num?)?.toDouble() ?? 0.0,
      accumulatedDebtHours:
          (map['accumulatedDebtHours'] as num?)?.toDouble() ?? 0.0,
      durationScore: (map['durationScore'] as num?)?.toInt() ?? 0,
      efficiencyScore: (map['efficiencyScore'] as num?)?.toInt() ?? 0,
      stagesScore: (map['stagesScore'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'needHours': needHours,
      'actualHours': actualHours,
      'accumulatedDebtHours': accumulatedDebtHours,
      'durationScore': durationScore,
      'efficiencyScore': efficiencyScore,
      'stagesScore': stagesScore,
    };
  }
}

/// Finaler ORBIT Gesamt-Score (0–100) aus Phase 21.
class OrbitScoreData {
  final int score;
  final int consistencyScore;
  final int tsbScore;
  final int recoveryAvg7d;
  final int sleepAvg7d;

  const OrbitScoreData({
    required this.score,
    required this.consistencyScore,
    required this.tsbScore,
    required this.recoveryAvg7d,
    required this.sleepAvg7d,
  });

  factory OrbitScoreData.fromMap(Map<String, dynamic> map) {
    return OrbitScoreData(
      score: (map['score'] as num?)?.toInt() ?? 75,
      consistencyScore: (map['consistencyScore'] as num?)?.toInt() ?? 80,
      tsbScore: (map['tsbScore'] as num?)?.toInt() ?? 80,
      recoveryAvg7d: (map['recoveryAvg7d'] as num?)?.toInt() ?? 70,
      sleepAvg7d: (map['sleepAvg7d'] as num?)?.toInt() ?? 75,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'consistencyScore': consistencyScore,
      'tsbScore': tsbScore,
      'recoveryAvg7d': recoveryAvg7d,
      'sleepAvg7d': sleepAvg7d,
    };
  }
}

/// 30-Tage-Baselines & Normbänder aus Phase 21.
class HealthBaselinesData {
  final double? hrvMean;
  final double? hrvStd;
  final double? rhrMean;
  final double? rhrStd;
  final double? sleepMeanHours;
  final double? sleepStdHours;

  const HealthBaselinesData({
    this.hrvMean,
    this.hrvStd,
    this.rhrMean,
    this.rhrStd,
    this.sleepMeanHours,
    this.sleepStdHours,
  });

  factory HealthBaselinesData.fromMap(Map<String, dynamic> map) {
    return HealthBaselinesData(
      hrvMean: (map['hrvMean'] as num?)?.toDouble(),
      hrvStd: (map['hrvStd'] as num?)?.toDouble(),
      rhrMean: (map['rhrMean'] as num?)?.toDouble(),
      rhrStd: (map['rhrStd'] as num?)?.toDouble(),
      sleepMeanHours: (map['sleepMeanHours'] as num?)?.toDouble(),
      sleepStdHours: (map['sleepStdHours'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hrvMean': hrvMean,
      'hrvStd': hrvStd,
      'rhrMean': rhrMean,
      'rhrStd': rhrStd,
      'sleepMeanHours': sleepMeanHours,
      'sleepStdHours': sleepStdHours,
    };
  }
}

/// 15-Sekunden-Morgen-Journal Daten aus Phase 21.
class JournalData {
  final List<String>? tags;
  final String? notes;
  final bool? lateCaffeine;
  final bool? alcohol;
  final bool? soreness;
  final bool? highStress;
  final bool? goodHydration;
  final bool? lateMeal;
  final bool? travelAltitude;
  final bool? meditationBreathwork;
  final DateTime? loggedAt;

  const JournalData({
    this.tags,
    this.notes,
    this.lateCaffeine,
    this.alcohol,
    this.soreness,
    this.highStress,
    this.goodHydration,
    this.lateMeal,
    this.travelAltitude,
    this.meditationBreathwork,
    this.loggedAt,
  });

  bool get hasAnyTag =>
      (lateCaffeine == true) ||
      (alcohol == true) ||
      (soreness == true) ||
      (highStress == true) ||
      (goodHydration == true) ||
      (lateMeal == true) ||
      (travelAltitude == true) ||
      (meditationBreathwork == true) ||
      (tags != null && tags!.isNotEmpty);

  factory JournalData.fromMap(Map<String, dynamic> map) {
    DateTime? logged;
    final rawLogged = map['loggedAt'];
    if (rawLogged is Timestamp) {
      logged = rawLogged.toDate();
    } else if (rawLogged is String) {
      logged = DateTime.tryParse(rawLogged);
    }

    final tagsList = map['tags'] is List
        ? (map['tags'] as List).map((e) => e.toString()).toList()
        : null;

    return JournalData(
      tags: tagsList,
      notes: map['notes'] as String?,
      lateCaffeine:
          map['lateCaffeine'] as bool? ?? (tagsList?.contains('lateCaffeine')),
      alcohol: map['alcohol'] as bool? ?? (tagsList?.contains('alcohol')),
      soreness: map['soreness'] as bool? ?? (tagsList?.contains('soreness')),
      highStress:
          map['highStress'] as bool? ?? (tagsList?.contains('highStress')),
      goodHydration: map['goodHydration'] as bool? ??
          (tagsList?.contains('goodHydration')),
      lateMeal: map['lateMeal'] as bool? ?? (tagsList?.contains('lateMeal')),
      travelAltitude: map['travelAltitude'] as bool? ??
          (tagsList?.contains('travelAltitude')),
      meditationBreathwork: map['meditationBreathwork'] as bool? ??
          (tagsList?.contains('meditationBreathwork')),
      loggedAt: logged,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (tags != null) 'tags': tags,
      if (notes != null) 'notes': notes,
      if (lateCaffeine != null) 'lateCaffeine': lateCaffeine,
      if (alcohol != null) 'alcohol': alcohol,
      if (soreness != null) 'soreness': soreness,
      if (highStress != null) 'highStress': highStress,
      if (goodHydration != null) 'goodHydration': goodHydration,
      if (lateMeal != null) 'lateMeal': lateMeal,
      if (travelAltitude != null) 'travelAltitude': travelAltitude,
      if (meditationBreathwork != null)
        'meditationBreathwork': meditationBreathwork,
      if (loggedAt != null) 'loggedAt': Timestamp.fromDate(loggedAt!),
    };
  }
}

/// Repräsentiert die aggregierten Gesundheits- und Wellnessdaten eines Tages (Tageswerte).
/// Gespeichert unter `users/{uid}/dailyMetrics/{localDate}`.
class DailyMetrics {
  /// Datum im Format YYYY-MM-DD am Ort des Athleten.
  final String localDate;

  /// Netto-Schlafdauer in Sekunden.
  final int? sleepSeconds;

  /// Schlaf-Score (0 bis 100), sofern von der Uhr / Garmin bereitgestellt.
  final int? sleepScore;

  /// Nächtlicher bzw. Ruhe-Puls in Schlägen pro Minute.
  final int? restingHrBpm;

  /// Herzfrequenzvariabilität (HRV rMSSD) der letzten Nacht in Millisekunden.
  final int? hrvMs;

  /// Durchschnittliches Stress-Level des Tages (0 bis 100).
  final int? stress;

  /// Schrittanzahl des Tages.
  final int? steps;

  /// Garmin Body Battery Wert zum Tagesende / Ladezustand (0 bis 100).
  final int? bodyBattery;

  /// Nächtliche Atemfrequenz (Atemzüge pro Minute).
  final double? respirationRate;

  /// Tiefschlafdauer in Sekunden.
  final int? deepSleepSeconds;

  /// REM-Schlafdauer in Sekunden.
  final int? remSleepSeconds;

  /// Wachphasen in Sekunden.
  final int? awakeSleepSeconds;

  /// Gesamte Zeit im Bett in Sekunden.
  final int? timeInBedSeconds;

  /// Aktive Kalorien des Tages.
  final int? activeCalories;

  /// Trainings-TSS aller Einheiten des Tages.
  final double? activitiesTss;

  /// Phase 21 Berechnete Scores
  final RecoveryData? recovery;
  final StrainData? strain;
  final SleepScoreData? sleep;
  final OrbitScoreData? orbitScore;
  final HealthBaselinesData? baselines;

  /// 15-Sekunden-Morgen-Journal
  final JournalData? journal;

  /// Quelle der Daten, z. B. 'GARMIN' oder 'DEMO'.
  final String source;

  /// Letzter Aktualisierungszeitpunkt.
  final DateTime? updatedAt;

  const DailyMetrics({
    required this.localDate,
    this.sleepSeconds,
    this.sleepScore,
    this.restingHrBpm,
    this.hrvMs,
    this.stress,
    this.steps,
    this.bodyBattery,
    this.respirationRate,
    this.deepSleepSeconds,
    this.remSleepSeconds,
    this.awakeSleepSeconds,
    this.timeInBedSeconds,
    this.activeCalories,
    this.activitiesTss,
    RecoveryData? recovery,
    RecoveryData? recoveryData,
    StrainData? strain,
    StrainData? strainData,
    SleepScoreData? sleep,
    SleepScoreData? sleepScoreData,
    OrbitScoreData? orbitScore,
    OrbitScoreData? orbitScoreData,
    this.baselines,
    this.journal,
    this.source = 'GARMIN',
    this.updatedAt,
  })  : recovery = recovery ?? recoveryData,
        strain = strain ?? strainData,
        sleep = sleep ?? sleepScoreData,
        orbitScore = orbitScore ?? orbitScoreData;

  /// Schlafdauer in Stunden als Dezimalwert.
  double? get sleepHours =>
      sleepSeconds != null ? sleepSeconds! / 3600.0 : null;

  /// Tiefschlaf in Minuten.
  int? get deepSleepMinutes =>
      deepSleepSeconds != null ? deepSleepSeconds! ~/ 60 : null;

  /// Formatierte Schlafdauer (z. B. "7h 45m").
  String get formattedSleepDuration {
    if (sleepSeconds == null) return '--';
    final hours = sleepSeconds! ~/ 3600;
    final minutes = (sleepSeconds! % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  /// Effektiver Erholungs-Score (0–100 %)
  int get effectiveRecoveryScore => recovery?.score ?? 50;

  /// Erholungs-Ampel ('GREEN' | 'YELLOW' | 'RED')
  String get recoveryTrafficLight => recovery?.classification ?? 'YELLOW';

  /// Effektive Tagesbelastung (0–100)
  int get effectiveStrainScore => strain?.score ?? 0;

  /// Belastungs-Zielkorridor
  int get strainTargetMin => strain?.targetMin ?? 35;
  int get strainTargetMax => strain?.targetMax ?? 60;

  /// Effektiver Schlaf-Score (0–100 %)
  int get effectiveSleepScore => sleep?.score ?? sleepScore ?? 75;

  /// Effektiver ORBIT Gesamt-Score (0–100)
  int get effectiveOrbitScore => orbitScore?.score ?? 75;

  /// Zeigt an, ob Graceful Degradation aktiv ist (z. B. keine HRV vorhanden)
  bool get hasGracefulDegradation => recovery?.isGracefulDegradation ?? false;

  /// Tages-Empfehlung
  String get recoveryRecommendation =>
      recovery?.recommendationDe ??
      'Solide Grundverfassung. Moderates Training empfohlen.';

  /// Aliase & Convenience Getter
  RecoveryData? get recoveryData => recovery;
  StrainData? get strainData => strain;
  SleepScoreData? get sleepScoreData => sleep;
  OrbitScoreData? get orbitScoreData => orbitScore;
  int? get effectiveSleepSeconds => sleepSeconds;
  double? get respirationRateBreathsPerMin => respirationRate;

  /// Erstellt ein [DailyMetrics]-Objekt aus einem Firestore-Dokument.
  factory DailyMetrics.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DailyMetrics.fromMap(doc.id, data);
  }

  /// Erstellt ein [DailyMetrics]-Objekt aus einer Map mit gegebener [dateId].
  factory DailyMetrics.fromMap(String dateId, Map<String, dynamic> map) {
    DateTime? updated;
    final rawUpdated = map['updatedAt'];
    if (rawUpdated is Timestamp) {
      updated = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      updated = DateTime.tryParse(rawUpdated);
    }

    JournalData? journalData;
    if (map['journal'] is Map) {
      journalData =
          JournalData.fromMap(Map<String, dynamic>.from(map['journal'] as Map));
    }

    return DailyMetrics(
      localDate: dateId,
      sleepSeconds: (map['sleepSeconds'] as num?)?.toInt(),
      sleepScore: (map['sleepScore'] as num?)?.toInt(),
      restingHrBpm: (map['restingHrBpm'] as num?)?.toInt(),
      hrvMs: (map['hrvMs'] as num?)?.toInt(),
      stress: (map['stress'] as num?)?.toInt(),
      steps: (map['steps'] as num?)?.toInt(),
      bodyBattery: (map['bodyBattery'] as num?)?.toInt(),
      respirationRate: (map['respirationRate'] as num?)?.toDouble(),
      deepSleepSeconds: (map['deepSleepSeconds'] as num?)?.toInt(),
      remSleepSeconds: (map['remSleepSeconds'] as num?)?.toInt(),
      awakeSleepSeconds: (map['awakeSleepSeconds'] as num?)?.toInt(),
      timeInBedSeconds: (map['timeInBedSeconds'] as num?)?.toInt(),
      activeCalories: (map['activeCalories'] as num?)?.toInt(),
      activitiesTss: (map['activitiesTss'] as num?)?.toDouble(),
      recovery: map['recovery'] != null
          ? RecoveryData.fromMap(map['recovery'] as Map<String, dynamic>)
          : null,
      strain: map['strain'] != null
          ? StrainData.fromMap(map['strain'] as Map<String, dynamic>)
          : null,
      sleep: map['sleep'] != null
          ? SleepScoreData.fromMap(map['sleep'] as Map<String, dynamic>)
          : null,
      orbitScore: map['orbitScore'] != null
          ? OrbitScoreData.fromMap(map['orbitScore'] as Map<String, dynamic>)
          : null,
      baselines: map['baselines'] != null
          ? HealthBaselinesData.fromMap(
              map['baselines'] as Map<String, dynamic>,
            )
          : null,
      journal: journalData,
      source: (map['source'] as String?) ?? 'GARMIN',
      updatedAt: updated,
    );
  }

  /// Konvertiert das Objekt in eine speicherbare Map für Firestore.
  Map<String, dynamic> toMap() {
    return {
      'sleepSeconds': sleepSeconds,
      'sleepScore': sleepScore,
      'restingHrBpm': restingHrBpm,
      'hrvMs': hrvMs,
      'stress': stress,
      'steps': steps,
      'bodyBattery': bodyBattery,
      'respirationRate': respirationRate,
      'deepSleepSeconds': deepSleepSeconds,
      'remSleepSeconds': remSleepSeconds,
      'awakeSleepSeconds': awakeSleepSeconds,
      'timeInBedSeconds': timeInBedSeconds,
      'activeCalories': activeCalories,
      'activitiesTss': activitiesTss,
      if (recovery != null) 'recovery': recovery!.toMap(),
      if (strain != null) 'strain': strain!.toMap(),
      if (sleep != null) 'sleep': sleep!.toMap(),
      if (orbitScore != null) 'orbitScore': orbitScore!.toMap(),
      if (baselines != null) 'baselines': baselines!.toMap(),
      if (journal != null) 'journal': journal!.toMap(),
      'source': source,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
