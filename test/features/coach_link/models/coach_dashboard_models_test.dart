import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/features/coach_link/models/coach_dashboard_athlete.dart';
import 'package:orbit/features/coach_link/models/coach_view_preference.dart';

void main() {
  group('CoachDashboard Models Tests', () {
    test('CoachDashboardAthlete serialization and deserialization', () {
      final athlete = CoachDashboardAthlete(
        athleteId: 'a123',
        coachId: 'c456',
        name: 'Max Mustermann',
        sport: 'TRIATHLON',
        formStatus: CoachAthleteFormStatus.optimal,
        ctl: 55,
        atl: 52,
        tsb: 3,
        compliance7d: 92,
        actualLoad7d: 380,
        plannedLoad7d: 410,
        unreadMessagesCount: 2,
        pendingProposalsCount: 1,
        alert: 'LOAD_SPIKE',
      );

      final map = athlete.toMap();
      expect(map['athleteId'], equals('a123'));
      expect(map['formStatus'], equals('optimal'));
      expect(map['compliance7d'], equals(92));

      final restored = CoachDashboardAthlete.fromMap('a123', map);
      expect(restored.athleteId, equals('a123'));
      expect(restored.name, equals('Max Mustermann'));
      expect(restored.formStatus, equals(CoachAthleteFormStatus.optimal));
      expect(restored.formStatusLabelDe, equals('Optimal'));
      expect(restored.alertLabelDe, equals('Starker Belastungssprung'));
    });

    test('CoachViewPreference default presets and copyWith', () {
      const defaultPref = CoachViewPreference.defaultView;
      expect(defaultPref.id, equals('default'));
      expect(defaultPref.alertOnly, isFalse);

      final modified = defaultPref.copyWith(
        filterSport: 'BIKE',
        alertOnly: true,
      );

      expect(modified.filterSport, equals('BIKE'));
      expect(modified.alertOnly, isTrue);
      expect(modified.sortField, equals('name'));
    });
  });
}
