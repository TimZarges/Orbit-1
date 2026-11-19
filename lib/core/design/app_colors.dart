/// Datei-Header: `lib/core/design/app_colors.dart`
/// Zweck: Verbindliche Single Source of Truth aller ORBIT-Farbtokens (Light & Dark)
/// gemäß `docs/design/COLOR_SYSTEM_V1.md`, abgestuft in GROSS (Flächen & Haupttext),
/// MITTEL (Akzent, Struktur & Sportarten) und KLEIN (Status, GPX-Spur, Zonen Z1–Z7 & V2–V4).
/// Architektur-Einordnung: Core-Design-Schicht (`lib/core/design/`).
library;

import 'package:flutter/material.dart';

/// Zentrale Farbpalette für das verankerte ORBIT-Farbsystem (Light & Dark).
///
/// Grundprinzipien:
/// 1. Light Mode nutzt Logo-Navy (`#001F47` / `#003B82`) als primären Marken-Akzent.
///    Logo-Volt (`#CDFB17`) wird im Light Mode NICHT auf Text oder UI-Flächen genutzt,
///    sondern bleibt für die zukünftige GPX-Spur reserviert.
/// 2. Dark Mode nutzt Logo-Volt (`#CDFB17`) als primären Marken-Akzent auf ruhigem
///    Tiefdunkel (`#0B0E14` / `#141923` / `#1B2230`).
/// 3. Sportarten und Zonen-/Matrix-/V2–V4-Tokens sind strikt von den Markenfarben
///    unabhängig (einzige Ausnahme: zukünftige GPX-Spur `#CDFB17`).
class AppColors {
  /// Privater Konstruktor zur Verhinderung direkter Instanziierung.
  const AppColors._();

  // ===========================================================================
  // Marken- & Akzentfarben
  // ===========================================================================

  /// Offizielles ORBIT Logo-Navy (`#001F47`): Primärer Marken-Akzent im Light Mode.
  static const Color navy = Color(0xFF001F47);

  /// Ergänzendes Navy (`#003B82`): Sekundärer Marken-Akzent im Light Mode.
  static const Color navyLight = Color(0xFF003B82);

  /// Offizielles ORBIT Logo-Volt (`#CDFB17`): Primärer Akzent im Dark Mode & GPX-Spur.
  static const Color volt = Color(0xFFCDFB17);

  /// Reservierte Signalfarbe für die zukünftige GPX-Karten-Spur (`#CDFB17`).
  static const Color gpxTrack = Color(0xFFCDFB17);

  // ===========================================================================
  // GROSS: Flächen & Haupttext (Light Mode)
  // ===========================================================================

  /// Ruhiger Seiten-Hintergrund im Light Mode (`#F6F8FB`).
  static const Color lightBackground = Color(0xFFF6F8FB);

  /// Karten- & Leisten-Oberfläche im Light Mode (`#FFFFFF`).
  static const Color lightCardSurface = Color(0xFFFFFFFF);

  /// Sanfte Sekundärfläche im Light Mode (`#EEF2F7`).
  static const Color lightSecondarySurface = Color(0xFFEEF2F7);

  /// Kontraststarker Haupttext im Light Mode (`#0F172A`).
  static const Color lightTextPrimary = Color(0xFF0F172A);

  // ===========================================================================
  // GROSS: Flächen & Haupttext (Dark Mode)
  // ===========================================================================

  /// Ruhiger Hintergrund im Dark Mode (`#0B0E14`).
  static const Color darkBackground = Color(0xFF0B0E14);

  /// Karten- & Leisten-Oberfläche im Dark Mode (`#141923`).
  static const Color darkCardSurface = Color(0xFF141923);

  /// Erhöhte Fläche (Sheets, Dialoge) im Dark Mode (`#1B2230`).
  static const Color darkElevatedSurface = Color(0xFF1B2230);

  /// Haupttext im Dark Mode (`#F8FAFC`).
  static const Color darkTextPrimary = Color(0xFFF8FAFC);

  // ===========================================================================
  // MITTEL: Struktur, Text & Rahmen (Light & Dark)
  // ===========================================================================

  /// Sekundärtext im Light Mode (`#64748B`).
  static const Color lightTextSecondary = Color(0xFF64748B);

