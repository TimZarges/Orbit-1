import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../../features/workout_builder/domain/workout_parser.dart';
import '../../features/workout_builder/widgets/workout_profile_chart.dart';
import '../../features/analysis/models/form_traffic_light.dart';
import '../../features/analysis/models/weekly_load_summary.dart';
import '../../features/analysis/models/consistency_summary.dart';
import '../../features/analysis/models/sport_distribution.dart';
import '../../features/analysis/models/zone_distribution.dart';
import '../../features/analysis/domain/aggregates_calculator.dart';
import '../../features/analysis/widgets/form_traffic_light_card.dart';
import '../../features/analysis/widgets/weekly_load_card.dart';
import '../../features/analysis/widgets/consistency_card.dart';
import '../../features/analysis/widgets/sport_distribution_card.dart';
import '../../features/analysis/widgets/zone_distribution_card.dart';
import '../../features/analysis/widgets/weekly_load_trend_chart.dart';
import '../../features/analysis/widgets/fitness_fatigue_trend_chart.dart';
import 'dart:math';
import '../../features/activities/models/activity_stream.dart';
import '../../features/activities/models/power_duration_curve.dart';
import '../../features/activities/widgets/telemetry_channel_chips.dart';
import '../../features/activities/widgets/telemetry_chart_widget.dart';
import '../../features/activities/widgets/telemetry_map_widget.dart';
import '../../features/activities/widgets/power_duration_curve_widget.dart';
import '../../features/diagnostics/models/threshold_proposal.dart';
import '../../features/diagnostics/models/threshold_entry.dart';
import '../../features/diagnostics/models/guided_test_info.dart';
import '../../features/diagnostics/widgets/threshold_proposal_card.dart';
import '../../features/diagnostics/widgets/guided_test_card.dart';
import '../../features/diagnostics/widgets/threshold_history_chart.dart';
import '../../features/chat/models/chat_message.dart';
import '../../features/chat/widgets/chat_bubble.dart';
import '../../features/home/models/race_goal.dart';
import '../../features/home/widgets/home_hero_card.dart';
import '../../features/home/widgets/home_action_banner.dart';
import '../../features/home/widgets/race_countdown_card.dart';
import '../../features/calendar/models/planned_workout.dart';
import '../../features/coach_link/widgets/keyboard_shortcuts_dialog.dart';

