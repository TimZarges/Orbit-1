import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../coach_link/providers/athlete_context_provider.dart';
import '../models/planned_workout.dart';
import '../providers/calendar_provider.dart';
import '../widgets/create_workout_dialog.dart';
import '../widgets/workout_card.dart';
import '../widgets/workout_detail_sheet.dart';

/// Haupt-Kalender-Screen von ORBIT: Wochen-, Monats- und Listenansicht
/// für Athleten und Trainer.
class CalendarScreen extends ConsumerWidget {
  /// Optionale ID des Athleten. Falls null, wird der aktuelle Kontext herangezogen.
  final String? athleteId;

  const CalendarScreen({super.key, this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAthleteId = athleteId ?? ref.watch(currentAthleteIdProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final summary = ref.watch(weekSummaryProvider(activeAthleteId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy', 'de').format(selectedDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // "Heute" Button
          TextButton.icon(
            onPressed: () {
              ref.read(selectedCalendarDateProvider.notifier).state = DateTime.now();
            },
            icon: const Icon(Icons.today, size: 18),
            label: const Text('Heute'),
          ),
          // Vorherige / Nächste Periode
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateDate(ref, viewMode, -1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateDate(ref, viewMode, 1),
          ),
        ],
      ),
      body: Column(
        children: [
          // View Mode Umschalter (Woche / Monat / Liste)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<CalendarViewMode>(
              segments: const [
                ButtonSegment(
                  value: CalendarViewMode.week,
                  icon: Icon(Icons.view_week_outlined),
                  label: Text('Woche'),
                ),
                ButtonSegment(
                  value: CalendarViewMode.month,
                  icon: Icon(Icons.calendar_month_outlined),
                  label: Text('Monat'),
                ),
                ButtonSegment(
                  value: CalendarViewMode.list,
                  icon: Icon(Icons.view_list_outlined),
                  label: Text('Liste'),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (newSelection) {
                ref.read(calendarViewModeProvider.notifier).state = newSelection.first;
              },
            ),
          ),

          // Wochen-Soll-Ist-Zusammenfassung (nur in Woche & Liste)
          if (viewMode != CalendarViewMode.month)
            _buildWeekSummaryCard(context, theme, isDark, summary),

          // Haupt-Inhalt je nach Ansicht
          Expanded(
            child: switch (viewMode) {
              CalendarViewMode.week => _buildWeekView(context, ref, activeAthleteId, selectedDate),
              CalendarViewMode.month => _buildMonthView(context, ref, activeAthleteId, selectedDate),
              CalendarViewMode.list => _buildListView(context, ref, activeAthleteId),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateWorkoutDialog(
          context,
          athleteId: activeAthleteId,
          initialDate: selectedDate,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Training planen'),
      ),
    );
  }

  void _navigateDate(WidgetRef ref, CalendarViewMode viewMode, int direction) {
    final current = ref.read(selectedCalendarDateProvider);
    if (viewMode == CalendarViewMode.month) {
      ref.read(selectedCalendarDateProvider.notifier).state =
          DateTime(current.year, current.month + direction, current.day);
    } else {
      ref.read(selectedCalendarDateProvider.notifier).state =
          current.add(Duration(days: direction * 7));
    }
  }

  /// Wochen-Zusammenfassungskarte mit Soll-Ist Abweichung
  Widget _buildWeekSummaryCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    WeekSummary summary,
  ) {
    final compliance = summary.durationCompliancePercentage;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final plannedHours = (summary.plannedDurationSec / 3600).toStringAsFixed(1);
    final actualHours = (summary.actualDurationSec / 3600).toStringAsFixed(1);

    Color progressColor = const Color(0xFF10B981);
    if (compliance < 75) progressColor = const Color(0xFFF59E0B);
    if (compliance > 130) progressColor = const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wochensoll: ${actualHours}h von ${plannedHours}h (${compliance.toStringAsFixed(0)} %)',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${summary.completedWorkoutsCount}/${summary.totalPlannedWorkoutsCount} Einheiten',
                style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (summary.plannedDurationSec > 0 ? summary.actualDurationSec / summary.plannedDurationSec : 0.0)
                  .clamp(0.0, 1.0),
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              color: progressColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// Wochenansicht: 7 scrollbare Wochentage
  Widget _buildWeekView(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    DateTime selectedDate,
  ) {
    final workoutsAsync = ref.watch(athleteCurrentWeekWorkoutsProvider(athleteId));
    final workouts = workoutsAsync.valueOrNull ?? [];

    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = monday.add(Duration(days: index));
        final dayStr = DateFormat('yyyy-MM-dd').format(day);
        final dayWorkouts = workouts.where((w) => w.localDate == dayStr).toList();
        final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dayStr;

        return _buildDaySection(context, day, dayWorkouts, isToday, athleteId);
      },
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<PlannedWorkout> workouts,
    bool isToday,
    String athleteId,
  ) {
    final theme = Theme.of(context);
    final weekdayName = DateFormat('EEEE', 'de').format(date);
    final dateNum = DateFormat('dd.MM.').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$weekdayName, $dateNum',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isToday ? AppColors.navyLight : null,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.volt.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Heute', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (workouts.isEmpty)
            InkWell(
              onTap: () => showCreateWorkoutDialog(context, athleteId: athleteId, initialDate: date),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '+ Ruhetag / Einheit planen',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            for (final w in workouts)
              WorkoutCard(
                workout: w,
                onTap: () => showWorkoutDetailSheet(context, w),
              ),
        ],
      ),
    );
  }

  /// Monatsansicht: Monatsraster mit Terminpunkten
  Widget _buildMonthView(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    DateTime selectedDate,
  ) {
    final workoutsAsync = ref.watch(athleteCurrentMonthWorkoutsProvider(athleteId));
    final workouts = workoutsAsync.valueOrNull ?? [];

    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    // Ausgewählter Tag im Monat
    final selectedDayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final selectedDayWorkouts = workouts.where((w) => w.localDate == selectedDayStr).toList();

    return Column(
      children: [
        // Wochentags-Header (Mo - So)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Mo', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Di', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Mi', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Do', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Fr', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sa', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('So', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),


        // Tage-Grid
        Expanded(
          flex: 2,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: lastDayOfMonth.day + (firstDayOfMonth.weekday - 1),
            itemBuilder: (context, index) {
              final offset = firstDayOfMonth.weekday - 1;
              if (index < offset) return const SizedBox.shrink();

              final dayNum = index - offset + 1;
              final dayDate = DateTime(selectedDate.year, selectedDate.month, dayNum);
              final dayStr = DateFormat('yyyy-MM-dd').format(dayDate);
              final dayWorkouts = workouts.where((w) => w.localDate == dayStr).toList();
              final isSelected = dayStr == selectedDayStr;

              return InkWell(
                onTap: () {
                  ref.read(selectedCalendarDateProvider.notifier).state = dayDate;
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navyLight.withValues(alpha: 0.15) : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: AppColors.navyLight) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (dayWorkouts.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < dayWorkouts.length.clamp(0, 3); i++)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // Liste der Einheiten des am Raster angetippten Tages
        Expanded(
          flex: 2,
          child: selectedDayWorkouts.isEmpty
              ? Center(
                  child: TextButton.icon(
                    onPressed: () => showCreateWorkoutDialog(
                      context,
                      athleteId: athleteId,
                      initialDate: selectedDate,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Einheit an diesem Tag planen'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: selectedDayWorkouts.length,
                  itemBuilder: (context, idx) {
                    final w = selectedDayWorkouts[idx];
                    return WorkoutCard(
                      workout: w,
                      onTap: () => showWorkoutDetailSheet(context, w),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Listenansicht: Chronologische Liste
  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
  ) {
    final workoutsAsync = ref.watch(athleteCurrentMonthWorkoutsProvider(athleteId));
    final workouts = workoutsAsync.valueOrNull ?? [];

    if (workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Keine geplanten Einheiten in diesem Zeitraum.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => showCreateWorkoutDialog(context, athleteId: athleteId),
              icon: const Icon(Icons.add),
              label: const Text('Erste Einheit planen'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final w = workouts[index];
        return WorkoutCard(
          workout: w,
          showDate: true,
          onTap: () => showWorkoutDetailSheet(context, w),
        );
      },
    );
  }
}
