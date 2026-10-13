import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';

/// Die physiologischen Zustände der Form-Ampel.
///
/// Basiert auf dem Verhältnis von TSB (Training Stress Balance) zu CTL (Chronic Training Load)
/// gemäß `docs/specs/METRICS.md` Ergänzung A.
enum FormStatus {
  /// Hohe akute Ermüdung (TSB / CTL < -0.30).
  veryTired,

  /// Wirksamer Aufbau- und Trainingsreiz (-0.30 <= TSB / CTL < -0.10).
  wellLoaded,

  /// Belastung und Erholung im Gleichgewicht (-0.10 <= TSB / CTL <= +0.15).
  balanced,

  /// Hohe Frische / Tapering (TSB / CTL > +0.15).
  fresh,

  /// CTL unterhalb der Mindestschwelle (< 10).
  lowBaseline,

  /// Zu kurze Datenhistorie (< 21 Tage mit Training).
  insufficientData,
}

/// Modell für die aggregierte Form-Ampel eines Athleten.
class FormTrafficLight {
  final FormStatus status;
  final double ctl;
  final double atl;
  final double tsb;
  final double ratio;
  final int daysOfHistory;
  final DateTime? firstRecordedDate;
  final double? orbitScore;

  const FormTrafficLight({
    required this.status,
    required this.ctl,
    required this.atl,
    required this.tsb,
    required this.ratio,
    required this.daysOfHistory,
    this.firstRecordedDate,
    this.orbitScore,
  });

  /// Deutscher Titel des Formzustands.
  String get titleDe {
    switch (status) {
      case FormStatus.veryTired:
        return 'Sehr müde';
      case FormStatus.wellLoaded:
        return 'Gut belastet';
      case FormStatus.balanced:
        return 'Ausgeglichen';
      case FormStatus.fresh:
        return 'Frisch';
      case FormStatus.lowBaseline:
        return 'Geringe Grundbelastung';
      case FormStatus.insufficientData:
        return 'Noch zu wenig Daten';
    }
  }

  /// Englischer Titel des Formzustands.
  String get titleEn {
    switch (status) {
      case FormStatus.veryTired:
        return 'High fatigue';
      case FormStatus.wellLoaded:
        return 'Productive';
      case FormStatus.balanced:
        return 'Balanced';
      case FormStatus.fresh:
        return 'Fresh';
      case FormStatus.lowBaseline:
        return 'Low baseline load';
      case FormStatus.insufficientData:
        return 'Insufficient data';
    }
  }

  /// Ausführliche physiologische Einordnung (Deutsch, neutral, kein ärztlicher Rat).
  String get descriptionDe {
    switch (status) {
      case FormStatus.veryTired:
        return 'Die kurzfristige Belastung liegt deutlich über deiner gewohnten Basis. Der Körper verarbeitet intensive Trainingsreize.';
      case FormStatus.wellLoaded:
        return 'Wirksamer Trainingsreiz im optimalen Aufbaukorridor. Sehr gute Anpassungsbedingungen.';
      case FormStatus.balanced:
        return 'Belastung und Erholung halten sich die Waage. Geeignet für Formerhalt oder Trainingsübergänge.';
      case FormStatus.fresh:
        return 'Hohe Frische durch Erholung oder Tapering. Gute Voraussetzungen für Spitzenleistungen oder neue Belastungsblöcke.';
      case FormStatus.lowBaseline:
        return 'Deine gemessene Grundbelastung ist noch sehr gering. Der Formwert gewinnt mit zunehmender Trainingsdauer an Aussagekraft.';
      case FormStatus.insufficientData:
        return 'Für eine verlässliche Form-Einschätzung werden mindestens 21 Tage kontinuierliche Trainingsdaten benötigt.';
    }
  }

  /// Ausführliche physiologische Einordnung (Englisch).
  String get descriptionEn {
    switch (status) {
      case FormStatus.veryTired:
        return 'Short-term training load is significantly above your usual baseline. Your body is absorbing intensive training stress.';
      case FormStatus.wellLoaded:
        return 'Effective training stimulus in an optimal building zone. Strong physiological adaptation conditions.';
      case FormStatus.balanced:
        return 'Load and recovery are in equilibrium. Suitable for maintenance or transition phases.';
      case FormStatus.fresh:
        return 'High freshness from recovery or tapering. Favorable conditions for peak efforts or new loading blocks.';
      case FormStatus.lowBaseline:
        return 'Your baseline training load is still low. The fitness metric becomes more meaningful with sustained training.';
      case FormStatus.insufficientData:
        return 'At least 21 days of continuous training data are required for a reliable fitness evaluation.';
    }
  }

  /// Text über die zugrundeliegende Datenbasis.
  String get dataBasisTextDe {
    if (status == FormStatus.insufficientData) {
      return '$daysOfHistory von 21 Tagen erfasst';
    }
    final weeks = (daysOfHistory / 7).floor();
    if (weeks >= 2) {
      return 'Basiert auf $weeks Wochen Training ($daysOfHistory Tagen)';
    }
    return 'Basiert auf $daysOfHistory Tagen Training';
  }

  /// Text über die zugrundeliegende Datenbasis (Englisch).
  String get dataBasisTextEn {
    if (status == FormStatus.insufficientData) {
      return '$daysOfHistory of 21 days recorded';
    }
    final weeks = (daysOfHistory / 7).floor();
    if (weeks >= 2) {
      return 'Based on $weeks weeks of training ($daysOfHistory days)';
    }
    return 'Based on $daysOfHistory days of training';
  }

  /// Leitfarbe des Zustands gemäß Design-System.
  Color get statusColor {
    switch (status) {
      case FormStatus.veryTired:
        return const Color(0xFFDD6B20); // Warmes Amber/Orange (neutral statt Alarm-Rot)
      case FormStatus.wellLoaded:
        return AppColors.volt; // Performance Volt / Grün
      case FormStatus.balanced:
        return AppColors.navy; // Neutrales Navy
      case FormStatus.fresh:
        return const Color(0xFF0EA5E9); // Cyan / Frisch
      case FormStatus.lowBaseline:
      case FormStatus.insufficientData:
        return const Color(0xFF94A3B8); // Neutral Slate
    }
  }

  /// Icon für den Zustand.
  IconData get icon {
    switch (status) {
      case FormStatus.veryTired:
        return Icons.battery_charging_full_outlined;
      case FormStatus.wellLoaded:
        return Icons.trending_up;
      case FormStatus.balanced:
        return Icons.balance;
      case FormStatus.fresh:
        return Icons.bolt;
      case FormStatus.lowBaseline:
        return Icons.hourglass_bottom;
      case FormStatus.insufficientData:
        return Icons.query_builder;
    }
  }
}
