import 'dart:math' as math;
import '../models/daily_metrics.dart';

/// Client-seitige mathematische Score-Engine für ORBIT Health & Recovery (Phase 21).
/// Spiegelt die Backend-Algorithmen für Offline-Verfügbarkeit und Sofort-Berechnung wider.
class HealthScoreCalculator {
  const HealthScoreCalculator();

  /// Sigmoid-Transformation eines Z-Scores in eine 0–100 % Skala
  static double sigmoid(double z, [double k = 1.25]) {
    final val = 100.0 / (1.0 + math.exp(-k * z));
    return val.clamp(0.0, 100.0);
  }

  /// Berechnet rollierenden Mittelwert und Standardabweichung
  static (double mean, double std)? calculateRollingBaseline(
    List<double> values, [
    double minStd = 1.0,
  ]) {
    final valid = values.where((v) => v > 0 && !v.isNaN && v.isFinite).toList();
    if (valid.length < 3) return null;

    final mean = valid.reduce((a, b) => a + b) / valid.length;
    final sumSquaredDiffs =
        valid.fold<double>(0.0, (acc, v) => acc + math.pow(v - mean, 2));
    final rawStd = math.sqrt(sumSquaredDiffs / (valid.length - 1));
    final std = math.max(minStd, rawStd);

    return (mean, std);
  }

  /// Berechnet den Erholungs-Score (0–100 %) mit Graceful Degradation
  static RecoveryData calculateRecovery(
    DailyMetrics today, {
    HealthBaselinesData? baselines,
  }) {
    final rawWeights = <String, double>{
      'hrv': 0.45,
      'rhr': 0.25,
      'sleep': 0.20,
      'respOrBb': 0.10,
    };

    final scores = <String, double>{};
    double? zHrv;
    double? zRhr;

    // 1. HRV
    if (today.hrvMs != null && today.hrvMs! > 0) {
      final mean = baselines?.hrvMean ?? 55.0;
      final std = baselines?.hrvStd ?? 15.0;
      zHrv = (today.hrvMs! - mean) / std;
      scores['hrv'] = sigmoid(zHrv);
    }

    // 2. Ruhepuls (invertiert)
    if (today.restingHrBpm != null && today.restingHrBpm! > 0) {
      final mean = baselines?.rhrMean ?? 56.0;
      final std = baselines?.rhrStd ?? 6.0;
      zRhr = (mean - today.restingHrBpm!) / std;
      scores['rhr'] = sigmoid(zRhr);
    }

    // 3. Schlaf
    if (today.sleepScore != null && today.sleepScore! >= 0) {
      scores['sleep'] = today.sleepScore!.toDouble().clamp(0.0, 100.0);
    } else if (today.sleepSeconds != null && today.sleepSeconds! > 0) {
      scores['sleep'] =
          ((today.sleepSeconds! / 27900.0) * 100.0).clamp(0.0, 100.0);
    }

    // 4. Atemfrequenz / Body Battery
    final respOrBb = <double>[];
    if (today.bodyBattery != null && today.bodyBattery! >= 0) {
      respOrBb.add(today.bodyBattery!.toDouble().clamp(0.0, 100.0));
    }
    if (today.respirationRate != null && today.respirationRate! > 0) {
      final mean = 14.5;
      final std = 1.5;
      final zResp = (today.respirationRate! - mean) / std;
      final respScore = (100.0 - 35.0 * math.max(0.0, zResp)).clamp(0.0, 100.0);
      respOrBb.add(respScore);
    }
    if (respOrBb.isNotEmpty) {
      scores['respOrBb'] = respOrBb.reduce((a, b) => a + b) / respOrBb.length;
    }

    // Graceful Degradation
    double activeWeightSum = 0.0;
    for (final key in scores.keys) {
      activeWeightSum += rawWeights[key] ?? 0.0;
    }

    if (activeWeightSum == 0.0) {
      return const RecoveryData(
        score: 50,
        classification: 'YELLOW',
        recommendationDe:
            'Keine aktuellen Vitalwerte erfasst. Moderates Training empfohlen.',
        recommendationEn:
            'No current biometric data available. Moderate training recommended.',
      );
    }

    final normalizedWeights = <String, double>{};
    double totalScore = 0.0;

    for (final entry in scores.entries) {
      final normW = (rawWeights[entry.key] ?? 0.0) / activeWeightSum;
      normalizedWeights[entry.key] = normW;
      totalScore += normW * entry.value;
    }

    final finalScore = totalScore.round().clamp(0, 100);

    String classification;
    String recommendationDe;
    String recommendationEn;

    if (finalScore >= 67) {
      classification = 'GREEN';
      recommendationDe =
          'Exzellente Erholung. Bereit für Schwellenintervalle und intensive Einheiten.';
      recommendationEn =
          'Excellent recovery. Primed for threshold intervals and demanding sessions.';
    } else if (finalScore >= 34) {
      classification = 'YELLOW';
      recommendationDe =
          'Solide Grundverfassung. Moderates Grundlagentraining oder Erhaltungsreize ideal.';
      recommendationEn =
          'Solid baseline state. Ideal for steady endurance or maintenance workouts.';
    } else {
      classification = 'RED';
      recommendationDe =
          'Erhöhte vegetative Belastung. Fokus auf aktive Erholung, Mobility oder Ruhetag.';
      recommendationEn =
          'Elevated autonomic stress. Focus on active recovery, mobility, or rest.';
    }

    return RecoveryData(
      score: finalScore,
      classification: classification,
      recommendationDe: recommendationDe,
      recommendationEn: recommendationEn,
      zHrv: zHrv,
      zRhr: zRhr,
      weightsUsed: normalizedWeights,
    );
  }

