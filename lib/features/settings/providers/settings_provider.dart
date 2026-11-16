import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../../../core/metrics/term_resolver.dart';
import 'package:flutter/material.dart';

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return const AppSettings();
  }

  void setLanguage(String code) {
    state = state.copyWith(languageCode: code);
  }

  void setMeasurementSystem(MeasurementSystem system) {
    state = state.copyWith(measurementSystem: system);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setExperienceLevel(ExperienceLevel level) {
    state = state.copyWith(experienceLevel: level);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(() {
  return SettingsController();
});

/// Alias für settingsControllerProvider
final settingsProvider = settingsControllerProvider;
