import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/daily_metrics.dart';
import '../models/health_baseline.dart';
import '../providers/health_provider.dart';
import '../services/health_demo_seeder.dart';
import '../widgets/three_rings_hero_card.dart';
import '../widgets/daily_journal_card.dart';
import '../widgets/correlation_insights_card.dart';
import '../widgets/health_report_card.dart';
import '../widgets/vital_trend_chart_card.dart';
import '../widgets/sleep_breakdown_card.dart';
import '../widgets/stress_body_battery_card.dart';

/// Haupt-Screen des Health- & Recovery-Cockpits (Whoop-Vorbild im ORBIT-Design).
///
/// Bietet:
/// 1. Drei-Ringe-Status (Erholung, Tagesbelastung, Schlaf, ORBIT Score)
/// 2. 15-Sekunden-Kurz-Journal & automatisierte Korrelations-Engine
/// 3. Wochen- & Monatsberichte
/// 4. 7-/30-/90-Tage Trendcharts mit 30-Tage-Normband (\mu \pm 1\sigma)
/// 5. Schlafphasen, Schlafbedarf, Schlafschuld & Body Battery
/// 6. Medizinischer Disclaimer
class HealthCockpitScreen extends ConsumerStatefulWidget {
  final String? athleteId;
  final String? athleteName;

  const HealthCockpitScreen({
    super.key,
    this.athleteId,
    this.athleteName,
  });

  @override
  ConsumerState<HealthCockpitScreen> createState() =>
      _HealthCockpitScreenState();
}

class _HealthCockpitScreenState extends ConsumerState<HealthCockpitScreen> {
  int _selectedDays = 30; // 7, 30 oder 90 Tage

  @override
  Widget build(BuildContext context) {
    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      currentUid = null;
    }
    final effectiveAthleteId = widget.athleteId ?? currentUid ?? 'current_user';

    final historyAsync =
        ref.watch(athleteDailyMetricsHistoryProvider(effectiveAthleteId));

    final rawHistory = historyAsync.valueOrNull ?? [];
    final List<DailyMetrics> history = rawHistory.isNotEmpty
        ? rawHistory
        : HealthDemoSeeder.generateDemoHistory();

    final now = DateTime.now();
    final todayStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    DailyMetrics? todayMetrics;
    for (final m in history) {
      if (m.localDate == todayStr) {
        todayMetrics = m;
        break;
      }
    }
    todayMetrics ??= history.isNotEmpty ? history.last : null;

    // Filter nach gewähltem Zeitraum (7, 30, 90 Tage)
    final filteredHistory = history.length > _selectedDays
        ? history.sublist(history.length - _selectedDays)
        : history;

    // Baselines (30 Tage)
    final baseline = HealthBaseline.fromMetrics(history);

