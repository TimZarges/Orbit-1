import 'package:flutter/material.dart';
import 'package:orbit/core/metrics/term_resolver.dart';

enum MeasurementSystem { metric, imperial }

class AppSettings {
  final String languageCode;
  final MeasurementSystem measurementSystem;
  final ThemeMode themeMode;
  final ExperienceLevel experienceLevel;

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