  /// Feiner 1px-Rahmen / Divider im Light Mode (`#DCE3EC`).
  static const Color lightBorder = Color(0xFFDCE3EC);

  /// Subtile Fläche im Dark Mode (`#222B3A`).
  static const Color darkSubtleSurface = Color(0xFF222B3A);

  /// Sekundärtext im Dark Mode (`#94A3B8`).
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  /// Feiner 1px-Rahmen im Dark Mode (`0x24FFFFFF`, 14 % Weiß).
  static const Color darkSubtleBorder = Color(0x24FFFFFF);

  // ===========================================================================
  // MITTEL: Sportarten-Tokens (strikt unabhängig von Logo-Navy & Logo-Volt)
  // ===========================================================================

  /// Triathlon im Light Mode (`#0284C7`).
  static const Color sportTriathlonLight = Color(0xFF0284C7);

  /// Radfahren im Light Mode (`#D97706`).
  static const Color sportBikeLight = Color(0xFFD97706);

  /// Laufen im Light Mode (`#059669`).
  static const Color sportRunLight = Color(0xFF059669);

  /// Schwimmen im Light Mode (`#2563EB`).
  static const Color sportSwimLight = Color(0xFF2563EB);

  /// Krafttraining im Light Mode (`#475569`).
  static const Color sportStrengthLight = Color(0xFF475569);

  /// Triathlon im Dark Mode (`#38BDF8`).
  static const Color sportTriathlonDark = Color(0xFF38BDF8);

  /// Radfahren im Dark Mode (`#F59E0B`).
  static const Color sportBikeDark = Color(0xFFF59E0B);

  /// Laufen im Dark Mode (`#10B981`).
  static const Color sportRunDark = Color(0xFF10B981);

  /// Schwimmen im Dark Mode (`#60A5FA`).
  static const Color sportSwimDark = Color(0xFF60A5FA);

  /// Krafttraining im Dark Mode (`#94A3B8`).
  static const Color sportStrengthDark = Color(0xFF94A3B8);

  // ===========================================================================
  // KLEIN: Status-Tokens (Light & Dark)
  // ===========================================================================

  /// Erfolg im Light Mode (`#059669`).
  static const Color successLight = Color(0xFF059669);

  /// Warnung / Info im Light Mode (`#D97706`).
  static const Color warningLight = Color(0xFFD97706);

  /// Fehler / Löschen im Light Mode (`#DC2626`).
  static const Color errorLight = Color(0xFFDC2626);

  /// Erfolg im Dark Mode (`#10B981`).
  static const Color successDark = Color(0xFF10B981);

  /// Warnung / Info im Dark Mode (`#F59E0B`).
  static const Color warningDark = Color(0xFFF59E0B);

  /// Fehler / Löschen im Dark Mode (`#EF4444`).
  static const Color errorDark = Color(0xFFEF4444);

  // ===========================================================================
  // KLEIN: Zonen Z1–Z7 (Light & Dark)
  // ===========================================================================

  /// Zone Z1 (Erholung) für Light & Dark (`#94A3B8`).
  static const Color z1Light = Color(0xFF94A3B8);
  static const Color z1Dark = Color(0xFF94A3B8);

  /// Zone Z2 (Grundlage): `#0284C7` (Light) / `#38BDF8` (Dark).
  static const Color z2Light = Color(0xFF0284C7);
  static const Color z2Dark = Color(0xFF38BDF8);

  /// Zone Z3 (Tempo): `#059669` (Light) / `#10B981` (Dark).
  static const Color z3Light = Color(0xFF059669);
  static const Color z3Dark = Color(0xFF10B981);

  /// Zone Z4 (Schwelle): `#D97706` (Light) / `#F59E0B` (Dark).
  static const Color z4Light = Color(0xFFD97706);
  static const Color z4Dark = Color(0xFFF59E0B);

  /// Zone Z5 (VO₂max): `#DC2626` (Light) / `#EF4444` (Dark).
  static const Color z5Light = Color(0xFFDC2626);
  static const Color z5Dark = Color(0xFFEF4444);