    final title = widget.athleteName != null && widget.athleteName!.isNotEmpty
        ? 'Gesundheit: ${widget.athleteName}'
        : 'Gesundheit & Erholung';

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B), // Deep Navy Space Background
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF001F47),
        elevation: 0,
        actions: [
          _buildTimeframeDropdown(),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.volt,
        backgroundColor: AppColors.navy,
        onRefresh: () async {
          ref.invalidate(
              athleteDailyMetricsHistoryProvider(effectiveAthleteId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drei-Ringe-Hero-Card auf zwingendem Deep-Navy-Hintergrund (#001F47)
              ThreeRingsHeroCard(
                dailyMetrics: todayMetrics,
                actualLoad: todayMetrics?.strainData?.score.toDouble() ?? 55.0,
              ),
              const SizedBox(height: 18),

              // 2. Morgen-Check-in (15 Sek.)
              DailyJournalCard(
                athleteId: effectiveAthleteId,
                dateStr: todayStr,
                initialJournal: todayMetrics?.journal,
                onSaved: (updatedJournal) {
                  ref.invalidate(
                      athleteDailyMetricsHistoryProvider(effectiveAthleteId));
                },
              ),
              const SizedBox(height: 18),

              // 3. Korrelations-Insights
              CorrelationInsightsCard(history: history),
              const SizedBox(height: 18),

              // 4. Wochenbericht
              HealthReportCard(
                metrics: filteredHistory,
                title: _selectedDays == 7
                    ? 'Wochenbericht (7 Tage)'
                    : (_selectedDays == 30
                        ? 'Monatsbericht (30 Tage)'
                        : 'Quartalsbericht (90 Tage)'),
              ),
              const SizedBox(height: 18),

              // 5. HRV-Trendchart mit 30-Tage-Normband (\mu \pm 1\sigma)
              VitalTrendChartCard(
                title: 'Herzfrequenz-Variabilität (HRV)',
                unit: 'ms',
                points: filteredHistory.map((m) {
                  return VitalDataPoint(
                    date: DateTime.tryParse(m.localDate) ?? DateTime.now(),
                    value: (m.hrvMs ?? 0).toDouble(),
                    isMissing: m.hrvMs == null,
                  );
                }).toList(),
                baselineMean: baseline.meanHrv,
                baselineStd:
                    (baseline.stdHrv ?? 0) > 0 ? baseline.stdHrv! : 6.0,
                primaryColor: AppColors.volt,
                infoTooltip:
                    'HRV rmssd bei Nacht. Höhere Werte deuten auf parasympathische Dominanz und gute Erholung hin.',
              ),
              const SizedBox(height: 18),

              // 6. Ruhepuls-Trendchart mit 30-Tage-Normband
              VitalTrendChartCard(
                title: 'Ruhepuls (RHR)',
                unit: 'bpm',
                points: filteredHistory.map((m) {
                  return VitalDataPoint(
                    date: DateTime.tryParse(m.localDate) ?? DateTime.now(),
                    value: (m.restingHrBpm ?? 0).toDouble(),
                    isMissing: m.restingHrBpm == null,
                  );
                }).toList(),
                baselineMean: baseline.meanRestingHr,
                baselineStd: (baseline.stdRestingHr ?? 0) > 0
                    ? baseline.stdRestingHr!
                    : 2.5,
                primaryColor: const Color(0xFF38BDF8),
                lowerIsBetter: true,
                infoTooltip:
                    'Niedrigster Ruhepuls der Nacht. Ein Anstieg über den 30-Tage-Normbereich kann auf beginnende Ermüdung oder Infekt hinweisen.',
              ),
              const SizedBox(height: 18),

              // 7. Schlaf & Phasenanalyse
              SleepBreakdownCard(todayMetrics: todayMetrics),
              const SizedBox(height: 18),

              // 8. Atemfrequenz-Trendchart
              VitalTrendChartCard(
                title: 'Atemfrequenz bei Nacht',
                unit: 'Br/min',
                points: filteredHistory.map((m) {
                  final resp = m.respirationRateBreathsPerMin ?? 14.5;
                  return VitalDataPoint(
                    date: DateTime.tryParse(m.localDate) ?? DateTime.now(),
                    value: resp,
                    isMissing: false,
                  );
                }).toList(),
                baselineMean: 14.5,
                baselineStd: 0.8,
                primaryColor: AppColors.emerald,
                infoTooltip:
                    'Nächtliche Atemfrequenz. Sehr stabil – Abweichungen > 1 Br/min über dem Normbereich korrelieren häufig mit Immunreaktionen.',
              ),
              const SizedBox(height: 18),

              // 9. Stress & Body Battery
              StressBodyBatteryCard(
                todayMetrics: todayMetrics,
                history: filteredHistory,
              ),
              const SizedBox(height: 24),

              // 10. Medizinischer Disclaimer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sportwissenschaftlicher Hinweis: ORBIT ist kein Medizinprodukt. Alle Metriken, Baselines und Empfehlungen dienen ausschließlich der Trainingssteuerung und sportlichen Optimierung. Bei gesundheitlichen Beschwerden oder anhaltenden Anomalien wende dich bitte an medizinisches Fachpersonal.',
                        style: AppTypography.label.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedDays,
          dropdownColor: const Color(0xFF0F172A),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          icon: const Icon(Icons.arrow_drop_down,
              color: AppColors.volt, size: 20),
          items: const [
            DropdownMenuItem(value: 7, child: Text('7 Tage')),
            DropdownMenuItem(value: 30, child: Text('30 Tage')),
            DropdownMenuItem(value: 90, child: Text('90 Tage')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedDays = val);
            }
          },
        ),
      ),
    );
  }
}
