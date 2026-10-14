import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/workout_builder/domain/workout_formatter.dart';
import 'package:orbit/features/workout_builder/domain/workout_parser.dart';
import 'package:orbit/features/workout_builder/models/workout_builder_models.dart';

void main() {
  group('WorkoutParser & WorkoutFormatter - Alle 10 kanonischen Beispiele', () {
    test('1. Rad: Schwellenintervalle mit Zonen', () {
      const parser = WorkoutParser(sport: 'BIKE');
      final result = parser.parse("10' Z1, 4x(4' Z4 / 2' Z1), 10' Z1");

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect(s.sport, 'BIKE');
      expect(s.blocks.length, 3);
      expect((s.blocks[0] as StepBlock).role, WorkoutRole.warmup);
      expect((s.blocks[0] as StepBlock).target.durationSec, 600);
      expect((s.blocks[1] as RepeatBlock).count, 4);
      expect((s.blocks[2] as StepBlock).role, WorkoutRole.cooldown);

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('2. Rad: Sweet Spot mit % FTP & Trittfrequenz', () {
      const parser = WorkoutParser(sport: 'BIKE');
      final result = parser.parse(
          "15' 55%FTP, 3x(8' 88-92%FTP @90-95rpm / 4' Z1), 10' Z1 [Locker ausfahren]");

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect((s.blocks[0] as StepBlock).intensity, isA<PctFtpIntensity>());
      final repeat = s.blocks[1] as RepeatBlock;
      final workStep = repeat.blocks[0] as StepBlock;
      expect(workStep.cadence, isNotNull);
      expect(workStep.cadence!.low, 90);
      expect(workStep.cadence!.high, 95);
      final cdStep = s.blocks[2] as StepBlock;
      expect(cdStep.note, 'Locker ausfahren');

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('3. Rad: VO2max Kurz-Kurz 30/30s (Verschachtelt Tiefe 2)', () {
      const parser = WorkoutParser(sport: 'BIKE');
      final result = parser
          .parse("15' Z2, 2x(10x(30\" 120%FTP / 30\" Z1) / 5' Z1), 10' Z1");

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect(s.maxDepth, 3);
      final outerRepeat = s.blocks[1] as RepeatBlock;
      expect(outerRepeat.count, 2);
      expect(outerRepeat.blocks[0], isA<RepeatBlock>());
      final innerRepeat = outerRepeat.blocks[0] as RepeatBlock;
      expect(innerRepeat.count, 10);

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('4. Lauf: Schwellenlauf mit Pace-Vorgabe (@min:sec/km)', () {
      const parser = WorkoutParser(sport: 'RUN');
      final result = parser.parse('2km Z1, 5x(1000m @4:30/km / 90"), 1.5km Z1');

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect((s.blocks[0] as StepBlock).target.distanceM, 2000);
      expect((s.blocks[2] as StepBlock).target.distanceM, 1500);

      final repeat = s.blocks[1] as RepeatBlock;
      final work = repeat.blocks[0] as StepBlock;
      expect(work.intensity, isA<PaceIntensity>());
      expect((work.intensity as PaceIntensity).secPerKm, 270);

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('5. Lauf: Fahrtspiel mit Tempowechsel', () {
      const parser = WorkoutParser(sport: 'RUN');
      final result = parser.parse("10' Z1, 6x(3' Z4 / 2' Z2), 10' Z1");

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect(s.blocks.length, 3);
      final repeat = s.blocks[1] as RepeatBlock;
      expect(repeat.count, 6);

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('6. Lauf: Bergsprints mit Gehpause', () {
      const parser = WorkoutParser(sport: 'RUN');
      final result =
          parser.parse('15\' Z2, 8x(30" Z6 / 90" frei [Gehpause]), 10\' Z1');

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      final repeat = s.blocks[1] as RepeatBlock;
      final rest = repeat.blocks[1] as StepBlock;
      expect(rest.intensity, isA<FreeIntensity>());
      expect(rest.note, 'Gehpause');

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('7. Schwimmen: CSS-Schwellenset', () {
      const parser = WorkoutParser(sport: 'SWIM');
      final result = parser.parse('400m Z1, 8x(100m CSS / 20"), 200m Z1');

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      final repeat = s.blocks[1] as RepeatBlock;
      final work = repeat.blocks[0] as StepBlock;
      expect(work.intensity, isA<CssOffsetIntensity>());
      expect((work.intensity as CssOffsetIntensity).offsetSecPer100m, 0);

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('8. Schwimmen: Stufenserie mit CSS-Offset', () {
      const parser = WorkoutParser(sport: 'SWIM');
      final result = parser.parse(
          '300m Z1, 4x(100m CSS+4" / 15"), 4x(100m CSS / 15"), 4x(100m CSS-3" / 20"), 200m Z1');

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect(s.blocks.length, 5);

      final r1 = s.blocks[1] as RepeatBlock;
      expect(
          ((r1.blocks[0] as StepBlock).intensity as CssOffsetIntensity)
              .offsetSecPer100m,
          4);

      final r3 = s.blocks[3] as RepeatBlock;
      expect(
          ((r3.blocks[0] as StepBlock).intensity as CssOffsetIntensity)
              .offsetSecPer100m,
          -3);

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('9. Schwimmen: Verschachteltes Sprintset (Tiefe 2)', () {
      const parser = WorkoutParser(sport: 'SWIM');
      final result =
          parser.parse('400m Z1, 3x(4x(50m Z5 / 15") / 2\'), 200m Z1');

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect(s.maxDepth, 3);

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });

    test('10. Kraft: Rumpf- und Athletikzirkel', () {
      const parser = WorkoutParser(sport: 'STRENGTH');
      final result = parser.parse(
          '5\' Z1 [Mobilisation], 3x(45" frei [Plank] / 15", 45" frei [Side Plank] / 15"), 5\' frei [Stretching]');

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect(s.sport, 'STRENGTH');

      // Round-Trip
      final formatted = WorkoutFormatter.format(s);
      final roundTrip = parser.parse(formatted);
      expect(roundTrip.isSuccess, isTrue);
      expect(roundTrip.structure, equals(s));
    });
  });

  group('WorkoutParser - Kurzformen & Toleranz', () {
    test('Kurzform ohne Klammern: 8x100m CSS / 20"', () {
      const parser = WorkoutParser(sport: 'SWIM');
      final result = parser.parse('8x100m CSS / 20"');

      expect(result.isSuccess, isTrue);
      final s = result.structure!;
      expect(s.blocks.length, 1);
      final repeat = s.blocks[0] as RepeatBlock;
      expect(repeat.count, 8);
      expect(repeat.blocks.length, 2);
    });

    test(
        'Normalisiert typografische Anführungszeichen (z. B. auf iOS: ’ und ”)',
        () {
      const parser = WorkoutParser(sport: 'BIKE');
      final result = parser.parse('10’ Z1, 4x(4’ Z4 / 2’ Z1), 10’ Z1');

      expect(result.isSuccess, isTrue);
      expect(
          (result.structure!.blocks[0] as StepBlock).target.durationSec, 600);
    });
  });

  group('WorkoutParser - Fehlererkennung & Positionen', () {
    test('Leere Eingabe liefert EMPTY_INPUT Fehler', () {
      const parser = WorkoutParser(sport: 'BIKE');
      final result = parser.parse('   ');

      expect(result.isSuccess, isFalse);
      expect(result.errors.first.code, 'EMPTY_INPUT');
    });

    test('Ungeschlossene Klammer meldet UNCLOSED_PAREN mit exakter Position',
        () {
      const parser = WorkoutParser(sport: 'BIKE');
      final result = parser.parse("10' Z1, 4x(4' Z4 / 2' Z1");

      expect(result.isSuccess, isFalse);
      expect(result.errors.any((e) => e.code == 'UNCLOSED_PAREN'), isTrue);
    });

    test('Sportartenfremde Intensität meldet passenden Fehlercode', () {
      const parser = WorkoutParser(sport: 'SWIM');
      final result = parser.parse("400m Z1, 4x(100m 95%FTP / 20\"), 200m Z1");

      expect(result.isSuccess, isFalse);
      expect(result.errors.any((e) => e.code == 'FTP_NOT_ALLOWED'), isTrue);
    });

    test('Wiederholungsanzahl außerhalb 2..99 wird gemeldet', () {
      const parser = WorkoutParser(sport: 'BIKE');
      final result = parser.parse("10' Z1, 1x(4' Z4 / 2' Z1), 10' Z1");

      expect(result.isSuccess, isFalse);
      expect(
          result.errors.any((e) => e.code == 'INVALID_REPEAT_COUNT'), isTrue);
    });
  });
}
