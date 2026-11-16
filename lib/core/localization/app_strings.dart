/// Datei-Header: `lib/core/localization/app_strings.dart`
/// Zweck: Zentraler zweisprachiger Sprach-Index (`de` & `en`) für die gesamte
/// ORBIT-Applikation gemäß `AGENTS.md` Regel 7 & 10.
/// Architektur-Einordnung: Core-Lokalisierungsschicht (`lib/core/localization/`),
/// liefert typensichere Übersetzungen für alle in V1.0.0 sichtbaren Texte, Labels,
/// Buttons und Fehlermeldungen ohne hartcodierte UI-Strings.
library;

import 'package:flutter/material.dart';
import '../metrics/term_resolver.dart';
import '../../features/settings/models/app_settings.dart';

/// Zentraler String- & Lokalisierungs-Index für ORBIT (`de` & `en`).
///
/// Was: Übersetzt alle UI-Begriffe, Navigations-Tabs, Einstellungs-Labels,
/// Buttons und Statusmeldungen anhand des übergebenen Sprachcodes (`'de'` oder `'en'`).
/// Warum: Verhindert hartcodierte UI-Strings und garantiert sofortiges Umschalten
/// zwischen Deutsch und Englisch in den Einstellungen.
class AppStrings {
  /// Privater Konstruktor zur Verhinderung direkter Instanziierung.
  const AppStrings._();

  /// Prüft, ob der übergebene Sprachcode Englisch ist.
  static bool _isEn(String lang) => lang.toLowerCase().startsWith('en');

  // ===========================================================================
  // Erfahrungsstufen, Theme-Modi, Einheiten, Rollen & Sportarten
  // ===========================================================================

  /// Liefert die lokalisierte Bezeichnung einer [ExperienceLevel].
  static String experienceLevelLabel(
    ExperienceLevel level, {
    String lang = 'de',
  }) {
    // Übersetzt die Erfahrungsstufe (Einfach / Fortgeschritten / Experte)
    switch (level) {
      case ExperienceLevel.beginner:
        return _isEn(lang) ? 'Simple' : 'Einfach';
      case ExperienceLevel.advanced:
        return _isEn(lang) ? 'Advanced' : 'Fortgeschritten';
      case ExperienceLevel.expert:
        return _isEn(lang) ? 'Expert' : 'Experte';
    }
  }

  /// Liefert die lokalisierte Beschreibung einer [ExperienceLevel].
  static String experienceLevelDescription(
    ExperienceLevel level, {
    String lang = 'de',
  }) {
    // Erklärt den Umfang der jeweiligen Erfahrungsstufe
    switch (level) {
      case ExperienceLevel.beginner:
        return _isEn(lang)
            ? 'Focus on essentials (duration, distance, avg HR & power, .FIT download).'
            : 'Fokus auf Grundwerte (Dauer, Distanz, Ø Puls & Watt, .FIT-Download).';
      case ExperienceLevel.advanced:
        return _isEn(lang)
            ? 'Adds training zones (Z1–Z7), load metrics & form traffic light.'
            : 'Zusätzlich Trainingszonen (Z1–Z7), Belastungspunkte & Form-Ampel.';
      case ExperienceLevel.expert:
        return _isEn(lang)
            ? 'Full exercise physiology telemetry including CP, W\'bal & aerobic decoupling.'
            : 'Volle sportwissenschaftliche Telemetrie inkl. CP, W\'bal & Aerobic Decoupling.';
    }
  }

  /// Liefert die lokalisierte Bezeichnung eines [ThemeMode].
  static String themeModeLabel(ThemeMode mode, {String lang = 'de'}) {
    // Übersetzt System, Hell und Dunkel
    switch (mode) {
      case ThemeMode.system:
        return _isEn(lang) ? 'System Default' : 'Automatisch (System)';
      case ThemeMode.light:
        return _isEn(lang) ? 'Light' : 'Hell';
      case ThemeMode.dark:
        return _isEn(lang) ? 'Dark' : 'Dunkel';
    }
  }

  /// Liefert die lokalisierte Bezeichnung eines [MeasurementSystem].
  static String measurementSystemLabel(
    MeasurementSystem system, {
    String lang = 'de',
  }) {
    // Übersetzt Metrisch vs. Imperial
    switch (system) {
      case MeasurementSystem.metric:
        return _isEn(lang) ? 'Metric (km, kg, °C)' : 'Metrisch (km, kg, °C)';
      case MeasurementSystem.imperial:
        return _isEn(lang)
            ? 'Imperial (mi, lbs, °F)'
            : 'Imperial (mi, lbs, °F)';
    }
  }

