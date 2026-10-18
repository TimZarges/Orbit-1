/// Zentraler Datums- und Uhrzeit-Formatierer für die ORBIT-Applikation (Phase 38.2).
///
/// Garantiert ein einheitliches, DIN- und sportwissenschaftlich konformes deutsches
/// Anzeigeformat (`DD.MM.YYYY` und 24h-Uhrzeit `HH:mm Uhr`) in der gesamten UI,
/// ohne unvorhersehbare Lokalisierungs-Ausnahmen in Testumgebungen zu provozieren.
class OrbitDateFormatter {
  OrbitDateFormatter._();

  /// Formatiert ein [DateTime] als deutsches Datum im Format `DD.MM.YYYY`.
  /// Beispiel: 18.10.2026
  static String formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    return '$day.$month.$year';
  }

  /// Formatiert einen Datumsstring (z. B. ISO `2026-10-18` oder UTC-Timestamp)
  /// in das deutsche Format `DD.MM.YYYY`. Bei Parsing-Fehlern wird der Originalstring
  /// zurückgegeben.
  static String formatDateString(String raw) {
    try {
      final parsed = DateTime.parse(raw);
      return formatDate(parsed);
    } catch (_) {
      return raw;
    }
  }

  /// Formatiert eine Uhrzeit im 24h-Format mit optionalem Suffix (' Uhr').
  /// Beispiel: 19:06 Uhr (mit withSuffix=true) oder 19:06 (withSuffix=false)
  static String formatTime(DateTime dt, {bool withSuffix = true}) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return withSuffix ? '$hour:$minute Uhr' : '$hour:$minute';
  }

  /// Formatiert Datum und Uhrzeit zusammen.
  /// Beispiel: 18.10.2026 • 19:06 Uhr
  static String formatDateTime(DateTime dt, {String separator = ' • '}) {
    return '${formatDate(dt)}$separator${formatTime(dt, withSuffix: true)}';
  }

  /// Formatiert Datum und Uhrzeit aus einem ISO-String.
  static String formatDateTimeString(String raw, {String separator = ' • '}) {
    try {
      final parsed = DateTime.parse(raw);
      return formatDateTime(parsed, separator: separator);
    } catch (_) {
      return raw;
    }
  }

  /// Formatiert ein Datum mit kurzem Wochentag.
  /// Beispiel: So., 18.10.2026
  static String formatWeekdayDate(DateTime dt) {
    final local = dt.toLocal();
    const weekdays = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];
    final weekday = weekdays[(local.weekday - 1).clamp(0, 6)];
    return '$weekday, ${formatDate(local)}';
  }

  /// Formatiert ein Datum mit vollem Monatsnamen.
  /// Beispiel: Oktober 2026
  static String formatMonthYear(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ];
    final month = months[(local.month - 1).clamp(0, 11)];
    return '$month ${local.year}';
  }

  /// Formatiert einen relativen Abstand oder das Datum.
  /// Beispiel: 'Heute', 'Gestern', 'Morgen' oder '18.10.2026'
  static String formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) return 'Heute';
    if (diffDays == 1) return 'Morgen';
    if (diffDays == -1) return 'Gestern';
    return formatDate(dt);
  }

  /// Konvertiert ein Datum in das interne ISO-Format `yyyy-MM-dd` für Firestore-Keys.
  static String toIsoDateKey(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString().padLeft(4, '0');
    return '$year-$month-$day';
  }
}
