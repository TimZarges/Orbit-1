/// Datei-Header: `lib/features/settings/providers/settings_provider.dart`
/// Zweck: Riverpod-Controller zur reaktiven und persistenten Verwaltung der
/// Benutzereinstellungen (Sprache DE/EN, Wohnland `countryCode`, ThemeMode
/// Hell/Dunkel/System, Einheitensystem und Erfahrungsstufe).
/// Architektur-Einordnung: Geschäftslogik-Schicht (`lib/features/settings/providers/`).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/metrics/term_resolver.dart';
import '../../../core/utils/country_date_time_formatter.dart';
import '../models/app_settings.dart';

/// Controller für die globalen App-Einstellungen ([AppSettings]).
///
/// Was: Verwaltet Sprachwechsel (`de`/`en`), Darstellungsmodus (`ThemeMode`),
/// Wohnland (`countryCode`), Einheitensystem und Erfahrungsstufe im Speicher
/// und synchronisiert Änderungen für eingeloggte Nutzer nicht-blockierend mit Firestore.
/// Warum: Sofortiges lokales State-Update garantiert ruckelfreie 120-Hz-Umschaltung
/// ohne Warten auf Netzwerk-Roundtrips (`AGENTS.md` Regel 10).
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    // Initialisiert die Standard-Einstellungen (DE, Wohnland DE, System-Theme)
    return const AppSettings();
  }

  /// Ändert die aktive App-Sprache (`'de'` oder `'en'`) sofort und persistiert sie.
  ///
  /// [code]: ISO-Sprachcode (`'de'` oder `'en'`).
  void setLanguage(String code) {
    // Aktualisiert den lokalen State unmittelbar für verzögerungsfreien UI-Rebuild
    final normalized = code.toLowerCase() == 'en' ? 'en' : 'de';
    state = state.copyWith(languageCode: normalized);
    _persistSetting({'language': normalized});
  }

  /// Ändert das Wohnland (ISO-Ländercode wie `'DE'`, `'AT'`, `'CH'`) für die
  /// Datums- (`dd.mm.yy`) und 24h-Zeitformatierung.
  ///
  /// [countryCode]: Zweistelliger ISO-Ländercode.
  void setCountryCode(String countryCode) {
    // Normalisiert den Ländercode über CountryDateTimeFormatter und aktualisiert den State
    final normalized =
        CountryDateTimeFormatter.normalizeCountryCode(countryCode);
    state = state.copyWith(countryCode: normalized);
    _persistSetting({'countryCode': normalized}, profilePatch: {
      'countryCode': normalized,
    },);
  }

  /// Ändert das Maßsystem (Metrisch vs. Imperial).
  ///
  /// [system]: Gewähltes [MeasurementSystem].
  void setMeasurementSystem(MeasurementSystem system) {
    // Aktualisiert das Einheitensystem im lokalen State und in Firestore
    state = state.copyWith(measurementSystem: system);
    _persistSetting({
      'units': system == MeasurementSystem.imperial ? 'IMPERIAL' : 'METRIC',
    });
  }

  /// Ändert den Darstellungsmodus ([ThemeMode.system], [ThemeMode.light], [ThemeMode.dark]).
  ///
  /// [mode]: Gewählter [ThemeMode].
  void setThemeMode(ThemeMode mode) {
    // Sofortiger Theme-Wechsel ohne Flackern
    state = state.copyWith(themeMode: mode);
    _persistSetting({'themeMode': mode.name});
  }

  /// Ändert die Erfahrungsstufe ([ExperienceLevel.beginner], `advanced`, `expert`).
  ///
  /// [level]: Gewählte [ExperienceLevel].
  void setExperienceLevel(ExperienceLevel level) {
    // Aktualisiert Erfahrungsstufe lokal und in Firestore
    state = state.copyWith(experienceLevel: level);
    _persistSetting(
      {'experienceLevel': level.name},
      profilePatch: {'experienceLevel': level.name.toUpperCase()},
    );
  }

  /// Persistiert Einstellungsänderungen im Hintergrund in Firestore (`users/{uid}`),
  /// sofern eine aktive Firebase-Session existiert.
  void _persistSetting(
    Map<String, dynamic> settingsPatch, {
    Map<String, dynamic>? profilePatch,
  }) {
    // Nicht-blockierendes Speichern mit sicherem Catch für Offline-/Test-Umgebungen
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;
      final payload = <String, dynamic>{
        'settings': settingsPatch,
        if (profilePatch != null) 'profile': profilePatch,
      };
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(payload, SetOptions(merge: true))
          .catchError((_) {});
    } catch (_) {
      // In reinen Widget-Tests ohne Firebase-Initialisierung still ignorieren
    }
  }
}

/// Primärer Provider für den [SettingsController] und den aktuellen [AppSettings]-Zustand.
final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(() {
  return SettingsController();
});

/// Komfort-Alias für [settingsControllerProvider].
final settingsProvider = settingsControllerProvider;
