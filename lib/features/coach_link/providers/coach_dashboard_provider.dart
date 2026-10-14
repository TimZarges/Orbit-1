import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coach_dashboard_athlete.dart';
import '../models/coach_view_preference.dart';

/// Provider für die aktuellen Ansichts- und Filtereinstellungen des Trainers.
final coachActivePreferenceProvider = StateProvider<CoachViewPreference>((ref) {
  return CoachViewPreference.defaultView;
});

/// Provider für gespeicherte Ansichten des Trainers aus `users/{coachId}/preferences/{viewId}`.
final coachSavedPreferencesProvider =
    StreamProvider.family<List<CoachViewPreference>, String>((ref, coachId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('users')
      .doc(coachId)
      .collection('preferences')
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return [
        CoachViewPreference.defaultView,
        CoachViewPreference.focusAlertsView,
        CoachViewPreference.complianceView,
      ];
    }
    return snapshot.docs
        .map((doc) => CoachViewPreference.fromMap(doc.id, doc.data()))
        .toList();
  });
});

/// Raw Stream der aggregierten Athleten-Dokumente aus `coachDashboard/{coachId}/athletes`.
final coachRawAthletesStreamProvider =
    StreamProvider.family<List<CoachDashboardAthlete>, String>((ref, coachId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('coachDashboard')
      .doc(coachId)
      .collection('athletes')
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      // Wenn noch keine Dokumente vorliegen (z.B. Demo / Dev), erzeuge realistische Demo-Athleten
      return _generateDemoAthletes(coachId);
    }
    return snapshot.docs
        .map((doc) => CoachDashboardAthlete.fromFirestore(doc))
        .toList();
  });
});

/// Suchfilter-String für die Tastatursuche (Cmd+K / /).
final coachAthleteSearchQueryProvider = StateProvider<String>((ref) => '');

/// Ausgewählte Athleten-IDs für Batch-Aktionen / Massenzuweisung.
final coachSelectedAthleteIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Aufbereiteter Provider: Gefilterte und sortierte Athletenliste für die Tabelle / das Dashboard.
final coachFilteredAthletesProvider =
    Provider.family<List<CoachDashboardAthlete>, String>((ref, coachId) {
  final rawList =
      ref.watch(coachRawAthletesStreamProvider(coachId)).valueOrNull ?? [];
  final pref = ref.watch(coachActivePreferenceProvider);
  final searchQuery =
      ref.watch(coachAthleteSearchQueryProvider).toLowerCase().trim();

  return rawList.where((a) {
    // 1. Suche
    if (searchQuery.isNotEmpty) {
      final matchesName = a.name.toLowerCase().contains(searchQuery);
      final matchesSport = a.sport.toLowerCase().contains(searchQuery);
      if (!matchesName && !matchesSport) return false;
    }

    // 2. Sportart-Filter
    if (pref.filterSport != null && pref.filterSport!.isNotEmpty) {
      if (a.sport != pref.filterSport) return false;
    }

    // 3. Form-Status-Filter
    if (pref.filterFormStatus != null && pref.filterFormStatus!.isNotEmpty) {
      if (a.formStatus.name != pref.filterFormStatus) return false;
    }

    // 4. Nur Alerts
    if (pref.alertOnly && a.alert == null) {
      return false;
    }

    return true;
  }).toList()
    ..sort((a, b) {
      int cmp = 0;
      switch (pref.sortField) {
        case 'compliance7d':
          cmp = a.compliance7d.compareTo(b.compliance7d);
          break;
        case 'ctl':
          cmp = a.ctl.compareTo(b.ctl);
          break;
        case 'daysRemaining':
          final aDays = (a.raceGoal?['daysRemaining'] as num?)?.toInt() ?? 9999;
          final bDays = (b.raceGoal?['daysRemaining'] as num?)?.toInt() ?? 9999;
          cmp = aDays.compareTo(bDays);
          break;
        case 'name':
        default:
          cmp = a.name.compareTo(b.name);
          break;
      }
      return pref.sortAscending ? cmp : -cmp;
    });
});