class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Galerie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Typography', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Text('Display', style: Theme.of(context).textTheme.displayLarge),
          Text('Title', style: Theme.of(context).textTheme.titleLarge),
          Text('Body', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          Text('Colors', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ColorBox(color: Theme.of(context).primaryColor, name: 'Navy'),
              _ColorBox(
                  color: Theme.of(context).colorScheme.secondary, name: 'Volt'),
            ],
          ),
          const SizedBox(height: 32),
          Text('Workout Profil (Live-Balkengrafik)',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              const parser = WorkoutParser(sport: 'BIKE');
              final result = parser.parse("10' Z1, 4x(4' Z4 / 2' Z1), 10' Z1");
              return WorkoutProfileChart(
                  structure: result.structure, height: 100);
            },
          ),
          const SizedBox(height: 32),
          Text('Trainingsanalyse (Phase 10)',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),

          // 1. Form-Ampel
          const FormTrafficLightCard(
            form: FormTrafficLight(
              status: FormStatus.wellLoaded,
              ctl: 58,
              atl: 68,
              tsb: -10,
              ratio: -0.17,
              daysOfHistory: 42,
            ),
          ),
          const SizedBox(height: 16),

          // 2. Wochenbelastung
          const WeeklyLoadCard(
            summary: WeeklyLoadSummary(
              actualLoad: 420,
              plannedLoad: 450,
              hasPlan: true,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Konsistenz
          const ConsistencyCard(
            consistency: ConsistencySummary(
              activeDays: 5,
              totalDays: 7,
              plannedDays: 5,
              streakWeeks: 4,
            ),
          ),
          const SizedBox(height: 16),

          // 4. Sportverteilung
          SportDistributionCard(
            summary: SportDistributionSummary.fromDurations(const {
              'BIKE': 14400,
              'RUN': 7200,
              'SWIM': 3600,
              'STRENGTH': 2400,
            }),
          ),
          const SizedBox(height: 16),

          // 5. Zonenverteilung
          ZoneDistributionCard(
            summary: ZoneDistributionSummary.fromSeconds(const [
              1800,
              10800,
              3600,
              1800,
              900,
              300,
              60,
            ]),
          ),
          const SizedBox(height: 16),

          // 6. 8-Wochen-Trend
          const WeeklyLoadTrendChart(
            points: [
              WeeklyLoadTrendPoint(
                  weekNumber: 1, weekLabel: 'W1', totalLoad: 280),
              WeeklyLoadTrendPoint(
                  weekNumber: 2, weekLabel: 'W2', totalLoad: 320),
              WeeklyLoadTrendPoint(
                  weekNumber: 3, weekLabel: 'W3', totalLoad: 350),
              WeeklyLoadTrendPoint(
                  weekNumber: 4, weekLabel: 'W4', totalLoad: 200),
              WeeklyLoadTrendPoint(
                  weekNumber: 5, weekLabel: 'W5', totalLoad: 380),
              WeeklyLoadTrendPoint(
                  weekNumber: 6, weekLabel: 'W6', totalLoad: 410),
              WeeklyLoadTrendPoint(
                  weekNumber: 7, weekLabel: 'W7', totalLoad: 440),
              WeeklyLoadTrendPoint(
                  weekNumber: 8, weekLabel: 'Aktuell', totalLoad: 420),
            ],
            trendDescription:
                'Belastung in den letzten 8 Wochen moderat gestiegen (+18 %).',
          ),
          const SizedBox(height: 16),

          // 7. CTL/ATL/TSB Verlauf
          const FitnessFatigueTrendChart(
            points: [
              FitnessFatiguePoint(
                  date: '2026-08-01', ctl: 40, atl: 45, tsb: -5),
              FitnessFatiguePoint(
                  date: '2026-08-15', ctl: 48, atl: 55, tsb: -7),
              FitnessFatiguePoint(
                  date: '2026-09-01', ctl: 52, atl: 62, tsb: -10),
              FitnessFatiguePoint(date: '2026-09-15', ctl: 55, atl: 50, tsb: 5),
              FitnessFatiguePoint(
                  date: '2026-10-01', ctl: 58, atl: 68, tsb: -10),
            ],
          ),
          const SizedBox(height: 32),

          Text('Cockpit Telemetrie (Phase 11)',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF003875)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Cockpit Telemetrie',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final points = List.generate(120, (i) {
                      return ActivityStreamPoint(
                        timeSec: i * 10,
                        power: 200.0 + (sin(i / 10) * 80),
                        hr: 135.0 + (sin(i / 10) * 20),
                        speedMps: 8.0 + (sin(i / 10) * 2),
                        cadence: 88.0 + (sin(i / 5) * 5),
                        altitudeM: 100.0 + (i * 2),
                        lat: 50.11 + sin(i / 20) * 0.02,
                        lng: 8.68 + cos(i / 20) * 0.03,
                        distanceM: i * 80.0,
                      );
                    });

                    return Column(
                      children: [
                        TelemetryChartWidget(
                          points: points,
                          activeChannels: const {
                            TelemetryChannel.power,
                            TelemetryChannel.heartRate,
                            TelemetryChannel.altitude,
                          },
                        ),
                        const SizedBox(height: 16),
                        TelemetryMapWidget(
                          points: points,
                          initialTilesEnabled: true,
                        ),
                        const SizedBox(height: 16),
                        const PowerDurationCurveWidget(
                          curve: PowerDurationCurve(
                            points: [
                              PowerDurationPoint(
                                  durationSec: 5,
                                  activityWatts: 620,
                                  allTimeBestWatts: 600),
                              PowerDurationPoint(
                                  durationSec: 60,
                                  activityWatts: 380,
                                  seasonBestWatts: 360),
                              PowerDurationPoint(
                                  durationSec: 300,
                                  activityWatts: 295,
                                  allTimeBestWatts: 310),
                              PowerDurationPoint(
                                  durationSec: 1200,
                                  activityWatts: 260,
                                  allTimeBestWatts: 270),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Leistungsdiagnostik & Schwellenwerte (Phase 12)',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          ThresholdProposalCard(
            proposal: ThresholdProposal(
              id: 'prop_demo_1',
              athleteId: 'demo',
              sport: 'BIKE',
              type: ThresholdType.ftp,
              proposedValue: 268.0,
              currentValue: 255.0,
              delta: 13.0,
              deltaPercent: 5.1,
              confidence: ConfidenceLevel.high,
              basis: const [
                '20-Minuten-Bestwert: 282 W am 12.10.2026',
                'Pacing-Gleichmäßigkeit: VI = 1.03',
              ],
              explanationDe:
                  'Basierend auf deinem 20-Minuten-Bestwert von 282 W vom 12.10. ergibt sich ein neuer FTP von 268 W (+13 W, +5.1 %).',
              explanationEn:
                  'Based on your 20-min peak of 282 W, your estimated FTP is 268 W (+13 W).',
              createdAt: DateTime.now(),
            ),
            onAccept: () {},
            onReject: () {},
          ),
          const SizedBox(height: 16),
          GuidedTestCard(
            testInfo: GuidedTestInfo.standardTests.first,
            onSchedule: () {},
          ),
          const SizedBox(height: 16),
          ThresholdHistoryChart(
            entries: [
              ThresholdEntry(
                id: '1',
                effectiveFrom: '2026-05-01',
                ftpW: 240.0,
                createdAt: DateTime(2026, 5, 1),
              ),
              ThresholdEntry(
                id: '2',
                effectiveFrom: '2026-07-15',
                ftpW: 250.0,
                createdAt: DateTime(2026, 7, 15),
              ),
              ThresholdEntry(
                id: '3',
                effectiveFrom: '2026-09-01',
                ftpW: 258.0,
                createdAt: DateTime(2026, 9, 1),
              ),
              ThresholdEntry(
                id: '4',
                effectiveFrom: '2026-10-13',
                ftpW: 268.0,
                createdAt: DateTime(2026, 10, 13),
              ),
            ],
            type: ThresholdType.ftp,
          ),
          const SizedBox(height: 32),
          Text('Chat & Nachrichten (Phase 13)',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          ChatBubble(
            message: ChatMessage(
              id: 'm1',
              chatId: 'c1',
              senderId: 'coach',
              type: MessageType.text,
              text:
                  'Hallo Tim! Die Intervalle gestern sahen technisch sehr stabil aus.',
              createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
            ),
            isMe: false,
          ),
          ChatBubble(
            message: ChatMessage(
              id: 'm2',
              chatId: 'c1',
              senderId: 'me',
              type: MessageType.text,
              text:
                  'Danke! Vor allem in Block 3 konnte ich den Druck gut halten.',
              createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
            ),
            isMe: true,
          ),
          ChatBubble(
            message: ChatMessage(
              id: 'm3',
              chatId: 'c1',
              senderId: 'me',
              type: MessageType.activityShare,
              activityShare: const ActivityShareSnapshot(
                activityId: 'act_demo_1',
                title: '4x4min Schwellenintervalle Rad',
                sport: 'BIKE',
                date: '13.10.2026',
                durationSec: 3600,
                distanceM: 32500,
                avgPowerW: 275,
                avgHr: 164,
              ),
              createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            isMe: true,
          ),
          ChatBubble(
            message: ChatMessage(
              id: 'm4',
              chatId: 'c1',
              senderId: 'me',
              type: MessageType.text,
              status: MessageStatus.deleted,
              createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
            ),
            isMe: true,
          ),
          const SizedBox(height: 32),
          Text('Home-Dashboard („Heute") (Phase 14)',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          const HomeActionBanner(
            pendingThresholdsCount: 1,
            unreadChatMessagesCount: 2,
          ),
          const SizedBox(height: 16),
          HomeHeroCard(
            actualLoad: 52.0,
            plannedWorkout: PlannedWorkout(
              id: 'w_demo',
              athleteId: 'a1',
              createdBy: 'a1',
              localDate: '2026-10-13',
              sport: 'BIKE',
              title: '4x4min Schwellenintervalle Rad',
              plannedDurationSec: 3600,
              plannedLoad: 68.0,
              status: 'PLANNED',
              createdAt: DateTime.now(),
            ),
          ),
          const SizedBox(height: 16),
          RaceCountdownCard(
            raceGoal: RaceGoal(
              title: 'Ironman 70.3 Kraichgau',
              date: '${DateTime.now().year + 1}-05-25',
              distance: 'Mitteldistanz',
            ),
          ),
          const SizedBox(height: 32),
          Text('Coach-Desktop & Web (Phase 15)',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => KeyboardShortcutsDialog.show(context),
            icon: const Icon(Icons.keyboard),
            label: const Text('Tastaturkürzel-Dialog öffnen (?)'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ColorBox extends StatelessWidget {
  final Color color;
  final String name;

  const _ColorBox({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: color,
      alignment: Alignment.center,
      child: Text(
        name,
        style: const TextStyle(
            color: Colors.white, shadows: [Shadow(blurRadius: 2)]),
      ),
    );
  }
}
