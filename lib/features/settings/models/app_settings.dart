import 'package:flutter/material.dart';
import 'package:orbit/core/metrics/term_resolver.dart';

/// Das Maßsystem für Einheiten (Metrisch vs. Imperial).
enum MeasurementSystem {
  /// Metrisches Einheitensystem (km, m, kg, km/h, min/km).
  metric,

  /// Imperiales Einheitensystem (miles, ft, lbs, mph, min/mi).
  imperial,
}

/// Datenmodell für benutzerspezifische App-Einstellungen.
class AppSettings {
  /// ISO-Sprachcode (Standard: 'de').
  final String languageCode;

  /// Gewähltes Maßsystem [MeasurementSystem.metric] oder [MeasurementSystem.imperial].
  final MeasurementSystem measurementSystem;

  /// Aktueller Theme-Modus (System, Hell oder Dunkel).
  final ThemeMode themeMode;

  /// Gewählte Erfahrungsstufe zur Steuerung der sichtbaren Datendichte.
  final ExperienceLevel experienceLevel;

  /// Erstellt eine neue Instanz von [AppSettings].
  const AppSettings({
    this.languageCode = 'de',
    this.measurementSystem = MeasurementSystem.metric,
    this.themeMode = ThemeMode.system,
    this.experienceLevel = ExperienceLevel.advanced,
  });

  AppSettings copyWith({
    String? languageCode,
    MeasurementSystem? measurementSystem,
    ThemeMode? themeMode,
    ExperienceLevel? experienceLevel,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      themeMode: themeMode ?? this.themeMode,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }
}