/// Erzeugt 28 realistische Demo-Athleten für Dev / Offline / Lasttests.
List<CoachDashboardAthlete> _generateDemoAthletes(String coachId) {
  final firstNames = [
    'Lukas',
    'Julia',
    'Felix',
    'Sophie',
    'Maximilian',
    'Hannah',
    'Leon',
    'Marie',
    'David',
    'Laura',
    'Jonas',
    'Lena',
    'Tim',
    'Sarah',
    'Paul',
    'Emma',
    'Niklas',
    'Mia',
    'Moritz',
    'Anna',
    'Florian',
    'Clara',
    'Simon',
    'Lara',
    'Tobias',
    'Lea',
    'Jan',
    'Lisa'
  ];
  final lastNames = [
    'Weber',
    'Müller',
    'Schmidt',
    'Schneider',
    'Fischer',
    'Meyer',
    'Wagner',
    'Becker',
    'Schulz',
    'Hoffmann',
    'Schäfer',
    'Koch',
    'Bauer',
    'Richter',
    'Klein',
    'Wolf',
    'Schröder',
    'Neumann',
    'Schwarz',
    'Zimmermann',
    'Braun',
    'Krüger',
    'Hofmann',
    'Hartmann',
    'Lange',
    'Schmitt',
    'Werner',
    'Schmitz'
  ];
  final sports = ['TRIATHLON', 'RUN', 'BIKE', 'SWIM'];
  final formStatuses = [
    CoachAthleteFormStatus.optimal,
    CoachAthleteFormStatus.wellLoaded,
    CoachAthleteFormStatus.caution,
    CoachAthleteFormStatus.fresh,
    CoachAthleteFormStatus.optimal,
    CoachAthleteFormStatus.wellLoaded,
    CoachAthleteFormStatus.building,
  ];

  return List.generate(firstNames.length, (i) {
    final athleteId = 'ath_demo_${i + 1}';
    final name = '${firstNames[i]} ${lastNames[i]}';
    final sport = sports[i % sports.length];
    final formStatus = formStatuses[i % formStatuses.length];
    final ctl = 40 + (i * 3) % 60;
    final atl = formStatus == CoachAthleteFormStatus.caution
        ? ctl + 22
        : ctl + ((i % 5) - 2) * 4;
    final tsb = ctl - atl;
    final plannedLoad7d = 260 + (i * 25) % 320;
    final compliance7d = [96, 85, 100, 68, 88, 104, 76, 92, 54, 90][i % 10];
    final actualLoad7d = (plannedLoad7d * compliance7d) ~/ 100;
    final raceDays = 14 + (i * 14) % 160;

    return CoachDashboardAthlete(
      athleteId: athleteId,
      coachId: coachId,
      name: name,
      sport: sport,
      formStatus: formStatus,
      ctl: ctl,
      atl: atl,
      tsb: tsb,
      compliance7d: compliance7d,
      actualLoad7d: actualLoad7d,
      plannedLoad7d: plannedLoad7d,
      unreadMessagesCount: i % 4 == 0 ? (i % 3) + 1 : 0,
      pendingProposalsCount: i % 5 == 0 ? 1 : 0,
      latestActivity: {
        'date': '2026-10-12',
        'title': sport == 'BIKE'
            ? 'Grundlagenfahrt'
            : sport == 'RUN'
                ? 'Tempodauerlauf'
                : 'Technikblock',
        'sport': sport,
        'load': 45 + (i * 6) % 75,
      },
      raceGoal: {
        'title': sport == 'TRIATHLON'
            ? 'Challenge Roth'
            : sport == 'RUN'
                ? 'Berlin Marathon'
                : 'Cyclassics',
        'date': '2027-06-20',
        'daysRemaining': raceDays,
      },
      alert: i == 3
          ? 'NO_ACTIVITY_7D'
          : i == 7
              ? 'LOAD_SPIKE'
              : null,
      updatedAt: DateTime.now(),
    );
  });
}
