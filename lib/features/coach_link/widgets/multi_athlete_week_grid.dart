import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../calendar/models/planned_workout.dart';
import '../models/coach_dashboard_athlete.dart';

/// Mehrathleten-Wochenraster für Trainer mit Drag & Drop und Alt-Kopieren.
class MultiAthleteWeekGrid extends StatefulWidget {
  final List<CoachDashboardAthlete> athletes;
  final String coachId;
  final Function(PlannedWorkout workout, String targetAthleteId, String targetDate, bool isCopy) onDrop;
  final Function(String athleteId, String name) onAthleteClick;

  const MultiAthleteWeekGrid({
    super.key,
    required this.athletes,
    required this.coachId,
    required this.onDrop,
    required this.onAthleteClick,
  });

  @override
  State<MultiAthleteWeekGrid> createState() => _MultiAthleteWeekGridState();
}

class _MultiAthleteWeekGridState extends State<MultiAthleteWeekGrid> {
  late DateTime _weekStart;
  bool _isCompactDensity = false;

  // Lokale Repräsentation geplanter Einheiten im Gitter für sofortiges Feedback
  final Map<String, List<PlannedWorkout>> _gridWorkouts = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Montag der aktuellen Woche
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _seedMockWorkouts();
  }

  void _seedMockWorkouts() {
    // Erzeugt ein paar anschauliche Workouts für das Raster
    for (var i = 0; i < widget.athletes.length; i++) {
      final a = widget.athletes[i];
      final athleteId = a.athleteId;
      _gridWorkouts[athleteId] = [];

      for (var d = 0; d < 7; d++) {
        final date = _weekStart.add(Duration(days: d));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        if ((i + d) % 3 == 0) {
          final sport = a.sport == 'TRIATHLON' ? (d % 2 == 0 ? 'BIKE' : 'RUN') : a.sport;
          _gridWorkouts[athleteId]!.add(PlannedWorkout(
            id: 'pw_${athleteId}_$d',
            athleteId: athleteId,
            coachId: widget.coachId,
            createdBy: widget.coachId,
            localDate: dateStr,
            sport: sport,
            title: sport == 'BIKE' ? '2h GA1 mit 4x30s Sprint' : '10km Tempodauerlauf',
            plannedDurationSec: 3600 + (d * 600),
            plannedLoad: 55.0 + (d * 10),
            status: PlannedWorkoutStatus.planned,
            createdAt: DateTime.now(),
          ));
        }
      }
    }
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _seedMockWorkouts();
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _seedMockWorkouts();
    });
  }

  void _currentWeek() {
    final now = DateTime.now();
    setState(() {
      _weekStart = now.subtract(Duration(days: now.weekday - 1));
      _seedMockWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final dayFormat = DateFormat('E, dd.MM.', 'de');

    return Column(
      children: [
        // Steuerungsleiste
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
                tooltip: 'Vorherige Woche',
              ),
              Text(
                'KW ${((_weekStart.difference(DateTime(_weekStart.year, 1, 1)).inDays) / 7).ceil()}: '
                '${DateFormat('dd.MM.').format(_weekStart)} – ${DateFormat('dd.MM.yyyy').format(days.last)}',
                style: AppTypography.title.copyWith(fontSize: 15, color: AppColors.navy),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
                tooltip: 'Nächste Woche',
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _currentWeek,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                child: const Text('Heute', style: TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isCompactDensity ? Icons.density_small : Icons.density_medium),
                tooltip: 'Dichte umschalten',
                onPressed: () => setState(() => _isCompactDensity = !_isCompactDensity),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Raster
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1000),
                child: Table(
                  defaultColumnWidth: const FixedColumnWidth(130),
                  columnWidths: const {
                    0: FixedColumnWidth(180), // Athleten-Spalte
                  },
                  border: TableBorder.all(color: Colors.grey.shade200),
                  children: [
                    // Kopfzeile: Tage
                    TableRow(
                      decoration: const BoxDecoration(color: AppColors.techGrey),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('Athlet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        ...days.map((d) => Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                dayFormat.format(d),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: d.day == DateTime.now().day && d.month == DateTime.now().month
                                      ? AppColors.navy
                                      : Colors.grey.shade700,
                                ),
                              ),
                            )),
                      ],
                    ),

                    // Zeilen pro Athlet
                    ...widget.athletes.map((athlete) {
                      final athleteWorkouts = _gridWorkouts[athlete.athleteId] ?? [];

                      return TableRow(
                        children: [
                          // Athleten-Zelle
                          InkWell(
                            onTap: () => widget.onAthleteClick(athlete.athleteId, athlete.name),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    athlete.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${athlete.sport} · ${athlete.ctl} CTL',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 7 Wochentage
                          ...days.map((day) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(day);
                            final dayWorkouts = athleteWorkouts.where((w) => w.localDate == dateStr).toList();

                            return DragTarget<PlannedWorkout>(
                              onAcceptWithDetails: (details) {
                                final isAltPressed = HardwareKeyboard.instance.isAltPressed;
                                widget.onDrop(details.data, athlete.athleteId, dateStr, isAltPressed);

                                setState(() {
                                  if (!isAltPressed) {
                                    // Altes entfernen
                                    _gridWorkouts[details.data.athleteId]?.removeWhere((w) => w.id == details.data.id);
                                  }
                                  // Neues hinzufügen
                                  final newW = details.data.copyWith(
                                    id: isAltPressed ? 'copy_${DateTime.now().millisecondsSinceEpoch}' : details.data.id,
                                    athleteId: athlete.athleteId,
                                    localDate: dateStr,
                                  );
                                  _gridWorkouts.putIfAbsent(athlete.athleteId, () => []).add(newW);
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    content: Text(
                                      isAltPressed
                                          ? 'Kopiert nach ${athlete.name} ($dateStr)'
                                          : 'Verschoben nach ${athlete.name} ($dateStr)',
                                    ),
                                  ),
                                );
                              },
                              builder: (context, candidateData, rejectedData) {
                                final isHovered = candidateData.isNotEmpty;

                                return Container(
                                  minHeight: _isCompactDensity ? 54 : 76,
                                  color: isHovered ? AppColors.volt.withValues(alpha: 0.15) : Colors.transparent,
                                  padding: const EdgeInsets.all(4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      ...dayWorkouts.map((workout) {
                                        return Draggable<PlannedWorkout>(
                                          data: workout,
                                          feedback: Material(
                                            elevation: 4,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getSportColor(workout.sport),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                workout.title,
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.3,
                                            child: _buildWorkoutChip(workout),
                                          ),
                                          child: _buildWorkoutChip(workout),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutChip(PlannedWorkout workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _getSportColor(workout.sport).withValues(alpha: 0.16),
        border: Border.all(color: _getSportColor(workout.sport).withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getSportIcon(workout.sport), size: 12, color: _getSportColor(workout.sport)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  workout.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          if (!_isCompactDensity && workout.plannedLoad != null) ...[
            Text(
              '${workout.plannedLoad!.round()} TSS',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSportColor(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'SWIM':
        return AppColors.sportSwim;
      default:
        return AppColors.navyLight;
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }
}
