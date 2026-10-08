import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamilyInter = 'Inter';
  static const String fontFamilyPlayfair = 'Playfair Display Italic';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 32,
    fontWeight: FontWeight.w900, // Black
    height: 1.2,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 24,
    fontWeight: FontWeight.w900, // Black
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 18,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    height: 1.2,
  );

  static const TextStyle metric = TextStyle(
    fontFamily: fontFamilyInter,
    fontSize: 32, // Kann je nach Widget skaliert werden (28-40)
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle quote = TextStyle(
    fontFamily: fontFamilyPlayfair,
    fontSize: 18, // 18-20
    fontStyle: FontStyle.italic,
  );
}
