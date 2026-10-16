import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/daily_metrics.dart';

/// Karte für datenbasierte Korrelationen zwischen Lifestyle-Faktoren (Journal)
/// und physiologischer Erholung bzw. HRV.
///
/// Schaltet ab $N \ge 14$ Journal-Einträgen automatisierte Korrelations-Insights frei.
class CorrelationInsightsCard extends StatelessWidget {
  final List<DailyMetrics> history;

  const CorrelationInsightsCard({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final journalEntries = history
        .where((m) =>
            m.journal != null &&
            (m.journal!.tags != null && m.journal!.tags!.isNotEmpty ||
                m.journal!.hasAnyTag))
        .toList();
    final count = journalEntries.length;
    final isUnlocked = count >= 14;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.volt.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUnlocked ? Icons.auto_graph_rounded : Icons.lock_clock,
                  color: isUnlocked ? AppColors.volt : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lifestyle- & HRV-Korrelationen',
                      style: AppTypography.title.copyWith(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUnlocked
                          ? 'Wissenschaftliche Muster aus deinen Journal-Einträgen'
                          : 'Erfordert mindestens 14 Journal-Einträge für statistische Validität',
                      style: AppTypography.label.copyWith(
                        color: AppColors.techGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.volt.withValues(alpha: 0.15)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? AppColors.volt.withValues(alpha: 0.4)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  '$count / 14 Tage',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? AppColors.volt : AppColors.techGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isUnlocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (count / 14).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF1E293B),
                color: AppColors.volt,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Noch ${14 - count} Morgen-Check-ins nötig. Sobald 14 Tage erfasst sind, ermittelt ORBIT, wie Koffein, Alkohol, Schlaf oder Stress deine Erholung messbar verändern.',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ] else ...[
            _buildInsightsList(context),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsList(BuildContext context) {
    final insights = _computeInsights();

    if (insights.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Bislang keine statistisch signifikanten Abweichungen festgestellt. Deine Erholung verhält sich stabil gegenüber den erfassten Faktoren.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      );
    }

    return Column(
      children: insights.map((insight) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: insight.isNegative
                  ? AppColors.coral.withValues(alpha: 0.3)
                  : AppColors.emerald.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (insight.isNegative ? AppColors.coral : AppColors.emerald)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  insight.icon,
                  size: 16,
                  color:
                      insight.isNegative ? AppColors.coral : AppColors.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      insight.description,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (insight.isNegative ? AppColors.coral : AppColors.emerald)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.deltaLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: insight.isNegative
                        ? AppColors.coral
                        : AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<_CorrelationItem> _computeInsights() {
    final List<_CorrelationItem> list = [];

    // 1. Alkohol
    final alcoholDays =
        history.where((m) => m.journal?.alcohol == true).toList();
    final nonAlcoholDays = history
        .where((m) => m.journal != null && m.journal?.alcohol != true)
        .toList();

    if (alcoholDays.length >= 3 && nonAlcoholDays.length >= 5) {
      final avgHrvWith = _avg(alcoholDays.map((m) => m.hrvMs).whereType<int>());
      final avgHrvWithout =
          _avg(nonAlcoholDays.map((m) => m.hrvMs).whereType<int>());

      if (avgHrvWith > 0 && avgHrvWithout > 0) {
        final deltaHrv = avgHrvWith - avgHrvWithout;
        final pct = ((deltaHrv / avgHrvWithout) * 100).round();
        if (pct.abs() >= 5) {
          list.add(_CorrelationItem(
            title: 'Alkohol am Vorabend',
            description:
                'An Tagen nach Alkoholkonsum sinkt deine HRV um durchschnittlich ${deltaHrv.abs().round()} ms.',
            deltaLabel: '$pct % HRV',
            isNegative: pct < 0,
            icon: Icons.local_bar,
          ));
        }
      }
    }

    // 2. Spätes Koffein
    final caffeineDays =
        history.where((m) => m.journal?.lateCaffeine == true).toList();
    final nonCaffeineDays = history
        .where((m) => m.journal != null && m.journal?.lateCaffeine != true)
        .toList();

    if (caffeineDays.length >= 3 && nonCaffeineDays.length >= 5) {
      final avgSleepWith = _avg(caffeineDays.map((m) => m.effectiveSleepScore));
      final avgSleepWithout =
          _avg(nonCaffeineDays.map((m) => m.effectiveSleepScore));

      if (avgSleepWith > 0 && avgSleepWithout > 0) {
        final delta = avgSleepWith - avgSleepWithout;
        final pct = ((delta / avgSleepWithout) * 100).round();
        if (pct.abs() >= 5) {
          list.add(_CorrelationItem(
            title: 'Spätes Koffein (> 14 Uhr)',
            description:
                'Dein Schlaf-Score fällt an Tagen mit spätem Koffein um ${delta.abs().round()} Punkte geringer aus.',
            deltaLabel: '$pct % Schlaf',
            isNegative: pct < 0,
            icon: Icons.coffee,
          ));
        }
      }
    }

    // 3. Gute Hydration
    final hydrationDays =
        history.where((m) => m.journal?.goodHydration == true).toList();
    final nonHydrationDays = history
        .where((m) => m.journal != null && m.journal?.goodHydration != true)
        .toList();

    if (hydrationDays.length >= 3 && nonHydrationDays.length >= 5) {
      final avgRecWith =
          _avg(hydrationDays.map((m) => m.effectiveRecoveryScore));
      final avgRecWithout =
          _avg(nonHydrationDays.map((m) => m.effectiveRecoveryScore));

      if (avgRecWith > 0 && avgRecWithout > 0) {
        final delta = avgRecWith - avgRecWithout;
        final pct = ((delta / avgRecWithout) * 100).round();
        if (pct.abs() >= 4) {
          list.add(_CorrelationItem(
            title: 'Ausreichende Hydration',
            description:
                'Gute Flüssigkeitszufuhr korreliert mit einem Anstieg des Erholungsscores um +${delta.round()} %.',
            deltaLabel: '+$pct % Erholung',
            isNegative: false,
            icon: Icons.water_drop,
          ));
        }
      }
    }

    // 4. Hoher Stress
    final stressDays =
        history.where((m) => m.journal?.highStress == true).toList();
    final nonStressDays = history
        .where((m) => m.journal != null && m.journal?.highStress != true)
        .toList();

    if (stressDays.length >= 3 && nonStressDays.length >= 5) {
      final avgRhrWith =
          _avg(stressDays.map((m) => m.restingHrBpm).whereType<int>());
      final avgRhrWithout =
          _avg(nonStressDays.map((m) => m.restingHrBpm).whereType<int>());

      if (avgRhrWith > 0 && avgRhrWithout > 0) {
        final deltaRhr = avgRhrWith - avgRhrWithout;
        if (deltaRhr.abs() >= 2) {
          list.add(_CorrelationItem(
            title: 'Hoher Alltagsstress',
            description:
                'An stressigen Tagen liegt dein Ruhepuls um durchschnittlich ${deltaRhr.abs().round()} bpm höher.',
            deltaLabel: '+${deltaRhr.round()} bpm Ruhepuls',
            isNegative: true,
            icon: Icons.sentiment_dissatisfied,
          ));
        }
      }
    }

    return list;
  }

  double _avg(Iterable<num> values) {
    if (values.isEmpty) return 0;
    double sum = 0;
    int count = 0;
    for (final v in values) {
      sum += v;
      count++;
    }
    return count > 0 ? sum / count : 0;
  }
}

class _CorrelationItem {
  final String title;
  final String description;
  final String deltaLabel;
  final bool isNegative;
  final IconData icon;

  _CorrelationItem({
    required this.title,
    required this.description,
    required this.deltaLabel,
    required this.isNegative,
    required this.icon,
  });
}
