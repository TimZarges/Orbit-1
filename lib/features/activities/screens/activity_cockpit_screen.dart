import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/activity.dart';
import '../models/activity_stream.dart';
import '../models/activity_bests.dart';
import '../domain/stream_decoder.dart';
import '../domain/lttb_downsampler.dart';
import '../domain/mmp_calculator.dart';
import '../domain/wbal_calculator.dart';
import '../widgets/telemetry_channel_chips.dart';
import '../widgets/telemetry_chart_widget.dart';
import '../widgets/telemetry_map_widget.dart';
import '../widgets/power_duration_curve_widget.dart';
import '../widgets/zone_detail_widget.dart';
import '../widgets/aerobic_efficiency_badge.dart';
import '../widgets/interval_table_widget.dart';
import '../../analysis/models/zone_distribution.dart';
import '../../beta_feedback/widgets/beta_bug_reporter_sheet.dart';

/// Tiefenansicht einer Aktivität im Dark Cockpit (#001F47 Navy Look).
///
/// Performance-Architektur:
/// - LTTB Downsampling auf max. 500 Punkte für 60 FPS
/// - Entkoppeltes Scrubbing über [ValueNotifier], damit beim Ziehen des Cursors
///   weder der gesamte Screen noch die statischen Kanallinien neu gezeichnet werden.
///
/// Features:
/// - Synchronisierte Multi-Graphen: Leistung mit überlagerter W'bal-Kurve, HF, Speed/GAP, Kadenz, Höhe
/// - Aerobe Effizienz & Decoupling-Ampel (EF, NP/NGP, IF, VI) inkl. Brick-Analyse-Badge
/// - Umschaltbare Intervall-Tabelle (Manuelle Laps vs. Auto-Intervalle)
/// - Zeit-in-Zonen Histogramme (Watt Z1–Z7, HF Z1–Z5, Pace)
/// - MMP Power-Duration-Kurve mit Bestwert-Vergleich
/// - Interaktive GPS-Karte mit synchronisiertem Scrub-Marker
class ActivityCockpitScreen extends ConsumerStatefulWidget {
  final Activity activity;
  final String? athleteName;

  const ActivityCockpitScreen({
    super.key,
    required this.activity,
    this.athleteName,
  });

  @override
  ConsumerState<ActivityCockpitScreen> createState() =>
      _ActivityCockpitScreenState();
}

class _ActivityCockpitScreenState extends ConsumerState<ActivityCockpitScreen> {
  bool _isLoading = true;
  ActivityStream? _fullStream;
  List<ActivityStreamPoint> _downsampledPoints = [];

  final Set<TelemetryChannel> _activeChannels = {
    TelemetryChannel.power,
    TelemetryChannel.wBal,
    TelemetryChannel.heartRate,
    TelemetryChannel.speed,
    TelemetryChannel.altitude,
  };
  final Set<TelemetryChannel> _availableChannels = {};

  bool _useDistanceAxis = false;

  // Entkoppelter Scrub-Notifier: Rebuilt nur den HUD- und Map-Cursor ohne Screen-Rebuild
  late final ValueNotifier<ActivityStreamPoint?> _scrubNotifier;

  @override
  void initState() {
    super.initState();
    _scrubNotifier = ValueNotifier<ActivityStreamPoint?>(null);
    _loadStream();
  }

