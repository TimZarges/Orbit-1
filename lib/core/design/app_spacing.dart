/// Definiert das zentrale 4er-/8er-Abstandsraster und Layout-Konstanten für ORBIT.
///
/// Basiert auf den Design-Richtlinien aus `docs/DESIGN.md` und garantiert
/// ein konsistentes visuelles Rhythmusgefühl auf allen Bildschirmgrößen.
class AppSpacing {
  /// 4 Pixel Abstand (sehr kompakt, z. B. Badge-Padding oder Icon-Spacing).
  static const double p4 = 4.0;

  /// 8 Pixel Abstand (kompakt, z. B. Chip-Abstände oder vertikales Zeilen-Padding).
  static const double p8 = 8.0;

  /// 12 Pixel Abstand (mittlerer Innenabstand für Eingabefelder und Buttons).
  static const double p12 = 12.0;

  /// 16 Pixel Standard-Abstand (Standard-Margin für Mobile-Pages und Cards).
  static const double p16 = 16.0;

  /// 24 Pixel Abstand (großer Trennabstand zwischen Sektionen).
  static const double p24 = 24.0;

  /// 32 Pixel Abstand (sehr großer Trennabstand für Header und Hero-Elemente).
  static const double p32 = 32.0;

  // Spezifische Layout-Abstände
  /// Standardmäßiger horizontaler Seitenrand auf Smartphones (16.0).
  static const double mobilePageMargin = 16.0;

  /// Eckenradius für Inhaltskarten und Panels (16.0).
  static const double cardRadius = 16.0;

  /// Standardmäßiges Innen-Padding für Inhaltskarten (16.0).
  static const double cardPadding = 16.0;

  /// Eckenradius für primäre und sekundäre Aktions-Buttons (12.0).
  static const double buttonRadius = 12.0;

  // Breakpoints
  /// Responsiver Breakpoint für Mobilgeräte (< 600 Pixel).
  static const double breakpointCompact = 600.0;

  /// Responsiver Breakpoint für Tablets und Desktop-Ansichten (>= 1024 Pixel).
  static const double breakpointMedium = 1024.0;
}
