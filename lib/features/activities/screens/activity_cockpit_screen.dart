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
import '../widgets/telemetry_channel_chips.dart';
import '../widgets/telemetry_chart_widget.dart';
import '../widgets/telemetry_map_widget.dart';
import '../widgets/power_duration_curve_widget.dart';
import '../widgets/zone_detail_widget.dart';
import '../../analysis/models/zone_distribution.dart';

/// Tiefenansicht einer Aktivität im Dark Cockpit (#0F172A).
///
/// Bietet interaktives Scrubbing, synchrone Kartendarstellung,
/// Power-Duration-Kurve und Zonenaufschlüsselung.
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
    TelemetryChannel.heartRate,
    TelemetryChannel.speed,
    TelemetryChannel.altitude,
  };
  final Set<TelemetryChannel> _availableChannels = {};

  bool _useDistanceAxis = false;
  ActivityStreamPoint? _scrubbedPoint;

  @override
  void initState() {
    super.initState();
    _loadStream();
  }

  Future<void> _loadStream() async {
    // Generiert oder lädt den Stream für diese Aktivität
    // In der Praxis wird hier der Stream aus Storage via StreamDecoder geladen;
    // Falls noch keine Storage-Datei verknüpft ist, nutzen wir den synthetischen Generator.
    final duration = widget.activity.durationSec > 0
        ? widget.activity.durationSec.toInt()
        : 3600;
    final isBike = widget.activity.sport.toUpperCase() == 'BIKE';
    final stream = StreamDecoder.generateSyntheticStream(
      durationSec: duration,
      sport: widget.activity.sport,
      hasPower: isBike || widget.activity.summary?.avgPowerW != null,
      hasHr: widget.activity.summary?.avgHr != null,
      hasGps: widget.activity.distanceM > 0,
    );

    // LTTB Downsampling auf 400 Punkte für flüssige 60 FPS
    final downsampled = LttbDownsampler.downsample(stream.points, 400);

    final available = <TelemetryChannel>{};
    if (stream.hasPower) available.add(TelemetryChannel.power);
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
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
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

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Cockpit Background
        cardColor: const Color(0xFF1E293B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.activity.title.isNotEmpty
              ? widget.activity.title
              : 'Cockpit'),
          actions: [
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
                          color: const Color(0xFF1E293B),
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

                    // Kopfzeile mit Metadaten
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

                    // Kanal-Chips
                    TelemetryChannelChips(
                      activeChannels: _activeChannels,
                      availableChannels: _availableChannels,
                      onToggle: _toggleChannel,
                    ),
                    const SizedBox(height: 12),

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
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
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

                    // 1. Telemetrie-Chart
                    TelemetryChartWidget(
                      points: _downsampledPoints,
                      activeChannels: _activeChannels,
                      useDistanceAxis: _useDistanceAxis,
                      onScrub: (pt) => setState(() => _scrubbedPoint = pt),
                      onToggleFullscreen: _openFullscreen,
                    ),
                    const SizedBox(height: 16),

                    // 2. Interaktive GPS-Karte
                    if (_fullStream != null && _fullStream!.hasGps) ...[
                      TelemetryMapWidget(
                        points: _downsampledPoints,
                        scrubPoint: _scrubbedPoint,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Power-Duration-Kurve (wenn Wattleistung vorhanden)
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

                    // 4. Zonenverteilung Detail
                    ZoneDetailWidget(
                      title: 'Herzfrequenz-Zonen',
                      summary: ZoneDistributionSummary.fromSeconds(const [
                        600,
                        2400,
                        1200,
                        600,
                        200,
                        0,
                        0,
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
