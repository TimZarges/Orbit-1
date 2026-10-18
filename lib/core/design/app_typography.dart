import 'package:flutter/material.dart';

/// Definiert die typografische Hierarchie für ORBIT.
///
/// Nutzt 'Inter' als primäre serifenlose Schriftart für maximale Lesbarkeit
/// hochfrequenter Telemetrie- und Belastungsdaten sowie 'Playfair Display' für Zitate.
/// Enthält [FontFeature.tabularFigures] für zitterfreie Ziffern in Metriken.
class AppTypography {
  /// Primäre serifenlose Schriftart ('Inter') für UI, Tabellen und Metriken.
  static const String fontFamilyInter = 'Inter';

  /// Serifenschriftart ('Playfair Display Italic') für Zitate und emotionale Akzente.
  static const String fontFamilyPlayfair = 'Playfair Display Italic';

  /// Große Display-Schrift (32pt, w900 Black) für Screen-Titel und markante Hero-Überschriften.
  static const TextStyle display = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 32,
    fontWeight: FontWeight.w900, // Black
    height: 1.2,
  );

  /// Headline-Schrift (24pt, w900 Black) für Sektionsüberschriften und Modaltitel.
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 24,
    fontWeight: FontWeight.w900, // Black
    height: 1.2,
  );

  /// Titel-Schrift (18pt, w600 SemiBold) für Kartentitel und Dialogköpfe.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 18,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.3,
  );

  /// Standard-Fließtext (16pt, w400 Regular) für Beschreibungen und Feed-Einträge.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
  );

  /// Kleinerer Fließtext (14pt, w400 Regular) für sekundäre Hinweise und Formular-Labels.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
  );

  /// Kompakte Beschriftung (12pt, w500 Medium) für Badges, Einheiten und Fußnoten.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    height: 1.2,
  );

  /// Große Ziffernanzeige (32pt, bold) mit Tabellenziffern für Watt, Pace, Puls und Distanz.
  static const TextStyle metric = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 32, // Kann je nach Widget skaliert werden (28-40)
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Kursive Serifenschrift (18pt, italic) für Zitate oder Coaching-Motti.
  static const TextStyle quote = TextStyle(
    fontFamily: fontFamilyPlayfair,
    fontSize: 18, // 18-20
    fontStyle: FontStyle.italic,
  );
}