  /// Liefert die lokalisierte Bezeichnung einer Benutzerrolle (`ATHLETE` / `TRAINER`).
  static String roleLabel(String role, {String lang = 'de'}) {
    // Übersetzt Athlet und Trainer/Coach
    switch (role.toUpperCase()) {
      case 'TRAINER':
      case 'COACH':
        return _isEn(lang) ? 'Coach' : 'Trainer / Coach';
      case 'ATHLETE':
      default:
        return _isEn(lang) ? 'Athlete' : 'Athlet';
    }
  }

  /// Liefert die lokalisierte Bezeichnung einer Sportart.
  static String sportLabel(String sport, {String lang = 'de'}) {
    // Übersetzt Radfahren, Laufen, Schwimmen, Triathlon und Kraft
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return _isEn(lang) ? 'Cycling' : 'Radsport';
      case 'RUN':
        return _isEn(lang) ? 'Running' : 'Laufen';
      case 'SWIM':
        return _isEn(lang) ? 'Swimming' : 'Schwimmen';
      case 'TRIATHLON':
        return 'Triathlon';
      case 'STRENGTH':
        return _isEn(lang) ? 'Strength & Conditioning' : 'Kraft & Athletik';
      default:
        return sport;
    }
  }

  // ===========================================================================
  // Navigation & Dashboard (V1.0.0 & V2/V3)
  // ===========================================================================

  /// Tab-Label „Heute“ / „Today“.
  static String navToday({String lang = 'de'}) =>
      _isEn(lang) ? 'Today' : 'Heute';

  /// Tab-Label „Kalender“ / „Calendar“.
  static String navCalendar({String lang = 'de'}) =>
      _isEn(lang) ? 'Calendar' : 'Kalender';

  /// Tab-Label „Analyse“ / „Analysis“.
  static String navAnalysis({String lang = 'de'}) =>
      _isEn(lang) ? 'Analysis' : 'Analyse';

  /// Tab-Label „Coach“.
  static String navCoach({String lang = 'de'}) => 'Coach';

  /// Tab-Label „Athleten“ / „Athletes“.
  static String navAthletes({String lang = 'de'}) =>
      _isEn(lang) ? 'Athletes' : 'Athleten';

  /// Tab-Label „Bibliothek“ / „Library“.
  static String navLibrary({String lang = 'de'}) =>
      _isEn(lang) ? 'Library' : 'Bibliothek';

  /// Tab- & Menü-Label „Profil“ / „Profile“.
  static String navProfile({String lang = 'de'}) =>
      _isEn(lang) ? 'Profile' : 'Profil';

  /// Menü-Label „Einstellungen“ / „Settings“.
  static String navSettings({String lang = 'de'}) =>
      _isEn(lang) ? 'Settings' : 'Einstellungen';

  /// Menü-Label „Meine gemeldeten Tickets“ / „My Reported Tickets“.
  static String navMyFeedback({String lang = 'de'}) =>
      _isEn(lang) ? 'My Reported Tickets' : 'Meine gemeldeten Tickets';

  /// Menü-Label „Abmelden“ / „Sign Out“.
  static String navLogout({String lang = 'de'}) =>
      _isEn(lang) ? 'Sign Out' : 'Abmelden';

  // ===========================================================================
  // Heute-Ansicht (V1.0.0 Fokus: Absolviertes Training + Garmin Sync & Upload)
  // ===========================================================================

  /// Überschrift für den Bereich absolvierter Einheiten auf der Heute-Ansicht.
  static String todayCompletedTrainingHeader({String lang = 'de'}) =>
      _isEn(lang) ? 'Completed Training' : 'Absolviertes Training';

  /// Untertitel für den Schnellzugriff auf Garmin Sync & Datei-Upload.
  static String todayQuickSyncSubtitle({String lang = 'de'}) => _isEn(lang)
      ? 'Sync completed sessions from Garmin Connect or import .fit/.tcx/.gpx files.'
      : 'Synchronisiere absolvierte Einheiten von Garmin Connect oder lade .fit/.tcx/.gpx Dateien hoch.';

  /// Button-Label für Garmin Sync.
  static String garminSyncAction({String lang = 'de'}) =>
      _isEn(lang) ? 'Garmin Sync' : 'Garmin Sync';

  /// Button-Label für Datei-Upload.
  static String fileUploadAction({String lang = 'de'}) => _isEn(lang)
      ? 'Import File (.fit, .tcx, .gpx)'
      : 'Datei-Upload (.fit, .tcx, .gpx)';

  /// Button-Label für direkten `.FIT`-Download auf der Trainings-Vorschaukarte.
  static String fitDownloadAction({String lang = 'de'}) =>
      _isEn(lang) ? 'Download .FIT' : '.FIT herunterladen';

  /// Hinweistext bei Start des `.FIT`-Downloads.
  static String fitDownloadStarted(String title, {String lang = 'de'}) =>
      _isEn(lang)
          ? 'Downloading original .FIT file for "$title"...'
          : 'Original .FIT-Datei für „$title“ wird heruntergeladen...';

  // ===========================================================================
  // Einstellungen (SettingsScreen)
  // ===========================================================================

  /// Titel „Sprache“ / „Language“.
  static String settingsLanguageTitle({String lang = 'de'}) =>
      _isEn(lang) ? 'Language' : 'Sprache';

  /// Titel „Wohnland (Datum & 24h-Format)“ / „Country of Residence (Date & 24h)“.
  static String settingsCountryTitle({String lang = 'de'}) => _isEn(lang)
      ? 'Country of Residence (dd.mm.yy & 24h)'
      : 'Wohnland (Datum dd.mm.yy & 24h)';

  /// Titel „Einheiten“ / „Units“.
  static String settingsUnitsTitle({String lang = 'de'}) =>
      _isEn(lang) ? 'Units' : 'Einheiten';

  /// Titel „Darstellung“ / „Appearance“.
  static String settingsThemeTitle({String lang = 'de'}) =>
      _isEn(lang) ? 'Appearance' : 'Darstellung';

  /// Titel „Erfahrungsstufe“ / „Experience Level“.
  static String settingsExperienceTitle({String lang = 'de'}) =>
      _isEn(lang) ? 'Experience Level' : 'Erfahrungsstufe';

  /// Titel „Verbindungen (Garmin)“ / „Connections (Garmin)“.
  static String settingsGarminTitle({String lang = 'de'}) =>
      _isEn(lang) ? 'Connections (Garmin)' : 'Verbindungen (Garmin)';

  /// Untertitel für Garmin-Verbindungen.
  static String settingsGarminSubtitle({String lang = 'de'}) => _isEn(lang)
      ? 'Connect or manage Garmin Connect'
      : 'Garmin Connect verknüpfen oder verwalten';

  /// Titel „Datenschutz“ / „Privacy & Data Protection“.
  static String settingsPrivacyTitle({String lang = 'de'}) =>
      _isEn(lang) ? 'Privacy & Data Protection' : 'Datenschutz';

  /// Untertitel für Datenschutz.
  static String settingsPrivacySubtitle({String lang = 'de'}) => _isEn(lang)
      ? 'Manage health consent, export data, delete account (GDPR)'
      : 'Gesundheitsdaten widerrufen, Datenexport, DSGVO';

  /// Titel „Fehler melden & Verbesserung vorschlagen“.
  static String settingsBugReportTitle({String lang = 'de'}) => _isEn(lang)
      ? 'Report Issue & Suggest Improvement'
      : 'Fehler melden & Verbesserung vorschlagen';

  /// Untertitel für Bug-Reporting.
  static String settingsBugReportSubtitle({String lang = 'de'}) => _isEn(lang)
      ? 'Direct feedback to the ORBIT engineering team'
      : 'Direktes Feedback an das ORBIT-Entwicklerteam';

  /// Untertitel für gemeldete Tickets.
  static String settingsMyFeedbackSubtitle({String lang = 'de'}) => _isEn(lang)
      ? 'Status of your bug reports and feature suggestions'
      : 'Status deiner Bug-Reports und Feedback-Vorschläge';

  /// Titel „Passwort ändern“ / „Change Password“.
  static String settingsChangePasswordTitle({String lang = 'de'}) =>
      _isEn(lang) ? 'Change Password' : 'Passwort ändern';

  /// Untertitel für Passwort ändern.
  static String settingsChangePasswordSubtitle({String lang = 'de'}) =>
      _isEn(lang)
          ? 'Securely update your account login password'
          : 'Sichere Aktualisierung deines Login-Passworts';

  /// Untertitel für Abmelden.
  static String settingsLogoutSubtitle({String lang = 'de'}) => _isEn(lang)
      ? 'Sign out of this account'
      : 'Aus diesem Konto abmelden';
}
