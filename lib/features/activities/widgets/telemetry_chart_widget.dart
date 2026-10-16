import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../models/activity_stream.dart';
import 'telemetry_channel_chips.dart';

/// Interaktives Telemetrie-Chart im Dark Cockpit (#001F47 / #0F172A).
///
/// Performance-Architektur:
/// - Statische Kanallinien (Watt, W'bal, HF, Speed, Kadenz, Höhe) sind in einem
///   eigenen [RepaintBoundary] gekapselt und werden bei Scrub-Bewegungen NICHT neu gezeichnet.
/// - Der Scrubbing-Cursor und das HUD sind über [ValueNotifier] entkoppelt,
///   sodass Fingerbewegungen mit < 16 ms Frame-Zeit (60/120 FPS) gerendert werden.
class TelemetryChartWidget extends StatefulWidget {
  final List<ActivityStreamPoint> points;
  final Set<TelemetryChannel> activeChannels;
  final bool useDistanceAxis;
  final ValueChanged<ActivityStreamPoint?>? onScrub;
  final VoidCallback? onToggleFullscreen;
  final double height;
  final ValueNotifier<ActivityStreamPoint?>? externalScrubNotifier;

  const TelemetryChartWidget({
    super.key,
    required this.points,
    required this.activeChannels,
    this.useDistanceAxis = false,
    this.onScrub,
    this.onToggleFullscreen,
    this.height = 240,
    this.externalScrubNotifier,
  });

  @override
  State<TelemetryChartWidget> createState() => _TelemetryChartWidgetState();
}

class _TelemetryChartWidgetState extends State<TelemetryChartWidget> {
  late final ValueNotifier<int?> _scrubIndexNotifier;
  late final ValueNotifier<Offset?> _scrubPositionNotifier;

  @override
  void initState() {
    super.initState();
    _scrubIndexNotifier = ValueNotifier<int?>(null);
    _scrubPositionNotifier = ValueNotifier<Offset?>(null);
  }

  @override
  void dispose() {
    _scrubIndexNotifier.dispose();
    _scrubPositionNotifier.dispose();
    super.dispose();
  }

  void _handleLongPressStart(
      LongPressStartDetails details, BoxConstraints constraints) {
    HapticFeedback.selectionClick();
    _updateScrub(details.localPosition.dx, constraints.maxWidth);
  }

  void _handleLongPressMoveUpdate(
      LongPressMoveUpdateDetails details, BoxConstraints constraints) {
    _updateScrub(details.localPosition.dx, constraints.maxWidth);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _scrubIndexNotifier.value = null;
    _scrubPositionNotifier.value = null;
    widget.onScrub?.call(null);
    widget.externalScrubNotifier?.value = null;
  }

