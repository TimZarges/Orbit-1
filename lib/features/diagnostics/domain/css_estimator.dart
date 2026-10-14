import '../models/threshold_proposal.dart';

/// Ergebnis einer CSS-Schätzung.
class CssEstimationResult {
  final bool hasProposal;
  final ThresholdProposal? proposal;
  final String? reasonForNoProposal;

  const CssEstimationResult({
    required this.hasProposal,
    this.proposal,
    this.reasonForNoProposal,
  });
}

/// Domänenlogik zur Schätzung der Critical Swim Speed (CSS).
///
/// Basiert auf:
/// - 400m / 200m Zeitschwimmen (Standard-Formel):
///   - CSS [m/s] = (400 - 200) / (T400 - T200)
///   - CSS-Pace [s / 100m] = 100 / CSS = (T400 - T200) / 2
/// - Plausibilitätsprüfungen:
///   - T400 > T200
///   - Schwimmer kann 400m nicht mit höherer Geschwindigkeit schwimmen als 200m (T400 / 400 >= T200 / 200).
///   - CSS-Pace zwischen 45 s/100m und 240 s/100m.
/// - Relevanzkriterium: Mindestdelta >= 1.0 s / 100m.
class CssEstimator {
  const CssEstimator();

  static const double minPlausibleCssPaceSec =
      45.0; // Weltklasse (0:45 min/100m)
  static const double maxPlausibleCssPaceSec =
      240.0; // Einsteiger (4:00 min/100m)
  static const double minDeltaSecPer100m = 1.0;

  /// Schätzt die CSS aus den Zeiten über 400m und 200m (jeweils in Sekunden).
  CssEstimationResult estimateFrom400mAnd200m({
    required double t400Seconds,
    required double t200Seconds,
    double? currentCssPaceSec,
    required String athleteId,
    required DateTime testDate,
  }) {
    if (t400Seconds <= 0 || t200Seconds <= 0) {
      return const CssEstimationResult(
        hasProposal: false,
        reasonForNoProposal: 'Ungültige Zeitangaben für den CSS-Test.',
      );
    }

    if (t400Seconds <= t200Seconds) {
      return const CssEstimationResult(
        hasProposal: false,
        reasonForNoProposal: '400m-Zeit muss größer sein als 200m-Zeit.',
      );
    }

    // Geschwindigkeit über 400m kann nicht höher sein als über 200m
    final pace400Per100m = t400Seconds / 4.0;
    final pace200Per100m = t200Seconds / 2.0;
    if (pace400Per100m < pace200Per100m * 0.95) {
      return const CssEstimationResult(
        hasProposal: false,
        reasonForNoProposal:
            'Unplausible Pacing-Differenz: Das 400m-Tempo war schneller als das 200m-Tempo.',
      );
    }

    // CSS-Berechnung: CSS Pace pro 100m = (T400 - T200) / 2
    final calculatedCssPaceSec = (t400Seconds - t200Seconds) / 2.0;

    if (calculatedCssPaceSec < minPlausibleCssPaceSec ||
        calculatedCssPaceSec > maxPlausibleCssPaceSec) {
      return const CssEstimationResult(
        hasProposal: false,
        reasonForNoProposal:
            'Errechnetes CSS-Tempo liegt außerhalb des physiologischen Bereichs (0:45–4:00 min/100m).',
      );
    }

    double delta = 0.0;
    double deltaPercent = 0.0;
    if (currentCssPaceSec != null && currentCssPaceSec > 0) {
      delta = calculatedCssPaceSec - currentCssPaceSec; // Negativ = schneller!
      deltaPercent = (delta / currentCssPaceSec) * 100.0;

      if (delta.abs() < minDeltaSecPer100m) {
        return const CssEstimationResult(
          hasProposal: false,
          reasonForNoProposal:
              'CSS-Änderung liegt unter der Relevanzschwelle (< 1.0 s / 100m).',
        );
      }
    }

    final dateStr =
        '${testDate.day.toString().padLeft(2, '0')}.${testDate.month.toString().padLeft(2, '0')}.${testDate.year}';
    final m = calculatedCssPaceSec.toInt() ~/ 60;
    final s = (calculatedCssPaceSec % 60).round();
    final cssPaceStr = '$m:${s.toString().padLeft(2, '0')} min/100m';

    final t400M = t400Seconds.toInt() ~/ 60;
    final t400S = (t400Seconds % 60).round();
    final t200M = t200Seconds.toInt() ~/ 60;
    final t200S = (t200Seconds % 60).round();

    final basis = [
      '400m-Zeit: $t400M:${t400S.toString().padLeft(2, '0')} min',
      '200m-Zeit: $t200M:${t200S.toString().padLeft(2, '0')} min',
      'Testdatum: $dateStr',
    ];

    final deltaText = currentCssPaceSec != null
        ? ' (${deltaPercent >= 0 ? '+' : ''}${deltaPercent.toStringAsFixed(1)} %)'
        : '';

    final explanationDe = currentCssPaceSec != null
        ? 'Aus deinem 400m/200m-Test vom $dateStr ergibt sich eine neue CSS von $cssPaceStr$deltaText.'
        : 'Aus deinem Test vom $dateStr wird eine neue Einstiegs-CSS von $cssPaceStr ermittelt.';

    final explanationEn = currentCssPaceSec != null
        ? 'Based on your 400m/200m test on $dateStr, your new CSS is $cssPaceStr$deltaText.'
        : 'Based on your test on $dateStr, an estimated CSS of $cssPaceStr is suggested.';

    final proposal = ThresholdProposal(
      id: 'prop_css_${testDate.millisecondsSinceEpoch}',
      athleteId: athleteId,
      sport: 'SWIM',
      type: ThresholdType.css,
      proposedValue: calculatedCssPaceSec,
      currentValue: currentCssPaceSec,
      delta: delta,
      deltaPercent: deltaPercent,
      confidence:
          ConfidenceLevel.high, // Direkter 400/200 Feldtest hat hohe Güte
      basis: basis,
      explanationDe: explanationDe,
      explanationEn: explanationEn,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    return CssEstimationResult(
      hasProposal: true,
      proposal: proposal,
    );
  }
}
