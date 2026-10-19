import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/core/utils/orbit_date_formatter.dart';

void main() {
  group('OrbitDateFormatter (Phase 38.2)', () {
    test(
        'formatDate formatiert Datum exakt im deutschen Format DD.MM.YYYY mit führenden Nullen',
        () {
      final dt = DateTime(2026, 4, 5, 14, 30);
      expect(OrbitDateFormatter.formatDate(dt), '05.04.2026');
    });

    test('formatDateString wandelt ISO-Strings zuverlässig um', () {
      expect(OrbitDateFormatter.formatDateString('2026-10-18'), '18.10.2026');
      expect(OrbitDateFormatter.formatDateString('2026-03-09T08:15:00Z'),
          '09.03.2026');
      // Ungültiger Fallback
      expect(OrbitDateFormatter.formatDateString('ungueltiges_datum'),
          'ungueltiges_datum');
    });

    test('formatTime liefert 24h-Format mit und ohne Suffix', () {
      final dt = DateTime(2026, 10, 18, 19, 6);
      expect(OrbitDateFormatter.formatTime(dt, withSuffix: true), '19:06 Uhr');
      expect(OrbitDateFormatter.formatTime(dt, withSuffix: false), '19:06');

      final morningDt = DateTime(2026, 10, 18, 8, 5);
      expect(OrbitDateFormatter.formatTime(morningDt, withSuffix: true),
          '08:05 Uhr');
    });

    test('formatDateTime kombiniert Datum und 24h-Uhrzeit', () {
      final dt = DateTime(2026, 10, 18, 19, 6);
      expect(OrbitDateFormatter.formatDateTime(dt), '18.10.2026 • 19:06 Uhr');
    });

    test('formatWeekdayDate liefert deutschen Wochentag mit Datum', () {
      // 2026-10-18 ist ein Sonntag
      final dt = DateTime(2026, 10, 18);
      expect(OrbitDateFormatter.formatWeekdayDate(dt), 'So., 18.10.2026');
    });

    test('formatMonthYear liefert vollen deutschen Monatsnamen', () {
      final dt = DateTime(2026, 10, 18);
      expect(OrbitDateFormatter.formatMonthYear(dt), 'Oktober 2026');
    });

    test('formatRelativeDate unterscheidet Heute, Morgen, Gestern', () {
      final now = DateTime.now();
      expect(OrbitDateFormatter.formatRelativeDate(now), 'Heute');

      final tomorrow = now.add(const Duration(days: 1));
      expect(OrbitDateFormatter.formatRelativeDate(tomorrow), 'Morgen');

      final yesterday = now.subtract(const Duration(days: 1));
      expect(OrbitDateFormatter.formatRelativeDate(yesterday), 'Gestern');
    });

    test('toIsoDateKey erzeugt sauberen yyyy-MM-dd Schlüssel für Firestore',
        () {
      final dt = DateTime(2026, 7, 3);
      expect(OrbitDateFormatter.toIsoDateKey(dt), '2026-07-03');
    });
  });
}
