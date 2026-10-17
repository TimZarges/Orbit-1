import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Zentrales Design-Token-System für ORBIT.
/// Basiert strikt auf Brand-Navy (#001F47) und Volt (#CDFB17) ohne verbotenes #0F172A.
class OrbitThemeTokens {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color cardBorder;
  final Color primary; // Volt
  final Color onPrimary; // Navy
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

  /// Dark-Cockpit-Theme (Standard für High-End Telemetrie)
  static const OrbitThemeTokens dark = OrbitThemeTokens(
    brightness: Brightness.dark,
    background: AppColors.navy,
    surface: Color(0xFF002A5C),
    cardBackground: Color(0xFF002A5C),
    cardBorder: Color(0xFF003D82),
    primary: AppColors.volt,
    onPrimary: AppColors.navy,
    textPrimary: AppColors.white,
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    divider: Color(0xFF003D82),
  );

  /// Helles Theme (Optimale Ablesbarkeit im Freien / bei Sonnenlicht)
  static const OrbitThemeTokens light = OrbitThemeTokens(
    brightness: Brightness.light,
    background: Color(0xFFF8FAFC),
    surface: AppColors.white,
    cardBackground: AppColors.white,
    cardBorder: AppColors.cardBorder,
    primary: AppColors.volt,
    onPrimary: AppColors.navy,
    textPrimary: AppColors.navy,
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    divider: Color(0xFFE2E8F0),
  );

  static OrbitThemeTokens of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