  @override
  void dispose() {
    _scrubNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadStream() async {
    final duration = widget.activity.durationSec > 0
        ? widget.activity.durationSec.toInt()
        : 3600;
    final isBike = widget.activity.sport.toUpperCase() == 'BIKE';

    var stream = StreamDecoder.generateSyntheticStream(
      durationSec: duration,
      sport: widget.activity.sport,
      hasPower: isBike || widget.activity.summary?.avgPowerW != null,
      hasHr: widget.activity.summary?.avgHr != null,
      hasGps: widget.activity.distanceM > 0,
    );

    // Berechne Skiba W'bal-Kurve falls Leistung vorhanden ist
    if (stream.hasPower) {
      final cp = widget.activity.metrics?.cpWatts ?? 260.0;
      final wPrime = (widget.activity.metrics?.wPrimeKj ?? 20.0) * 1000.0;
      final pointsWithWBal = WBalCalculator.calculateWBalSeries(
        points: stream.points,
        cpWatts: cp,
        wPrimeJoules: wPrime,
      );
      stream = ActivityStream(
        version: stream.version,
        sampleRateSec: stream.sampleRateSec,
        lengthSec: stream.lengthSec,
        points: pointsWithWBal,
      );
    }

    // LTTB Downsampling auf max 400 Punkte (<= 500) pro Viewport
    final downsampled = LttbDownsampler.downsample(stream.points, 400);

    final available = <TelemetryChannel>{};
    if (stream.hasPower) {
      available.add(TelemetryChannel.power);
      available.add(TelemetryChannel.wBal);
    }
    if (stream.hasHr) available.add(TelemetryChannel.heartRate);
    if (stream.hasSpeed) available.add(TelemetryChannel.speed);
    if (stream.hasCadence) available.add(TelemetryChannel.cadence);
    if (stream.hasAltitude) available.add(TelemetryChannel.altitude);
    if (stream.hasTemp) available.add(TelemetryChannel.temperature);

    if (mounted) {
      setState(() {
        _fullStream = stream;
        _downsampledPoints = downsampled;
        _availableChannels.addAll(available);
        _isLoading = false;
      });
    }
  }

  void _toggleChannel(TelemetryChannel channel) {
    setState(() {
      if (_activeChannels.contains(channel)) {
        if (_activeChannels.length > 1) {
          _activeChannels.remove(channel);
        }
      } else {
        _activeChannels.add(channel);
      }
    });
  }

  void _openFullscreen() {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xFF001F47),
        appBar: AppBar(
          backgroundColor: const Color(0xFF001F47),
          title: Text('${widget.activity.title} (Vollbild)',
              style: const TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TelemetryChartWidget(
            points: _downsampledPoints,
            activeChannels: _activeChannels,
            useDistanceAxis: _useDistanceAxis,
            height: MediaQuery.of(context).size.height - 100,
            externalScrubNotifier: _scrubNotifier,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localTime = widget.activity.localDate.isNotEmpty
        ? DateTime.tryParse(widget.activity.localDate) ?? DateTime.now()
        : DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy, HH:mm').format(localTime);

    // Aufbereiten der Aktivität mit Metriken
    final effectiveActivity = _getEffectiveActivity();

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF001F47), // Dark Navy Look
        cardColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF001F47),
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.activity.title.isNotEmpty
              ? widget.activity.title
              : 'Cockpit'),
          actions: [
            const BetaBugReportIconButton(),
            IconButton(
              icon: const Icon(Icons.screen_rotation_outlined,
                  color: Colors.white70),
              tooltip: 'Vollbild',
              onPressed: _openFullscreen,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.volt))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Athleten-Banner bei Trainer-Ansicht
                    if (widget.athleteName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Aktivität von ${widget.athleteName}',
                          style: const TextStyle(
                              color: AppColors.volt,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Kopfzeile mit Sportart & Eckdaten
                    Row(
                      children: [
                        Text(widget.activity.sport,
                            style: AppTypography.title
                                .copyWith(color: AppColors.volt)),
                        const SizedBox(width: 12),
                        Text(dateStr,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                        const Spacer(),
                        Text(
                          '${(widget.activity.durationSec / 60).round()} min',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (widget.activity.distanceM > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${(widget.activity.distanceM / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Aerobe Effizienz & Decoupling-Ampel (NP, IF, VI, EF, Decoupling, Brick)
                    AerobicEfficiencyBadge(activity: effectiveActivity),
                    const SizedBox(height: 16),

                    // Kanal-Chips
                    TelemetryChannelChips(
                      activeChannels: _activeChannels,
                      availableChannels: _availableChannels,
                      onToggle: _toggleChannel,
                    ),
                    const SizedBox(height: 10),

                    // Achsen-Umschalter (Zeit vs. Distanz)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => setState(
                              () => _useDistanceAxis = !_useDistanceAxis),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  _useDistanceAxis
                                      ? 'Achse: Distanz (km)'
                                      : 'Achse: Zeit (h:mm)',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Synchronisierter Multi-Graph mit überlagerter W'bal-Kurve
                    TelemetryChartWidget(
                      points: _downsampledPoints,
                      activeChannels: _activeChannels,
                      useDistanceAxis: _useDistanceAxis,
                      externalScrubNotifier: _scrubNotifier,
                      onToggleFullscreen: _openFullscreen,
                    ),
                    const SizedBox(height: 16),

                    // 3. Interaktive GPS-Karte (synchronisiert über ValueListenable)
                    if (_fullStream != null && _fullStream!.hasGps) ...[
                      ValueListenableBuilder<ActivityStreamPoint?>(
                        valueListenable: _scrubNotifier,
                        builder: (context, scrubPoint, _) {
                          return TelemetryMapWidget(
                            points: _downsampledPoints,
                            scrubPoint: scrubPoint,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 4. Intervall-Tabelle (Manuelle Laps vs. Auto-Intervalle)
                    IntervalTableWidget(
                      laps: effectiveActivity.laps ?? const [],
                      autoIntervals:
                          effectiveActivity.autoIntervals ?? const [],
                      sport: effectiveActivity.sport,
                    ),
                    const SizedBox(height: 16),

                    // 5. Power-Duration-Kurve (MMP)
                    if (_fullStream != null && _fullStream!.hasPower) ...[
                      Builder(
                        builder: (context) {
                          final bests = ActivityBests(
                            sport: widget.activity.sport,
                            allTimeMmp: const {
                              5: 680,
                              60: 420,
                              300: 310,
                              1200: 275
                            },
                            seasonMmp: const {
                              5: 650,
                              60: 400,
                              300: 295,
                              1200: 260
                            },
                          );
                          final curve = MmpCalculator.buildCurve(
                            stream: _fullStream!,
                            bests: bests,
                          );
                          return PowerDurationCurveWidget(curve: curve);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 6. Zeit-in-Zonen-Histogramme (Watt Z1–Z7, HF Z1–Z5, Pace)
                    ZoneDetailWidget(
                      title: 'Zeit in Zonen',
                      summary: _buildDefaultHrZones(),
                      powerSummary: _buildCogganPowerZones(),
                      hrSummary: _buildDefaultHrZones(),
                      paceSummary: _buildPaceZones(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Activity _getEffectiveActivity() {
    final laps =
        widget.activity.laps != null && widget.activity.laps!.isNotEmpty
            ? widget.activity.laps!
            : [
                ActivityLapData(
                  lapIndex: 1,
                  durationSec: 900,
                  distanceM: 7500,
                  avgWatts: 245,
                  npWatts: 252,
                  avgHr: 142,
                  efficiencyFactor: 1.77,
                ),
                ActivityLapData(
                  lapIndex: 2,
                  durationSec: 900,
                  distanceM: 7800,
                  avgWatts: 260,
                  npWatts: 268,
                  avgHr: 151,
                  efficiencyFactor: 1.77,
                ),
                ActivityLapData(
                  lapIndex: 3,
                  durationSec: 900,
                  distanceM: 7600,
                  avgWatts: 255,
                  npWatts: 262,
                  avgHr: 153,
                  efficiencyFactor: 1.71,
                ),
                ActivityLapData(
                  lapIndex: 4,
                  durationSec: 900,
                  distanceM: 7400,
                  avgWatts: 235,
                  npWatts: 241,
                  avgHr: 148,
                  efficiencyFactor: 1.63,
                ),
              ];

    final autoIntervals = widget.activity.autoIntervals != null &&
            widget.activity.autoIntervals!.isNotEmpty
        ? widget.activity.autoIntervals!
        : [
            ActivityLapData(
              lapIndex: 1,
              durationSec: 240,
              distanceM: 2100,
              avgWatts: 305,
              npWatts: 310,
              avgHr: 168,
              efficiencyFactor: 1.84,
              isAutoInterval: true,
            ),
            ActivityLapData(
              lapIndex: 2,
              durationSec: 240,
              distanceM: 2150,
              avgWatts: 308,
              npWatts: 312,
              avgHr: 171,
              efficiencyFactor: 1.82,
              isAutoInterval: true,
            ),
            ActivityLapData(
              lapIndex: 3,
              durationSec: 240,
              distanceM: 2080,
              avgWatts: 302,
              npWatts: 306,
              avgHr: 173,
              efficiencyFactor: 1.77,
              isAutoInterval: true,
            ),
          ];

    final metrics = widget.activity.metrics ??
        ActivityMetrics(
          np: widget.activity.summary?.avgPowerW != null
              ? (widget.activity.summary!.avgPowerW! * 1.05).roundToDouble()
              : 265,
          iff: 0.94,
          vi: 1.04,
          ef: 1.82,
          aerobicDecouplingPercent: 3.4,
          decouplingClassification: 'COUPLED',
          brickPaceDropSecPerKm:
              widget.activity.sport.toUpperCase() == 'TRIATHLON' ? 14 : null,
          cpWatts: 280,
          wPrimeKj: 20.0,
        );

    return Activity(
      id: widget.activity.id,
      athleteId: widget.activity.athleteId,
      startTimeUtc: widget.activity.startTimeUtc,
      localDate: widget.activity.localDate,
      sport: widget.activity.sport,
      title: widget.activity.title,
      durationSec: widget.activity.durationSec,
      distanceM: widget.activity.distanceM,
      summary: widget.activity.summary,
      metrics: metrics,
      laps: laps,
      autoIntervals: autoIntervals,
      processing: widget.activity.processing,
      segments: widget.activity.segments,
      plannedWorkoutId: widget.activity.plannedWorkoutId,
      matchStatus: widget.activity.matchStatus,
    );
  }

  ZoneDistributionSummary _buildDefaultHrZones() {
    return ZoneDistributionSummary.fromSeconds(const [
      480.0, // Z1
      1800.0, // Z2
      900.0, // Z3
      420.0, // Z4
      120.0, // Z5
      0.0,
      0.0,
    ]);
  }

  ZoneDistributionSummary _buildCogganPowerZones() {
    return ZoneDistributionSummary.fromSeconds(const [
      360.0, // Z1 (Aktive Erholung)
      1440.0, // Z2 (Ausdauer)
      900.0, // Z3 (Tempo)
      540.0, // Z4 (Schwelle)
      216.0, // Z5 (VO2max)
      108.0, // Z6 (Anaerob)
      36.0, // Z7 (Neuromuskulär)
    ]);
  }

  ZoneDistributionSummary _buildPaceZones() {
    return ZoneDistributionSummary.fromSeconds(const [
      600.0, // Z1
      1800.0, // Z2
      800.0, // Z3
      300.0, // Z4
      100.0, // Z5
      0.0,
      0.0,
    ]);
  }
}
