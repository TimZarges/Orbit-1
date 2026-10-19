import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/utils/orbit_date_formatter.dart';
import '../../activities/models/activity.dart';
import '../../activities/providers/activities_provider.dart';
import '../../activities/screens/activity_detail_screen.dart';
import '../../coach_link/providers/athlete_context_provider.dart';
import '../models/planned_workout.dart';
import '../providers/calendar_provider.dart';
import '../widgets/create_workout_dialog.dart';
import '../widgets/workout_card.dart';
import '../widgets/workout_detail_sheet.dart';

/// Haupt-Kalender-Screen von ORBIT: Wochen-, Monats- und Listenansicht
/// für Athleten und Trainer.
/// Zeigt sowohl geplante Einheiten ([PlannedWorkout]) als auch absolvierte
/// Garmin- und Datei-Aktivitäten ([Activity]) mit direkter Navigation ins Analyse-Cockpit.
class CalendarScreen extends ConsumerWidget {
  /// Optionale ID des Athleten. Falls null, wird der aktuelle Kontext herangezogen.
  final String? athleteId;

  const CalendarScreen({super.key, this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String activeAthleteId =
        athleteId ?? (ref.watch(viewedAthleteIdProvider) ?? 'me');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final summary = ref.watch(weekSummaryProvider(activeAthleteId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          OrbitDateFormatter.formatMonthYear(selectedDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // "Heute" Button
          TextButton.icon(
            onPressed: () {
              ref.read(selectedCalendarDateProvider.notifier).state =
                  DateTime.now();
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
                ref.read(calendarViewModeProvider.notifier).state =
                    newSelection.first;
              },
            ),
          ),

          // Wochen-Soll-Ist-Zusammenfassung (nur in Woche & Liste)
          if (viewMode != CalendarViewMode.month)
            _buildWeekSummaryCard(context, theme, isDark, summary),

          // Haupt-Inhalt je nach Ansicht
          Expanded(
            child: switch (viewMode) {
              CalendarViewMode.week =>
                _buildWeekView(context, ref, activeAthleteId, selectedDate),
              CalendarViewMode.month =>
                _buildMonthView(context, ref, activeAthleteId, selectedDate),
              CalendarViewMode.list =>
                _buildListView(context, ref, activeAthleteId),
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
    final cardBg = isDark ? const Color(0xFF002A5C) : const Color(0xFFF8FAFC);
    final cardBorder =
        isDark ? const Color(0xFF003D82) : const Color(0xFFE2E8F0);

    final plannedHours = (summary.plannedDurationSec / 3600).toStringAsFixed(1);
    final actualHours = (summary.actualDurationSec / 3600).toStringAsFixed(1);

    Color progressColor = const Color(0xFF10B981);
    if (compliance < 75) progressColor = const Color(0xFFF59E0B);
    if (compliance > 130) progressColor = const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wochensoll: ${actualHours}h von ${plannedHours}h (${compliance.toStringAsFixed(0)} %)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${summary.trainingDaysCount} aktive Tage · ${summary.completedWorkoutsCount}/${summary.totalPlannedWorkoutsCount} geplant',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (summary.plannedDurationSec > 0
                      ? summary.actualDurationSec / summary.plannedDurationSec
                      : (summary.actualDurationSec > 0 ? 1.0 : 0.0))
                  .clamp(0.0, 1.0),
              backgroundColor:
                  isDark ? const Color(0xFF001F47) : const Color(0xFFE2E8F0),
              color: progressColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// Wochenansicht: 7 scrollbare Wochentage inkl. absolvierter Aktivitäten
  Widget _buildWeekView(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    DateTime selectedDate,
  ) {
    final workoutsAsync =
        ref.watch(athleteCurrentWeekWorkoutsProvider(athleteId));
    final workouts = workoutsAsync.valueOrNull ?? [];
    final activities = ref.watch(activitiesProvider).valueOrNull ?? [];

    final monday =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = monday.add(Duration(days: index));
        final dayStr = DateFormat('yyyy-MM-dd').format(day);
        final dayWorkouts =
            workouts.where((w) => w.localDate == dayStr).toList();
        final dayActivities =
            activities.where((a) => a.localDate == dayStr).toList();
        final isToday =
            DateFormat('yyyy-MM-dd').format(DateTime.now()) == dayStr;

        return _buildDaySection(
          context,
          day,
          dayWorkouts,
          dayActivities,
          isToday,
          athleteId,
        );
      },
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<PlannedWorkout> workouts,
    List<Activity> activities,
    bool isToday,
    String athleteId,
  ) {
    final theme = Theme.of(context);
    final formattedHeaderDate = OrbitDateFormatter.formatWeekdayDate(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formattedHeaderDate,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isToday ? AppColors.navyLight : null,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.volt.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Heute',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (workouts.isEmpty && activities.isEmpty)
            InkWell(
              onTap: () => showCreateWorkoutDialog(context,
                  athleteId: athleteId, initialDate: date),
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
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ),
            )
          else ...[
            for (final a in activities)
              _buildCompletedActivityCard(context, a, showDate: false),
            for (final w in workouts)
              WorkoutCard(
                workout: w,
                onTap: () => showWorkoutDetailSheet(context, w),
              ),
          ],
        ],
      ),
    );
  }

  /// Monatsansicht: Monatsraster mit Terminpunkten für absolvierte Aktivitäten und geplante Workouts
  Widget _buildMonthView(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    DateTime selectedDate,
  ) {
    final workoutsAsync =
        ref.watch(athleteCurrentMonthWorkoutsProvider(athleteId));
    final workouts = workoutsAsync.valueOrNull ?? [];
    final activities = ref.watch(activitiesProvider).valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0);

    // Ausgewählter Tag im Monat
    final selectedDayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final selectedDayWorkouts =
        workouts.where((w) => w.localDate == selectedDayStr).toList();
    final selectedDayActivities =
        activities.where((a) => a.localDate == selectedDayStr).toList();

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
              final dayDate =
                  DateTime(selectedDate.year, selectedDate.month, dayNum);
              final dayStr = DateFormat('yyyy-MM-dd').format(dayDate);
              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final isToday = dayStr == todayStr;
              final isSelected = dayStr == selectedDayStr;
              final dayWorkouts =
                  workouts.where((w) => w.localDate == dayStr).toList();
              final dayActivities =
                  activities.where((a) => a.localDate == dayStr).toList();

              Color? cellBg;
              Border? cellBorder;
              Color textColor;

              if (isToday) {
                cellBg = AppColors.volt;
                textColor = AppColors.navy;
                cellBorder = Border.all(color: AppColors.volt, width: 2);
              } else if (isSelected) {
                cellBg = isDark
                    ? const Color(0xFF003D82)
                    : AppColors.volt.withValues(alpha: 0.25);
                textColor = isDark ? AppColors.white : AppColors.navy;
                cellBorder = Border.all(color: AppColors.volt, width: 1.5);
              } else {
                cellBg = isDark ? const Color(0xFF00224D) : null;
                textColor = isDark ? AppColors.white : AppColors.navy;
                cellBorder = Border.all(
                  color: isDark ? const Color(0xFF003366) : Colors.black12,
                  width: 0.5,
                );
              }

              // Kombinierte Indikatoren (absolvierte Aktivitäten gefüllt, geplante hohl/gefüllt)
              final dotEntries = <({Color color, bool filled})>[
                for (final a in dayActivities)
                  (color: _getSportColor(a.sport), filled: true),
                for (final w in dayWorkouts)
                  (color: _getSportColor(w.sport), filled: w.isCompleted),
              ];

              return InkWell(
                onTap: () {
                  ref.read(selectedCalendarDateProvider.notifier).state =
                      dayDate;
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(8),
                    border: cellBorder,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontWeight: (isToday || isSelected)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                      if (dotEntries.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0;
                                  i < dotEntries.length.clamp(0, 4);
                                  i++) ...[
                                () {
                                  final entry = dotEntries[i];
                                  final sColor = entry.color;
                                  final isDone = entry.filled;

                                  return Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? (isToday ? AppColors.navy : sColor)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            isToday ? AppColors.navy : sColor,
                                        width: 1.5,
                                      ),
                                    ),
                                  );
                                }(),
                              ],
                            ],
                          ),
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
          child: (selectedDayWorkouts.isEmpty && selectedDayActivities.isEmpty)
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  children: [
                    for (final a in selectedDayActivities)
                      _buildCompletedActivityCard(context, a, showDate: false),
                    for (final w in selectedDayWorkouts)
                      WorkoutCard(
                        workout: w,
                        onTap: () => showWorkoutDetailSheet(context, w),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Listenansicht: Chronologische Liste aller absolvierten Aktivitäten und geplanten Workouts
  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
  ) {
    final workoutsAsync =
        ref.watch(athleteCurrentMonthWorkoutsProvider(athleteId));
    final workouts = workoutsAsync.valueOrNull ?? [];
    final activities = ref.watch(activitiesProvider).valueOrNull ?? [];

    if (workouts.isEmpty && activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Keine Einheiten in diesem Zeitraum.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  showCreateWorkoutDialog(context, athleteId: athleteId),
              icon: const Icon(Icons.add),
              label: const Text('Erste Einheit planen'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        for (final a in activities)
          _buildCompletedActivityCard(context, a, showDate: true),
        for (final w in workouts)
          WorkoutCard(
            workout: w,
            showDate: true,
            onTap: () => showWorkoutDetailSheet(context, w),
          ),
      ],
    );
  }

  /// Rendert eine absolvierte Aktivität (z. B. aus Garmin Connect oder FIT-Upload) im Kalender.
  Widget _buildCompletedActivityCard(
    BuildContext context,
    Activity activity, {
    required bool showDate,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sportColor = _getSportColor(activity.sport);
    final cardBg = isDark ? const Color(0xFF002A5C) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF003D82) : const Color(0xFFE2E8F0);
    const doneColor = Color(0xFF10B981);

    final durMin = (activity.durationSec / 60).round();
    final hours = durMin ~/ 60;
    final mins = durMin % 60;
    final durStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final distKm = activity.distanceM > 0
        ? (activity.distanceM / 1000).toStringAsFixed(1)
        : null;
    final avgPower = activity.summary?.avgPowerW?.round();
    final avgHr = activity.summary?.avgHr?.round();
    final tss = activity.metrics?.tss?.round();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(activity: activity),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: sportColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getSportIcon(activity.sport),
                                size: 16, color: sportColor),
                            const SizedBox(width: 6),
                            Text(
                              activity.sport,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: sportColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (showDate) ...[
                              const SizedBox(width: 8),
                              Text(
                                OrbitDateFormatter.formatDateString(
                                    activity.localDate),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: doneColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 12, color: doneColor),
                                  SizedBox(width: 4),
                                  Text(
                                    'Absolviert',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: doneColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activity.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              durStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            if (distKm != null)
                              Text(
                                '· $distKm km',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            if (avgPower != null && avgPower > 0)
                              Text(
                                '· Ø $avgPower W',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            if (avgHr != null && avgHr > 0)
                              Text(
                                '· Ø $avgHr bpm',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            if (tss != null && tss > 0)
                              Text(
                                '· $tss Load',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return Icons.directions_bike;
      case 'RUN':
        return Icons.directions_run;
      case 'SWIM':
        return Icons.pool;
      case 'STRENGTH':
        return Icons.fitness_center;
      default:
        return Icons.bolt;
    }
  }

  Color _getSportColor(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'SWIM':
        return AppColors.sportSwim;
      case 'STRENGTH':
        return AppColors.sportStrength;
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