  void _updateScrub(double dx, double width) {
    if (widget.points.isEmpty || width <= 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    final index = (fraction * (widget.points.length - 1)).round();

    if (_scrubIndexNotifier.value != index) {
      HapticFeedback.selectionClick();
    }

    _scrubIndexNotifier.value = index;
    _scrubPositionNotifier.value = Offset(dx.clamp(0.0, width), 0);

    final pt = widget.points[index];
    widget.onScrub?.call(pt);
    widget.externalScrubNotifier?.value = pt;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Container(
        height: widget.height,
        color: const Color(0xFF001F47),
        alignment: Alignment.center,
        child: const Text('Keine Telemetrie-Daten vorhanden',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onLongPressStart: (d) => _handleLongPressStart(d, constraints),
              onLongPressMoveUpdate: (d) =>
                  _handleLongPressMoveUpdate(d, constraints),
              onLongPressEnd: _handleLongPressEnd,
              onHorizontalDragStart: (d) =>
                  _updateScrub(d.localPosition.dx, constraints.maxWidth),
              onHorizontalDragUpdate: (d) =>
                  _updateScrub(d.localPosition.dx, constraints.maxWidth),
              onHorizontalDragEnd: (_) =>
                  _handleLongPressEnd(const LongPressEndDetails()),
              child: Container(
                height: widget.height,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF001F47), // Dark Navy Cockpit
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Stack(
                  children: [
                    // 1. Statische Kanallinien (isoliert in RepaintBoundary für 60 FPS)
                    RepaintBoundary(
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, widget.height),
                        painter: _TelemetryChartStaticPainter(
                          points: widget.points,
                          activeChannels: widget.activeChannels,
                          useDistanceAxis: widget.useDistanceAxis,
                        ),
                      ),
                    ),

                    // 2. Entkoppelter Scrubbing Cursor (nur Cursor repainted bei Fingerbewegung)
                    RepaintBoundary(
                      child: ValueListenableBuilder<int?>(
                        valueListenable: _scrubIndexNotifier,
                        builder: (context, scrubIndex, _) {
                          if (scrubIndex == null)
                            return const SizedBox.shrink();
                          return CustomPaint(
                            size: Size(constraints.maxWidth, widget.height),
                            painter: _TelemetryCursorPainter(
                              pointsCount: widget.points.length,
                              scrubIndex: scrubIndex,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating HUD über dem Finger (nur bei aktivem Scrubbing aktualisiert)
            ValueListenableBuilder<int?>(
              valueListenable: _scrubIndexNotifier,
              builder: (context, scrubIndex, _) {
                if (scrubIndex == null) return const SizedBox.shrink();
                final scrubPoint = widget.points[scrubIndex];
                final scrubPos = _scrubPositionNotifier.value;
                if (scrubPos == null) return const SizedBox.shrink();

                return Positioned(
                  left: (scrubPos.dx - 80)
                      .clamp(8.0, constraints.maxWidth - 170.0),
                  top: -55,
                  child: _buildHud(scrubPoint),
                );
              },
            ),

            // Vollbild-Button oben rechts
            if (widget.onToggleFullscreen != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen,
                      color: Colors.white70, size: 20),
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: widget.onToggleFullscreen,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHud(ActivityStreamPoint point) {
    final timeStr = _formatTime(point.timeSec);
    final distKm = (point.distanceM / 1000).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentVolt.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.useDistanceAxis
                ? '$distKm km ($timeStr)'
                : '$timeStr ($distKm km)',
            style: AppTypography.label.copyWith(
                color: AppColors.accentVolt,
                fontWeight: FontWeight.bold,
                fontSize: 10),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            children: [
              if (widget.activeChannels.contains(TelemetryChannel.power) &&
                  point.power != null)
                Text('${point.power!.round()} W',
                    style: TextStyle(
                        color: TelemetryChannel.power.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if ((widget.activeChannels.contains(TelemetryChannel.wBal) ||
                      widget.activeChannels.contains(TelemetryChannel.power)) &&
                  point.wBalPercent != null)
                Text("W'bal ${point.wBalPercent!.round()}%",
                    style: TextStyle(
                        color: TelemetryChannel.wBal.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (widget.activeChannels.contains(TelemetryChannel.heartRate) &&
                  point.hr != null)
                Text('${point.hr!.round()} bpm',
                    style: TextStyle(
                        color: TelemetryChannel.heartRate.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (widget.activeChannels.contains(TelemetryChannel.speed) &&
                  point.speedMps != null)
                Text('${(point.speedMps! * 3.6).toStringAsFixed(1)} km/h',
                    style: TextStyle(
                        color: TelemetryChannel.speed.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (widget.activeChannels.contains(TelemetryChannel.cadence) &&
                  point.cadence != null)
                Text('${point.cadence!.round()} rpm',
                    style: TextStyle(
                        color: TelemetryChannel.cadence.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              if (widget.activeChannels.contains(TelemetryChannel.altitude) &&
                  point.altitudeM != null)
                Text('${point.altitudeM!.round()} m',
                    style: TextStyle(
                        color: TelemetryChannel.altitude.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// Statischer Painter für die Telemetrielinien (wird durch RepaintBoundary isoliert).
class _TelemetryChartStaticPainter extends CustomPainter {
  final List<ActivityStreamPoint> points;
  final Set<TelemetryChannel> activeChannels;
  final bool useDistanceAxis;

  _TelemetryChartStaticPainter({
    required this.points,
    required this.activeChannels,
    this.useDistanceAxis = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final n = points.length;
    final w = size.width;
    final h = size.height - 20;

    final maxPower = points.map((p) => p.power ?? 0.0).fold(0.0, max);
    final maxHr = points.map((p) => p.hr ?? 0.0).fold(0.0, max);
    final maxSpeed = points.map((p) => p.speedMps ?? 0.0).fold(0.0, max);
    final maxCad = points.map((p) => p.cadence ?? 0.0).fold(0.0, max);
    final minAlt = points.map((p) => p.altitudeM ?? 0.0).fold(10000.0, min);
    final maxAlt = points.map((p) => p.altitudeM ?? 0.0).fold(-1000.0, max);

    final stepX = w / (n - 1);

    // 1. Höhe als weiches Backdrop-Band
    if (activeChannels.contains(TelemetryChannel.altitude) && maxAlt > minAlt) {
      final altPath = Path();
      altPath.moveTo(0, h);
      for (int i = 0; i < n; i++) {
        final x = i * stepX;
        final a = points[i].altitudeM ?? minAlt;
        final normA = (a - minAlt) / (maxAlt - minAlt);
        final y = h - (normA * (h * 0.45));
        altPath.lineTo(x, y);
      }
      altPath.lineTo(w, h);
      altPath.close();

      final altPaint = Paint()
        ..color = TelemetryChannel.altitude.color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawPath(altPath, altPaint);
    }

    // 2. W'bal Kurve (überlagert oder eigenständig)
    final hasWBalData = points.any((p) => p.wBalPercent != null);
    if ((activeChannels.contains(TelemetryChannel.wBal) ||
            activeChannels.contains(TelemetryChannel.power)) &&
        hasWBalData) {
      _drawLine(
        canvas,
        size,
        h,
        (p) => p.wBalPercent,
        100.0, // 0 bis 100%
        TelemetryChannel.wBal.color,
        strokeWidth: 1.8,
      );
    }

    // 3. Kanallinien
    if (activeChannels.contains(TelemetryChannel.power) && maxPower > 0) {
      _drawLine(canvas, size, h, (p) => p.power, maxPower * 1.1,
          TelemetryChannel.power.color,
          strokeWidth: 1.5);
    }

    if (activeChannels.contains(TelemetryChannel.heartRate) && maxHr > 0) {
      _drawLine(canvas, size, h, (p) => p.hr, maxHr * 1.05,
          TelemetryChannel.heartRate.color,
          strokeWidth: 1.5);
    }

    if (activeChannels.contains(TelemetryChannel.speed) && maxSpeed > 0) {
      _drawLine(canvas, size, h, (p) => p.speedMps, maxSpeed * 1.1,
          TelemetryChannel.speed.color,
          strokeWidth: 1.5);
    }

    if (activeChannels.contains(TelemetryChannel.cadence) && maxCad > 0) {
      _drawLine(canvas, size, h, (p) => p.cadence, maxCad * 1.1,
          TelemetryChannel.cadence.color,
          strokeWidth: 1.5);
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double h,
    double? Function(ActivityStreamPoint) getter,
    double maxScale,
    Color color, {
    double strokeWidth = 1.5,
  }) {
    final path = Path();
    bool started = false;
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final val = getter(points[i]);
      if (val != null && val >= 0) {
        final x = i * stepX;
        final y = h - (val / maxScale) * (h - 15);
        if (!started) {
          path.moveTo(x, y.clamp(0.0, h));
          started = true;
        } else {
          path.lineTo(x, y.clamp(0.0, h));
        }
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TelemetryChartStaticPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.activeChannels != activeChannels ||
        oldDelegate.useDistanceAxis != useDistanceAxis;
  }
}

/// Leichtgewichtiger Painter nur für Cursor-Linie und Indikator
class _TelemetryCursorPainter extends CustomPainter {
  final int pointsCount;
  final int scrubIndex;

  _TelemetryCursorPainter({
    required this.pointsCount,
    required this.scrubIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pointsCount < 2 || scrubIndex >= pointsCount) return;

    final w = size.width;
    final h = size.height - 20;
    final stepX = w / (pointsCount - 1);
    final scrubX = scrubIndex * stepX;

    final linePaint = Paint()
      ..color = AppColors.accentVolt
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(scrubX, 0), Offset(scrubX, h), linePaint);

    final dotPaint = Paint()
      ..color = AppColors.accentVolt
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(scrubX, h / 2), 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TelemetryCursorPainter oldDelegate) {
    return oldDelegate.scrubIndex != scrubIndex ||
        oldDelegate.pointsCount != pointsCount;
  }
}
