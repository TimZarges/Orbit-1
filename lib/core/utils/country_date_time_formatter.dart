/// Datei-Header: `lib/core/utils/country_date_time_formatter.dart`
/// Zweck: Schlanker, hocheffizienter Formatierungs-Service für Datum (`dd.mm.yy`)
/// und Uhrzeit (`24h`-Format `HH:mm`), gekoppelt an das im Profil gespeicherte
/// Wohnland (z. B. `DE`, `AT`, `CH` und weitere EU-Länder).
/// Architektur-Einordnung: Core-Utility-Schicht (`lib/core/utils/`), arbeitet mit
/// reiner Integer-Arithmetik ohne `intl`-Allokationsoverhead für garantierte 120 FPS.
library;

/// Hocheffizienter Datums- und Uhrzeit-Formatierer nach Wohnland für ORBIT V1.0.0 (Phase 41).
///
/// Was: Formatiert jedes Datum strikt als zweistelliges Jahr `dd.mm.yy` (z. B. `21.10.26`)
/// und jede Uhrzeit im 24-Stunden-Format `HH:mm` (z. B. `19:54`), gekoppelt an das
/// im Nutzerprofil hinterlegte Wohnland (`DE`, `AT`, `CH`, `LU`, `LI`, `NL`, `BE`,
/// `FR`, `IT`, `ES`, `PL`, `DK`, `SE`, `NO`, `FI` u. a.).
/// Warum: Vermeidet teure `DateFormat`-Objektinstanziierungen in `build()`-Methoden
/// (`AGENTS.md` Regel 10) und garantiert ein einheitliches europäisches Sport-Layout.
class CountryDateTimeFormatter {
  /// Privater Konstruktor zur Verhinderung direkter Instanziierung.
  const CountryDateTimeFormatter._();

  /// Liste der unterstützten ISO-3166-1 Alpha-2 Ländercodes für DACH & EU mit
  /// kanonischem `dd.mm.yy` & `24h`-Standard.
  static const Set<String> supportedEuCountryCodes = {
    'DE', // Deutschland
    'AT', // Österreich
    'CH', // Schweiz
    'LU', // Luxemburg
    'LI', // Liechtenstein
    'NL', // Niederlande
    'BE', // Belgien
    'FR', // Frankreich
    'IT', // Italien
    'ES', // Spanien
    'PT', // Portugal
    'PL', // Polen
    'CZ', // Tschechien
    'DK', // Dänemark
    'SE', // Schweden
    'NO', // Norwegen
    'FI', // Finnland
    'IE', // Irland
    'GB', // Vereinigtes Königreich
  };

  /// Normalisiert einen übergebenen Ländercode auf Großbuchstaben (Fallback: `'DE'`).
  ///
  /// [countryCode]: Optionaler ISO-Ländercode aus dem Nutzerprofil.
  /// Rückgabewert: Gültiger zweistelliger ISO-Ländercode (Standard `'DE'`).
  static String normalizeCountryCode(String? countryCode) {
    // Prüft auf leeren String und normalisiert auf 2 Großbuchstaben
    if (countryCode == null || countryCode.trim().isEmpty) {
      return 'DE';
    }
    final normalized = countryCode.trim().toUpperCase();
    return supportedEuCountryCodes.contains(normalized) ? normalized : 'DE';
  }

  /// Gibt zurück, ob für das angegebene Wohnland das 24-Stunden-Format aktiv ist.
  ///
  /// Gemäß V1.0.0-Spezifikation (`docs/ROADMAP_V1_TO_V4.md`) nutzen alle DACH- und
  /// EU-Wohnländer in ORBIT strikt das 24h-Format.
  /// [countryCode]: ISO-Ländercode des Wohnlands.
  /// Rückgabewert: Immer `true` für die unterstützten Wohnländer.
  static bool uses24HourFormat({String? countryCode}) {
    // Alle europäischen Zielmärkte in V1.0.0 verwenden 24h-Uhrzeit
    final code = normalizeCountryCode(countryCode);
    return code.isNotEmpty;
  }

  /// Formatiert ein [DateTime] strikt im kurzen Format `dd.mm.yy` (z. B. `21.10.26`).
  ///
  /// [dateTime]: Das zu formatierende Datum (wird in lokale Zeit überführt, sofern UTC).
  /// [countryCode]: Optionaler ISO-Ländercode des Wohnlands (Standard: `'DE'`).
  /// Rückgabewert: Formatierter Datums-String im Format `dd.mm.yy`.
  static String formatDate(DateTime dateTime, {String? countryCode}) {
    // Normalisiert Wohnland und extrahiert Tag, Monat und zweistelliges Jahr
    normalizeCountryCode(countryCode);
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final shortYear = (local.year % 100).abs().toString().padLeft(2, '0');
    return '$day.$month.$shortYear';
  }