  /// Zone Z6 (Anaerob): `#7C3AED` (Light) / `#A78BFA` (Dark).
  static const Color z6Light = Color(0xFF7C3AED);
  static const Color z6Dark = Color(0xFFA78BFA);

  /// Zone Z7 (Neuromuskulär): `#DB2777` (Light) / `#F472B6` (Dark).
  static const Color z7Light = Color(0xFFDB2777);
  static const Color z7Dark = Color(0xFFF472B6);

  // ===========================================================================
  // KLEIN: Zukünftige V2–V4 Tokens (Light & Dark)
  // ===========================================================================

  /// V2–V4 Erholung: `#059669` (Light) / `#10B981` (Dark).
  static const Color v2RecoveryLight = Color(0xFF059669);
  static const Color v2RecoveryDark = Color(0xFF10B981);

  /// V2–V4 Belastung: `#D97706` (Light) / `#F59E0B` (Dark).
  static const Color v2LoadLight = Color(0xFFD97706);
  static const Color v2LoadDark = Color(0xFFF59E0B);

  /// V2–V4 Schlaf: `#0284C7` (Light) / `#38BDF8` (Dark).
  static const Color v2SleepLight = Color(0xFF0284C7);
  static const Color v2SleepDark = Color(0xFF38BDF8);

  /// V2–V4 2D-RPE Quadrant: `#7C3AED` (Light) / `#A78BFA` (Dark).
  static const Color v2RpeQuadrantLight = Color(0xFF7C3AED);
  static const Color v2RpeQuadrantDark = Color(0xFFA78BFA);

  /// V2–V4 LIT / MIT / HIT Basis-Token: `#475569` (Light) / `#94A3B8` (Dark).
  static const Color v2IntensityZoneLight = Color(0xFF475569);
  static const Color v2IntensityZoneDark = Color(0xFF94A3B8);

  /// V3–V4 Machine Learning & KI-Trainer: `#4F46E5` (Light) / `#818CF8` (Dark).
  static const Color v3MlAiLight = Color(0xFF4F46E5);
  static const Color v3MlAiDark = Color(0xFF818CF8);

  // ===========================================================================
  // Brightness-abhängige Komfort-Resolver
  // ===========================================================================

  /// Liefert den primären UI-Akzent (`#001F47` im Light Mode, `#CDFB17` im Dark Mode).
  static Color primaryAccent({required bool isDark}) => isDark ? volt : navy;

  /// Liefert den passenden Seitenhintergrund für Hell und Dunkel.
  static Color scaffoldBg({required bool isDark}) =>
      isDark ? darkBackground : lightBackground;

  /// Liefert die passende Kartenoberfläche für Hell und Dunkel.
  static Color cardBg({required bool isDark}) =>
      isDark ? darkCardSurface : lightCardSurface;

  /// Liefert eine sanfte Sekundär- bzw. Subtilfläche für Hell und Dunkel.
  static Color subtleSurface({required bool isDark}) =>
      isDark ? darkSubtleSurface : lightSecondarySurface;

  /// Liefert den passenden feinen Kartenrahmen für Hell und Dunkel.
  static Color cardBorderFor({required bool isDark}) =>
      isDark ? darkSubtleBorder : lightBorder;

  /// Liefert die primäre Textfarbe für Hell und Dunkel.
  static Color primaryText({required bool isDark}) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  /// Liefert die sekundäre Textfarbe für Hell und Dunkel.
  static Color secondaryText({required bool isDark}) =>
      isDark ? darkTextSecondary : lightTextSecondary;

  /// Liefert die Erfolgsfarbe für Hell und Dunkel.
  static Color statusSuccess({required bool isDark}) =>
      isDark ? successDark : successLight;

  /// Liefert die Warn- bzw. Hinweisfarbe für Hell und Dunkel.
  static Color statusWarning({required bool isDark}) =>
      isDark ? warningDark : warningLight;

  /// Liefert die Fehler- bzw. Löschfarbe für Hell und Dunkel.
  static Color statusError({required bool isDark}) =>
      isDark ? errorDark : errorLight;

