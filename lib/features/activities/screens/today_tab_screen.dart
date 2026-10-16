import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/error/orbit_error_handler.dart';
import '../../beta_feedback/models/beta_feedback_report.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';

import '../../coach_link/providers/athlete_context_provider.dart';
import '../../health/widgets/readiness_card.dart';
import '../../health/screens/health_cockpit_screen.dart';
import '../../analysis/widgets/form_traffic_light_card.dart';
import '../../calendar/widgets/workout_detail_sheet.dart';
import '../../diagnostics/screens/diagnostics_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../providers/activity_upload_provider.dart';
import 'activity_detail_screen.dart';

import '../../home/models/home_dashboard_data.dart';
import '../../home/domain/home_card_resolver.dart';
import '../../home/providers/home_dashboard_provider.dart';
import '../../home/widgets/home_hero_card.dart';
import '../../home/widgets/home_action_banner.dart';
import '../../home/widgets/race_countdown_card.dart';
import '../../home/widgets/home_recent_activity_card.dart';
import '../../home/widgets/edit_race_goal_sheet.dart';

/// Der Haupt-Tab „Heute" (Home-Dashboard) für Athleten.
///
/// Bietet ein ruhiges, priorisiertes Dashboard:
/// 1. Action-Banner (bei dringenden To-Dos wie neuen Schwellenwerten oder Trainer-Nachrichten)
/// 2. Zentrale Navy Hero-Karte mit Daily Ring (Volt) und heutigem Trainingsziel
/// 3. Saisonziel-Countdown mit Bearbeitungsmöglichkeit
/// 4. Physiologische Form-Ampel & Erholungsstatus
/// 5. Letzte absolvierte Trainingseinheit mit Direktzugriff auf das Analyse-Cockpit
class TodayTabScreen extends ConsumerWidget {
  const TodayTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athleteId = ref.watch(currentAthleteIdProvider);
    final homeDataAsync = ref.watch(homeDashboardProvider(athleteId));
    final uploadState = ref.watch(activityUploadProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: RefreshIndicator(
        color: AppColors.navy,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          ref.invalidate(homeDashboardProvider(athleteId));
          await ref.read(homeDashboardProvider(athleteId).future);
        },
        child: homeDataAsync.when(
          data: (data) => _buildDashboardContent(
            context,
            ref,
            athleteId,
            data,
            uploadState,
          ),
          loading: () => _buildLoadingSkeleton(context),
          error: (error, stack) =>
              _buildErrorState(context, ref, athleteId, error),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Aktivitäten importieren (.fit, .tcx, .gpx)',
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.volt,
        onPressed: uploadState.isUploading
            ? null
            : () => ref.read(activityUploadProvider.notifier).pickAndUpload(),
        child: uploadState.isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.volt,
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  /// Rendert das Dashboard basierend auf den von HomeCardResolver aufgelösten sichtbaren Karten.
  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    HomeDashboardData data,
    ActivityUploadState uploadState,
  ) {
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

    final visibleCards =
        const HomeCardResolver().resolveVisibleCards(cardContext);

    if (visibleCards.length == 1 &&
        visibleCards.first == HomeCardType.emptyGetStarted) {
      return _buildEmptyState(context, ref, athleteId, uploadState);
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
                  // Upload-Fortschrittsanzeige (falls aktiv)
                  if (uploadState.isUploading) ...[
                    Container(
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
                              backgroundColor:
                                  AppColors.navy.withValues(alpha: 0.12),
                              color: AppColors.navy,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (uploadState.error != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.p12),
                      child: OrbitErrorBanner(
                        error: uploadState.error!,
                        contextHint: 'ActivityUpload',
                        onRetry: () => ref
                            .read(activityUploadProvider.notifier)
                            .pickAndUpload(),
                        onReportIssue: () => showBetaBugReporterSheet(
                          context,
                          initialCategory: BetaFeedbackCategory.garminUpload,
                          initialDescription: uploadState.error,
                        ),
                      ),
                    ),
                  ],

                  // Karten-Rendering
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

  /// Kompakte Ansicht (Mobile) – Eine vertikale Spalte
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

  /// Breite Ansicht (Tablet / Desktop) – 2 Spalten
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
      // Hero-Card und Action-Banner bevorzugt links oder oben
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

  /// Rendert eine einzelne Home-Karte nach Typ
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
            // Zeigt Kalender zur Zuordnung
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
            color: const Color(0xFF1E293B),
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

  /// Leerer Zustand für brandneue Nutzer
  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    String athleteId,
    ActivityUploadState uploadState,
  ) {
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
              const Text(
                'Willkommen bei ORBIT',
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: 12),
              Text(
                'Verbinde dein Garmin-Konto oder lade eine FIT-Datei hoch, um dein Home-Dashboard mit dem täglichen Belastungsring, Form-Status und Analysen zu aktivieren.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 32),

              // Multi-Format Batch-Upload Button
              ElevatedButton.icon(
                onPressed: uploadState.isUploading
                    ? null
                    : () => ref
                        .read(activityUploadProvider.notifier)
                        .pickAndUpload(),
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
                      ? (uploadState.statusMessage ?? 'Lade Dateien hoch...')
                      : 'Aktivitäten importieren (.fit, .tcx, .gpx)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.volt,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),

              // Saisonziel Button
              OutlinedButton.icon(
                onPressed: () {
                  EditRaceGoalSheet.show(
                    context,
                    onSaved: () =>
                        ref.refresh(homeDashboardProvider(athleteId)),
                  );
                },
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Saisonziel festlegen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tagesform
              ReadinessCard(athleteId: athleteId),
            ],
          ),
        ),
      ),
    );
  }

  /// Skeleton Loader während des Datenabrufs
  Widget _buildLoadingSkeleton(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.p16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Skeleton
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.volt),
                ),
              ),
              const SizedBox(height: AppSpacing.p16),
              // Secondary Card Skeleton
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
              ),
              const SizedBox(height: AppSpacing.p16),
              // Form Skeleton
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fehlerzustand mit Wiederholen- und Problem-melden-Button
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