  /// Berechnet die Tagesbelastung (0–100) & dynamischen Zielkorridor
  static StrainData calculateStrain(
    double tss, {
    int? activeCalories,
    int? avgStress,
    int? recoveryScore,
  }) {
    final validTss = math.max(0.0, tss);
    double alltagLoad = 0.0;
    if (avgStress != null && avgStress > 0) {
      alltagLoad += avgStress * 0.35;
    }
    if (activeCalories != null && activeCalories > 0) {
      alltagLoad += (activeCalories / 100.0) * 1.8;
    }

    final totalRawLoad = validTss + alltagLoad;
    int score = 0;
    if (totalRawLoad > 0) {
      score =
          math.min(100, (21.5 * math.log(1.0 + totalRawLoad / 15.0)).round());
    }

    final r = (recoveryScore ?? 50).clamp(0, 100);
    int targetMin;
    int targetMax;

    if (r >= 67) {
      targetMin = (55 + 0.25 * (r - 67)).round();
      targetMax = math.min(100, (75 + 0.35 * (r - 67)).round());
    } else if (r >= 34) {
      targetMin = (35 + 0.35 * (r - 34)).round();
      targetMax = (55 + 0.35 * (r - 34)).round();
    } else {
      targetMin = 10;
      targetMax = (25 + 0.3 * r).round();
    }

    return StrainData(
      score: score,
      trainingTss: validTss,
      alltagLoad: alltagLoad,
      totalRawLoad: totalRawLoad,
      targetMin: targetMin,
      targetMax: targetMax,
    );
  }

  /// Berechnet Schlafbedarf und akkumulierte 7-Tage-Schlafschuld
  static (double needHours, double debtHours) calculateSleepNeedAndDebt(
    List<DailyMetrics> history, {
    double baseNeedHours = 7.75,
    double yesterdayStrain = 0.0,
  }) {
    // Letzte 7 Tage
    final recent7 =
        history.length > 7 ? history.sublist(history.length - 7) : history;
    double accumulatedDebt = 0.0;

    for (final day in recent7) {
      final actualH = day.sleepHours ?? 0.0;
      final dayNeed = baseNeedHours;
      if (actualH < dayNeed) {
        accumulatedDebt += (dayNeed - actualH);
      }
    }
    accumulatedDebt = math.min(6.0, accumulatedDebt);

    final strainSurcharge = 0.012 * yesterdayStrain.clamp(0.0, 100.0);
    final need = baseNeedHours + strainSurcharge + 0.5 * accumulatedDebt;

    return (need, accumulatedDebt);
  }

  /// Berechnet den 4-Faktoren-Schlaf-Score (0–100 %)
  static SleepScoreData calculateSleepScore({
    required double durationHours,
    required double needHours,
    double? timeInBedHours,
    double? deepHours,
    double? remHours,
    double accumulatedDebtHours = 0.0,
  }) {
    final durScore =
        (durationHours / math.max(1.0, needHours) * 100.0).clamp(0.0, 100.0);

    double effScore = 90.0;
    if (timeInBedHours != null && timeInBedHours > 0) {
      effScore = (durationHours / timeInBedHours * 100.0).clamp(0.0, 100.0);
    }

    double stagesScore = 85.0;
    if (deepHours != null && remHours != null && durationHours > 0) {
      final ratio = (deepHours + remHours) / durationHours;
      stagesScore = (ratio / 0.40 * 100.0).clamp(0.0, 100.0);
    }

    const consistencyScore = 85.0;

    final total = durScore * 0.5 +
        effScore * 0.25 +
        stagesScore * 0.15 +
        consistencyScore * 0.10;

    return SleepScoreData(
      score: total.round().clamp(0, 100),
      needHours: needHours,
      actualHours: durationHours,
      accumulatedDebtHours: accumulatedDebtHours,
      durationScore: durScore.round(),
      efficiencyScore: effScore.round(),
      stagesScore: stagesScore.round(),
    );
  }

