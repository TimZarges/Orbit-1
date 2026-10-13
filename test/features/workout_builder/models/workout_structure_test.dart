import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/workout_builder/models/workout_builder_models.dart';

void main() {
  group('WorkoutTarget', () {
    test('Dauer-Ziel erzeugt korrektes JSON und Display-String', () {
      const target = WorkoutTarget.duration(600);
      expect(target.isDuration, isTrue);
      expect(target.isDistance, isFalse);
      expect(target.durationSec, 600);
      expect(target.formattedDisplay, '10 min');
      expect(target.toJson(), {'durationSec': 600});

      final fromJson = WorkoutTarget.fromJson(target.toJson());
      expect(fromJson, equals(target));
    });

    test('Sekunden-Ziel unter 1 Minute formatiert korrekt mit "', () {
      const target = WorkoutTarget.duration(30);
      expect(target.formattedDisplay, '30"');
    });

    test('Stunden-Ziel formatiert korrekt', () {
      const target1 = WorkoutTarget.duration(3600);
      expect(target1.formattedDisplay, '1h');
      const target2 = WorkoutTarget.duration(5400);
      expect(target2.formattedDisplay, '1h 30min');
    });

    test('Distanz-Ziel erzeugt korrektes JSON und Display-String', () {
      const targetMeters = WorkoutTarget.distance(400);
      expect(targetMeters.isDistance, isTrue);
      expect(targetMeters.formattedDisplay, '400 m');
      expect(targetMeters.toJson(), {'distanceM': 400});

      const targetKm = WorkoutTarget.distance(2500);
      expect(targetKm.formattedDisplay, '2.5 km');

      const targetEvenKm = WorkoutTarget.distance(2000);
      expect(targetEvenKm.formattedDisplay, '2 km');

      final fromJson = WorkoutTarget.fromJson(targetKm.toJson());
      expect(fromJson, equals(targetKm));
    });
  });

  group('WorkoutCadence', () {
    test('JSON Serialisierung und Display-String', () {
      const cadence = WorkoutCadence(low: 85, high: 95);
      expect(cadence.toJson(), {'low': 85, 'high': 95});
      expect(cadence.formattedDisplay(), '85-95 rpm');
      expect(cadence.formattedDisplay(unit: 'spm'), '85-95 spm');

      final fromJson = WorkoutCadence.fromJson(cadence.toJson());
      expect(fromJson, equals(cadence));
    });
  });

  group('WorkoutIntensity', () {
    test('ZoneIntensity', () {
      const zoneRange = ZoneIntensity(low: 2, high: 3);
      expect(zoneRange.kind, 'ZONE');
      expect(zoneRange.formattedDisplay, 'Z2-Z3');
      expect(zoneRange.toJson(), {'kind': 'ZONE', 'low': 2, 'high': 3});
      expect(WorkoutIntensity.fromJson(zoneRange.toJson()), equals(zoneRange));

      const zoneSingle = ZoneIntensity.single(4);
      expect(zoneSingle.formattedDisplay, 'Z4');
    });

    test('PctFtpIntensity (nur BIKE erlaubt)', () {
      const ftp = PctFtpIntensity(low: 90, high: 95);
      expect(ftp.kind, 'PCT_FTP');
      expect(ftp.formattedDisplay, '90-95% FTP');
      expect(ftp.isAllowedForSport('BIKE'), isTrue);
      expect(ftp.isAllowedForSport('RUN'), isFalse);
      expect(ftp.isAllowedForSport('SWIM'), isFalse);
      expect(WorkoutIntensity.fromJson(ftp.toJson()), equals(ftp));
    });

    test('PctLthrIntensity (BIKE und RUN erlaubt)', () {
      const lthr = PctLthrIntensity.single(88);
      expect(lthr.kind, 'PCT_LTHR');
      expect(lthr.formattedDisplay, '88% LTHR');
      expect(lthr.isAllowedForSport('BIKE'), isTrue);
      expect(lthr.isAllowedForSport('RUN'), isTrue);
      expect(lthr.isAllowedForSport('SWIM'), isFalse);
      expect(WorkoutIntensity.fromJson(lthr.toJson()), equals(lthr));
    });

    test('PaceIntensity (nur RUN erlaubt)', () {
      const pace = PaceIntensity(secPerKm: 270); // 4:30 min/km
      expect(pace.kind, 'PACE');
      expect(pace.formattedDisplay, '@4:30/km');
      expect(pace.isAllowedForSport('RUN'), isTrue);
      expect(pace.isAllowedForSport('BIKE'), isFalse);
      expect(WorkoutIntensity.fromJson(pace.toJson()), equals(pace));
    });

    test('SwimPaceIntensity & CssOffsetIntensity (nur SWIM erlaubt)', () {
      const swimPace = SwimPaceIntensity(secPer100m: 105); // 1:45 /100m
      expect(swimPace.formattedDisplay, '@1:45/100m');
      expect(swimPace.isAllowedForSport('SWIM'), isTrue);
      expect(swimPace.isAllowedForSport('RUN'), isFalse);
      expect(WorkoutIntensity.fromJson(swimPace.toJson()), equals(swimPace));

      const cssZero = CssOffsetIntensity(offsetSecPer100m: 0);
      expect(cssZero.formattedDisplay, 'CSS');
      const cssPlus = CssOffsetIntensity(offsetSecPer100m: 5);
      expect(cssPlus.formattedDisplay, 'CSS+5"');
      const cssMinus = CssOffsetIntensity(offsetSecPer100m: -3);
      expect(cssMinus.formattedDisplay, 'CSS-3"');
      expect(cssPlus.isAllowedForSport('SWIM'), isTrue);
      expect(WorkoutIntensity.fromJson(cssPlus.toJson()), equals(cssPlus));
    });

    test('FreeIntensity', () {
      const free = FreeIntensity();
      expect(free.kind, 'FREE');
      expect(free.formattedDisplay, 'Frei');
      expect(free.isAllowedForSport('STRENGTH'), isTrue);
      expect(free.isAllowedForSport('BIKE'), isTrue);
      expect(WorkoutIntensity.fromJson(free.toJson()), equals(free));
    });
  });

  group('WorkoutStructure & Blocks (Schema v1)', () {
    test('Round-Trip Deserialisierung einer komplexen Einheit', () {
      const structure = WorkoutStructure(
        schemaVersion: 1,
        sport: 'BIKE',
        blocks: [
          StepBlock(
            role: WorkoutRole.warmup,
            target: WorkoutTarget.duration(600),
            intensity: ZoneIntensity.single(1),
            note: 'Locker einrollen',
          ),
          RepeatBlock(
            count: 4,
            blocks: [
              StepBlock(
                role: WorkoutRole.work,
                target: WorkoutTarget.duration(240),
                intensity: ZoneIntensity.single(4),
                cadence: WorkoutCadence(low: 90, high: 95),
              ),
              StepBlock(
                role: WorkoutRole.rest,
                target: WorkoutTarget.duration(120),
                intensity: ZoneIntensity.single(1),
              ),
            ],
          ),
          StepBlock(
            role: WorkoutRole.cooldown,
            target: WorkoutTarget.duration(600),
            intensity: ZoneIntensity.single(1),
          ),
        ],
      );

      expect(structure.isValid, isTrue);
      expect(structure.validate(), isEmpty);
      expect(structure.maxDepth, 2);
      expect(structure.totalStepsCount, 1 + (4 * 2) + 1); // 10 Schritte

      final json = structure.toJson();
      final restored = WorkoutStructure.fromJson(json);
      expect(restored, equals(structure));
    });

    test('Verschachtelte Wiederholungen bis Tiefe 3 sind valide', () {
      const structure = WorkoutStructure(
        sport: 'SWIM',
        blocks: [
          RepeatBlock(
            count: 2,
            blocks: [
              RepeatBlock(
                count: 4,
                blocks: [
                  StepBlock(
                    role: WorkoutRole.work,
                    target: WorkoutTarget.distance(50),
                    intensity: ZoneIntensity.single(5),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(structure.maxDepth, 3);
      expect(structure.isValid, isTrue);
    });

    test('Tiefe 4 wird durch Validierung abgelehnt', () {
      const structure = WorkoutStructure(
        sport: 'RUN',
        blocks: [
          RepeatBlock(
            count: 2,
            blocks: [
              RepeatBlock(
                count: 2,
                blocks: [
                  RepeatBlock(
                    count: 2,
                    blocks: [
                      StepBlock(
                        role: WorkoutRole.work,
                        target: WorkoutTarget.duration(60),
                        intensity: ZoneIntensity.single(4),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(structure.maxDepth, 4);
      final errors = structure.validate();
      expect(errors.any((e) => e.contains('Verschachtelungstiefe')), isTrue);
    });

    test('Sportartenfremde Intensität wird durch Validierung abgelehnt', () {
      const bikeWithRunPace = WorkoutStructure(
        sport: 'BIKE',
        blocks: [
          StepBlock(
            role: WorkoutRole.work,
            target: WorkoutTarget.duration(300),
            intensity: PaceIntensity(secPerKm: 270), // Pace ist RUN-spezifisch
          ),
        ],
      );

      final errors = bikeWithRunPace.validate();
      expect(errors.any((e) => e.contains('nicht zulässig')), isTrue);
    });

    test('migrateStructure weist unbekannte schemaVersion ab', () {
      expect(
        () => WorkoutStructure.migrateStructure({'schemaVersion': 2}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => WorkoutStructure.migrateStructure({'sport': 'BIKE'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
