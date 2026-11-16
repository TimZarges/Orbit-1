/// Datei-Header: `lib/features/settings/models/app_settings.dart`
/// Zweck: Datenmodell für benutzerspezifische App-Einstellungen (Sprache DE/EN,
/// Wohnland für `dd.mm.yy` & 24h-Format, Maßsystem, Theme-Modus Hell/Dunkel/System
/// und Erfahrungsstufe).
/// Architektur-Einordnung: Modellschicht des Settings-Features (`lib/features/settings/models/`).
library;

import 'package:flutter/material.dart';
import '../../../core/metrics/term_resolver.dart';

/// Das Maßsystem für Einheiten (Metrisch vs. Imperial).
enum MeasurementSystem {
  /// Metrisches Einheitensystem (km, m, kg, km/h, min/km).
  metric,

  /// Imperiales Einheitensystem (miles, ft, lbs, mph, min/mi).
  imperial,
}

/// Datenmodell für benutzerspezifische App-Einstellungen.
class AppSettings {
  /// ISO-Sprachcode (Standard: `'de'`, unterstützt `'de'` und `'en'`).
  final String languageCode;

  /// ISO-Ländercode des Wohnlands (Standard: `'DE'`), steuert das Datumsformat
  /// `dd.mm.yy` und das 24h-Uhrzeitformat über `CountryDateTimeFormatter`.
  final String countryCode;

  /// Gewähltes Maßsystem [MeasurementSystem.metric] oder [MeasurementSystem.imperial].
  final MeasurementSystem measurementSystem;

  /// Aktueller Theme-Modus (System, Hell oder Dunkel).
  final ThemeMode themeMode;

  /// Gewählte Erfahrungsstufe zur Steuerung der sichtbaren Datendichte.
  final ExperienceLevel experienceLevel;

  /// Erstellt eine neue Instanz von [AppSettings].
  const AppSettings({
    this.languageCode = 'de',
    this.countryCode = 'DE',
    this.measurementSystem = MeasurementSystem.metric,
    this.themeMode = ThemeMode.system,
    this.experienceLevel = ExperienceLevel.advanced,
  });

  /// Erstellt eine kopierte Instanz von [AppSettings] mit aktualisierten Feldern.
  ///
  /// [languageCode]: Neuer Sprachcode (`'de'` oder `'en'`).
  /// [countryCode]: Neuer ISO-Ländercode des Wohnlands (z. B. `'DE'`, `'AT'`, `'CH'`).
  /// [measurementSystem]: Neues Einheitensystem.
  /// [themeMode]: Neuer Darstellungsmodus (`ThemeMode.system`, `light`, `dark`).
  /// [experienceLevel]: Neue Erfahrungsstufe.
  /// Rückgabewert: Aktualisierte [AppSettings]-Instanz.
  AppSettings copyWith({
    String? languageCode,
    String? countryCode,
    MeasurementSystem? measurementSystem,
    ThemeMode? themeMode,
    ExperienceLevel? experienceLevel,
  }) {
    // Erzeugt unveränderliches Einstellungs-Objekt
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      countryCode: countryCode ?? this.countryCode,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      themeMode: themeMode ?? this.themeMode,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }
}
