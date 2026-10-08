import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.navy,
      scaffoldBackgroundColor: AppColors.greyLight,
      fontFamily: AppTypography.fontFamilyInter,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        secondary: AppColors.volt,
        surface: AppColors.white,
        background: AppColors.greyLight,
        error: AppColors.z5,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppSpacing.cardRadius)),
          side: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.headline,
        titleLarge: AppTypography.title,
        bodyLarge: AppTypography.body,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.label,
      ).apply(
        bodyColor: AppColors.navy,
        displayColor: AppColors.navy,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.navy,
      scaffoldBackgroundColor: AppColors.cockpit,
      fontFamily: AppTypography.fontFamilyInter,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.navyLight,
        secondary: AppColors.volt,
        surface: AppColors.navy,
        background: AppColors.cockpit,
        error: AppColors.channelHeartRate,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.navy,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppSpacing.cardRadius)),
          // No border or dark border for dark mode
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.headline,
        titleLarge: AppTypography.title,
        bodyLarge: AppTypography.body,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.label,
      ).apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
    );
  }
}
