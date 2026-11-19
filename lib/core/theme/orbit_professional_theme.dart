/// Datei-Header: `lib/core/theme/orbit_professional_theme.dart`
/// Zweck: Verankertes Clean Professional Design System für ORBIT in Light & Dark Mode
/// (`docs/design/COLOR_SYSTEM_V1.md`), abgeleitet direkt aus [AppColors].
/// Architektur-Einordnung: Core-Theme-Schicht (`lib/core/theme/`), stellt `const`-optimierte
/// und gecachte Material-3-Themes für die gesamte App bereit (`AGENTS.md` Regel 10).
library;

import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

/// Zentrale `ThemeData`-Fabrik für ORBIT (Light & Dark).
///
/// Was: Baut konsistente Material-3-Themes für Light Mode (`#F6F8FB` BG, `#FFFFFF` Cards,
/// `#EEF2F7` Sekundärfläche, `#0F172A` Text, `#001F47`/`#003B82` Navy-Akzent, `#DCE3EC` Rahmen)
/// und Dark Mode (`#0B0E14` BG, `#141923` Cards, `#1B2230` Elevated, `#222B3A` Subtilfläche,
/// `#F8FAFC` Text, `#CDFB17` Volt-Akzent, `0x24FFFFFF` Rahmen).
/// Warum: Alle UI-Komponenten beziehen ihre Farben zentral ohne Einzel-Hex-Wildwuchs.
class OrbitProfessionalTheme {
  /// Privater Konstruktor zur Verhinderung von Instanziierungen.
  const OrbitProfessionalTheme._();

  // ===========================================================================
  // Verankerte Token-Verweise (Single Source of Truth: AppColors)
  // ===========================================================================

  /// Ruhiger Dark-Background (`#0B0E14`).
  static const Color darkBackground = AppColors.darkBackground;

  /// Dark-Karten- und Leistenfläche (`#141923`).
  static const Color darkCardSurface = AppColors.darkCardSurface;

  /// Erhöhte Dark-Oberfläche für Sheets und Dialoge (`#1B2230`).
  static const Color darkElevatedSurface = AppColors.darkElevatedSurface;

  /// Subtile Dark-Fläche (`#222B3A`).
  static const Color darkSubtleSurface = AppColors.darkSubtleSurface;

  /// Feiner Dark-Rahmen (`0x24FFFFFF`).
  static const Color darkSubtleBorder = AppColors.darkSubtleBorder;

  /// Primäre Textfarbe im Dark Mode (`#F8FAFC`).
  static const Color darkTextPrimary = AppColors.darkTextPrimary;

  /// Sekundäre Textfarbe im Dark Mode (`#94A3B8`).
  static const Color darkTextSecondary = AppColors.darkTextSecondary;

  /// Ruhiger Light-Background (`#F6F8FB`).
  static const Color lightBackground = AppColors.lightBackground;

  /// Reinweiße Karten- & Leistenfläche im Light Mode (`#FFFFFF`).
  static const Color lightCardSurface = AppColors.lightCardSurface;

  /// Sanfte Sekundärfläche im Light Mode (`#EEF2F7`).
  static const Color lightSecondarySurface = AppColors.lightSecondarySurface;

  /// Feiner Rahmen im Light Mode (`#DCE3EC`).
  static const Color lightSubtleBorder = AppColors.lightBorder;

  /// Kontraststarker Haupttext im Light Mode (`#0F172A`).
  static const Color lightTextPrimary = AppColors.lightTextPrimary;

  /// Sekundärtext im Light Mode (`#64748B`).
  static const Color lightTextSecondary = AppColors.lightTextSecondary;

  /// Erzeugt das verankerte Light Theme (ohne Logo-Volt in Standard-UI/Texten).
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

    // Zusammenbau des Material-3 Light-Themes mit Logo-Navy (#001F47 / #003B82) als Akzent
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.navy,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: AppTypography.fontFamilyInter,
      dividerColor: lightSubtleBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: lightCardSurface,
        secondary: AppColors.navyLight,
        onSecondary: lightCardSurface,
        surface: lightCardSurface,
        onSurface: lightTextPrimary,
        surfaceContainerHighest: lightSecondarySurface,
        onSurfaceVariant: lightTextSecondary,
        outline: lightSubtleBorder,
        error: AppColors.errorLight,
        onError: lightCardSurface,
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
      dialogTheme: const DialogThemeData(
        backgroundColor: lightCardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: lightSubtleBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCardSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: lightSubtleBorder,
        thickness: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.navy;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(lightCardSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: lightCardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: lightCardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: lightSubtleBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navyLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
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

  /// Erzeugt das verankerte Dark Theme (`#0B0E14` BG, `#141923` Cards, `#1B2230` Elevated,
  /// `0x24FFFFFF` Rahmen und Volt `#CDFB17` Akzent).
  static ThemeData buildDarkTheme() {
    // Statische TextTheme-Definition für gestochen scharfe Typografie (#F8FAFC)
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

    // Zusammenbau des Material-3 Dark-Themes mit Volt (#CDFB17) als Primär-Akzent
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
        error: AppColors.errorDark,
        onError: darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCardSurface,
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
      dialogTheme: const DialogThemeData(
        backgroundColor: darkElevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: darkSubtleBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkElevatedSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: darkSubtleBorder,
        thickness: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.volt;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(AppColors.navy),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.volt,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSubtleSurface,
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
