import '../models/threshold_proposal.dart';

/// Ergebnis einer Schwellenwert-Schätzung für Rad-FTP.
class FtpEstimationResult {
  final bool hasProposal;
  final ThresholdProposal? proposal;
  final String? reasonForNoProposal;

  const FtpEstimationResult({
    required this.hasProposal,
    this.proposal,
    this.reasonForNoProposal,
  });
}

/// Domänenlogik zur Schätzung der funktionellen Schwellenleistung (FTP) beim Radfahren.
///
/// Basiert auf:
/// - 20-Minuten Mean Maximal Power (MMP): FTP = 20m MMP * 0.95
/// - Variability Index (VI = NP / Avg Power) zur Konfidenzbestimmung:
///   - VI <= 1.05: HIGH (sehr gleichmäßige Pacing-Qualität)
///   - 1.05 < VI <= 1.12: MEDIUM (leichte Pacing-Schwankungen)
///   - VI > 1.12: LOW oder kein Vorschlag (Intervall-/Kriteriumsfahrt, ungeeignet für 20m-FTP-Formel)
/// - Relevanzkriterium: Mindestdelta >= 3 Watt ODER >= 1.5 % zum aktuellen FTP-Wert.
class FtpEstimator {
  const FtpEstimator();

  /// Mindest-Leistungsschwelle in Watt für ein plausibles Ergebnis.
  static const double minPlausibleFtp = 50.0;
  static const double maxPlausibleFtp = 600.0;

  /// Mindestdifferenz für einen Vorschlag.
  static const double minDeltaWatt = 3.0;
  static const double minDeltaPercent = 1.5;

  /// Schätzt den FTP aus einer 20-minütigen maximalen Belastung.
  ///
  /// [twentyMinMmp]: Durchschnittsleistung über 20 Minuten in Watt.
  /// [normalizedPower]: Normalized Power über denselben 20-Minuten-Abschnitt in Watt.
  /// [currentFtp]: Bisheriger hinterlegter FTP in Watt (optional).
  /// [athleteId]: ID des Athleten.
  /// [activityDate]: Datum der Aktivität.
  /// [isIndoor]: Kennzeichnung, ob auf der Rolle gefahren wurde.
  FtpEstimationResult estimateFrom20MinMmp({
    required double twentyMinMmp,
    required double normalizedPower,
    double? currentFtp,
    required String athleteId,
    required DateTime activityDate,
    bool isIndoor = false,
  }) {
    // Plausibilitätsprüfungen
    if (twentyMinMmp < minPlausibleFtp || twentyMinMmp > maxPlausibleFtp) {
      return const FtpEstimationResult(
        hasProposal: false,
        reasonForNoProposal: '20-Minuten-Leistung außerhalb des physiologisch plausiblen Bereichs (50–600 W).',
      );
    }

    // Variabilitätsindex über den 20-Minuten-Block berechnen
    final vi = normalizedPower > 0 ? (normalizedPower / twentyMinMmp) : 1.0;

    // Wenn die Einheit extrem ungleichmäßig war (z. B. kurze harte Antritte statt Pacing),
    // ist die 95%-Formel nicht valide.
    if (vi > 1.15) {
      return const FtpEstimationResult(
        hasProposal: false,
        reasonForNoProposal: 'Pacing zu ungleichmäßig (Variabilitätsindex > 1.15). Eine 20-Minuten-FTP-Schätzung erfordert konstanten Druck auf dem Pedal.',
      );
    }

    // FTP = 95 % von 20m MMP
    final calculatedFtp = (twentyMinMmp * 0.95).roundToDouble();

    // Relevanz-Prüfung gegen aktuellen FTP
    double delta = 0.0;
    double deltaPercent = 0.0;
    if (currentFtp != null && currentFtp > 0) {
      delta = calculatedFtp - currentFtp;
      deltaPercent = (delta / currentFtp) * 100.0;

      // Wenn die Differenz kleiner als Mindestgrenze ist, kein Spam-Vorschlag
      if (delta.abs() < minDeltaWatt && deltaPercent.abs() < minDeltaPercent) {
        return FtpEstimationResult(
          hasProposal: false,
          reasonForNoProposal: 'Leistungsänderung liegt unter der Relevanzschwelle (< 3 W und < 1.5 %). Aktueller FTP bleibt stabil.',
        );
      }
    }

    // Konfidenz bestimmen
    final ConfidenceLevel confidence;
    if (vi <= 1.05) {
      confidence = ConfidenceLevel.high;
    } else if (vi <= 1.12) {
      confidence = ConfidenceLevel.medium;
    } else {
      confidence = ConfidenceLevel.low;
    }

    final dateStr = '${activityDate.day.toString().padLeft(2, '0')}.${activityDate.month.toString().padLeft(2, '0')}.${activityDate.year}';
    final basis = [
      '20-Minuten-Bestwert: ${twentyMinMmp.round()} W am $dateStr',
      'Pacing-Gleichmäßigkeit: VI = ${vi.toStringAsFixed(2)}',
      if (isIndoor) 'Aufzeichnung auf Rollentrainer (Indoor)',
    ];

    final deltaText = delta >= 0 ? '+${delta.round()} W (+${deltaPercent.toStringAsFixed(1)} %)' : '${delta.round()} W (${deltaPercent.toStringAsFixed(1)} %)';
    final explanationDe = currentFtp != null
        ? 'Basierend auf deinem 20-Minuten-Bestwert von ${twentyMinMmp.round()} W vom $dateStr ergibt sich ein neuer FTP von ${calculatedFtp.round()} W ($deltaText).'
        : 'Basierend auf deinem 20-Minuten-Bestwert von ${twentyMinMmp.round()} W vom $dateStr wird ein Einstiegs-FTP von ${calculatedFtp.round()} W empfohlen.';

    final explanationEn = currentFtp != null
        ? 'Based on your 20-min peak of ${twentyMinMmp.round()} W on $dateStr, your estimated FTP is ${calculatedFtp.round()} W ($deltaText).'
        : 'Based on your 20-min peak of ${twentyMinMmp.round()} W on $dateStr, an initial FTP of ${calculatedFtp.round()} W is suggested.';

    final proposal = ThresholdProposal(
      id: 'prop_ftp_${activityDate.millisecondsSinceEpoch}',
      athleteId: athleteId,
      sport: 'BIKE',
      type: ThresholdType.ftp,
      proposedValue: calculatedFtp,
      currentValue: currentFtp,
      delta: delta,
      deltaPercent: deltaPercent,
      confidence: confidence,
      basis: basis,
      explanationDe: explanationDe,
      explanationEn: explanationEn,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    return FtpEstimationResult(
      hasProposal: true,
      proposal: proposal,
    );
  }
}
