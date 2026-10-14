import '../models/threshold_proposal.dart';

/// Ergebnis einer Schwellenwert-Schätzung für Laufen (LTHR und Threshold Pace).
class RunThresholdEstimationResult {
  final bool hasLthrProposal;
  final ThresholdProposal? lthrProposal;
  final bool hasPaceProposal;
  final ThresholdProposal? paceProposal;
  final String? reasonForNoProposal;

  const RunThresholdEstimationResult({
    required this.hasLthrProposal,
    this.lthrProposal,
    required this.hasPaceProposal,
    this.paceProposal,
    this.reasonForNoProposal,
  });
}

/// Domänenlogik zur Schätzung der anaeroben Schwellenherzfrequenz (LTHR) und Schwellenpace.
///
/// Basiert auf:
/// - 30-Minuten-Feldtest (Friel-Methode):
///   - LTHR = Durchschnitts-Herzfrequenz der letzten 20 Minuten des 30-minütigen maximalen Dauerlaufs.
///   - Threshold Pace = Durchschnittliches Tempo über die 30 Minuten (in s/km).
/// - 20-Minuten-Wettkampf/Tempo-Dauerlauf (Konservative Alternative):
///   - LTHR = ca. 98–100 % der 20-Minuten-Durchschnitts-HF bei konstantem Pacing.
class LthrEstimator {
  const LthrEstimator();

  static const double minPlausibleLthr = 120.0;
  static const double maxPlausibleLthr = 215.0;
  static const double minPlausiblePaceSec = 150.0; // 2:30 min/km (Weltklasse)
  static const double maxPlausiblePaceSec = 600.0; // 10:00 min/km

  static const double minDeltaBpm = 2.0;
  static const double minDeltaPaceSec = 5.0; // 5 Sekunden pro km