  /// Parst einen ISO-Datumsstring (z. B. `'2026-10-21'` oder `'2026-10-21T19:54:00Z'`)
  /// und gibt ihn strikt als `dd.mm.yy` zurück.
  ///
  /// [rawDate]: Der rohe ISO-Datumsstring.
  /// [countryCode]: Optionaler ISO-Ländercode des Wohnlands.
  /// Rückgabewert: Formatierter String `dd.mm.yy` oder der Originalwert bei ungültigem Input.
  static String formatDateString(String rawDate, {String? countryCode}) {
    // Schneller Pfad für yyyy-MM-dd Strings ohne Zeitzonen-Verschiebung
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return rawDate;

    final dateOnlyMatch =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (dateOnlyMatch != null) {
      normalizeCountryCode(countryCode);
      final year = int.parse(dateOnlyMatch.group(1)!);
      final month = dateOnlyMatch.group(2)!;
      final day = dateOnlyMatch.group(3)!;
      final shortYear = (year % 100).abs().toString().padLeft(2, '0');
      return '$day.$month.$shortYear';
    }

    // Fallback auf DateTime.tryParse für vollständige ISO-8601 Timestamps
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return rawDate;
    return formatDate(parsed, countryCode: countryCode);
  }

  /// Formatiert die Uhrzeit eines [DateTime] strikt im 24h-Format `HH:mm` (z. B. `19:54`).
  ///
  /// [dateTime]: Der zu formatierende Zeitpunkt.
  /// [countryCode]: Optionaler ISO-Ländercode des Wohnlands (Standard: `'DE'`).
  /// Rückgabewert: Formatierte 24h-Uhrzeit als `HH:mm`.
  static String formatTime24h(DateTime dateTime, {String? countryCode}) {
    // Wandelt UTC in lokale Zeit um und formatiert Stunden (00-23) und Minuten (00-59)
    normalizeCountryCode(countryCode);
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Kombiniert Datum (`dd.mm.yy`) und 24h-Uhrzeit (`HH:mm`) für Karten-Header.
  ///
  /// Beispiel: `21.10.26 • 19:54`
  /// [dateTime]: Der zu formatierende Zeitpunkt.
  /// [countryCode]: Optionaler ISO-Ländercode des Wohnlands (Standard: `'DE'`).
  /// [separator]: Trennzeichen zwischen Datum und Uhrzeit (Standard: `' • '`).
  /// Rückgabewert: Kombinierter Datums- und Zeitstring.
  static String formatDateTime(
    DateTime dateTime, {
    String? countryCode,
    String separator = ' • ',
  }) {
    // Verknüpft dd.mm.yy und HH:mm mit dem gewünschten Separator
    final datePart = formatDate(dateTime, countryCode: countryCode);
    final timePart = formatTime24h(dateTime, countryCode: countryCode);
    return '$datePart$separator$timePart';
  }

  /// Liefert die lokalisierte Bezeichnung eines Wohnlands für Einstellungen und Profil.
  ///
  /// [countryCode]: ISO-Ländercode (`DE`, `AT`, `CH`, `LU`, `NL`, `BE`, `FR`, `IT`, `ES`, `GB`).
  /// [lang]: Zielsprache (`'de'` oder `'en'`).
  /// Rückgabewert: Lesbarer Ländername.
  static String countryLabel(String countryCode, {String lang = 'de'}) {
    // Übersetzt die wichtigsten Wohnländer zweisprachig (DE/EN)
    final isEn = lang.toLowerCase() == 'en';
    switch (normalizeCountryCode(countryCode)) {
      case 'DE':
        return isEn ? 'Germany (DE)' : 'Deutschland (DE)';
      case 'AT':
        return isEn ? 'Austria (AT)' : 'Österreich (AT)';
      case 'CH':
        return isEn ? 'Switzerland (CH)' : 'Schweiz (CH)';
      case 'LU':
        return isEn ? 'Luxembourg (LU)' : 'Luxemburg (LU)';
      case 'NL':
        return isEn ? 'Netherlands (NL)' : 'Niederlande (NL)';
      case 'BE':
        return isEn ? 'Belgium (BE)' : 'Belgien (BE)';
      case 'FR':
        return isEn ? 'France (FR)' : 'Frankreich (FR)';
      case 'IT':
        return isEn ? 'Italy (IT)' : 'Italien (IT)';
      case 'ES':
        return isEn ? 'Spain (ES)' : 'Spanien (ES)';
      case 'GB':
        return isEn ? 'United Kingdom (GB)' : 'Vereinigtes Königreich (GB)';
      default:
        return isEn ? 'Germany (DE)' : 'Deutschland (DE)';
    }
  }
}
