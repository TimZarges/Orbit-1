import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
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
        color: AppColors.navy,
      ),
      bodyLarge: AppTypography.body,
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamilyInter,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.navy,
      ),
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.label,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.navy,
      scaffoldBackgroundColor: AppColors.greyLight,
      fontFamily: AppTypography.fontFamilyInter,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: AppColors.white,
        secondary: AppColors.navyLight,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.navy,
        surfaceVariant: AppColors.greyLight,
        onSurfaceVariant: Color(0xFF475569),
        error: AppColors.z5,
        onError: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamilyInter,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppSpacing.cardRadius)),
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        floatingLabelStyle:
            const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.navy,
        displayColor: AppColors.navy,
      ),
    );
  }

  static ThemeData get darkTheme {
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
        color: AppColors.white,
      ),
      bodyLarge: AppTypography.body,
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamilyInter,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.white,
      ),
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.label,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.volt,
      scaffoldBackgroundColor: AppColors.cockpit,
      fontFamily: AppTypography.fontFamilyInter,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.volt,
        onPrimary: AppColors.navy,
        secondary: AppColors.volt,
        onSecondary: AppColors.navy,
        surface: Color(0xFF1E293B),
        onSurface: AppColors.white,
        surfaceVariant: Color(0xFF334155),
        onSurfaceVariant: Color(0xFF94A3B8),
        error: AppColors.channelHeartRate,
        onError: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cockpit,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamilyInter,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppSpacing.cardRadius)),
          side: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.volt,
          foregroundColor: AppColors.navy,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.volt,
          side: const BorderSide(color: AppColors.volt, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        floatingLabelStyle:
            const TextStyle(color: AppColors.volt, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.volt, width: 2),
        ),
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
    );
  }
}