  /// Schätzt LTHR und Schwellenpace aus einem 30-minütigen Testlauf.
  ///
  /// [last20MinAvgHr]: Durchschnittspuls der letzten 20 Minuten in bpm.
  /// [thirtyMinAvgPaceSec]: Durchschnittstempo über die vollen 30 Minuten in Sekunden/km.
  /// [hrStdDev]: Standardabweichung der Herzfrequenz in den letzten 20 Min (Stabilität des Plateaus).
  /// [currentLthr]: Aktuell hinterlegte Schwellen-HF.
  /// [currentPaceSec]: Aktuell hinterlegte Schwellenpace in s/km.
  RunThresholdEstimationResult estimateFrom30MinRun({
    required double last20MinAvgHr,
    required double thirtyMinAvgPaceSec,
    double hrStdDev = 3.0,
    double? currentLthr,
    double? currentPaceSec,
    required String athleteId,
    required DateTime activityDate,
  }) {
    // Plausibilitätsprüfungen
    if (last20MinAvgHr < minPlausibleLthr ||
        last20MinAvgHr > maxPlausibleLthr) {
      return const RunThresholdEstimationResult(
        hasLthrProposal: false,
        hasPaceProposal: false,
        reasonForNoProposal:
            'Herzfrequenz außerhalb des physiologisch plausiblen Bereichs (120–215 bpm).',
      );
    }

    if (thirtyMinAvgPaceSec < minPlausiblePaceSec ||
        thirtyMinAvgPaceSec > maxPlausiblePaceSec) {
      return const RunThresholdEstimationResult(
        hasLthrProposal: false,
        hasPaceProposal: false,
        reasonForNoProposal:
            'Lauftempo außerhalb des plausiblen Bereichs (2:30–10:00 min/km).',
      );
    }

    // Wenn der Puls extrem schwankte (> 8 bpm Standardabweichung), lag kein echtes Plateau vor
    if (hrStdDev > 8.0) {
      return const RunThresholdEstimationResult(
        hasLthrProposal: false,
        hasPaceProposal: false,
        reasonForNoProposal:
            'Herzfrequenz schwankte zu stark (kein stabiles Plateau im Schwellenbereich).',
      );
    }

    final dateStr =
        '${activityDate.day.toString().padLeft(2, '0')}.${activityDate.month.toString().padLeft(2, '0')}.${activityDate.year}';
    final calculatedLthr = last20MinAvgHr.roundToDouble();

    // LTHR Proposal
    ThresholdProposal? lthrProp;
    bool hasLthrProp = false;

    double lthrDelta = 0.0;
    double lthrDeltaPct = 0.0;
    if (currentLthr != null && currentLthr > 0) {
      lthrDelta = calculatedLthr - currentLthr;
      lthrDeltaPct = (lthrDelta / currentLthr) * 100.0;
    }

    if (currentLthr == null || lthrDelta.abs() >= minDeltaBpm) {
      hasLthrProp = true;
      final conf =
          hrStdDev <= 4.0 ? ConfidenceLevel.high : ConfidenceLevel.medium;
      final deltaSign = lthrDelta >= 0 ? '+' : '';
      lthrProp = ThresholdProposal(
        id: 'prop_lthr_${activityDate.millisecondsSinceEpoch}',
        athleteId: athleteId,
        sport: 'RUN',
        type: ThresholdType.lthr,
        proposedValue: calculatedLthr,
        currentValue: currentLthr,
        delta: lthrDelta,
        deltaPercent: lthrDeltaPct,
        confidence: conf,
        basis: [
          '30-Minuten-Lauftest am $dateStr',
          'Durchschnittspuls letzte 20 Min: ${calculatedLthr.round()} bpm',
          'HF-Stabilität: ±${hrStdDev.toStringAsFixed(1)} bpm',
        ],
        explanationDe: currentLthr != null
            ? 'Aus deinem 30-minütigen Testlauf vom $dateStr ergibt sich eine Schwellen-HF von ${calculatedLthr.round()} bpm ($deltaSign${lthrDelta.round()} bpm).'
            : 'Aus deinem Testlauf vom $dateStr wird eine Schwellen-HF von ${calculatedLthr.round()} bpm ermittelt.',
        explanationEn: currentLthr != null
            ? 'Based on your 30-min run test on $dateStr, your estimated LTHR is ${calculatedLthr.round()} bpm ($deltaSign${lthrDelta.round()} bpm).'
            : 'Based on your run test on $dateStr, an estimated LTHR of ${calculatedLthr.round()} bpm is suggested.',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    }

    // Pace Proposal
    ThresholdProposal? paceProp;
    bool hasPaceProp = false;

    double paceDelta = 0.0;
    double paceDeltaPct = 0.0;
    if (currentPaceSec != null && currentPaceSec > 0) {
      paceDelta = thirtyMinAvgPaceSec -
          currentPaceSec; // Negativ = schneller = Verbesserung!
      paceDeltaPct = (paceDelta / currentPaceSec) * 100.0;
    }

    if (currentPaceSec == null || paceDelta.abs() >= minDeltaPaceSec) {
      hasPaceProp = true;
      final conf =
          hrStdDev <= 4.0 ? ConfidenceLevel.high : ConfidenceLevel.medium;

      final m = thirtyMinAvgPaceSec.toInt() ~/ 60;
      final s = (thirtyMinAvgPaceSec % 60).round();
      final paceStr = '$m:${s.toString().padLeft(2, '0')} min/km';

      paceProp = ThresholdProposal(
        id: 'prop_pace_${activityDate.millisecondsSinceEpoch}',
        athleteId: athleteId,
        sport: 'RUN',
        type: ThresholdType.thresholdPace,
        proposedValue: thirtyMinAvgPaceSec,
        currentValue: currentPaceSec,
        delta: paceDelta,
        deltaPercent: paceDeltaPct,
        confidence: conf,
        basis: [
          '30-Minuten-Lauftest am $dateStr',
          'Durchschnittstempo: $paceStr',
        ],
        explanationDe: currentPaceSec != null
            ? 'Aus deinem Testlauf vom $dateStr ergibt sich ein Schwellentempo von $paceStr (${paceDeltaPct >= 0 ? '+' : ''}${paceDeltaPct.toStringAsFixed(1)} %).'
            : 'Aus deinem Testlauf vom $dateStr wird ein Schwellentempo von $paceStr ermittelt.',
        explanationEn: currentPaceSec != null
            ? 'Based on your run test on $dateStr, your estimated Threshold Pace is $paceStr (${paceDeltaPct >= 0 ? '+' : ''}${paceDeltaPct.toStringAsFixed(1)} %).'
            : 'Based on your run test on $dateStr, an estimated Threshold Pace of $paceStr is suggested.',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    }

    return RunThresholdEstimationResult(
      hasLthrProposal: hasLthrProp,
      lthrProposal: lthrProp,
      hasPaceProposal: hasPaceProp,
      paceProposal: paceProp,
      reasonForNoProposal: (!hasLthrProp && !hasPaceProp)
          ? 'Änderungen von Herzfrequenz und Tempo liegen unter den Mindestdifferenzen (2 bpm bzw. 5 s/km).'
          : null,
    );
  }
}
