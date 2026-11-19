/// Datei-Header: `lib/features/activities/screens/today_tab_screen.dart`
/// Zweck: Der Haupt-Tab „Heute" / „Today" für Athleten mit striktem V1.0.0-Scope-Gating
/// (`ReleaseConfig`) sowie voller V2/V3-Kompatibilität.
/// Architektur-Einordnung: Präsentationsschicht (`lib/features/activities/screens/`),
/// nutzt `ListView.builder`, `const`-Konstruktoren und granulare Riverpod-Selektoren
/// gemäß `AGENTS.md` Regel 10.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/release_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/error/orbit_error_handler.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/metrics/term_resolver.dart';
import '../../analysis/widgets/form_traffic_light_card.dart';
import '../../beta_feedback/models/beta_feedback_report.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';
import '../../calendar/widgets/workout_detail_sheet.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../coach_link/providers/athlete_context_provider.dart';
import '../../diagnostics/screens/diagnostics_screen.dart';
import '../../health/screens/health_cockpit_screen.dart';
import '../../health/widgets/readiness_card.dart';
import '../../home/domain/home_card_resolver.dart';
import '../../home/models/home_dashboard_data.dart';
import '../../home/providers/home_dashboard_provider.dart';
import '../../home/widgets/edit_race_goal_sheet.dart';
import '../../home/widgets/home_action_banner.dart';
import '../../home/widgets/home_hero_card.dart';
import '../../home/widgets/home_recent_activity_card.dart';
import '../../home/widgets/race_countdown_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/activity.dart';
import '../providers/activities_provider.dart';
import '../providers/activity_upload_provider.dart';
import 'activity_detail_screen.dart';

