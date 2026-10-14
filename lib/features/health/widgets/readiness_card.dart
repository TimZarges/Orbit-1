import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/metrics/term_resolver.dart';
import '../domain/readiness_evaluator.dart';
import '../models/daily_metrics.dart';
import '../models/health_baseline.dart';
import '../providers/health_provider.dart';
import '../services/health_demo_seeder.dart';

/// Die Tagesform-Karte: Visualisiert den Erholungs- und Bereitschaftszustand
/// basierend auf Ruhepuls, HRV und Schlaf im Verhältnis zur 28-Tage-Basislinie.
///
/// Unterstützt Progressive Disclosure (Einfach · Fortgeschritten · Experte).
class ReadinessCard extends ConsumerWidget {
  /// Die ID des betrachteten Athleten.
  final String athleteId;

  const ReadinessCard({
    super.key,
    required this.athleteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final experienceLevel = ref.watch(settingsProvider).experienceLevel;

    // 1. Berechtigungsprüfung für Trainer
    final hasPermissionAsync =
        ref.watch(coachHealthPermissionProvider(athleteId));
    final hasPermission = hasPermissionAsync.valueOrNull ?? false;

    if (!hasPermission && !hasPermissionAsync.isLoading) {
      return _buildPermissionBanner(context, l10n, theme, isDark);
    }

    // 2. Daten laden
    final historyAsync =
        ref.watch(athleteDailyMetricsHistoryProvider(athleteId));

    return historyAsync.when(
      loading: () => _buildLoadingSkeleton(context, theme, isDark),
      error: (err, stack) => _buildErrorCard(context, theme, err.toString()),
      data: (history) {
        if (history.isEmpty) {
          return _buildEmptyStateCard(context, l10n, theme, isDark, ref);
        }

        final baseline = ref.watch(healthBaselineProvider(athleteId));
        final evaluation = ref.watch(todayReadinessProvider(athleteId));

        return _buildContentCard(
          context: context,
          theme: theme,
          isDark: isDark,
          l10n: l10n,
          experienceLevel: experienceLevel,
          evaluation: evaluation,
          baseline: baseline,
          history: history,
        );
      },
    );
  }

  /// Baut die eigentliche Tagesform-Karte je nach Erfahrungsstufe.
  Widget _buildContentCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required AppLocalizations? l10n,
    required ExperienceLevel experienceLevel,
    required ReadinessEvaluation evaluation,
    required HealthBaseline baseline,
    required List<DailyMetrics> history,
  }) {
    final statusColor = _getStatusColor(evaluation.status, isDark);
    final statusTitle = _getStatusTitle(evaluation.status, l10n);
    final statusDescription = _getStatusDescription(
        evaluation.status, l10n, baseline.dataPointsCount);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Titel und Info-Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.readiness_title ?? 'Tagesform',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showReadinessInfoSheet(context, l10n),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status-Badge und ein prägnanter Satz (Einfach zuerst)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(evaluation.status),
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Einordnungssatz
          Text(
            statusDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              height: 1.4,
            ),
          ),

          // Fortgeschritten & Experte: Kern-Messwerte und Trend
          if (experienceLevel != ExperienceLevel.beginner &&
              evaluation.todayMetrics != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildMetricsGrid(context, theme, isDark, evaluation, baseline),
          ],

          // Experte: 28-Tage-Basislinienband und Datenbasis
          if (experienceLevel == ExperienceLevel.expert) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildExpertDetails(context, theme, isDark, baseline, evaluation),
          ],
        ],
      ),
    );
  }

  /// Baut die 3 Kennzahl-Kacheln (Ruhepuls, HRV, Schlaf) für Fortgeschrittene & Experten.
  Widget _buildMetricsGrid(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    ReadinessEvaluation eval,
    HealthBaseline baseline,
  ) {
    final today = eval.todayMetrics;
    if (today == null) return const SizedBox.shrink();

    return Row(
      children: [
        // Ruhepuls
        Expanded(
          child: _buildMetricTile(
            theme: theme,
            isDark: isDark,
            label: 'Ruhepuls',
            value:
                today.restingHrBpm != null ? '${today.restingHrBpm} bpm' : '--',
            deltaText: eval.restingHrDelta != null
                ? '${eval.restingHrDelta! >= 0 ? '+' : ''}${eval.restingHrDelta!.toStringAsFixed(0)} bpm'
                : null,
            isPositiveDeltaBetter: false,
            deltaValue: eval.restingHrDelta,
          ),
        ),
        const SizedBox(width: 8),

        // HRV
        Expanded(
          child: _buildMetricTile(
            theme: theme,
            isDark: isDark,
            label: 'HRV (rMSSD)',
            value: today.hrvMs != null ? '${today.hrvMs} ms' : '--',
            deltaText: eval.hrvDelta != null
                ? '${eval.hrvDelta! >= 0 ? '+' : ''}${eval.hrvDelta!.toStringAsFixed(0)} ms'
                : null,
            isPositiveDeltaBetter: true,
            deltaValue: eval.hrvDelta,
          ),
        ),
        const SizedBox(width: 8),

        // Schlaf
        Expanded(
          child: _buildMetricTile(
            theme: theme,
            isDark: isDark,
            label: 'Schlaf',
            value: today.formattedSleepDuration,
            deltaText:
                today.sleepScore != null ? 'Score ${today.sleepScore}' : null,
            isPositiveDeltaBetter: true,
            deltaValue: null,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required String value,
    String? deltaText,
    required bool isPositiveDeltaBetter,
    double? deltaValue,
  }) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    Color deltaColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    if (deltaValue != null) {
      if (isPositiveDeltaBetter) {
        if (deltaValue >= 0) {
          deltaColor = const Color(0xFF10B981); // Positiv (grün)
        } else if (deltaValue < -5) {
          deltaColor = const Color(0xFFF59E0B); // Amber
        }
      } else {
        // Bei Ruhepuls ist höherer Wert schlechter
        if (deltaValue > 3) {
          deltaColor = const Color(0xFFF59E0B);
        } else if (deltaValue <= 0) {
          deltaColor = const Color(0xFF10B981);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          if (deltaText != null) ...[
            const SizedBox(height: 4),
            Text(
              deltaText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: deltaColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Experteneinsicht: Exakte 28-Tage-Mittelwerte und Konfidenzbänder.
  Widget _buildExpertDetails(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    HealthBaseline baseline,
    ReadinessEvaluation eval,
  ) {
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '28-Tage-Basislinie (Median)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: subColor,
              ),
            ),
            Text(
              '${baseline.dataPointsCount} Tage analysiert',
              style: theme.textTheme.labelSmall?.copyWith(color: subColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Ruhepuls: ${baseline.medianRestingHr?.toStringAsFixed(1) ?? '--'} bpm (±${baseline.stdRestingHr?.toStringAsFixed(1) ?? '--'})  ·  '
          'HRV: ${baseline.medianHrv?.toStringAsFixed(1) ?? '--'} ms (±${baseline.stdHrv?.toStringAsFixed(1) ?? '--'})',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  /// Hinweiskarte, wenn der Trainer keine Leseberechtigung für Health-Daten hat.
  Widget _buildPermissionBanner(
    BuildContext context,
    AppLocalizations? l10n,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline,
                size: 22, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.readiness_coach_no_permission ??
                      'Health-Freigabe erforderlich',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.readiness_coach_no_permission_desc ??
                      'Der Athlet hat Health-Daten nicht freigegeben.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty State mit Aktionsbutton.
  Widget _buildEmptyStateCard(
    BuildContext context,
    AppLocalizations? l10n,
    ThemeData theme,
    bool isDark,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_outline,
                  size: 20, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                l10n?.readiness_title ?? 'Tagesform',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n?.readiness_no_data_desc ??
                'Verbinde dein Garmin-Konto oder lade Demo-Daten, um deine Tagesform und 28-Tage-Basislinie zu sehen.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => context.push('/settings/garmin'),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Garmin verbinden'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  await HealthDemoSeeder.seedDemoMetricsForAthlete(athleteId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('30 Tage Demo-Health-Daten geladen!')),
                  );
                },
                child: const Text('Demo laden'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 130,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, ThemeData theme, String error) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Fehler beim Laden der Health-Daten: $error',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
      ),
    );
  }

  /// Farbskala gemäß `docs/DESIGN.md`: Barrierefrei, keine grellen Alarme.
  Color _getStatusColor(ReadinessStatus status, bool isDark) {
    switch (status) {
      case ReadinessStatus.normal:
        return const Color(0xFF10B981); // Neutrales Grün
      case ReadinessStatus.slightDeviation:
        return const Color(0xFFF59E0B); // Weiches Amber
      case ReadinessStatus.noticeableDeviation:
        return const Color(0xFFEF4444); // Subdued Coral
      case ReadinessStatus.buildingBaseline:
      case ReadinessStatus.noData:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }
  }

  IconData _getStatusIcon(ReadinessStatus status) {
    switch (status) {
      case ReadinessStatus.normal:
        return Icons.check_circle_outline;
      case ReadinessStatus.slightDeviation:
        return Icons.change_circle_outlined;
      case ReadinessStatus.noticeableDeviation:
        return Icons.healing_outlined;
      case ReadinessStatus.buildingBaseline:
      case ReadinessStatus.noData:
        return Icons.hourglass_top_outlined;
    }
  }

  String _getStatusTitle(ReadinessStatus status, AppLocalizations? l10n) {
    switch (status) {
      case ReadinessStatus.normal:
        return l10n?.readiness_normal ?? 'Unauffällig';
      case ReadinessStatus.slightDeviation:
        return l10n?.readiness_slight_deviation ?? 'Leichte Abweichung';
      case ReadinessStatus.noticeableDeviation:
        return l10n?.readiness_noticeable_deviation ?? 'Deutliche Abweichung';
      case ReadinessStatus.buildingBaseline:
        return l10n?.readiness_building_baseline ?? 'Basislinie im Aufbau';
      case ReadinessStatus.noData:
        return l10n?.readiness_no_data ?? 'Keine Daten';
    }
  }

  String _getStatusDescription(
      ReadinessStatus status, AppLocalizations? l10n, int count) {
    switch (status) {
      case ReadinessStatus.normal:
        return l10n?.readiness_normal_desc ??
            'Ruhepuls und HRV liegen im gewohnten persönlichen Bereich.';
      case ReadinessStatus.slightDeviation:
        return l10n?.readiness_slight_deviation_desc ??
            'Einzelne Werte weichen leicht von deiner 28-Tage-Basislinie ab. Achte auf dein Körpergefühl und ausreichende Regeneration.';
      case ReadinessStatus.noticeableDeviation:
        return l10n?.readiness_noticeable_deviation_desc ??
            'Ruhepuls oder HRV weichen merklich von deinem Normalbereich ab. Erholung beachten; bei anhaltenden Beschwerden oder Unwohlsein ärztlichen Rat einholen.';
      case ReadinessStatus.buildingBaseline:
        return 'ORBIT benötigt mindestens 14 Tage Messwerte, um deinen persönlichen Normalbereich verlässlich zu bestimmen (aktuell: $count von 14 Tagen).';
      case ReadinessStatus.noData:
        return l10n?.readiness_no_data_desc ??
            'Verbinde dein Garmin-Konto oder lade Demo-Daten.';
    }
  }

  /// Zeigt den sachlichen Info-Dialog mit sportwissenschaftlicher Einordnung und Haftungsausschluss.
  void _showReadinessInfoSheet(BuildContext context, AppLocalizations? l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.health_info_title ?? 'Über die Tagesform',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Text(
                  'Die Tagesform in ORBIT vergleicht deine nächtlichen Vitalwerte (Ruhepuls und HRV rMSSD) mit deiner persönlichen 28-Tage-Basislinie.\n\n'
                  '• Ruhepuls: Ein Anstieg um mehr als 3–5 bpm gegenüber deiner Basislinie kann auf unvollständige Erholung, körperliche Belastung oder Dehydrierung hinweisen.\n'
                  '• HRV: Eine verringerte Herzfrequenzvariabilität spiegelt erhöhte vegetative Anspannung wider.\n'
                  '• Basislinie: Um verlässliche Aussagen zu treffen, benötigt ORBIT mindestens 14 aufgezeichnete Tage.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    l10n?.health_info_disclaimer ??
                        'Hinweis: Die Tagesform ist eine sportwissenschaftliche Orientierungshilfe zur Trainingssteuerung und Erholung. Sie stellt keine medizinische Diagnose oder Behandlungsempfehlung dar.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Verstanden'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
