/// Datei-Header: `lib/features/calendar/screens/calendar_screen.dart`
/// Zweck: Haupt-Kalender-Screen von ORBIT mit Wochen-, Monats- und Listenansicht
/// im Clean Professional Design (Hell & Dunkel), vollständiger DE/EN-Lokalisierung
/// und striktem V1.0.0-Scope-Gating über [ReleaseConfig].
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/calendar/screens/`),
/// nutzt `ListView.builder`, `const`-Konstruktoren, granulare Riverpod-Selektoren
/// (`.select(...)`) sowie die einheitliche [TrainingPreviewCard] (`AGENTS.md` Regel 10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/release_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/country_date_time_formatter.dart';
import '../../activities/models/activity.dart';
import '../../activities/providers/activities_provider.dart';
import '../../activities/screens/activity_detail_screen.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../coach_link/providers/athlete_context_provider.dart';
import '../../home/widgets/home_recent_activity_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/planned_workout.dart';
import '../providers/calendar_provider.dart';
import '../widgets/create_workout_dialog.dart';
import '../widgets/workout_card.dart';
import '../widgets/workout_detail_sheet.dart';

/// Haupt-Kalender-Screen von ORBIT (Woche, Monat und Liste).
///
/// Was:
/// - **V1.0.0-Standardmodus (`ReleaseConfig.isV2Enabled == false`):**
///   Stellt ausschließlich absolvierte Trainings in den drei Ansichten **Woche**,
///   **Monat** und **Liste** über die einheitliche [TrainingPreviewCard] (inkl. `.FIT`-
///   Download-Button rechts, nicht klickbar) dar. Blendet alle V2-Planungsfunktionen
///   (geplante Workouts, Wochensoll-Karte, „Training planen“-FAB) sauber aus.
/// - **V2/V3-Modus (`ReleaseConfig.isV2Enabled == true`):**
///   Zeigt zusätzlich geplante Workouts, Wochensoll-Abgleich und den Planungs-FAB.
/// Warum: Entspricht den verbindlichen V1.0.0-Vorgaben aus `docs/ROADMAP_V1_TO_V4.md`
/// bei gleichzeitiger 100-%-Kompatibilität für alle V2-Bestandstests.
class CalendarScreen extends ConsumerWidget {
  /// Optionale ID des Athleten. Falls `null`, wird der aktive Kontext verwendet.
  final String? athleteId;

  /// Blendet die obere Statusbar-Einrückung der AppBar aus, falls übergeordnet
  /// bereits eine Leiste (z. B. Coach-Athleten-Auswahl) mit `SafeArea` sitzt.
  final bool hideSafeAreaTop;

  /// Erstellt den [CalendarScreen].
  const CalendarScreen({
    super.key,
    this.athleteId,
    this.hideSafeAreaTop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Granulare Riverpod-Selektoren gemäß Effizienz-Gebot (AGENTS.md Regel 10)
    final String activeAthleteId =
        athleteId ?? (ref.watch(viewedAthleteIdProvider) ?? 'me');
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final countryCode = ref.watch(
      settingsControllerProvider.select((s) => s.countryCode),
    );
    final isV2Enabled = ref.watch(
      releaseConfigProvider.select((cfg) => cfg.isV2Enabled),
    );
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final viewMode = ref.watch(calendarViewModeProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        primary: !hideSafeAreaTop,
        title: Text(
          AppStrings.formatMonthYear(selectedDate, lang: lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Schnell-Sprung auf das heutige Datum
          TextButton.icon(
            key: const Key('calendar_today_button'),
            onPressed: () {
              ref.read(selectedCalendarDateProvider.notifier).state =
                  DateTime.now();
            },
            icon: const Icon(Icons.today, size: 18),
            label: Text(AppStrings.calendarToday(lang: lang)),
          ),
          // Perioden-Navigation (- / +)
          IconButton(
            key: const Key('calendar_prev_button'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateDate(ref, viewMode, -1),
          ),
          IconButton(
            key: const Key('calendar_next_button'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateDate(ref, viewMode, 1),
          ),
          // Topbar-Bugmeldung auch im Kalender-Tab (da Dashboard-AppBar hier ausgeblendet ist)
          const BetaBugReportIconButton(),
        ],
      ),
      body: Column(
        children: [
          // Umschalter zwischen Woche, Monat und Liste
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<CalendarViewMode>(
              key: const Key('calendar_view_mode_segmented'),
              segments: [
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.week,
                  icon: const Icon(Icons.view_week_outlined),
                  label: Text(AppStrings.calendarWeek(lang: lang)),
                ),
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.month,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(AppStrings.calendarMonth(lang: lang)),
                ),
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.list,
                  icon: const Icon(Icons.view_list_outlined),
                  label: Text(AppStrings.calendarList(lang: lang)),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (newSelection) {
                ref.read(calendarViewModeProvider.notifier).state =
                    newSelection.first;
              },
            ),
          ),

          // V2-Wochensoll-Karte nur bei aktiviertem V2-Scope anzeigen
          if (isV2Enabled && viewMode != CalendarViewMode.month)
            _buildWeekSummaryCard(
              context,
              theme,
              isDark,
              ref.watch(weekSummaryProvider(activeAthleteId)),
            ),

          // Hauptinhalt je nach aktivem Ansichtsmodus
          Expanded(
            child: switch (viewMode) {
              CalendarViewMode.week => _buildWeekView(
                  context,
                  ref,
                  activeAthleteId,
                  selectedDate,
                  lang: lang,
                  countryCode: countryCode,
                  isV2Enabled: isV2Enabled,
                ),
              CalendarViewMode.month => _buildMonthView(
                  context,
                  ref,
                  activeAthleteId,
                  selectedDate,
                  lang: lang,
                  countryCode: countryCode,
                  isV2Enabled: isV2Enabled,
                ),
              CalendarViewMode.list => _buildListView(
                  context,
                  ref,
                  activeAthleteId,
                  lang: lang,
                  isV2Enabled: isV2Enabled,
                ),
            },
          ),
        ],
      ),
      // Planungs-FAB ausschließlich in V2.0.0 sichtbar
      floatingActionButton: isV2Enabled
          ? FloatingActionButton.extended(
              key: const Key('calendar_plan_workout_fab'),
              onPressed: () => showCreateWorkoutDialog(
                context,
                athleteId: activeAthleteId,
                initialDate: selectedDate,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Training planen'),
            )
          : null,
    );
  }

  /// Verschiebt das ausgewählte Kalenderdatum um einen Monat oder eine Woche.
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

  /// V2-Wochensoll-Zusammenfassungskarte (nur bei `isV2Enabled == true` gerendert).
  Widget _buildWeekSummaryCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    WeekSummary summary,
  ) {
    final compliance = summary.durationCompliancePercentage;
    final cardBg = isDark ? AppColors.anthraciteCard : AppColors.white;
    final cardBorder =
        isDark ? AppColors.darkSubtleBorder : AppColors.cardBorder;

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
                    color:
                        isDark ? AppColors.white : AppColors.lightTextPrimary,
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
                      ? AppColors.textSecondaryDark
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
                  isDark ? AppColors.carbonDark : const Color(0xFFE2E8F0),
              color: progressColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// Wochenansicht: 7 Tage (Mo–So) mit Sportart-Farbpunkten und COROS-Vorschaukarten.
  Widget _buildWeekView(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    DateTime selectedDate, {
    required String lang,
    required String countryCode,
    required bool isV2Enabled,
  }) {
    final workouts = isV2Enabled
        ? (ref
                .watch(athleteCurrentWeekWorkoutsProvider(athleteId))
                .valueOrNull ??
            const <PlannedWorkout>[])
        : const <PlannedWorkout>[];
    final activities = ref.watch(
      activitiesProvider.select((a) => a.valueOrNull ?? const <Activity>[]),
    );

    final monday =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final todayIso = _toIsoDateKey(DateTime.now());

    return ListView.builder(
      key: const Key('calendar_week_list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = monday.add(Duration(days: index));
        final dayStr = _toIsoDateKey(day);
        final dayWorkouts = isV2Enabled
            ? workouts.where((w) => w.localDate == dayStr).toList()
            : const <PlannedWorkout>[];
        final dayActivities =
            activities.where((a) => a.localDate == dayStr).toList();
        final isToday = todayIso == dayStr;

        return _buildDaySection(
          context,
          day,
          dayWorkouts,
          dayActivities,
          isToday,
          athleteId,
          lang: lang,
          countryCode: countryCode,
          isV2Enabled: isV2Enabled,
        );
      },
    );
  }

  /// Rendert einen einzelnen Tag in der Wochenansicht inkl. Sportart-Farbpunkten.
  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<PlannedWorkout> workouts,
    List<Activity> activities,
    bool isToday,
    String athleteId, {
    required String lang,
    required String countryCode,
    required bool isV2Enabled,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weekdayLabels = AppStrings.weekdayShortLabels(lang: lang);
    final weekdayShort = weekdayLabels[(date.weekday - 1).clamp(0, 6)];
    final formattedDate =
        CountryDateTimeFormatter.formatDate(date, countryCode: countryCode);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$weekdayShort, $formattedDate',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? (isDark ? AppColors.volt : AppColors.navy)
                      : (isDark ? AppColors.white : AppColors.lightTextPrimary),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.volt.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppStrings.calendarToday(lang: lang),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.volt : AppColors.navy,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Sportart-Farbpunkte für alle absolvierten Einheiten des Tages
              if (activities.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in activities.take(4))
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: _getSportColor(a.sport),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (workouts.isEmpty && activities.isEmpty)
            isV2Enabled
                ? InkWell(
                    onTap: () => showCreateWorkoutDialog(
                      context,
                      athleteId: athleteId,
                      initialDate: date,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+ Ruhetag / Einheit planen',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      AppStrings.calendarNoSessionsOnDay(lang: lang),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF64748B),
                      ),
                    ),
                  )
          else ...[
            for (final a in activities)
              TrainingPreviewCard(
                activity: a,
                onOpenCockpit: isV2Enabled
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ActivityDetailScreen(activity: a),
                          ),
                        )
                    : null,
              ),
            if (isV2Enabled)
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

  /// Monatsansicht: Monatsraster mit Sportart-Farbpunkten und darunter die COROS-Karten.
  Widget _buildMonthView(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    DateTime selectedDate, {
    required String lang,
    required String countryCode,
    required bool isV2Enabled,
  }) {
    final workouts = isV2Enabled
        ? (ref
                .watch(athleteCurrentMonthWorkoutsProvider(athleteId))
                .valueOrNull ??
            const <PlannedWorkout>[])
        : const <PlannedWorkout>[];
    final activities = ref.watch(
      activitiesProvider.select((a) => a.valueOrNull ?? const <Activity>[]),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0);

    final selectedDayStr = _toIsoDateKey(selectedDate);
    final selectedDayWorkouts = isV2Enabled
        ? workouts.where((w) => w.localDate == selectedDayStr).toList()
        : const <PlannedWorkout>[];
    final selectedDayActivities =
        activities.where((a) => a.localDate == selectedDayStr).toList();
    final weekdayLabels = AppStrings.weekdayShortLabels(lang: lang);
    final todayStr = _toIsoDateKey(DateTime.now());

    return Column(
      children: [
        // Wochentags-Header (Mo - So bzw. Mon - Sun)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final label in weekdayLabels)
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),

        // Monats-Grid mit Sportart-Farbpunkten an Trainingstagen
        Expanded(
          flex: 2,
          child: GridView.builder(
            key: const Key('calendar_month_grid'),
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
              final dayStr = _toIsoDateKey(dayDate);
              final isToday = dayStr == todayStr;
              final isSelected = dayStr == selectedDayStr;
              final dayWorkouts = isV2Enabled
                  ? workouts.where((w) => w.localDate == dayStr).toList()
                  : const <PlannedWorkout>[];
              final dayActivities =
                  activities.where((a) => a.localDate == dayStr).toList();

              Color? cellBg;
              Border? cellBorder;
              Color textColor;

              if (isToday) {
                cellBg = isDark ? AppColors.volt : AppColors.navy;
                textColor = isDark ? AppColors.navy : AppColors.white;
                cellBorder = Border.all(
                  color: isDark ? AppColors.volt : AppColors.navy,
                  width: 2,
                );
              } else if (isSelected) {
                cellBg = isDark
                    ? AppColors.anthraciteCard
                    : AppColors.navy.withValues(alpha: 0.08);
                textColor =
                    isDark ? AppColors.white : AppColors.lightTextPrimary;
                cellBorder = Border.all(
                  color: isDark ? AppColors.volt : AppColors.navy,
                  width: 1.5,
                );
              } else {
                cellBg = isDark ? AppColors.anthraciteCard : AppColors.white;
                textColor =
                    isDark ? AppColors.white : AppColors.lightTextPrimary;
                cellBorder = Border.all(
                  color: isDark
                      ? AppColors.darkSubtleBorder
                      : AppColors.cardBorder,
                  width: 0.75,
                );
              }

              // Sportart-Farbpunkte (absolvierte Einheiten gefüllt, geplante in V2 hohl)
              final dotEntries = <({Color color, bool filled})>[
                for (final a in dayActivities)
                  (color: _getSportColor(a.sport), filled: true),
                if (isV2Enabled)
                  for (final w in dayWorkouts)
                    (color: _getSportColor(w.sport), filled: w.isCompleted),
              ];

              return InkWell(
                key: Key('calendar_month_day_$dayStr'),
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
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0;
                                  i < dotEntries.length.clamp(0, 4);
                                  i++)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: dotEntries[i].filled
                                        ? dotEntries[i].color
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: dotEntries[i].color,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
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

        // Liste der Einheiten des ausgewählten Tages (mit ListView.builder)
        Expanded(
          flex: 2,
          child: (selectedDayWorkouts.isEmpty && selectedDayActivities.isEmpty)
              ? Center(
                  child: isV2Enabled
                      ? TextButton.icon(
                          onPressed: () => showCreateWorkoutDialog(
                            context,
                            athleteId: athleteId,
                            initialDate: selectedDate,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Einheit an diesem Tag planen'),
                        )
                      : Text(
                          '${CountryDateTimeFormatter.formatDate(selectedDate, countryCode: countryCode)} • ${AppStrings.calendarNoSessionsOnDay(lang: lang)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF64748B),
                                  ),
                        ),
                )
              : ListView.builder(
                  key: const Key('calendar_month_day_list'),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                  itemCount:
                      selectedDayActivities.length + selectedDayWorkouts.length,
                  itemBuilder: (context, idx) {
                    if (idx < selectedDayActivities.length) {
                      final a = selectedDayActivities[idx];
                      return TrainingPreviewCard(
                        activity: a,
                        onOpenCockpit: isV2Enabled
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ActivityDetailScreen(activity: a),
                                  ),
                                )
                            : null,
                      );
                    }
                    final w =
                        selectedDayWorkouts[idx - selectedDayActivities.length];
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

  /// Listenansicht: Chronologische `ListView.builder`-Liste aller absolvierten Trainings.
  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    String athleteId, {
    required String lang,
    required bool isV2Enabled,
  }) {
    final workouts = isV2Enabled
        ? (ref
                .watch(athleteCurrentMonthWorkoutsProvider(athleteId))
                .valueOrNull ??
            const <PlannedWorkout>[])
        : const <PlannedWorkout>[];
    final activities = ref.watch(
      activitiesProvider.select((a) => a.valueOrNull ?? const <Activity>[]),
    );

    if (workouts.isEmpty && activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(AppStrings.calendarNoCompletedSessions(lang: lang)),
            if (isV2Enabled) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    showCreateWorkoutDialog(context, athleteId: athleteId),
                icon: const Icon(Icons.add),
                label: const Text('Erste Einheit planen'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      key: const Key('calendar_chronological_list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: activities.length + workouts.length,
      itemBuilder: (context, index) {
        if (index < activities.length) {
          final a = activities[index];
          return TrainingPreviewCard(
            activity: a,
            onOpenCockpit: isV2Enabled
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailScreen(activity: a),
                      ),
                    )
                : null,
          );
        }
        final w = workouts[index - activities.length];
        return WorkoutCard(
          workout: w,
          showDate: true,
          onTap: () => showWorkoutDetailSheet(context, w),
        );
      },
    );
  }

  /// Konvertiert ein [DateTime] in das interne ISO-Format `yyyy-MM-dd`.
  static String _toIsoDateKey(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$y-$m-$d';
  }

  /// Liefert die definierte Sport-Akzentfarbe für den Monats-/Wochen-Farbpunkt.
  static Color _getSportColor(String sport) {
    switch (sport.toUpperCase()) {
      case 'BIKE':
        return AppColors.sportBike;
      case 'RUN':
        return AppColors.sportRun;
      case 'SWIM':
        return AppColors.sportSwim;
      case 'TRIATHLON':
        return AppColors.volt;
      case 'STRENGTH':
        return AppColors.sportStrength;
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
