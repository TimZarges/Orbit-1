import '../models/form_traffic_light.dart';

/// Konfiguration für die Schwellenwerte der Form-Ampel.
class FormThresholdConfig {
  /// Mindestanzahl an Trainingstagen für eine valide Ampelbewertung (Standard: 21).
  final int minDaysRequired;

  /// Mindest-CTL für eine aussagekräftige Basis (Standard: 10.0).
  final double minCtlBaseline;

  /// Schwellenwert für sehr hohe Ermüdung (Standard: -0.30).
  final double tiredRatioThreshold;

  /// Schwellenwert für optimale Belastung / Aufbau (Standard: -0.10).
  final double productiveRatioThreshold;

  /// Schwellenwert für Frische / Tapering (Standard: 0.15).
  final double freshRatioThreshold;

  const FormThresholdConfig({
    this.minDaysRequired = 21,
    this.minCtlBaseline = 10.0,
    this.tiredRatioThreshold = -0.30,
    this.productiveRatioThreshold = -0.10,
    this.freshRatioThreshold = 0.15,
  });
}

/// Reine Berechnungs-Engine für die Form-Ampel.
///
/// Implementiert die Vorgaben aus `docs/specs/METRICS.md` Ergänzung A:
/// - Relative Auswertung TSB / CTL (individuell statt starrer Absolutwerte)
/// - Mindestdatenlage (>= 21 Tage)
/// - Mindest-CTL (>= 10.0)
/// - Vier Hauptzustände: Sehr müde, Gut belastet, Ausgeglichen, Frisch
class FormCalculator {
  final FormThresholdConfig config;

  const FormCalculator({
    this.config = const FormThresholdConfig(),
  });

  /// Berechnet den Zustand der Form-Ampel.
  ///
  /// [ctl] Chronic Training Load (Fitness)
  /// [atl] Acute Training Load (Ermüdung)
  /// [daysOfHistory] Anzahl Tage, für die Aktivitäts- oder Aggregat-Daten vorliegen
  /// [firstRecordedDate] Datum der frühesten erfassten Aktivität
  /// [orbitScore] Optionaler experimenteller Belastungsindex (0–100)
  FormTrafficLight calculate({
    required double ctl,
    required double atl,
    required int daysOfHistory,
    DateTime? firstRecordedDate,
    double? orbitScore,
  }) {
    // 1. Datenbasis prüfen
    if (daysOfHistory < config.minDaysRequired) {
      final tsb = ctl - atl;
      final ratio = ctl > 0 ? tsb / ctl : 0.0;
      return FormTrafficLight(
        status: FormStatus.insufficientData,
        ctl: ctl,
        atl: atl,
        tsb: tsb,
        ratio: ratio,
        daysOfHistory: daysOfHistory,
        firstRecordedDate: firstRecordedDate,
        orbitScore: orbitScore,
      );
    }

    // 2. Mindest-CTL prüfen
    if (ctl < config.minCtlBaseline) {
      final tsb = ctl - atl;
      final ratio = ctl > 0 ? tsb / ctl : 0.0;
      return FormTrafficLight(
        status: FormStatus.lowBaseline,
        ctl: ctl,
        atl: atl,
        tsb: tsb,
        ratio: ratio,
        daysOfHistory: daysOfHistory,
        firstRecordedDate: firstRecordedDate,
        orbitScore: orbitScore,
      );
    }

    // 3. TSB und relatives Verhältnis berechnen
    // TSB = CTL - ATL
    final tsb = ctl - atl;
    final ratio = tsb / ctl;

    final FormStatus status;
    if (ratio < config.tiredRatioThreshold) {
      status = FormStatus.veryTired;
    } else if (ratio < config.productiveRatioThreshold) {
      status = FormStatus.wellLoaded;
    } else if (ratio <= config.freshRatioThreshold) {
      status = FormStatus.balanced;
    } else {
      status = FormStatus.fresh;
    }

    return FormTrafficLight(
      status: status,
      ctl: ctl,
      atl: atl,
      tsb: tsb,
      ratio: ratio,
      daysOfHistory: daysOfHistory,
      firstRecordedDate: firstRecordedDate,
      orbitScore: orbitScore,
    );
  }
}
