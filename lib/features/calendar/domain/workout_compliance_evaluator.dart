import 'dart:ui';
import 'package:flutter/material.dart';

/// Status der Soll-/Ist-Erfüllung eines geplanten Workouts.
enum ComplianceStatus {
  /// Abweichung <= 15 % (Perfekt getroffen).
  green,

  /// Abweichung 15–35 % (Akzeptabel / Belastung angepasst).
  yellow,

  /// Abweichung > 35 % oder Einheit nach Mitternacht nicht absolviert (Ausgefallen / Überzogen).
  red,
}

/// Ergebnis der Soll-/Ist-Evaluierung eines Workouts.
class WorkoutComplianceResult {
  final double durationDeviationPct;
  final double loadDeviationPct;
  final double maxDeviationPct;
  final ComplianceStatus status;
  final String statusLabel;
  final String statusDetail;
  final Color statusColor;

  const WorkoutComplianceResult({
    required this.durationDeviationPct,
    required this.loadDeviationPct,
    required this.maxDeviationPct,
    required this.status,
    required this.statusLabel,
    required this.statusDetail,
    required this.statusColor,
  });

  bool get isGreen => status == ComplianceStatus.green;
  bool get isYellow => status == ComplianceStatus.yellow;
  bool get isRed => status == ComplianceStatus.red;
}

/// Evaluator für den wissenschaftlich-sportlichen Soll-/Ist-Abgleich von Trainingseinheiten.
class WorkoutComplianceEvaluator {
  /// Berechnet den Erfüllungsgrad zwischen Soll (geplant) und Ist (absolviert).
  ///
  /// Schwellenwerte gemäß Spezifikation:
  /// - Grün: <= 15 % Abweichung
  /// - Gelb: 15–35 % Abweichung
  /// - Rot: > 35 % Abweichung oder nach Mitternacht nicht absolviert
  static WorkoutComplianceResult evaluate({
    required int plannedDurationSec,
    required double? plannedLoad,
    required int actualDurationSec,
    required double? actualLoad,
    bool isCompleted = true,
    bool isPastMidnight = false,
  }) {
    if (!isCompleted || actualDurationSec <= 0) {
      if (isPastMidnight) {
        return const WorkoutComplianceResult(
          durationDeviationPct: 100.0,
          loadDeviationPct: 100.0,
          maxDeviationPct: 100.0,
          status: ComplianceStatus.red,
          statusLabel: 'Ausgefallen',
          statusDetail: 'Einheit wurde am geplanten Tag nicht absolviert.',
          statusColor: Color(0xFFEF4444),
        );
      }
      return const WorkoutComplianceResult(
        durationDeviationPct: 0.0,
        loadDeviationPct: 0.0,
        maxDeviationPct: 0.0,
        status: ComplianceStatus.yellow,
        statusLabel: 'Ausstehend',
        statusDetail: 'Noch nicht absolviert.',
        statusColor: Color(0xFFF59E0B),
      );
    }

    // Dauer-Abweichung in Prozent berechnen
    double durationDev = 0.0;
    if (plannedDurationSec > 0) {
      durationDev = ((actualDurationSec - plannedDurationSec).abs() /
              plannedDurationSec) *
          100.0;
    }

    // Belastungs-Abweichung (TSS) in Prozent berechnen
    double loadDev = 0.0;
    if (plannedLoad != null && plannedLoad > 0 && actualLoad != null) {
      loadDev = ((actualLoad - plannedLoad).abs() / plannedLoad) * 100.0;
    } else {
      loadDev = durationDev;
    }

    // Höchste Abweichung bestimmt die Ampelfarbe
    final maxDev = durationDev > loadDev ? durationDev : loadDev;

    ComplianceStatus status;
    String statusLabel;
    String statusDetail;
    Color statusColor;

    if (maxDev <= 15.0) {
      status = ComplianceStatus.green;
      statusLabel = 'Perfekt getroffen';
      statusDetail =
          '${maxDev.toStringAsFixed(0)} % Abweichung (Zielvorgabe exakt eingehalten)';
      statusColor = const Color(0xFF10B981);
    } else if (maxDev <= 35.0) {
      status = ComplianceStatus.yellow;
      statusLabel = 'Belastung angepasst';
      statusDetail =
          '${maxDev.toStringAsFixed(0)} % Abweichung (im akzeptablen Bereich)';
      statusColor = const Color(0xFFF59E0B);
    } else {
      status = ComplianceStatus.red;
      statusLabel = 'Stark abgewichen';
      statusDetail =
          '${maxDev.toStringAsFixed(0)} % Abweichung (> 35 % Differenz zu Plan)';
      statusColor = const Color(0xFFEF4444);
    }

    return WorkoutComplianceResult(
      durationDeviationPct: durationDev,
      loadDeviationPct: loadDev,
      maxDeviationPct: maxDev,
      status: status,
      statusLabel: statusLabel,
      statusDetail: statusDetail,
      statusColor: statusColor,
    );
  }
}
