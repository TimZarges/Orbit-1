import 'package:flutter/material.dart';
import '../metrics/term_resolver.dart';
import '../../features/settings/models/app_settings.dart';

/// Zentraler String- & Lokalisierungs-Index für ORBIT.
/// Verhindert unübersetzte Roh-Strings (wie 'system', 'advanced') in der UI.
class AppStrings {
  // Erfahrungsstufen
  static String experienceLevelLabel(ExperienceLevel level,
      {String lang = 'de'}) {
    switch (level) {
      case ExperienceLevel.beginner:
        return lang == 'de' ? 'Einfach' : 'Simple';
      case ExperienceLevel.advanced:
        return lang == 'de' ? 'Fortgeschritten' : 'Advanced';
      case ExperienceLevel.expert:
        return lang == 'de' ? 'Experte' : 'Expert';
    }
  }

  static String experienceLevelDescription(ExperienceLevel level,
      {String lang = 'de'}) {
    switch (level) {
      case ExperienceLevel.beginner:
        return lang == 'de'
            ? 'Fokus auf Grundwerte (3 Ringe, Dauer, Distanz, Ø Puls & Watt, Kalorien).'
            : 'Focus on essentials (3 rings, duration, distance, avg HR & power, calories).';
      case ExperienceLevel.advanced:
        return lang == 'de'
            ? 'Zusätzlich Trainingszonen (Z1–Z7), Belastungspunkte & Form-Ampel.'
            : 'Adds training zones (Z1–Z7), load metrics & form traffic light.';
      case ExperienceLevel.expert:
        return lang == 'de'
            ? 'Volle sportwissenschaftliche Telemetrie inkl. CP, W\'bal & Aerobic Decoupling.'
            : 'Full exercise physiology telemetry including CP, W\'bal & aerobic decoupling.';
    }
  }

  // Theme-Modi
  static String themeModeLabel(ThemeMode mode, {String lang = 'de'}) {
    switch (mode) {
      case ThemeMode.system:
        return lang == 'de' ? 'Automatisch (System)' : 'System Default';
      case ThemeMode.light:
        return lang == 'de' ? 'Hell' : 'Light';
      case ThemeMode.dark:
        return lang == 'de' ? 'Dunkel' : 'Dark';
    }
  }

  // Einheiten
  static String measurementSystemLabel(MeasurementSystem system,
      {String lang = 'de'}) {
    switch (system) {
      case MeasurementSystem.metric:
        return lang == 'de' ? 'Metrisch (km, kg, °C)' : 'Metric (km, kg, °C)';
      case MeasurementSystem.imperial:
        return lang == 'de'
            ? 'Imperial (mi, lbs, °F)'
            : 'Imperial (mi, lbs, °F)';
    }
  }

  // Rollen
  static String roleLabel(String role, {String lang = 'de'}) {
    switch (role.toUpperCase()) {
      case 'TRAINER':
      case 'COACH':
        return lang == 'de' ? 'Trainer / Coach' : 'Coach';
      case 'ATHLETE':
      default:
        return lang == 'de' ? 'Athlet' : 'Athlete';
    }
  }

  // Sportarten
  static String sportLabel(String sport, {String lang = 'de'}) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return lang == 'de' ? 'Radsport' : 'Cycling';
      case 'RUN':
        return lang == 'de' ? 'Laufen' : 'Running';
      case 'SWIM':
        return lang == 'de' ? 'Schwimmen' : 'Swimming';
      case 'TRIATHLON':
        return lang == 'de' ? 'Triathlon' : 'Triathlon';
      case 'STRENGTH':
        return lang == 'de' ? 'Kraft & Athletik' : 'Strength & Conditioning';
      default:
        return sport;
    }
  }
}
