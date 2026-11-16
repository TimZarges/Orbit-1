/// Datei-Header: `lib/core/design/app_theme.dart`
/// Zweck: Fassade und zentraler Einstiegspunkt für das ORBIT Theme-System.
/// Architektur-Einordnung: Delegiert an [OrbitProfessionalTheme] (`lib/core/theme/`),
/// damit bestehende Aufrufer (`AppTheme.lightTheme` und `AppTheme.darkTheme`) nahtlos
/// das Clean Professional Design System (Phase 41) erhalten.
library;

import 'package:flutter/material.dart';
import '../theme/orbit_professional_theme.dart';

/// Zentrales Theme-System für ORBIT.
///
/// Definiert das globale [lightTheme] (Alabaster `#F4F6F9`, reinweiße Karten `#FFFFFF`,
/// Schiefergrau-Rahmen `#E2E8F0`, dunkle Typografie `#0F172A`) und das [darkTheme]
/// (Carbon `#0D0F12`, Anthrazit-Karten `#16181D`, 1px Rahmen mit 8 % Weiß-Opazität
/// und Volt `#CDFB17` Markenakzente).
class AppTheme {
  /// Privater Konstruktor zur Verhinderung direkter Instanziierung.
  const AppTheme._();

  /// Gecachte Instanz des Light-Themes zur Vermeidung wiederholter `ThemeData`-Allokationen.
  static final ThemeData _cachedLightTheme =
      OrbitProfessionalTheme.buildLightTheme();

  /// Gecachte Instanz des Dark-Themes zur Vermeidung wiederholter `ThemeData`-Allokationen.
  static final ThemeData _cachedDarkTheme =
      OrbitProfessionalTheme.buildDarkTheme();

  /// Liefert das Clean Professional Light-Theme (`#F4F6F9` Alabaster & `#FFFFFF` Karten).
  static ThemeData get lightTheme => _cachedLightTheme;

  /// Liefert das Clean Professional Dark-Theme (`#0D0F12` Carbon & `#16181D` Karten).
  static ThemeData get darkTheme => _cachedDarkTheme;
}
