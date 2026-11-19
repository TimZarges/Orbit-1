/// Datei-Header: `lib/core/design/theme_tokens.dart`
/// Zweck: Leichtgewichtiger Kontext-Zugriff auf die verankerten Light- und Dark-Tokens.
/// Architektur-Einordnung: Delegiert vollständig an [AppColors] als Single Source of Truth.
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Zentrales Design-Token-System für ORBIT (abgeleitet von [AppColors]).
class OrbitThemeTokens {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color cardBorder;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;

  const OrbitThemeTokens({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.cardBorder,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
  });

  /// Dark-Mode-Tokens (`#0B0E14` / `#141923` / `#CDFB17`).
  static const OrbitThemeTokens dark = OrbitThemeTokens(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkCardSurface,
    cardBackground: AppColors.darkCardSurface,
    cardBorder: AppColors.darkSubtleBorder,
    primary: AppColors.volt,
    onPrimary: AppColors.navy,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextSecondary,
    divider: AppColors.darkSubtleBorder,
  );

  /// Light-Mode-Tokens (`#F6F8FB` / `#FFFFFF` / `#001F47`).
  static const OrbitThemeTokens light = OrbitThemeTokens(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightCardSurface,
    cardBackground: AppColors.lightCardSurface,
    cardBorder: AppColors.lightBorder,
    primary: AppColors.navy,
    onPrimary: AppColors.lightCardSurface,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextSecondary,
    divider: AppColors.lightBorder,
  );

  /// Liefert die passenden Tokens für den aktuellen [Theme]-Kontext.
  static OrbitThemeTokens of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