  /// Liefert die unabhängige Sportart-Farbe für Light & Dark Mode
  /// (ohne Logo-Navy `#001F47` oder Logo-Volt `#CDFB17`).
  static Color resolveSportColor(String sport, {required bool isDark}) {
    switch (sport.toUpperCase()) {
      case 'TRIATHLON':
      case 'MULTISPORT':
        return isDark ? sportTriathlonDark : sportTriathlonLight;
      case 'BIKE':
      case 'CYCLING':
        return isDark ? sportBikeDark : sportBikeLight;
      case 'RUN':
      case 'RUNNING':
        return isDark ? sportRunDark : sportRunLight;
      case 'SWIM':
      case 'SWIMMING':
        return isDark ? sportSwimDark : sportSwimLight;
      case 'STRENGTH':
        return isDark ? sportStrengthDark : sportStrengthLight;
      default:
        return isDark ? darkTextSecondary : lightTextSecondary;
    }
  }

  /// Liefert die Farbe für eine Trainingszone (`1` bis `7`) im jeweiligen Theme.
  static Color zoneColor(int zone, {bool isDark = true}) {
    switch (zone) {
      case 1:
        return isDark ? z1Dark : z1Light;
      case 2:
        return isDark ? z2Dark : z2Light;
      case 3:
        return isDark ? z3Dark : z3Light;
      case 4:
        return isDark ? z4Dark : z4Light;
      case 5:
        return isDark ? z5Dark : z5Light;
      case 6:
        return isDark ? z6Dark : z6Light;
      case 7:
        return isDark ? z7Dark : z7Light;
      default:
        return isDark ? z1Dark : z1Light;
    }
  }

  // ===========================================================================
  // Abwärtskompatible Aliase (für bestehende V2/V3-Komponenten & Tests)
  // ===========================================================================

  static const Color white = lightCardSurface;
  static const Color greyLight = lightBackground;
  static const Color alabaster = lightBackground;
  static const Color carbonDark = darkBackground;
  static const Color anthraciteCard = darkCardSurface;
  static const Color cockpit = navy;
  static const Color cardDark = darkElevatedSurface;
  static const Color card = cardDark;
  static const Color cardBorder = lightBorder;

  static const Color z1 = z1Dark;
  static const Color z2 = z2Dark;
  static const Color z3 = z3Dark;
  static const Color z4 = z4Dark;
  static const Color z5 = z5Dark;
  static const Color z6 = z6Dark;
  static const Color z7 = z7Dark;
  static const Color zone1 = z1Dark;
  static const Color zone2 = z2Dark;
  static const Color zone3 = z3Dark;
  static const Color zone4 = z4Dark;
  static const Color zone5 = z5Dark;
  static const Color zone6 = z6Dark;
  static const Color zone7 = z7Dark;

  // Telemetrie-Kanäle (V2 Analyse-Cockpit)
  static const Color channelPower = Color(0xFFF6C453);
  static const Color channelHeartRate = Color(0xFFFF6B6B);
  static const Color channelPace = Color(0xFF38BDF8);
  static const Color channelSwimPace = Color(0xFF818CF8);
  static const Color channelCadence = Color(0xFF4ADE80);
  static const Color channelAltitude = Color(0xFF94A3B8);
  static const Color channelCoreTemp = Color(0xFFFB923C);

  // Standard-Sport-Aliase (unabhängig von Markenfarben)
  static const Color sportSwim = sportSwimDark;
  static const Color sportBike = sportBikeDark;
  static const Color sportRun = sportRunDark;
  static const Color sportStrength = sportStrengthDark;
  static const Color sportMulti = sportTriathlonDark;

  static const Color background = darkBackground;
  static const Color backgroundLight = lightBackground;
  static const Color accentVolt = volt;
  static const Color techGrey = lightTextSecondary;
  static const Color borderDark = darkSubtleSurface;
  static const Color textTertiaryDark = lightTextSecondary;
  static const Color surfaceDark = darkCardSurface;
  static const Color green = successDark;
  static const Color red = errorDark;
  static const Color emerald = successDark;
  static const Color amber = warningDark;
  static const Color coral = errorDark;
  static const Color cyan = sportTriathlonDark;
  static const Color accentBlue = sportTriathlonLight;
  static const Color success = successDark;
  static const Color warning = warningDark;
  static const Color error = errorDark;
}