/// Der Haupt-Tab „Heute" (Home-Dashboard) für Athleten.
///
/// Was:
/// - Im V1.0.0-Standardbetrieb (`ReleaseConfig.isStrictV1 == true`):
///   - Zeigt ausschließlich **absolviertes Training** des heutigen Kalendertags als
///     kompakte Trainings-Vorschaukarten (`TrainingPreviewCard`, nicht klickbar,
///     rechts direkter `.FIT`-Download-Button) ohne Sync- oder Upload-Schaltflächen.
///   - Liegt heute noch keine Einheit vor, wird ausschließlich ein ruhiger Leerzustand
///     („Heute noch kein absolviertes Training“) angezeigt.
///   - Blendet die 3 Daily Health Ringe (`HomeHeroCard`), den Readiness-Score (`ReadinessCard`),
///     die Form-Ampel und den Wettkampf-Countdown strikt aus.
/// - Im V2/V3-Modus (`ReleaseConfig.isV2Enabled || ReleaseConfig.isV3Enabled`):
///   - Rendert das erweiterte Cockpit inkl. 3 Ringe, Form-Ampel, Action-Banner und Saisonziel.
/// Warum: Setzt die verbindlichen V1.0.0-Vorgaben aus `docs/ROADMAP_V1_TO_V4.md` um, ohne
/// bestehenden V2/V3-Code zu löschen.
class TodayTabScreen extends ConsumerWidget {
  /// Erstellt den `TodayTabScreen`.
  const TodayTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Granulare Riverpod-Selektoren gemäß Effizienz-Gebot (AGENTS.md Regel 10)
    final athleteId = ref.watch(currentAthleteIdProvider);
    final homeDataAsync = ref.watch(homeDashboardProvider(athleteId));
    final uploadState = ref.watch(activityUploadProvider);
    final lang = ref.watch(
      settingsControllerProvider.select((s) => s.languageCode),
    );
    final isV2Enabled = ref.watch(
      releaseConfigProvider.select((cfg) => cfg.isV2Enabled),
    );
    final isV3Enabled = ref.watch(
      releaseConfigProvider.select((cfg) => cfg.isV3Enabled),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: isDark ? AppColors.volt : AppColors.navy,
        backgroundColor: isDark ? AppColors.anthraciteCard : AppColors.white,
        onRefresh: () async {
          ref.invalidate(homeDashboardProvider(athleteId));
          ref.invalidate(activitiesProvider);
          await ref.read(homeDashboardProvider(athleteId).future);
        },
        child: homeDataAsync.when(
          data: (data) => (!isV2Enabled && !isV3Enabled)
              ? _buildV1CompletedTrainingView(
                  context,
                  ref,
                  athleteId: athleteId,
                  data: data,
                  uploadState: uploadState,
                  lang: lang,
                )
              : _buildDashboardContent(
                  context,
                  ref,
                  athleteId,
                  data,
                  uploadState,
                  lang: lang,
                  isV2Enabled: isV2Enabled,
                  isV3Enabled: isV3Enabled,
                ),
          loading: () => _buildLoadingSkeleton(context),
          error: (error, stack) =>
              _buildErrorState(context, ref, athleteId, error),
        ),
      ),
      floatingActionButton: (!isV2Enabled && !isV3Enabled)
          ? null
          : FloatingActionButton(
              key: const Key('today_fab_upload_button'),
              tooltip: AppStrings.fileUploadAction(lang: lang),
              backgroundColor: AppColors.primaryAccent(isDark: isDark),
              foregroundColor: isDark ? AppColors.navy : AppColors.white,
              onPressed: uploadState.isUploading
                  ? null
                  : () => ref
                      .read(activityUploadProvider.notifier)
                      .pickAndUpload(targetAthleteId: athleteId),
              child: uploadState.isUploading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? AppColors.navy : AppColors.white,
                      ),
                    )
                  : const Icon(Icons.add),
            ),
    );
  }

  /// Rendert die radikal entschlackte V1.0.0-Heute-Ansicht:
  /// - Zeigt ohne Sync-/Upload-Karten ausschließlich am heutigen Tag absolvierte
  ///   Trainings als kompakte `TrainingPreviewCard` (rechts `.FIT`-Download-Button).
  /// - Liegt heute noch kein absolviertes Training vor, wird ausschließlich der ruhige
  ///   Empty-State („Heute noch kein absolviertes Training“) angezeigt.
  Widget _buildV1CompletedTrainingView(
    BuildContext context,
    WidgetRef ref, {
    required String athleteId,
    required HomeDashboardData data,
    required ActivityUploadState uploadState,
    required String lang,
  }) {
    // Ermittelt den heutigen ISO-Datumsschlüssel (yyyy-MM-dd) in lokaler Zeit
    final now = DateTime.now();
    final todayIsoKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Filtert strikt auf heute absolvierte Einheiten (inkl. Fallback auf latestActivity von heute)
    final activitiesList = ref.watch(
      activitiesProvider.select((asyncList) => asyncList.valueOrNull),
    );
    final List<Activity> sourceList =
        (activitiesList != null && activitiesList.isNotEmpty)
            ? activitiesList
            : (data.latestActivity != null
                ? <Activity>[data.latestActivity!]
                : const <Activity>[]);
    final List<Activity> completedToday = sourceList
        .where((a) => a.localDate == todayIsoKey)
        .toList(growable: false);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = AppColors.cardBg(isDark: isDark);
    final borderColor = AppColors.cardBorderFor(isDark: isDark);
    final primaryTextColor = AppColors.primaryText(isDark: isDark);
    final secondaryTextColor = AppColors.secondaryText(isDark: isDark);

    if (completedToday.isEmpty) {
      return ListView(
        key: const Key('v1_today_completed_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.mobilePageMargin,
          vertical: AppSpacing.p24,
        ),
        children: [
          if (uploadState.isUploading) _buildUploadProgressBanner(uploadState),
          Container(
            key: const Key('v1_today_empty_completed_card'),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 42,
                  color: isDark ? AppColors.volt : AppColors.navy,
                ),
                const SizedBox(height: 14),
                Text(
                  lang == 'en'
                      ? 'No completed workout today'
                      : 'Heute noch kein absolviertes Training',
                  textAlign: TextAlign.center,
                  style: AppTypography.title.copyWith(
                    color: primaryTextColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang == 'en'
                      ? 'Once a workout for today is synced, it will appear here.'
                      : 'Sobald heute ein Training synchronisiert wird, erscheint es hier.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: const Key('v1_today_completed_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.mobilePageMargin,
        vertical: AppSpacing.p16,
      ),
      itemCount: completedToday.length + (uploadState.isUploading ? 1 : 0),
      itemBuilder: (context, index) {
        if (uploadState.isUploading && index == 0) {
          return _buildUploadProgressBanner(uploadState);
        }
        final actIndex = uploadState.isUploading ? index - 1 : index;
        final activity = completedToday[actIndex];
        return TrainingPreviewCard(
          activity: activity,
          onOpenCockpit: null,
        );
      },
    );
  }

  /// Rendert das Fortschritts-Banner während eines laufenden Datei-Uploads.
  Widget _buildUploadProgressBanner(ActivityUploadState uploadState) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.p12),
      padding: const EdgeInsets.all(AppSpacing.p12),
      decoration: BoxDecoration(
        color: AppColors.volt.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.volt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  uploadState.statusMessage ??
                      'Aktivitätsdateien werden hochgeladen und verarbeitet...',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.navy,
                  ),
                ),
              ),
              if (uploadState.totalFiles > 0)
                Text(
                  '${uploadState.currentFileIndex}/${uploadState.totalFiles}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.navy,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: uploadState.progress,
              backgroundColor: AppColors.navy.withValues(alpha: 0.12),
              color: AppColors.navy,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// Rendert das V2/V3-Dashboard basierend auf den von [HomeCardResolver] aufgelösten Karten.
  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    HomeDashboardData data,
    ActivityUploadState uploadState, {
    required String lang,
    required bool isV2Enabled,
    required bool isV3Enabled,
  }) {
    final cardContext = HomeCardContext(
      isBrandNewUser: data.isBrandNewUser,
      isDemo: data.isDemo,
      hasTodayPlan: data.todayPlannedWorkout != null,
      isRestDay: data.isRestDay,
      todayActualLoad: data.actualLoadToday,
      todayPlannedLoad: data.plannedLoadToday,
      unreadChatMessages: data.unreadMessagesCount,
      pendingThresholdProposals: data.pendingThresholdProposalsCount,
      unmatchedActivitiesCount: data.unmatchedActivitiesCount,
      hasRecentActivity: data.latestActivity != null,
      hasFormOrReadiness: data.formTrafficLight != null,
      raceGoal: data.raceGoal,
    );

    final experienceLevel = ref.watch(
      settingsControllerProvider.select((s) => s.experienceLevel),
    );
    final visibleCards =
        const HomeCardResolver().resolveVisibleCards(cardContext).where((c) {
      // V3-Karten (3 Ringe & Readiness/Form-Ampel) nur bei aktivem V3 anzeigen
      if (!isV3Enabled &&
          (c == HomeCardType.heroDailyRing ||
              c == HomeCardType.formTrafficLight)) {
        return false;
      }
      // V2-Karten (Action-Banner & Race-Countdown) nur bei aktivem V2 anzeigen
      if (!isV2Enabled &&
          (c == HomeCardType.actionBanner || c == HomeCardType.raceCountdown)) {
        return false;
      }
      return experienceLevel != ExperienceLevel.beginner ||
          c != HomeCardType.formTrafficLight;
    }).toList();

    if (visibleCards.length == 1 &&
        visibleCards.first == HomeCardType.emptyGetStarted) {
      return _buildEmptyState(
        context,
        ref,
        athleteId,
        uploadState,
        lang: lang,
        isV2Enabled: isV2Enabled,
        isV3Enabled: isV3Enabled,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppSpacing.breakpointCompact;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.p24 : AppSpacing.mobilePageMargin,
            vertical: AppSpacing.p16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (uploadState.isUploading)
                    _buildUploadProgressBanner(uploadState),
                  if (uploadState.error != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.p12),
                      child: OrbitErrorBanner(
                        error: uploadState.error!,
                        contextHint: 'ActivityUpload',
                        onRetry: () => ref
                            .read(activityUploadProvider.notifier)
                            .pickAndUpload(targetAthleteId: athleteId),
                        onReportIssue: () => showBetaBugReporterSheet(
                          context,
                          initialCategory: BetaFeedbackCategory.garminUpload,
                          initialDescription: uploadState.error,
                        ),
                      ),
                    ),
                  ],
                  if (isWide)
                    _buildWideLayout(
                      context,
                      ref,
                      athleteId,
                      data,
                      visibleCards,
                    )
                  else
                    _buildCompactLayout(
                      context,
                      ref,
                      athleteId,
                      data,
                      visibleCards,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Kompakte Ansicht (Mobile) – Eine vertikale Spalte.
  Widget _buildCompactLayout(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    HomeDashboardData data,
    List<HomeCardType> visibleCards,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: visibleCards.map((cardType) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.p16),
          child: _renderCard(context, ref, athleteId, data, cardType),
        );
      }).toList(),
    );
  }

  /// Breite Ansicht (Tablet / Desktop) – 2 Spalten.
  Widget _buildWideLayout(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    HomeDashboardData data,
    List<HomeCardType> visibleCards,
  ) {
    final leftCards = <HomeCardType>[];
    final rightCards = <HomeCardType>[];

    for (var i = 0; i < visibleCards.length; i++) {
      final card = visibleCards[i];
      if (card == HomeCardType.actionBanner ||
          card == HomeCardType.heroDailyRing) {
        leftCards.add(card);
      } else if (i % 2 == 0) {
        leftCards.add(card);
      } else {
        rightCards.add(card);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: leftCards.map((cardType) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.p16),
                child: _renderCard(context, ref, athleteId, data, cardType),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: AppSpacing.p16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rightCards.map((cardType) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.p16),
                child: _renderCard(context, ref, athleteId, data, cardType),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Rendert eine einzelne Home-Karte nach [HomeCardType].
  Widget _renderCard(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    HomeDashboardData data,
    HomeCardType cardType,
  ) {
    switch (cardType) {
      case HomeCardType.actionBanner:
        return HomeActionBanner(
          pendingThresholdsCount: data.pendingThresholdProposalsCount,
          unreadChatMessagesCount: data.unreadMessagesCount,
          unmatchedActivitiesCount: data.unmatchedActivitiesCount,
          onThresholdsTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiagnosticsScreen(athleteId: athleteId),
              ),
            );
          },
          onChatTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            );
          },
          onMatchTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Öffne Kalender, um Aktivitäten zuzuordnen.'),
              ),
            );
          },
        );

      case HomeCardType.heroDailyRing:
        return HomeHeroCard(
          actualLoad: data.actualLoadToday,
          plannedWorkout: data.todayPlannedWorkout,
          dailyMetrics: data.todayDailyMetrics,
          onWorkoutTap: data.todayPlannedWorkout != null
              ? () => showWorkoutDetailSheet(context, data.todayPlannedWorkout!)
              : null,
          onOpenHealthCockpit: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HealthCockpitScreen(athleteId: athleteId),
            ),
          ),
        );

      case HomeCardType.raceCountdown:
        if (data.raceGoal == null) return const SizedBox.shrink();
        return RaceCountdownCard(
          raceGoal: data.raceGoal!,
          onEdit: () {
            EditRaceGoalSheet.show(
              context,
              initialGoal: data.raceGoal,
              onSaved: () => ref.refresh(homeDashboardProvider(athleteId)),
            );
          },
        );

      case HomeCardType.formTrafficLight:
        if (data.formTrafficLight != null) {
          return FormTrafficLightCard(form: data.formTrafficLight!);
        }
        return ReadinessCard(athleteId: athleteId);

      case HomeCardType.recentActivity:
        if (data.latestActivity == null) return const SizedBox.shrink();
        return HomeRecentActivityCard(
          activity: data.latestActivity!,
          onOpenCockpit: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ActivityDetailScreen(activity: data.latestActivity!),
              ),
            );
          },
        );

      case HomeCardType.demoBanner:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.anthraciteCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.volt),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo-Modus aktiv: Beispieldaten zur Veranschaulichung aller Funktionen.',
                  style: AppTypography.label.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
        );

      case HomeCardType.emptyGetStarted:
        return const SizedBox.shrink();
    }
  }

  /// Leerer Zustand für brandneue Nutzer im V2/V3-Modus.
  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    ActivityUploadState uploadState, {
    required String lang,
    required bool isV2Enabled,
    required bool isV3Enabled,
  }) {
    final isEn = lang == 'en';
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.volt.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_run,
                    size: 40,
                    color: AppColors.volt,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEn ? 'Welcome to ORBIT' : 'Willkommen bei ORBIT',
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.todayQuickSyncSubtitle(lang: lang),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: uploadState.isUploading
                    ? null
                    : () => ref
                        .read(activityUploadProvider.notifier)
                        .pickAndUpload(targetAthleteId: athleteId),
                icon: uploadState.isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  uploadState.isUploading
                      ? (uploadState.statusMessage ??
                          (isEn
                              ? 'Uploading files...'
                              : 'Lade Dateien hoch...'))
                      : AppStrings.fileUploadAction(lang: lang),
                ),
              ),
              if (isV2Enabled) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    EditRaceGoalSheet.show(
                      context,
                      onSaved: () =>
                          ref.refresh(homeDashboardProvider(athleteId)),
                    );
                  },
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: Text(
                    isEn ? 'Set Season Goal' : 'Saisonziel festlegen',
                  ),
                ),
              ],
              if (isV3Enabled) ...[
                const SizedBox(height: 24),
                ReadinessCard(athleteId: athleteId),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Skeleton-Loader während des Datenabrufs.
  Widget _buildLoadingSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.anthraciteCard : AppColors.white;
    final borderColor =
        isDark ? AppColors.darkSubtleBorder : AppColors.cardBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.p16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.volt),
                ),
              ),
              const SizedBox(height: AppSpacing.p16),
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fehlerzustand mit Wiederholen- und Problem-melden-Button.
  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: OrbitErrorBanner(
            error: error,
            contextHint: 'HomeDashboard',
            onRetry: () => ref.refresh(homeDashboardProvider(athleteId)),
            onReportIssue: () => showBetaBugReporterSheet(
              context,
              initialCategory: BetaFeedbackCategory.bugCrash,
            ),
          ),
        ),
      ),
    );
  }
}