  /// Berechnet den finalen ORBIT Gesamt-Score (0–100)
  static OrbitScoreData calculateOrbitScore({
    required double consistencyRatio,
    required double tsb,
    required double recoveryAvg7d,
    required double sleepAvg7d,
    double accumulatedDebt7dHours = 0.0,
  }) {
    final consScore = (consistencyRatio.clamp(0.0, 1.0) * 100.0).round();

    double tsbScore = 100.0;
    if (tsb < -10.0) {
      tsbScore = math.max(0.0, 100.0 - (tsb - -10.0).abs() * 2.5);
    } else if (tsb > 10.0) {
      tsbScore = math.max(0.0, 100.0 - (tsb - 10.0) * 3.0);
    }

    double effSleep = sleepAvg7d.clamp(0.0, 100.0);
    if (accumulatedDebt7dHours > 2.0) {
      effSleep = math.max(0.0, effSleep - (accumulatedDebt7dHours - 2.0) * 5.0);
    }

    final total = consScore * 0.30 +
        tsbScore * 0.25 +
        recoveryAvg7d.clamp(0.0, 100.0) * 0.25 +
        effSleep * 0.20;

    return OrbitScoreData(
      score: total.round().clamp(0, 100),
      consistencyScore: consScore,
      tsbScore: tsbScore.round(),
      recoveryAvg7d: recoveryAvg7d.round(),
      sleepAvg7d: effSleep.round(),
    );
  }

  /// Analysiert Journal-Korrelationen ab N >= 14 Tagen
  static List<Map<String, dynamic>> analyzeCorrelations(
    List<DailyMetrics> history,
  ) {
    if (history.length < 14) return [];

    final tags = [
      ('lateCaffeine', 'spätem Koffein', 'late caffeine'),
      ('alcohol', 'Alkohol', 'alcohol'),
      ('muscleSoreness', 'Muskelkater', 'muscle soreness'),
      ('highStress', 'hohem Alltagsstress', 'high daily stress'),
      ('poorFeeling', 'schlechtem Wohlbefinden', 'poor feeling'),
      ('goodHydration', 'guter Hydration', 'good hydration'),
      ('lateMeal', 'später Mahlzeit', 'late meal'),
      ('travelAltitude', 'Reise / Höhe', 'travel / altitude'),
    ];

    final insights = <Map<String, dynamic>>[];

    for (final tagInfo in tags) {
      final tagKey = tagInfo.$1;
      final labelDe = tagInfo.$2;
      final labelEn = tagInfo.$3;

      bool hasTag(DailyMetrics d) {
        final j = d.journal;
        if (j == null) return false;
        switch (tagKey) {
          case 'lateCaffeine':
            return j.lateCaffeine == true;
          case 'alcohol':
            return j.alcohol == true;
          case 'soreness':
            return j.soreness == true;
          case 'highStress':
            return j.highStress == true;
          case 'goodHydration':
            return j.goodHydration == true;
          case 'lateMeal':
            return j.lateMeal == true;
          case 'travelAltitude':
            return j.travelAltitude == true;
          default:
            return j.tags?.contains(tagKey) == true;
        }
      }

      final withTag = history.where(hasTag).toList();
      final withoutTag = history.where((d) => !hasTag(d)).toList();

      if (withTag.length < 3 || withoutTag.length < 3) continue;

      // HRV
      final hrvWith = withTag.map((d) => d.hrvMs).whereType<int>().toList();
      final hrvWithout =
          withoutTag.map((d) => d.hrvMs).whereType<int>().toList();
      if (hrvWith.length >= 3 && hrvWithout.length >= 3) {
        final avgWith = hrvWith.reduce((a, b) => a + b) / hrvWith.length;
        final avgWithout =
            hrvWithout.reduce((a, b) => a + b) / hrvWithout.length;
        final delta = avgWith - avgWithout;
        if (delta.abs() >= 3.0) {
          final verbDe = delta > 0 ? 'stieg' : 'sank';
          final verbEn = delta > 0 ? 'increased' : 'dropped';
          insights.add({
            'tag': tagKey,
            'metric': 'hrv',
            'delta': delta.round(),
            'insightDe':
                'An Tagen mit $labelDe $verbDe deine HRV im Schnitt um ${delta.abs().round()} ms.',
            'insightEn':
                'On days with $labelEn, your HRV $verbEn by ${delta.abs().round()} ms on average.',
          });
        }
      }

      // Tiefschlaf
      final deepWith =
          withTag.map((d) => d.deepSleepMinutes).whereType<int>().toList();
      final deepWithout =
          withoutTag.map((d) => d.deepSleepMinutes).whereType<int>().toList();
      if (deepWith.length >= 3 && deepWithout.length >= 3) {
        final avgWith = deepWith.reduce((a, b) => a + b) / deepWith.length;
        final avgWithout =
            deepWithout.reduce((a, b) => a + b) / deepWithout.length;
        final delta = avgWith - avgWithout;
        if (delta.abs() >= 10.0) {
          final advDe = delta > 0 ? 'länger' : 'kürzer';
          final advEn = delta > 0 ? 'longer' : 'shorter';
          insights.add({
            'tag': tagKey,
            'metric': 'deepSleep',
            'delta': delta.round(),
            'insightDe':
                'An Tagen mit $labelDe war dein Tiefschlaf im Schnitt ${delta.abs().round()} Min. $advDe.',
            'insightEn':
                'On days with $labelEn, your deep sleep was ${delta.abs().round()} min $advEn on average.',
          });
        }
      }
    }

    return insights;
  }
}
