/// Datei-Header: `lib/core/design/app_theme.dart`
/// Zweck: Fassade und zentraler Einstiegspunkt für das ORBIT Theme-System.
/// Architektur-Einordnung: Delegiert an [OrbitProfessionalTheme] (`lib/core/theme/`),
/// damit bestehende Aufrufer (`AppTheme.lightTheme` und `AppTheme.darkTheme`) nahtlos
/// das Clean Professional Design System (Phase 41) erhalten.
library;

import 'package:flutter/material.dart';
import '../theme/orbit_professional_theme.dart';

/// Zentrales Theme-System für ORBIT (`docs/design/COLOR_SYSTEM_V1.md`).
///
/// Definiert das globale [lightTheme] (`#F6F8FB` Hintergrund, `#FFFFFF` Karten,
/// `#EEF2F7` Sekundärfläche, `#DCE3EC` Rahmen, `#0F172A` Text, `#001F47` Navy) und
/// das [darkTheme] (`#0B0E14` Hintergrund, `#141923` Karten, `#1B2230` Elevated,
/// `0x24FFFFFF` Rahmen und Volt `#CDFB17` Akzent).
class AppTheme {
  /// Privater Konstruktor zur Verhinderung direkter Instanziierung.
  const AppTheme._();

  /// Gecachte Instanz des Light-Themes zur Vermeidung wiederholter `ThemeData`-Allokationen.
  static final ThemeData _cachedLightTheme =
      OrbitProfessionalTheme.buildLightTheme();

  /// Gecachte Instanz des Dark-Themes zur Vermeidung wiederholter `ThemeData`-Allokationen.
  static final ThemeData _cachedDarkTheme =
      OrbitProfessionalTheme.buildDarkTheme();

  /// Liefert das Clean Professional Light-Theme (`#F6F8FB` & `#FFFFFF` Karten).
  static ThemeData get lightTheme => _cachedLightTheme;

  /// Liefert das Clean Professional Dark-Theme (`#0B0E14` & `#141923` Karten).
  static ThemeData get darkTheme => _cachedDarkTheme;
}
