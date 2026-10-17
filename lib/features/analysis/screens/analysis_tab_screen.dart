import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/metrics/term_resolver.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/analysis_providers.dart';
import '../widgets/analysis_timeframe_selector.dart';
import '../widgets/form_traffic_light_card.dart';
import '../widgets/weekly_load_card.dart';
import '../widgets/consistency_card.dart';
import '../widgets/sport_distribution_card.dart';
import '../widgets/zone_distribution_card.dart';
import '../widgets/weekly_load_trend_chart.dart';
import '../widgets/fitness_fatigue_trend_chart.dart';
import '../widgets/performance_profile_card.dart';
import '../widgets/threshold_progress_card.dart';
import '../../health/screens/health_cockpit_screen.dart';
import '../../home/models/race_goal.dart';
import '../../races/providers/races_provider.dart';

/// Haupt-Screen des Tabs „Analyse".
///
/// Bietet eine hierarchisch wachsende Ansicht je nach Erfahrungsstufe:
/// - Einfach: Form-Ampel, Wochenbelastung vs. Plan, Konsistenz
/// - Fortgeschritten: zusätzlich Sportverteilung, Zonenverteilung, 8-Wochen-Trend
/// - Experte: zusätzlich CTL/ATL/TSB-Linienverlauf und Schwellenwerte
class AnalysisTabScreen extends ConsumerWidget {
  final String? athleteId;
  final String? athleteName;

  const AnalysisTabScreen({
    super.key,
    this.athleteId,
    this.athleteName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wenn athleteId übergeben wurde, setzen wir den Override
    if (athleteId != null &&
        athleteId != ref.watch(analysisAthleteIdOverrideProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(analysisAthleteIdOverrideProvider.notifier).state = athleteId;
      });
    }

    // Erfahrungsstufe reaktiv aus den App-Einstellungen beziehen
    final experienceLevel = ref.watch(settingsProvider).experienceLevel;

    final selectedTimeframe = ref.watch(selectedAnalysisTimeframeProvider);
    final analysisAsync = ref.watch(analysisStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analysisStateProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trainer-Kopfzeile wenn Athleten-Kontext aktiv
              if (athleteName != null && athleteName!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.navy.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Text(
                        'Analysedaten von $athleteName',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Schnellzugriff: Health & Recovery Cockpit
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HealthCockpitScreen(
                        athleteId: athleteId,
                        athleteName: athleteName,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.volt.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.volt,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health & Recovery Cockpit',
                              style: AppTypography.title.copyWith(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '3 Ringe, HRV-Baselines, Schlafschuld & Journal',
                              style: AppTypography.label.copyWith(
                                color: AppColors.techGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.volt,
                      ),
                    ],
                  ),
                ),
              ),

              // Zeitraum-Auswahl
              AnalysisTimeframeSelector(
                selected: selectedTimeframe,
                onSelected: (tf) {
                  ref.read(selectedAnalysisTimeframeProvider.notifier).state =
                      tf;
                },
              ),
              const SizedBox(height: 16),

              // Async State Handling
              analysisAsync.when(
                data: (data) {
                  final races =
                      ref.watch(racesStreamProvider).valueOrNull ?? [];
                  final raceGoals = races.map(RaceGoal.fromRace).toList();
                  return _buildContent(
                      context, data, experienceLevel, raceGoals);
                },
                loading: () => _buildLoadingSkeleton(),
                error: (err, stack) =>
                    _buildErrorCard(context, ref, err.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AnalysisViewState data,
    ExperienceLevel level,
    List<RaceGoal> races,
  ) {
    if (!data.hasData) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Demo-Banner
        if (data.isDemo) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentVolt.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentVolt),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.navy),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Demomodus aktiv: Zeigt beispielhafte 12-Wochen-Trainingsdaten.',
                    style: AppTypography.label.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 1. Form-Ampel (immer sichtbar)
        FormTrafficLightCard(
          form: data.formTrafficLight,
          experienceLevel: level,
        ),
        const SizedBox(height: 16),

        // 2. Wochenbelastung vs. Plan (immer sichtbar)
        WeeklyLoadCard(
          summary: data.weeklyLoad,
          experienceLevel: level,
        ),
        const SizedBox(height: 16),

        // 3. Konsistenz (immer sichtbar)
        ConsistencyCard(
          consistency: data.consistency,
        ),
        const SizedBox(height: 16),

        // 4. Sportverteilung (ab Fortgeschritten)
        if (level == ExperienceLevel.advanced ||
            level == ExperienceLevel.expert) ...[
          SportDistributionCard(
            summary: data.sportDistribution,
          ),
          const SizedBox(height: 16),

          // 5. Zonenverteilung (ab Fortgeschritten)
          ZoneDistributionCard(
            summary: data.zoneDistribution,
          ),
          const SizedBox(height: 16),

          // 6. 8-Wochen-Trend (ab Fortgeschritten)
          WeeklyLoadTrendChart(
            points: data.weeklyTrend,
            trendDescription: data.weeklyTrendDescription,
          ),
          const SizedBox(height: 16),
        ],

        // 7. CTL/ATL/TSB-Linienchart, MMP-Profil & Schwellenwerte (Experten-Ansicht)
        if (level == ExperienceLevel.expert) ...[
          FitnessFatigueTrendChart(
            points: data.fitnessFatiguePoints,
            races: races,
          ),
          const SizedBox(height: 16),
          const PerformanceProfileCard(
            recentMmp: {},
            seasonMmp: {},
            cpWatts: 280,
            wPrimeKj: 20.4,
            pMaxWatts: 980,
          ),
          const SizedBox(height: 16),
          ThresholdProgressCard(athleteId: athleteId),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.navy.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text('Fehler beim Laden der Analyse', style: AppTypography.title),
          const SizedBox(height: 8),
          Text(error,
              style: AppTypography.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(analysisStateProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.query_stats,
              size: 48, color: AppColors.navy.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Noch keine Trainingsdaten', style: AppTypography.title),
          const SizedBox(height: 8),
          Text(
            'Sobald du Aktivitäten importierst oder Garmin verbindest, werden hier deine Form-Ampel, Belastung und Trends berechnet.',
            style:
                AppTypography.bodySmall.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
