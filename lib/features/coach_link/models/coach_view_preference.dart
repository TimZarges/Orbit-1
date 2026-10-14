/// Modell für konfigurierbare und speicherbare Ansichten des Coach-Dashboards (`users/{coachId}/preferences/{viewId}`).
class CoachViewPreference {
  final String id;
  final String name;
  final List<String> visibleColumns;
  final String sortField; // 'name', 'compliance7d', 'ctl', 'daysRemaining'
  final bool sortAscending;
  final String? filterSport; // null = alle, 'TRIATHLON', 'RUN', 'BIKE', 'SWIM'
  final String? filterFormStatus;
  final bool alertOnly;

  const CoachViewPreference({
    required this.id,
    required this.name,
    this.visibleColumns = const [
      'name',
      'sport',
      'form',
      'compliance',
      'load7d',
      'raceGoal',
      'lastActivity',
      'alerts',
    ],
    this.sortField = 'name',
    this.sortAscending = true,
    this.filterSport,
    this.filterFormStatus,
    this.alertOnly = false,
  });

  factory CoachViewPreference.fromMap(String id, Map<String, dynamic> map) {
    return CoachViewPreference(
      id: id,
      name: map['name'] as String? ?? 'Standard',
      visibleColumns: (map['visibleColumns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'name',
            'sport',
            'form',
            'compliance',
            'load7d',
            'raceGoal',
            'lastActivity',
            'alerts',
          ],
      sortField: map['sortField'] as String? ?? 'name',
      sortAscending: map['sortAscending'] as bool? ?? true,
      filterSport: map['filterSport'] as String?,
      filterFormStatus: map['filterFormStatus'] as String?,
      alertOnly: map['alertOnly'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'visibleColumns': visibleColumns,
      'sortField': sortField,
      'sortAscending': sortAscending,
      'filterSport': filterSport,
      'filterFormStatus': filterFormStatus,
      'alertOnly': alertOnly,
    };
  }

  CoachViewPreference copyWith({
    String? id,
    String? name,
    List<String>? visibleColumns,
    String? sortField,
    bool? sortAscending,
    String? filterSport,
    String? filterFormStatus,
    bool? alertOnly,
  }) {
    return CoachViewPreference(
      id: id ?? this.id,
      name: name ?? this.name,
      visibleColumns: visibleColumns ?? this.visibleColumns,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      filterSport: filterSport ?? this.filterSport,
      filterFormStatus: filterFormStatus ?? this.filterFormStatus,
      alertOnly: alertOnly ?? this.alertOnly,
    );
  }

  static const CoachViewPreference defaultView = CoachViewPreference(
    id: 'default',
    name: 'Standard-Kader',
  );

  static const CoachViewPreference focusAlertsView = CoachViewPreference(
    id: 'alerts',
    name: 'Auffälligkeiten & Alerts',
    alertOnly: true,
  );

  static const CoachViewPreference complianceView = CoachViewPreference(
    id: 'compliance',
    name: 'Soll-Ist Erfüllung',
    sortField: 'compliance7d',
    sortAscending: true,
  );
}
