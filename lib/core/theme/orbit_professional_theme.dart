/// Datei-Header: `lib/core/theme/orbit_professional_theme.dart`
/// Zweck: Clean Professional Design System für ORBIT (Phase 41) in Hell & Dunkel.
/// Architektur-Einordnung: Core-Theme-Schicht (`lib/core/theme/`), definiert die
/// professionellen Carbon/Anthrazit-Tokens für den Dark Mode (`#0D0F12` / `#16181D`)
/// und Alabaster/Reinweiß-Tokens für den Light Mode (`#F4F6F9` / `#FFFFFF`) unter
/// Wahrung der ORBIT Marken- und Sportfarben (`#001F47` Navy & `#CDFB17` Volt).
library;

import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

/// Zentrale Farb- und Design-Tokens sowie `ThemeData`-Fabrik für das
/// Clean Professional Design System (Phase 41).
///
/// Was: Liefert hochperformante, `const`-optimierte Farbkonstanten und fertige
/// Material-3-Themes für Light Mode und Dark Mode.
/// Warum: Vermeidet Objekt-Instanziierungen innerhalb von `build()`-Methoden
/// (`AGENTS.md` Regel 10) und garantiert einen ruhigen, kontrastreichen Look.
class OrbitProfessionalTheme {
  /// Privater Konstruktor zur Verhinderung von Instanziierungen.
  const OrbitProfessionalTheme._();

  // ===========================================================================
  // Dark Mode Tokens (Carbon & Anthrazit)
  // ===========================================================================

  /// Tiefer Carbon-Hintergrund (`#0D0F12`) für den Dark Mode.
  static const Color darkBackground = Color(0xFF0D0F12);

  /// Abgesetzte Anthrazit-Kartenoberfläche (`#16181D`) für den Dark Mode.
  static const Color darkCardSurface = Color(0xFF16181D);

  /// Erhöhte Oberfläche im Dark Mode (`#1E2128`) für Sheets und Dialoge.
  static const Color darkElevatedSurface = Color(0xFF1E2128);

  /// Dezenter 1px-Rahmen im Dark Mode (8 % Weiß-Opazität: `0x14FFFFFF`).
  static const Color darkSubtleBorder = Color(0x14FFFFFF);

  /// Primäre Textfarbe im Dark Mode (`#F8FAFC`).
  static const Color darkTextPrimary = Color(0xFFF8FAFC);

  /// Sekundäre, gedämpfte Textfarbe im Dark Mode (`#94A3B8`).
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ===========================================================================
  // Light Mode Tokens (Alabaster & Reinweiß)
  // ===========================================================================

  /// Klarer Alabaster-Hintergrund (`#F4F6F9`) für den Light Mode.
  static const Color lightBackground = Color(0xFFF4F6F9);

  /// Reinweiße Kartenoberfläche (`#FFFFFF`) für den Light Mode.
  static const Color lightCardSurface = Color(0xFFFFFFFF);

  /// Feiner Schiefergrau-Rahmen (`#E2E8F0`) für Karten im Light Mode.
  static const Color lightSubtleBorder = Color(0xFFE2E8F0);

  /// Kontrastreiche dunkle Typografie (`#0F172A`) für den Light Mode.
  static const Color lightTextPrimary = Color(0xFF0F172A);

  /// Sekundäre Textfarbe im Light Mode (`#475569`).
  static const Color lightTextSecondary = Color(0xFF475569);

  /// Erzeugt das Clean Professional Light Theme (`#F4F6F9` Alabaster, `#FFFFFF` Karten,
  /// `#E2E8F0` Rahmen, `#0F172A` Typografie).
  ///
  /// Rückgabewert: Konfiguriertes [ThemeData] für `Brightness.light`.
  static ThemeData buildLightTheme() {
    // Statische TextTheme-Definition für scharfe, kontrastreiche Typografie (#0F172A)
    const textTheme = TextTheme(
      displayLarge: AppTypography.display,
      displayMedium: AppTypography.headline,
      headlineLarge: AppTypography.headline,
      headlineMedium: AppTypography.title,
      titleLarge: AppTypography.title,
      titleMedium: TextStyle(
        fontFamily: AppTypography.fontFamilyInter,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
      bodyLarge: AppTypography.body,
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamilyInter,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightTextPrimary,
      ),
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.label,
    );

    // Zusammenbau des Material-3 Light-Themes mit Alabaster-Hintergrund und weißen Karten
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.navy,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: AppTypography.fontFamilyInter,
      dividerColor: lightSubtleBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: AppColors.white,
        secondary: AppColors.navyLight,
        onSecondary: AppColors.white,
        surface: lightCardSurface,
        onSurface: lightTextPrimary,
        surfaceContainerHighest: lightBackground,
        onSurfaceVariant: lightTextSecondary,
        outline: lightSubtleBorder,
        error: AppColors.z5,
        onError: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCardSurface,
        foregroundColor: lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamilyInter,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCardSurface,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: lightTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        color: lightCardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.cardRadius)),
          side: BorderSide(color: lightSubtleBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightSubtleBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCardSurface,
        labelStyle: const TextStyle(color: lightTextSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightSubtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightSubtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
      ),
      textTheme: textTheme.apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
    );
  }

  /// Erzeugt das Clean Professional Dark Theme (`#0D0F12` Carbon-Hintergrund,
  /// `#16181D` Anthrazit-Karten, 1px Rahmen mit 8 % Weiß-Opazität, Volt `#CDFB17` Akzente).
  ///
  /// Rückgabewert: Konfiguriertes [ThemeData] für `Brightness.dark`.
  static ThemeData buildDarkTheme() {
    // Statische TextTheme-Definition für gestochen scharfe helle Typografie auf Carbon
    const textTheme = TextTheme(
      displayLarge: AppTypography.display,
      displayMedium: AppTypography.headline,
      headlineLarge: AppTypography.headline,
      headlineMedium: AppTypography.title,
      titleLarge: AppTypography.title,
      titleMedium: TextStyle(
        fontFamily: AppTypography.fontFamilyInter,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      bodyLarge: AppTypography.body,
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamilyInter,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkTextPrimary,
      ),
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.label,
    );

    // Zusammenbau des Material-3 Dark-Themes mit Carbon-Hintergrund und Anthrazit-Karten
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.volt,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: AppTypography.fontFamilyInter,
      dividerColor: darkSubtleBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.volt,
        onPrimary: AppColors.navy,
        secondary: AppColors.volt,
        onSecondary: AppColors.navy,
        surface: darkCardSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkElevatedSurface,
        onSurfaceVariant: darkTextSecondary,
        outline: darkSubtleBorder,
        error: AppColors.channelHeartRate,
        onError: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamilyInter,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCardSurface,
        selectedItemColor: AppColors.volt,
        unselectedItemColor: darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        color: darkCardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.cardRadius)),
          side: BorderSide(color: darkSubtleBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.volt,
          foregroundColor: AppColors.navy,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.volt,
          side: const BorderSide(color: AppColors.volt, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardSurface,
        labelStyle: const TextStyle(color: darkTextSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppColors.volt,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkSubtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkSubtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.volt, width: 2),
        ),
      ),
      textTheme: textTheme.apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
    );
  }
}
